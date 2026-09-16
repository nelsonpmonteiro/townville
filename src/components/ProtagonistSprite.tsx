// ProtagonistSprite - Real protagonist with directional sprites
import React from 'react';
import { Animated, StyleSheet } from 'react-native';
import { getSpritePosition, computeRenderSize } from '../utils/spriteScale';

type Direction = 'front' | 'back' | 'left' | 'right';

const PROTAGONIST_SPRITES = {
  front: require('../../assets/images/player/boy-front.png'),
  back: require('../../assets/images/player/boy-back.png'),
  left: require('../../assets/images/player/boy-left.png'),
  right: require('../../assets/images/player/boy-right.png'),
};

// Native dimensions after trim (measured from trimmed files)
const NATIVE_DIMS = {
  width: 400,
  height: 1061,
};

const TILE_SIZE = 48;

interface Props {
  animatedX: Animated.Value; // Animated position in pixels
  animatedY: Animated.Value;
  direction?: Direction;
}

export default function ProtagonistSprite({ animatedX, animatedY, direction = 'front' }: Props) {
  // Compute render size using sprite scale system
  const { width, height } = computeRenderSize(
    NATIVE_DIMS.width,
    NATIVE_DIMS.height,
    'protagonist'
  );
  
  // Position anchored at bottom-center (footprint 1×1)
  // Offset to center horizontally and anchor at bottom
  const offsetX = (TILE_SIZE - width) / 2;
  const offsetY = TILE_SIZE - height;
  
  return (
    <Animated.Image
      source={PROTAGONIST_SPRITES[direction]}
      style={[
        styles.sprite,
        {
          width,
          height,
          transform: [
            { translateX: Animated.add(animatedX, offsetX) },
            { translateY: Animated.add(animatedY, offsetY) },
          ],
        },
      ]}
    />
  );
}

const styles = StyleSheet.create({
  sprite: {
    position: 'absolute',
    zIndex: 45, // Between buildings (30) and event points (50)
  },
});
