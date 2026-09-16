import React, { useRef, useEffect } from 'react';
import { View, StyleSheet, ScrollView, Dimensions, Image } from 'react-native';
import { WorldMap } from './data/worldMaps';
import { Point } from './core';

interface WorldMapRendererProps {
  world: WorldMap;
  protagonistPos: Point;
  onTilePress?: (x: number, y: number) => void;
}

const TILE_SIZE = 48;
const VIEWPORT_WIDTH = Math.min(Dimensions.get('window').width, 1440);
const VIEWPORT_HEIGHT = Math.min(Dimensions.get('window').height - 56, 960); // minus header

export default function WorldMapRenderer({
  world,
  protagonistPos,
  onTilePress,
}: WorldMapRendererProps) {
  const scrollXRef = useRef<ScrollView>(null);
  const scrollYRef = useRef<ScrollView>(null);

  // Camera follow protagonist
  useEffect(() => {
    const centerX = protagonistPos.x * TILE_SIZE - VIEWPORT_WIDTH / 2 + TILE_SIZE / 2;
    const centerY = protagonistPos.y * TILE_SIZE - VIEWPORT_HEIGHT / 2 + TILE_SIZE / 2;

    scrollXRef.current?.scrollTo({ 
      x: Math.max(0, Math.min(centerX, 30 * TILE_SIZE - VIEWPORT_WIDTH)),
      animated: true 
    });
    scrollYRef.current?.scrollTo({ 
      y: Math.max(0, Math.min(centerY, 20 * TILE_SIZE - VIEWPORT_HEIGHT)),
      animated: true 
    });
  }, [protagonistPos]);

  return (
    <View style={s.container}>
      <ScrollView
        ref={scrollYRef}
        showsVerticalScrollIndicator={false}
        bounces={false}
        scrollEnabled={false}
      >
        <ScrollView
          ref={scrollXRef}
          horizontal
          showsHorizontalScrollIndicator={false}
          bounces={false}
          scrollEnabled={false}
        >
          <View style={s.grid}>
            {/* Render chunks as colored placeholders */}
            {renderChunks(world)}
            
            {/* Render buildings */}
            {world.buildings.map((b, i) => (
              <View
                key={`building-${i}`}
                style={[
                  s.building,
                  {
                    left: b.x * TILE_SIZE,
                    top: b.y * TILE_SIZE,
                    width: b.w * TILE_SIZE,
                    height: b.h * TILE_SIZE,
                  },
                ]}
              >
                <View style={s.buildingInner}>
                  {/* Placeholder - will be replaced with PNG */}
                </View>
              </View>
            ))}

            {/* Render NPCs/Event Points */}
            {world.npcs.map((npc) => (
              <View
                key={npc.id}
                style={[
                  s.eventPoint,
                  {
                    left: npc.x * TILE_SIZE,
                    top: npc.y * TILE_SIZE,
                  },
                ]}
              >
                <View style={s.eventMarker} />
              </View>
            ))}

            {/* Render Protagonist */}
            <View
              style={[
                s.protagonist,
                {
                  left: protagonistPos.x * TILE_SIZE,
                  top: protagonistPos.y * TILE_SIZE,
                },
              ]}
            >
              <View style={s.protagonistInner}>
                {/* Placeholder emoji - will use sprite when available */}
                🧒
              </View>
            </View>
          </View>
        </ScrollView>
      </ScrollView>
    </View>
  );
}

// Chunk images - must use static requires for Metro bundler
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

function renderChunks(world: WorldMap) {
  // 3×2 grid of 480×480px chunks (10×10 tiles each)
  const chunks = [];
  const worldKey = world.id === 1 ? 'w1' : 'w2';
  const chunkKeys = ['a1', 'b1', 'c1', 'a2', 'b2', 'c2'] as const;
  
  let idx = 0;
  for (let row = 0; row < 2; row++) {
    for (let col = 0; col < 3; col++) {
      const chunkKey = chunkKeys[idx];
      chunks.push(
        <Image
          key={`chunk-${row}-${col}`}
          source={CHUNK_IMAGES[worldKey][chunkKey]}
          style={[
            s.chunk,
            {
              left: col * 10 * TILE_SIZE,
              top: row * 10 * TILE_SIZE,
            },
          ]}
          resizeMode="cover"
        />
      );
      idx++;
    }
  }
  
  return chunks;
}

const s = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#87CEEB', // Sky blue
  },
  grid: {
    width: 30 * TILE_SIZE,
    height: 20 * TILE_SIZE,
    position: 'relative',
  },
  chunk: {
    position: 'absolute',
    width: 10 * TILE_SIZE,
    height: 10 * TILE_SIZE,
  },
  building: {
    position: 'absolute',
    zIndex: 10,
  },
  buildingInner: {
    flex: 1,
    backgroundColor: '#8B4513',
    borderWidth: 2,
    borderColor: '#654321',
    borderRadius: 4,
  },
  eventPoint: {
    position: 'absolute',
    width: TILE_SIZE,
    height: TILE_SIZE,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 15,
  },
  eventMarker: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F59E0B',
    borderWidth: 3,
    borderColor: '#FFFFFF',
  },
  protagonist: {
    position: 'absolute',
    width: TILE_SIZE,
    height: TILE_SIZE,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 20,
  },
  protagonistInner: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    fontSize: 32,
  },
});
