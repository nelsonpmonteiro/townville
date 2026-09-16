import React from 'react';
import { View, Image, StyleSheet, Animated } from 'react-native';
import { WorldMap, Building } from './data/worldMaps';
import CharacterSprite from './components/CharacterSprite';
import RealBuildingSprite from './components/RealBuildingSprite';
import ProtagonistSprite from './components/ProtagonistSprite';

const TILE_SIZE = 48;
const MAP_COLS = 40; // Updated from 30 to 40
const MAP_ROWS = 30; // Updated from 20 to 30
const CHUNK_SIZE = 480; // Display size (native files are 512px but must render at 480)

interface Point {
  x: number;
  y: number;
}

interface Props {
  world: WorldMap;
  protagonistAnimatedX: Animated.Value;
  protagonistAnimatedY: Animated.Value;
  protagonistDirection?: 'front' | 'back' | 'left' | 'right';
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


function buildingPosition(
  footprintCol: number,
  footprintRow: number,
  footprintW: number,
  footprintH: number,
  spriteSize = 96
): Point {
  const footprintPxW = footprintW * TILE_SIZE;
  const footprintPxH = footprintH * TILE_SIZE;
  const x = footprintCol * TILE_SIZE + (footprintPxW - spriteSize) / 2;
  const y = footprintRow * TILE_SIZE + footprintPxH - spriteSize;
  return { x, y };
}

function protagonistScreenPosition(col: number, row: number): Point {
  const spriteW = 40;
  const spriteH = 56;
  return {
    x: col * TILE_SIZE + (TILE_SIZE - spriteW) / 2,
    y: row * TILE_SIZE + TILE_SIZE - spriteH,
  };
}

export default function WorldMapRenderer({ world, protagonistAnimatedX, protagonistAnimatedY, protagonistDirection = 'front', buildingStates, onTilePress }: Props) {
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

  // Render event points (z=10) - with real character sprites
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
            size={48}
          />
        </View>
      );
    });
  };

  // Render buildings (z=30) - with real building sprites and 5-state system
  const renderBuildings = () => {
    return world.buildings.map((building) => {
      // Use buildingPosition function for correct placement
      const pos = buildingPosition(
        building.footprintCol,
        building.footprintRow,
        building.footprintW,
        building.footprintH,
        96
      );

      const state = buildingStates[building.id] || 'LOCKED';

      return (
        <View
          key={building.id}
          style={[
            styles.building,
            {
              left: pos.x,
              top: pos.y,
              zIndex: state === 'LOCKED' ? 30 : 20,
            },
          ]}
        >
          <RealBuildingSprite
            buildingId={building.id}
            state={state}
            size={96}
          />
        </View>
      );
    });
  };

  // Render protagonist (z=45) - real sprite with animated position
  const renderProtagonist = () => {
    return (
      <ProtagonistSprite
        animatedX={protagonistAnimatedX}
        animatedY={protagonistAnimatedY}
        direction={protagonistDirection}
      />
    );
  };

  return (
    <View style={styles.mapContainer}>
      {renderChunks()}
      {renderEventPoints()}
      {renderBuildings()}
      {renderProtagonist()}
    </View>
  );
}

const styles = StyleSheet.create({
  mapContainer: {
    position: 'relative',
    width: MAP_COLS * TILE_SIZE, // 1440
    height: MAP_ROWS * TILE_SIZE, // 960
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
    borderRadius: TILE_SIZE / 2,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 10,
  },
  eventPointInner: {
    fontSize: 24,
  },
  building: {
    position: 'absolute',
    zIndex: 30,
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
