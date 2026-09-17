// CharacterSprite - Renders NPC with expression (idle/happy/sad)
import React from 'react';
import { Image, View, StyleSheet } from 'react-native';
import { useAspectScaledSize } from '../hooks/useAspectScaledSize';

const TILE_SIZE = 48;
const NPC_TARGET_HEIGHT = 67; // 1.4 tiles

type Expression = 'idle' | 'happy' | 'sad';

interface Props {
  npcId: string;
  world: 1 | 2;
  expression?: Expression;
  size?: number; // Size in pixels (default: 48 for map icons, 96 for full sprites)
}

// Map NPC IDs to their file names
const NPC_FILENAMES: Record<string, string> = {
  // World 1
  'mae': 'mae',
  'chester': 'chester',
  'lily': 'lily',
  'farmer-joe': 'farmer-joe',
  'grandma-rose': 'grandma-rose',
  'billy': 'billy',
  'vera': 'vera',
  'old-mac': 'old-mac',
  // World 2
  'sam': 'sam',
  'rosa': 'rosa',
  'mayor-chen': 'mayor-chen',
  'tommy': 'tommy',
  'ms-park': 'ms-park',
  'carlos': 'carlos',
  'danny': 'danny',
  'officer-pat': 'officer-pat',
};

// Require all character sprites statically (Metro bundler requirement)
const WORLD1_SPRITES = {
  'mae-idle': require('../../assets/images/characters/world1/mae-idle.png'),
  'mae-happy': require('../../assets/images/characters/world1/mae-happy.png'),
  'mae-sad': require('../../assets/images/characters/world1/mae-sad.png'),
  'chester-idle': require('../../assets/images/characters/world1/chester-idle.png'),
  'chester-happy': require('../../assets/images/characters/world1/chester-happy.png'),
  'chester-sad': require('../../assets/images/characters/world1/chester-sad.png'),
  'lily-idle': require('../../assets/images/characters/world1/lily-idle.png'),
  'lily-happy': require('../../assets/images/characters/world1/lily-happy.png'),
  'lily-sad': require('../../assets/images/characters/world1/lily-sad.png'),
  'farmer-joe-idle': require('../../assets/images/characters/world1/farmer-joe-idle.png'),
  'farmer-joe-happy': require('../../assets/images/characters/world1/farmer-joe-happy.png'),
  'farmer-joe-sad': require('../../assets/images/characters/world1/farmer-joe-sad.png'),
  'grandma-rose-idle': require('../../assets/images/characters/world1/grandma-rose-idle.png'),
  'grandma-rose-happy': require('../../assets/images/characters/world1/grandma-rose-happy.png'),
  'grandma-rose-sad': require('../../assets/images/characters/world1/grandma-rose-sad.png'),
  'billy-idle': require('../../assets/images/characters/world1/billy-idle.png'),
  'billy-happy': require('../../assets/images/characters/world1/billy-happy.png'),
  'billy-sad': require('../../assets/images/characters/world1/billy-sad.png'),
  'vera-idle': require('../../assets/images/characters/world1/vera-idle.png'),
  'vera-happy': require('../../assets/images/characters/world1/vera-happy.png'),
  'vera-sad': require('../../assets/images/characters/world1/vera-sad.png'),
  'old-mac-idle': require('../../assets/images/characters/world1/old-mac-idle.png'),
  'old-mac-happy': require('../../assets/images/characters/world1/old-mac-happy.png'),
  'old-mac-sad': require('../../assets/images/characters/world1/old-mac-sad.png'),
};

const WORLD2_SPRITES = {
  'sam-idle': require('../../assets/images/characters/world2/sam-idle.png'),
  'sam-happy': require('../../assets/images/characters/world2/sam-happy.png'),
  'sam-sad': require('../../assets/images/characters/world2/sam-sad.png'),
  'rosa-idle': require('../../assets/images/characters/world2/rosa-idle.png'),
  'rosa-happy': require('../../assets/images/characters/world2/rosa-happy.png'),
  'rosa-sad': require('../../assets/images/characters/world2/rosa-sad.png'),
  'mayor-chen-idle': require('../../assets/images/characters/world2/mayor-chen-idle.png'),
  'mayor-chen-happy': require('../../assets/images/characters/world2/mayor-chen-happy.png'),
  'mayor-chen-sad': require('../../assets/images/characters/world2/mayor-chen-sad.png'),
  'tommy-idle': require('../../assets/images/characters/world2/tommy-idle.png'),
  'tommy-happy': require('../../assets/images/characters/world2/tommy-happy.png'),
  'tommy-sad': require('../../assets/images/characters/world2/tommy-sad.png'),
  'ms-park-idle': require('../../assets/images/characters/world2/ms-park-idle.png'),
  'ms-park-happy': require('../../assets/images/characters/world2/ms-park-happy.png'),
  'ms-park-sad': require('../../assets/images/characters/world2/ms-park-sad.png'),
  'carlos-idle': require('../../assets/images/characters/world2/carlos-idle.png'),
  'carlos-happy': require('../../assets/images/characters/world2/carlos-happy.png'),
  'carlos-sad': require('../../assets/images/characters/world2/carlos-sad.png'),
  'danny-idle': require('../../assets/images/characters/world2/danny-idle.png'),
  'danny-happy': require('../../assets/images/characters/world2/danny-happy.png'),
  'danny-sad': require('../../assets/images/characters/world2/danny-sad.png'),
  'officer-pat-idle': require('../../assets/images/characters/world2/officer-pat-idle.png'),
  'officer-pat-happy': require('../../assets/images/characters/world2/officer-pat-happy.png'),
  'officer-pat-sad': require('../../assets/images/characters/world2/officer-pat-sad.png'),
};

export default function CharacterSprite({ npcId, world, expression = 'idle', size }: Props) {
  const filename = NPC_FILENAMES[npcId];
  if (!filename) {
    console.warn(`CharacterSprite: Unknown npcId "${npcId}"`);
    return <View style={[styles.placeholder, { width: size || NPC_TARGET_HEIGHT, height: size || NPC_TARGET_HEIGHT }]} />;
  }

  const spriteKey = `${filename}-${expression}` as keyof typeof WORLD1_SPRITES;
  const sprites = world === 1 ? WORLD1_SPRITES : WORLD2_SPRITES;
  const sprite = sprites[spriteKey];

  if (!sprite) {
    console.warn(`CharacterSprite: Missing sprite for ${spriteKey} in world ${world}`);
    return <View style={[styles.placeholder, { width: size || NPC_TARGET_HEIGHT, height: size || NPC_TARGET_HEIGHT }]} />;
  }

  // Use aspect-scaled size (respects native proportions)
  const targetHeight = size || NPC_TARGET_HEIGHT;
  const scaledSize = useAspectScaledSize(sprite, targetHeight);

  return (
    <Image
      source={sprite}
      style={{ width: scaledSize.width, height: scaledSize.height }}
      resizeMode="contain"
    />
  );
}

const styles = StyleSheet.create({
  placeholder: {
    backgroundColor: '#888',
    borderRadius: 4,
  },
});
