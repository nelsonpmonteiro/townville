// ProtagonistSprite - protagonist with continuous walk animation.
//
// SIZING CONTRACT (do not break):
// - Use one union alpha-bbox per direction for idle + all walk frames.
//   Never trim frames independently: their shared canvas keeps scale
//   and foot placement stable throughout the gait.
// - Render size is computed from the STATIC dimension table below —
//   never from Image.getSize (async → one-frame flicker at 48×48).
// - Height is fixed at CHARACTER_TARGET_HEIGHT for every frame and
//   direction; width follows each source's aspect ratio.
// - Anchor: bottom-center of the logical tile.
import React, { useEffect, useState } from 'react';
import { Animated, Image, StyleSheet } from 'react-native';
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
// PixelLab idle + 8 walk frames share a union-cropped canvas per direction.
const NATIVE_DIMS = {
  walk: {
    front: { width: 20, height: 54 },
    back: { width: 20, height: 52 },
    left: { width: 26, height: 53 },
    right: { width: 27, height: 53 },
  },
  idle: {
    front: { width: 20, height: 54 },
    back: { width: 20, height: 52 },
    left: { width: 26, height: 53 },
    right: { width: 27, height: 53 },
  },
} as const;

/** Deterministic render size: fixed target height, aspect-true width. */
function renderSize(isMoving: boolean, direction: Direction) {
  const dims = isMoving ? NATIVE_DIMS.walk[direction] : NATIVE_DIMS.idle[direction];
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
  const [loaded, setLoaded] = useState<ReadonlySet<string>>(() => new Set());
  const markLoaded = (key: string) => setLoaded(previous => {
    if (previous.has(key)) return previous;
    return new Set(previous).add(key);
  });
  // All layers stay mounted, including across direction/idle transitions.
  // A source swap can display undecoded pixels even with fadeDuration=0.
  const allReady = loaded.size === 4 * (WALK_FRAME_COUNT + 1);
  const shownDirection = allReady ? direction : 'front';
  const shownMoving = allReady && isMoving;
  const activeKey = `${shownDirection}:${shownMoving ? frame : 'idle'}`;

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

  const size = renderSize(shownMoving, shownDirection);

  // Anchor: bottom-center of the tile (feet planted on tile base)
  const offsetX = (TILE_SIZE - size.width) / 2;
  const offsetY = TILE_SIZE - size.height;

  return (
    <Animated.View
      testID="protagonist"
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
    >
      {(Object.keys(IDLE_SPRITES) as Direction[]).flatMap(dir =>
        [IDLE_SPRITES[dir], ...WALK_FRAMES[dir]].map((source, index) => {
          const key = `${dir}:${index === 0 ? 'idle' : index - 1}`;
          const active = key === activeKey;
          return (
            <Image
              key={key}
              source={source}
              nativeID={active ? "protagonist-active" : undefined}
              onLoad={() => markLoaded(key)}
              style={{ position: 'absolute', width: '100%', height: '100%',
                opacity: active ? 1 : 0 }}
              resizeMode="contain"
              fadeDuration={0}
            />
          );
        })
      )}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  sprite: {
    position: 'absolute',
    zIndex: 45,
  },
});
