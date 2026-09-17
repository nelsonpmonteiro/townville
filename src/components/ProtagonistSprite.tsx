// ProtagonistSprite - Real protagonist with walk animation
import React, { useEffect, useState } from 'react';
import { Animated, StyleSheet } from 'react-native';
import { useAspectScaledSize } from '../hooks/useAspectScaledSize';

const TILE_SIZE = 48;
const PROTAGONIST_TARGET_HEIGHT = 67; // 1.4 tiles

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

// Idle frames (use ORIGINAL static sprites, not GIF frames)
const IDLE_SPRITES = {
  front: require('../../assets/images/player/boy-front.png'),
  back: require('../../assets/images/player/boy-back.png'),
  left: require('../../assets/images/player/boy-left.png'),
  right: require('../../assets/images/player/boy-right.png'),
};

// Dimensions of ORIGINAL verified sprites (not trimmed/normalized)
const NATIVE_DIMS = {
  // boy-front/back/left are 1254×1254, boy-right is 128×128
  // We'll use a fixed render size instead of scaling from native
  width: 67,  // 1.4 tiles × 48px = 67px height
  height: 67,
};

const TILE_SIZE = 48;
const FRAME_DURATION = 100; // ms per frame (200ms movement / 8 frames = 25ms, but 100ms looks better)

interface Props {
  animatedX: Animated.Value;
  animatedY: Animated.Value;
  direction?: Direction;
  isMoving?: boolean; // Whether protagonist is currently moving
}

export default function ProtagonistSprite({ 
  animatedX, 
  animatedY, 
  direction = 'front',
  isMoving = false 
}: Props) {
  const [currentFrame, setCurrentFrame] = useState(0);
  
  // Animate frames when moving
  useEffect(() => {
    if (!isMoving) {
      setCurrentFrame(0); // Reset to idle frame
      return;
    }
    
    // Start immediately on first frame
    setCurrentFrame(0);
    
    // Cycle through 8 frames
    const interval = setInterval(() => {
      setCurrentFrame(prev => (prev + 1) % 8);
    }, FRAME_DURATION);
    
    return () => clearInterval(interval);
  }, [isMoving, direction]); // Re-sync when direction changes
  
  // Use aspect-scaled size (respects native proportions)
  const scaledSize = useAspectScaledSize(spriteSource, PROTAGONIST_TARGET_HEIGHT);
  
  // Position offsets (center horizontally, bottom-aligned)
  const offsetX = (TILE_SIZE - scaledSize.width) / 2;
  const offsetY = TILE_SIZE - scaledSize.height;
  
  // DISABLED: Walk animation causing size mismatch with idle sprites
  // const spriteSource = isMoving 
  //   ? WALK_FRAMES[direction][currentFrame]
  //   : IDLE_SPRITES[direction];
  
  // Use ONLY idle sprites (no animation) until we get consistent assets
  const spriteSource = IDLE_SPRITES[direction];
  
  return (
    <Animated.Image
      source={spriteSource}
      style={[
        styles.sprite,
        {
          width: scaledSize.width,
          height: scaledSize.height,
          transform: [
            { translateX: Animated.add(animatedX, offsetX) },
            { translateY: Animated.add(animatedY, offsetY) },
          ],
        },
      ]}
      resizeMode="contain"
    />
  );
}

const styles = StyleSheet.create({
  sprite: {
    position: 'absolute',
    zIndex: 45,
  },
});
