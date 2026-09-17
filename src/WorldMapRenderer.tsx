import React from 'react';
import { View, Image, Text, StyleSheet, Animated } from 'react-native';
import { WorldMap, Building } from './data/worldMaps';
import CharacterSprite from './components/CharacterSprite';
import RealBuildingSprite from './components/RealBuildingSprite';
import ProtagonistSprite from './components/ProtagonistSprite';
import { Save, Point as CorePoint } from './core';
import { fencePosts } from './engine/fence';
import SceneryProp from './components/SceneryProp';
import { WORLD1_PROPS } from './data/worldProps';
import {
  TILE_SIZE,
  CHUNK_SIZE,
  BUILDING_TARGET_HEIGHT,
  GATE_TARGET_HEIGHT,
} from './config';


interface Point {
  x: number;
  y: number;
}

interface Props {
  world: WorldMap;
  save: Save;
  protagonistAnimatedX: Animated.Value;
  protagonistAnimatedY: Animated.Value;
  protagonistDirection?: 'front' | 'back' | 'left' | 'right';
  protagonistIsMoving?: boolean;
  buildingStates: Record<string, 'LOCKED' | 'STAGE_1' | 'STAGE_2' | 'STAGE_3' | 'COMPLETE'>;
  onTilePress?: (x: number, y: number) => void;
}

// Chunk images - static requires for Metro bundler (4×3 grid)
const CHUNK_IMAGES = {
  w1: {
    a1: require('../assets/images/maps/map-w1-a1.png'),
    b1: require('../assets/images/maps/map-w1-b1.png'),
    c1: require('../assets/images/maps/map-w1-c1.png'),
    d1: require('../assets/images/maps/map-w1-d1.png'),
    a2: require('../assets/images/maps/map-w1-a2.png'),
    b2: require('../assets/images/maps/map-w1-b2.png'),
    c2: require('../assets/images/maps/map-w1-c2.png'),
    d2: require('../assets/images/maps/map-w1-d2.png'),
    a3: require('../assets/images/maps/map-w1-a3.png'),
    b3: require('../assets/images/maps/map-w1-b3.png'),
    c3: require('../assets/images/maps/map-w1-c3.png'),
    d3: require('../assets/images/maps/map-w1-d3.png'),
  },
  w2: {
    a1: require('../assets/images/maps/map-w2-a1.png'),
    b1: require('../assets/images/maps/map-w2-b1.png'),
    c1: require('../assets/images/maps/map-w2-c1.png'),
    d1: require('../assets/images/maps/map-w2-d1.png'),
    a2: require('../assets/images/maps/map-w2-a2.png'),
    b2: require('../assets/images/maps/map-w2-b2.png'),
    c2: require('../assets/images/maps/map-w2-c2.png'),
    d2: require('../assets/images/maps/map-w2-d2.png'),
    a3: require('../assets/images/maps/map-w2-a3.png'),
    b3: require('../assets/images/maps/map-w2-b3.png'),
    c3: require('../assets/images/maps/map-w2-c3.png'),
    d3: require('../assets/images/maps/map-w2-d3.png'),
  },
};


// (Positioning helpers removed — containers are the footprint/tile rects;
// sprites anchor bottom-center via flexbox inside them.)

