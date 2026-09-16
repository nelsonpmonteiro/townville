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

// Chunk images - TEMPORARILY DISABLED until correct assets arrive
// const CHUNK_IMAGES = {
//   w1: {
//     a1: require('../assets/images/maps/map-w1-a1.png'),
//     ...
//   },
// };

// Building sprites - TEMPORARILY DISABLED
// const BUILDING_SPRITES: Record<string, any> = { ... };

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
  // TEMP: removed chunk/building image loading until correct assets arrive

  // Render terrain chunks (z=0) - PLACEHOLDER COLORS until assets arrive
  const renderChunks = () => {
    const colors = ['#2d5016', '#3a6622', '#1e3a0f', '#4a7c35', '#2a4d1a', '#1a3310'];
    return colors.map((color, idx) => {
      const col = idx % 3;
      const row = Math.floor(idx / 3);
      return (
        <View
          key={idx}
          style={[
            styles.chunk,
            {
              left: col * CHUNK_SIZE,
              top: row * CHUNK_SIZE,
              backgroundColor: color,
            },
          ]}
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
      // TEMP: all buildings as placeholders until assets arrive
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
    });
  };

  // Render protagonist (z=45)
  const renderProtagonist = () => {
    const pos = protagonistScreenPosition(protagonistPos.x, protagonistPos.y);
    return (
      <View
        style={[
          styles.protagonist,
          {
            left: pos.x,
            top: pos.y,
            width: 40,
            height: 56,
            backgroundColor: '#3b82f6',
            borderRadius: 20,
            borderWidth: 2,
            borderColor: '#fff',
          },
        ]}
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
