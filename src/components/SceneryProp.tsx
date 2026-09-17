// SceneryProp — renders one decorative prop anchored bottom-center
// on its tile. Height comes from targetHeightTiles; width follows
// the trimmed PNG's aspect ratio.
import React from 'react';
import { Image, StyleSheet, View } from 'react-native';
import { WorldProp } from '../data/worldProps';
import { useAspectScaledSize } from '../hooks/useAspectScaledSize';
import { TILE_SIZE } from '../config';

// Static requires (Metro bundler)
const PROP_SPRITES: Record<string, any> = {
  'tree': require('../../assets/images/scenery/world1/scenery-tree.png'),
  'bush': require('../../assets/images/scenery/world1/scenery-bush.png'),
  'flower-yellow': require('../../assets/images/scenery/world1/scenery-flower-yellow.png'),
  'flower-red': require('../../assets/images/scenery/world1/scenery-flower-red.png'),
  'stone': require('../../assets/images/scenery/world1/scenery-stone.png'),
  'well': require('../../assets/images/scenery/world1/scenery-well.png'),
};

interface Props {
  prop: WorldProp;
}

export default function SceneryProp({ prop }: Props) {
  const sprite = PROP_SPRITES[prop.type];
  const targetHeight = Math.round(prop.targetHeightTiles * TILE_SIZE);
  const size = useAspectScaledSize(sprite, targetHeight);

  if (!sprite) return null;

  return (
    <View
      style={[
        styles.container,
        {
          left: prop.col * TILE_SIZE,
          top: prop.row * TILE_SIZE,
          pointerEvents: 'none',
        },
      ]}
    >
      <Image
        source={sprite}
        style={{ width: size.width, height: size.height }}
        resizeMode="contain"
        fadeDuration={0}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    width: TILE_SIZE,
    height: TILE_SIZE,
    alignItems: 'center', // horizontal center on tile
    justifyContent: 'flex-end', // base planted on tile bottom
    zIndex: 15, // above terrain (0) and event circles, below buildings (30)
  },
});
