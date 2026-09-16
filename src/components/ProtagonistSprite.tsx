// ProtagonistSprite - Real protagonist with directional sprites
import React from 'react';
import { Image, StyleSheet } from 'react-native';
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

interface Props {
  col: number; // Grid position
  row: number;
  direction?: Direction;
}

export default function ProtagonistSprite({ col, row, direction = 'front' }: Props) {
  // Compute render size using sprite scale system
  const { width, height } = computeRenderSize(
    NATIVE_DIMS.width,
    NATIVE_DIMS.height,
    'protagonist'
  );
  
  // Get position anchored at bottom-center (footprint 1×1)
  const { x, y } = getSpritePosition(col, row, 1, 1, width, height);
  
  return (
    <Image
      source={PROTAGONIST_SPRITES[direction]}
      style={[
        styles.sprite,
        {
          left: x,
          top: y,
          width,
          height,
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