export default function WorldMapRenderer({ world, save, protagonistAnimatedX, protagonistAnimatedY, protagonistDirection = 'front', protagonistIsMoving = false, buildingStates, onTilePress }: Props) {
  const worldKey = world.id === 1 ? 'w1' : 'w2';
  const chunks = CHUNK_IMAGES[worldKey];

  // Render terrain chunks (z=0) - 4×3 grid (1920×1440px)
  const renderChunks = () => {
    return (
      <>
        {/* Row 1 */}
        <Image source={chunks.a1} style={[styles.chunk, { left: 0, top: 0 }]} />
        <Image source={chunks.b1} style={[styles.chunk, { left: 480, top: 0 }]} />
        <Image source={chunks.c1} style={[styles.chunk, { left: 960, top: 0 }]} />
        <Image source={chunks.d1} style={[styles.chunk, { left: 1440, top: 0 }]} />
        {/* Row 2 */}
        <Image source={chunks.a2} style={[styles.chunk, { left: 0, top: 480 }]} />
        <Image source={chunks.b2} style={[styles.chunk, { left: 480, top: 480 }]} />
        <Image source={chunks.c2} style={[styles.chunk, { left: 960, top: 480 }]} />
        <Image source={chunks.d2} style={[styles.chunk, { left: 1440, top: 480 }]} />
        {/* Row 3 */}
        <Image source={chunks.a3} style={[styles.chunk, { left: 0, top: 960 }]} />
        <Image source={chunks.b3} style={[styles.chunk, { left: 480, top: 960 }]} />
        <Image source={chunks.c3} style={[styles.chunk, { left: 960, top: 960 }]} />
        <Image source={chunks.d3} style={[styles.chunk, { left: 1440, top: 960 }]} />
      </>
    );
  };

  // Render event points (z=10) — NPC anchored bottom-center on its tile.
  // Container = the 48px tile; sprite may overflow upward (1.4 tiles tall).
  const renderEventPoints = () => {
    return world.eventPoints.map((ep) => {
      const x = ep.x * TILE_SIZE;
      const y = ep.y * TILE_SIZE;

      return (
        <View
          key={ep.id}
          style={[
            styles.eventPoint,
            {
              left: x,
              top: y,
            },
          ]}
        >
          <CharacterSprite
            npcId={ep.npcId}
            world={world.id as 1 | 2}
            expression="idle"
          />
        </View>
      );
    });
  };

  // Render buildings (z=30) — container IS the footprint rect; the sprite
  // scales to its category target height and anchors bottom-center.
  const renderBuildings = () => {
    return world.buildings.map((building) => {
      const state = buildingStates[building.id] || 'LOCKED';
      const isGate = building.sprite.includes('gate');

      return (
        <View
          key={building.id}
          style={[
            styles.building,
            {
              left: building.footprintCol * TILE_SIZE,
              top: building.footprintRow * TILE_SIZE,
              width: building.footprintW * TILE_SIZE,
              height: building.footprintH * TILE_SIZE,
              zIndex: state === 'LOCKED' ? 30 : 20,
            },
          ]}
        >
          <RealBuildingSprite
            buildingId={building.id}
            state={state}
            targetHeight={isGate ? GATE_TARGET_HEIGHT : BUILDING_TARGET_HEIGHT}
          />
        </View>
      );
    });
  };

  // Scenery props (z=15) — decorative; collision via engine/collision.ts
  const renderScenery = () => {
    if (world.id !== 1) return null;
    return WORLD1_PROPS.map((prop, i) => (
      <SceneryProp key={`prop-${prop.type}-${i}`} prop={prop} />
    ));
  };

  // Billy's fence posts (z=25) — drawn over the painted fence gap.
  // Code-drawn wood posts; collision handled by engine/collision.ts.
  const renderFencePosts = () => {
    if (world.id !== 1) return null;
    return fencePosts(save).map((tile: CorePoint, i: number) => (
      <View
        key={`fence-post-${i}`}
        style={[
          styles.fencePost,
          {
            left: tile.x * TILE_SIZE + TILE_SIZE / 2 - 4,
            top: tile.y * TILE_SIZE + 8,
          },
        ]}
      />
    ));
  };

  // Render protagonist (z=45) - real sprite with animated position
  const renderProtagonist = () => {
    return (
      <ProtagonistSprite
        animatedX={protagonistAnimatedX}
        animatedY={protagonistAnimatedY}
        direction={protagonistDirection}
        isMoving={protagonistIsMoving}
      />
    );
  };

  return (
    <View style={[styles.mapContainer, { width: world.cols * TILE_SIZE, height: world.rows * TILE_SIZE }]}>
      {renderChunks()}
      {renderScenery()}
      {renderEventPoints()}
      {renderBuildings()}
      {renderFencePosts()}
      {renderProtagonist()}
    </View>
  );
}

const styles = StyleSheet.create({
  mapContainer: {
    position: 'relative',
    overflow: 'hidden',
    backgroundColor: '#1a1a1a',
  },
  chunk: {
    position: 'absolute',
    width: CHUNK_SIZE, // Force 480px (native is 512)
    height: CHUNK_SIZE,
  },
  eventPoint: {
    position: 'absolute',
    width: TILE_SIZE,
    height: TILE_SIZE,
    alignItems: 'center', // horizontal center
    justifyContent: 'flex-end', // feet planted on tile base
    zIndex: 10,
  },
  eventPointInner: {
    fontSize: 24,
  },
  building: {
    position: 'absolute',
    alignItems: 'center', // horizontal center on footprint
    justifyContent: 'flex-end', // base sits on footprint bottom
    zIndex: 30,
  },
  fencePost: {
    position: 'absolute',
    width: 8,
    height: 32,
    backgroundColor: '#8B6914', // wood brown, matches painted fence
    borderWidth: 1,
    borderColor: '#5C4409',
    borderRadius: 2,
    zIndex: 25,
  },
  buildingPlaceholder: {
    position: 'absolute',
    zIndex: 30,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#fff',
  },
  protagonist: {
    position: 'absolute',
    zIndex: 45,
  },
});
