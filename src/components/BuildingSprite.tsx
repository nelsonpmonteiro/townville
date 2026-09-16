// Building sprite component with 5 states per HERMES-implementation-instruction.md §2
import React from 'react';
import { View, Image, StyleSheet } from 'react-native';
import { BuildingState } from '../types/progress';

interface Props {
  buildingId: string;
  sprite: string; // base sprite name
  state: BuildingState;
  x: number;
  y: number;
  size?: number;
}

// Building sprites - static requires for Metro
const BUILDING_SPRITES: Record<string, any> = {
  'henhouse': require('../../assets/images/buildings/building-henhouse.png'),
  'henhouse-locked': require('../../assets/images/buildings/building-henhouse-locked.png'),
  'stable': require('../../assets/images/buildings/building-stable.png'),
  'stable-locked': require('../../assets/images/buildings/building-stable-locked.png'),
  'barn': require('../../assets/images/buildings/building-barn.png'),
  'barn-locked': require('../../assets/images/buildings/building-barn-locked.png'),
  'coop': require('../../assets/images/buildings/building-coop.png'),
  'coop-locked': require('../../assets/images/buildings/building-coop-locked.png'),
  'bakery': require('../../assets/images/buildings/building-bakery.png'),
  'bakery-locked': require('../../assets/images/buildings/building-bakery-locked.png'),
  'hardware': require('../../assets/images/buildings/building-hardware.png'),
  'hardware-locked': require('../../assets/images/buildings/building-hardware-locked.png'),
  'town-hall': require('../../assets/images/buildings/building-town-hall.png'),
  'town-hall-locked': require('../../assets/images/buildings/building-town-hall-locked.png'),
  'library': require('../../assets/images/buildings/building-library.png'),
  'library-locked': require('../../assets/images/buildings/building-library-locked.png'),
  'fountain': require('../../assets/images/buildings/building-fountain.png'),
};

export default function BuildingSprite({ buildingId, sprite, state, x, y, size = 96 }: Props) {
  // Get sprite source
  const spriteKey = state === 'LOCKED' ? `${sprite}-locked` : sprite;
  const spriteSource = BUILDING_SPRITES[spriteKey];
  
  // Fallback to placeholder if sprite not found
  if (!spriteSource) {
    return (
      <View
        style={[
          styles.placeholder,
          {
            left: x,
            top: y,
            width: size,
            height: size,
            backgroundColor: state === 'LOCKED' ? '#9ca3af' : '#8b5cf6',
          },
        ]}
      />
    );
  }
  
  // Calculate opacity based on state
  const opacity = state === 'LOCKED' ? 1.0
    : state === 'STAGE_1' ? 0.55
    : state === 'STAGE_2' ? 0.8
    : 1.0;
  
  return (
    <View style={{ position: 'absolute', left: x, top: y, width: size, height: size }}>
      {/* Base sprite */}
      <Image
        source={spriteSource}
        style={[
          styles.sprite,
          {
            width: size,
            height: size,
            opacity,
          },
        ]}
        resizeMode="contain"
      />
      
      {/* Overlays for intermediate stages */}
      {state === 'STAGE_1' && <ScaffoldingOverlay size={size} />}
      {state === 'STAGE_2' && (
        <>
          <ScaffoldingOverlay size={size} />
          <BoxesOverlay size={size} />
        </>
      )}
      {state === 'STAGE_3' && (
        <>
          <ToolsOverlay size={size} />
          <GlowOverlay size={size} />
        </>
      )}
    </View>
  );
}

// Stage 1: Scaffolding overlay (translucent rectangles)
function ScaffoldingOverlay({ size }: { size: number }) {
  return (
    <View style={[styles.overlay, { width: size, height: size }]}>
      <View style={[styles.scaffold, { left: size * 0.1, top: size * 0.2, width: 4, height: size * 0.6 }]} />
      <View style={[styles.scaffold, { left: size * 0.9, top: size * 0.2, width: 4, height: size * 0.6 }]} />
      <View style={[styles.scaffold, { left: size * 0.1, top: size * 0.2, width: size * 0.8, height: 4 }]} />
      <View style={[styles.scaffold, { left: size * 0.1, top: size * 0.5, width: size * 0.8, height: 4 }]} />
      <View style={[styles.scaffold, { left: size * 0.1, top: size * 0.8, width: size * 0.8, height: 4 }]} />
    </View>
  );
}

// Stage 2: Material boxes at base
function BoxesOverlay({ size }: { size: number }) {
  return (
    <View style={[styles.overlay, { width: size, height: size }]}>
      <View style={[styles.box, { left: size * 0.15, top: size * 0.7, width: size * 0.2, height: size * 0.2 }]} />
      <View style={[styles.box, { left: size * 0.4, top: size * 0.75, width: size * 0.15, height: size * 0.15 }]} />
      <View style={[styles.box, { left: size * 0.65, top: size * 0.7, width: size * 0.2, height: size * 0.2 }]} />
    </View>
  );
}

// Stage 3: Tools leaning against wall
function ToolsOverlay({ size }: { size: number }) {
  return (
    <View style={[styles.overlay, { width: size, height: size }]}>
      <View style={[styles.tool, { left: size * 0.2, top: size * 0.6, width: 3, height: size * 0.3 }]} />
      <View style={[styles.tool, { left: size * 0.75, top: size * 0.6, width: 3, height: size * 0.3 }]} />
    </View>
  );
}

// Stage 3: Window glow (pulsing light)
function GlowOverlay({ size }: { size: number }) {
  return (
    <View
      style={[
        styles.glow,
        {
          left: size * 0.45,
          top: size * 0.3,
          width: size * 0.1,
          height: size * 0.1,
        },
      ]}
    />
  );
}

const styles = StyleSheet.create({
  placeholder: {
    position: 'absolute',
    borderRadius: 8,
    zIndex: 30,
  },
  sprite: {
    position: 'absolute',
    zIndex: 30,
  },
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    zIndex: 31,
  },
  scaffold: {
    position: 'absolute',
    backgroundColor: 'rgba(128, 128, 128, 0.4)',
  },
  box: {
    position: 'absolute',
    backgroundColor: '#8B4513',
    borderWidth: 1,
    borderColor: '#654321',
  },
  tool: {
    position: 'absolute',
    backgroundColor: '#696969',
  },
  glow: {
    position: 'absolute',
    backgroundColor: '#FFD700',
    borderRadius: 999,
    opacity: 0.6,
    shadowColor: '#FFD700',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.8,
    shadowRadius: 10,
  },
});
