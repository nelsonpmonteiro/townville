import React from 'react';
import { View, Image, StyleSheet } from 'react-native';
import { WorldMap, Building } from './data/worldMaps';

const TILE_SIZE = 48;
const MAP_COLS = 30;
const MAP_ROWS = 20;
const CHUNK_SIZE = 480; // Display size (native files are 512px but must render at 480)

interface Point {
  x: number;
  y: number;
}

interface Props {
  world: WorldMap;
  protagonistPos: Point;
  onTilePress?: (x: number, y: number) => void;
}

// Chunk images - static requires for Metro bundler
const CHUNK_IMAGES = {
  w1: {
    a1: require('../assets/images/maps/map-w1-a1.png'),
    b1: require('../assets/images/maps/map-w1-b1.png'),
    c1: require('../assets/images/maps/map-w1-c1.png'),
    a2: require('../assets/images/maps/map-w1-a2.png'),
    b2: require('../assets/images/maps/map-w1-b2.png'),
    c2: require('../assets/images/maps/map-w1-c2.png'),
  },
  w2: {
    a1: require('../assets/images/maps/map-w2-a1.png'),
    b1: require('../assets/images/maps/map-w2-b1.png'),
    c1: require('../assets/images/maps/map-w2-c1.png'),
    a2: require('../assets/images/maps/map-w2-a2.png'),
    b2: require('../assets/images/maps/map-w2-b2.png'),
    c2: require('../assets/images/maps/map-w2-c2.png'),
  },
};

// Building sprites (World 1 pending - using placeholders)
const BUILDING_SPRITES: Record<string, any> = {
  // World 2 (available now)
  'bakery': require('../assets/images/buildings/building-bakery.png'),
  'bakery-locked': require('../assets/images/buildings/building-bakery-locked.png'),
  'hardware': require('../assets/images/buildings/building-hardware.png'),
  'hardware-locked': require('../assets/images/buildings/building-hardware-locked.png'),
  'town-hall': require('../assets/images/buildings/building-town-hall.png'),
  'town-hall-locked': require('../assets/images/buildings/building-town-hall-locked.png'),
  'library': require('../assets/images/buildings/building-library.png'),
  'library-locked': require('../assets/images/buildings/building-library-locked.png'),
  'fountain': require('../assets/images/buildings/building-fountain.png'),
  // World 1 - all pending, will use colored placeholders
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

export default function WorldMapRenderer({ world, protagonistPos, onTilePress }: Props) {
  const worldKey = world.id === 1 ? 'w1' : 'w2';
  const chunks = CHUNK_IMAGES[worldKey];

  // Render terrain chunks (z=0)
  const renderChunks = () => {
    const chunkNames: Array<keyof typeof chunks> = ['a1', 'b1', 'c1', 'a2', 'b2', 'c2'];
    return chunkNames.map((name, idx) => {
      const col = idx % 3;
      const row = Math.floor(idx / 3);
      return (
        <Image
          key={name}
          source={chunks[name]}
          style={[
            styles.chunk,
            {
              left: col * CHUNK_SIZE,
              top: row * CHUNK_SIZE,
            },
          ]}
          resizeMode="stretch"
        />
      );
    });
  };

  // Render event points (z=10)
  const renderEventPoints = () => {
    return world.eventPoints.map((ep) => {
      const x = ep.x * TILE_SIZE;
      const y = ep.y * TILE_SIZE;
      const isCompleted = false; // TODO: check from save
      const isLocked = false; // TODO: check requiredCompletions

      return (
        <View
          key={ep.id}
          style={[
            styles.eventPoint,
            {
              left: x,
              top: y,
              backgroundColor: isCompleted ? '#10b981' : isLocked ? '#6b7280' : '#fbbf24',
            },
          ]}
        />

      );
    });
  };

  // Render buildings (z=30)
  const renderBuildings = () => {
    return world.buildings.map((building) => {
      const pos = buildingPosition(
        building.footprintCol,
        building.footprintRow,
        building.footprintW,
        building.footprintH,
        96
      );

      const isLocked = false; // TODO: check from save
      const spriteKey = isLocked ? `${building.sprite}-locked` : building.sprite;
      const sprite = BUILDING_SPRITES[spriteKey];

      // If no sprite available, use colored placeholder
      if (!sprite) {
        return (
          <View
            key={building.id}
            style={[
              styles.buildingPlaceholder,
              {
                left: pos.x,
                top: pos.y,
                width: 96,
                height: 96,
                backgroundColor: isLocked ? '#9ca3af' : '#8b5cf6',
              },
            ]}
          />
        );
      }

      return (
        <Image
          key={building.id}
          source={sprite}
          style={[
            styles.building,
            {
              left: pos.x,
              top: pos.y,
              width: 96,
              height: 96,
            },
          ]}
          resizeMode="contain"
        />
      );
    });
  };

  // Render protagonist (z=45)
  const renderProtagonist = () => {
    const pos = protagonistScreenPosition(protagonistPos.x, protagonistPos.y);
    return (
      <Image
        source={require('../assets/images/protagonist/_reference-only/frontal-pose-reference.png')}
        style={[
          styles.protagonist,
          {
            left: pos.x,
            top: pos.y,
            width: 40,
            height: 56,
          },
        ]}
        resizeMode="contain"
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
