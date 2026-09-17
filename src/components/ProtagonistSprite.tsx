// ProtagonistSprite - protagonist with continuous walk animation.
//
// SIZING CONTRACT (do not break):
// - All player PNGs are TRIMMED (canvas == visible content). If you
//   replace assets, trim them (scripts or PIL bbox crop) or the
//   character will visibly shrink/grow between idle and walk.
// - Render size is computed from the STATIC dimension table below —
//   never from Image.getSize (async → one-frame flicker at 48×48).
// - Height is fixed at CHARACTER_TARGET_HEIGHT for every frame and
//   direction; width follows each source's aspect ratio.
// - Anchor: bottom-center of the logical tile.
import React, { useEffect, useState } from 'react';
import { Animated, StyleSheet } from 'react-native';
import {
  TILE_SIZE,
  CHARACTER_TARGET_HEIGHT,
  WALK_FRAME_COUNT,
  WALK_FRAME_DURATION_MS,
} from '../config';

type Direction = 'front' | 'back' | 'left' | 'right';

// Walk animation frames (8 frames per direction)
const WALK_FRAMES = {
  front: [
    require('../../assets/images/player/walk/boy-walk-front-0.png'),
    require('../../assets/images/player/walk/boy-walk-front-1.png'),
    require('../../assets/images/player/walk/boy-walk-front-2.png'),
    require('../../assets/images/player/walk/boy-walk-front-3.png'),
    require('../../assets/images/player/walk/boy-walk-front-4.png'),
    require('../../assets/images/player/walk/boy-walk-front-5.png'),
    require('../../assets/images/player/walk/boy-walk-front-6.png'),
    require('../../assets/images/player/walk/boy-walk-front-7.png'),
  ],
  back: [
    require('../../assets/images/player/walk/boy-walk-back-0.png'),
    require('../../assets/images/player/walk/boy-walk-back-1.png'),
    require('../../assets/images/player/walk/boy-walk-back-2.png'),
    require('../../assets/images/player/walk/boy-walk-back-3.png'),
    require('../../assets/images/player/walk/boy-walk-back-4.png'),
    require('../../assets/images/player/walk/boy-walk-back-5.png'),
    require('../../assets/images/player/walk/boy-walk-back-6.png'),
    require('../../assets/images/player/walk/boy-walk-back-7.png'),
  ],
  left: [
    require('../../assets/images/player/walk/boy-walk-left-0.png'),
    require('../../assets/images/player/walk/boy-walk-left-1.png'),
    require('../../assets/images/player/walk/boy-walk-left-2.png'),
    require('../../assets/images/player/walk/boy-walk-left-3.png'),
    require('../../assets/images/player/walk/boy-walk-left-4.png'),
    require('../../assets/images/player/walk/boy-walk-left-5.png'),
    require('../../assets/images/player/walk/boy-walk-left-6.png'),
    require('../../assets/images/player/walk/boy-walk-left-7.png'),
  ],
  right: [
    require('../../assets/images/player/walk/boy-walk-right-0.png'),
    require('../../assets/images/player/walk/boy-walk-right-1.png'),
    require('../../assets/images/player/walk/boy-walk-right-2.png'),
    require('../../assets/images/player/walk/boy-walk-right-3.png'),
    require('../../assets/images/player/walk/boy-walk-right-4.png'),
    require('../../assets/images/player/walk/boy-walk-right-5.png'),
    require('../../assets/images/player/walk/boy-walk-right-6.png'),
    require('../../assets/images/player/walk/boy-walk-right-7.png'),
  ],
};

// Idle sprites (trimmed static poses)
const IDLE_SPRITES = {
  front: require('../../assets/images/player/boy-front.png'),
  back: require('../../assets/images/player/boy-back.png'),
  left: require('../../assets/images/player/boy-left.png'),
  right: require('../../assets/images/player/boy-right.png'),
};

// STATIC native dimensions of the trimmed assets (measured, checked by
// tests/sprites.test.ts). Update ONLY when replacing the asset files.
const NATIVE_DIMS = {
  walk: { width: 40, height: 106 }, // all 32 walk frames share this canvas
  idle: {
    front: { width: 25, height: 58 },
    back: { width: 24, height: 59 },
    left: { width: 25, height: 59 },
    right: { width: 25, height: 59 },
  },
} as const;

/** Deterministic render size: fixed target height, aspect-true width. */
function renderSize(isMoving: boolean, direction: Direction) {
  const dims = isMoving ? NATIVE_DIMS.walk : NATIVE_DIMS.idle[direction];
  const scale = CHARACTER_TARGET_HEIGHT / dims.height;
  return { width: dims.width * scale, height: CHARACTER_TARGET_HEIGHT };
}

interface Props {
  animatedX: Animated.Value;
  animatedY: Animated.Value;
  direction?: Direction;
  isMoving?: boolean;
}

export default function ProtagonistSprite({
  animatedX,
  animatedY,
  direction = 'front',
  isMoving = false,
}: Props) {
  const [frame, setFrame] = useState(0);

  // Continuous walk clock: frame derives from wall time, so the cycle
  // NEVER restarts between tiles (tile hops briefly toggle isMoving).
  // Direction changes swap the frame source but keep the gait phase.
  useEffect(() => {
    if (!isMoving) return; // keep last frame; idle sprite is shown anyway

    const tick = () =>
      setFrame(Math.floor(Date.now() / WALK_FRAME_DURATION_MS) % WALK_FRAME_COUNT);

    tick(); // sync immediately
    const interval = setInterval(tick, WALK_FRAME_DURATION_MS);
    return () => clearInterval(interval);
  }, [isMoving]);

  const spriteSource = isMoving
    ? WALK_FRAMES[direction][frame]
    : IDLE_SPRITES[direction];

  const size = renderSize(isMoving, direction);

  // Anchor: bottom-center of the tile (feet planted on tile base)
  const offsetX = (TILE_SIZE - size.width) / 2;
  const offsetY = TILE_SIZE - size.height;

  return (
    <Animated.Image
      source={spriteSource}
      style={[
        styles.sprite,
        {
          width: size.width,
          height: size.height,
          transform: [
            { translateX: Animated.add(animatedX, offsetX) },
            { translateY: Animated.add(animatedY, offsetY) },
          ],
        },
      ]}
      resizeMode="contain"
      fadeDuration={0}
    />
  );
}

const styles = StyleSheet.create({
  sprite: {
    position: 'absolute',
    zIndex: 45,
  },
});
