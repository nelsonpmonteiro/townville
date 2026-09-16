// Map Editor - drag assets to correct positions
import React, { useState } from 'react';
import { View, Text, StyleSheet, Pressable, Image } from 'react-native';
import { WorldMap, Building, EventPoint } from '../data/worldMaps';

const TILE_SIZE = 48;
const CHUNK_SIZE = 480;

// Chunk images - same as WorldMapRenderer
const CHUNK_IMAGES = {
  w1: {
    a1: require('../../assets/images/maps/map-w1-a1.png'),
    b1: require('../../assets/images/maps/map-w1-b1.png'),
    c1: require('../../assets/images/maps/map-w1-c1.png'),
    a2: require('../../assets/images/maps/map-w1-a2.png'),
    b2: require('../../assets/images/maps/map-w1-b2.png'),
    c2: require('../../assets/images/maps/map-w1-c2.png'),
  },
  w2: {
    a1: require('../../assets/images/maps/map-w2-a1.png'),
    b1: require('../../assets/images/maps/map-w2-b1.png'),
    c1: require('../../assets/images/maps/map-w2-c1.png'),
    a2: require('../../assets/images/maps/map-w2-a2.png'),
    b2: require('../../assets/images/maps/map-w2-b2.png'),
    c2: require('../../assets/images/maps/map-w2-c2.png'),
  },
};

interface Props {
  world: WorldMap;
  onSave: (buildings: Building[], eventPoints: EventPoint[]) => void;
  onClose: () => void;
}

interface DragState {
  type: 'building' | 'eventPoint';
  id: string;
  startX: number;
  startY: number;
}

export default function MapEditor({ world, onSave, onClose }: Props) {
  const [buildings, setBuildings] = useState([...world.buildings]);
  const [eventPoints, setEventPoints] = useState([...world.eventPoints]);
  const [dragging, setDragging] = useState<DragState | null>(null);
  const [showGrid, setShowGrid] = useState(true);

  // Convert mouse/touch position to tile coordinates
  const pixelToTile = (px: number, py: number) => {
    const col = Math.floor(px / TILE_SIZE);
    const row = Math.floor(py / TILE_SIZE);
    return { col, row };
  };

  // Handle drag start for buildings
  const handleBuildingDragStart = (building: Building, e: any) => {
    const rect = e.currentTarget.getBoundingClientRect();
    setDragging({
      type: 'building',
      id: building.id,
      startX: e.clientX - rect.left,
      startY: e.clientY - rect.top,
    });
  };

  // Handle drag start for event points
  const handleEventPointDragStart = (ep: EventPoint, e: any) => {
    const rect = e.currentTarget.getBoundingClientRect();
    setDragging({
      type: 'eventPoint',
      id: ep.id,
      startX: e.clientX - rect.left,
      startY: e.clientY - rect.top,
    });
  };

  // Handle drag move
  const handleMouseMove = (e: any) => {
    if (!dragging) return;

    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left - dragging.startX;
    const y = e.clientY - rect.top - dragging.startY;
    
    const { col, row } = pixelToTile(x, y);

    if (dragging.type === 'building') {
      setBuildings(prev =>
        prev.map(b =>
          b.id === dragging.id
            ? { ...b, footprintCol: col, footprintRow: row }
            : b
        )
      );
    } else {
      setEventPoints(prev =>
        prev.map(ep =>
          ep.id === dragging.id
            ? { ...ep, x: col, y: row }
            : ep
        )
      );
    }
  };

  // Handle drag end
  const handleMouseUp = () => {
    setDragging(null);
  };

  // Render grid overlay
  const renderGrid = () => {
    if (!showGrid) return null;

    const lines = [];
    // Vertical lines every 5 tiles
    for (let col = 0; col <= 30; col += 5) {
      lines.push(
        <View
          key={`v${col}`}
          style={{
            position: 'absolute',
            left: col * TILE_SIZE,
            top: 0,
            width: col % 10 === 0 ? 2 : 1,
            height: 960,
            backgroundColor: col % 10 === 0 ? 'rgba(255, 255, 0, 0.5)' : 'rgba(255, 255, 255, 0.2)',
            zIndex: 1,
          }}
        />
      );
    }
    // Horizontal lines every 5 tiles
    for (let row = 0; row <= 20; row += 5) {
      lines.push(
        <View
          key={`h${row}`}
          style={{
            position: 'absolute',
            left: 0,
            top: row * TILE_SIZE,
            width: 1440,
            height: row % 10 === 0 ? 2 : 1,
            backgroundColor: row % 10 === 0 ? 'rgba(255, 255, 0, 0.5)' : 'rgba(255, 255, 255, 0.2)',
            zIndex: 1,
          }}
        />
      );
    }
    return lines;
  };

  // Render map chunks as background
  const renderMapBackground = () => {
    const worldKey = world.id === 1 ? 'w1' : 'w2';
    const chunks = CHUNK_IMAGES[worldKey];

    return (
      <>
        <Image source={chunks.a1} style={[styles.chunk, { left: 0, top: 0 }]} />
        <Image source={chunks.b1} style={[styles.chunk, { left: 480, top: 0 }]} />
        <Image source={chunks.c1} style={[styles.chunk, { left: 960, top: 0 }]} />
        <Image source={chunks.a2} style={[styles.chunk, { left: 0, top: 480 }]} />
        <Image source={chunks.b2} style={[styles.chunk, { left: 480, top: 480 }]} />
        <Image source={chunks.c2} style={[styles.chunk, { left: 960, top: 480 }]} />
      </>
    );
  };

  // Save and export positions
  const handleSave = () => {
    console.log('=== SAVED POSITIONS ===');
    console.log('\nBuildings:');
    buildings.forEach(b => {
      console.log(
        `{ id: '${b.id}', npcId: '${b.npcId}', sprite: '${b.sprite}', ` +
        `footprintCol: ${b.footprintCol}, footprintRow: ${b.footprintRow}, ` +
        `footprintW: ${b.footprintW}, footprintH: ${b.footprintH} },`
      );
    });
    console.log('\nEvent Points:');
    eventPoints.forEach(ep => {
      console.log(`{ id: '${ep.id}', npcId: '${ep.npcId}', x: ${ep.x}, y: ${ep.y} },`);
    });

    onSave(buildings, eventPoints);
  };

  return (
    <View style={styles.container}>
      {/* Toolbar */}
      <View style={styles.toolbar}>
        <Text style={styles.title}>Map Editor - Arraste os assets</Text>
        <Pressable
          style={[styles.button, { backgroundColor: showGrid ? '#10b981' : '#6b7280' }]}
          onPress={() => setShowGrid(!showGrid)}
        >
          <Text style={styles.buttonText}>Grid: {showGrid ? 'ON' : 'OFF'}</Text>
        </Pressable>
        <Pressable style={[styles.button, styles.saveButton]} onPress={handleSave}>
          <Text style={styles.buttonText}>💾 Salvar (veja console)</Text>
        </Pressable>
        <Pressable style={[styles.button, styles.closeButton]} onPress={onClose}>
          <Text style={styles.buttonText}>✕ Fechar</Text>
        </Pressable>
      </View>

      {/* Map canvas */}
      <View
        style={styles.canvas}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
      >
        {/* Map background (chunks) */}
        {renderMapBackground()}
        
        {/* Grid */}
        {renderGrid()}

        {/* Buildings */}
        {buildings.map((building) => {
          const x = building.footprintCol * TILE_SIZE + (building.footprintW * TILE_SIZE - 96) / 2;
          const y = building.footprintRow * TILE_SIZE + building.footprintH * TILE_SIZE - 96;

          return (
            <Pressable
              key={building.id}
              style={[
                styles.building,
                {
                  left: x,
                  top: y,
                  backgroundColor: '#9333EA',
                  opacity: dragging?.id === building.id ? 0.7 : 1,
                },
              ]}
              onMouseDown={(e) => handleBuildingDragStart(building, e)}
            >
              <Text style={styles.label}>{building.sprite}</Text>
              <Text style={styles.coords}>
                ({building.footprintCol},{building.footprintRow})
              </Text>
            </Pressable>
          );
        })}

        {/* Event Points */}
        {eventPoints.map((ep) => {
          const x = ep.x * TILE_SIZE;
          const y = ep.y * TILE_SIZE;

          return (
            <Pressable
              key={ep.id}
              style={[
                styles.eventPoint,
                {
                  left: x - 12,
                  top: y - 12,
                  opacity: dragging?.id === ep.id ? 0.7 : 1,
                },
              ]}
              onMouseDown={(e) => handleEventPointDragStart(ep, e)}
            >
              <Text style={styles.epCoords}>
                {ep.npcId}
                {'\n'}({ep.x},{ep.y})
              </Text>
            </Pressable>
          );
        })}
      </View>

      {/* Instructions */}
      <View style={styles.instructions}>
        <Text style={styles.instructionText}>
          🖱️ Arraste prédios roxos e event points dourados para alinhar com o mapa
        </Text>
        <Text style={styles.instructionText}>
          📍 As coordenadas (col, row) aparecem em cada asset
        </Text>
        <Text style={styles.instructionText}>
          💾 Clique em "Salvar" e copie o código do console para worldMaps.ts
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.95)',
    zIndex: 9999,
  },
  toolbar: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#1f2937',
    gap: 12,
  },
  title: {
    flex: 1,
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
  },
  button: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 6,
    backgroundColor: '#4b5563',
  },
  saveButton: {
    backgroundColor: '#10b981',
  },
  closeButton: {
    backgroundColor: '#ef4444',
  },
  buttonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  canvas: {
    flex: 1,
    position: 'relative',
    backgroundColor: '#000',
    width: 1440,
    height: 960,
    margin: 'auto',
  },
  chunk: {
    position: 'absolute',
    width: CHUNK_SIZE,
    height: CHUNK_SIZE,
    zIndex: 0,
  },
  building: {
    position: 'absolute',
    width: 96,
    height: 96,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    cursor: 'move',
    zIndex: 100,
  },
  label: {
    color: '#fff',
    fontSize: 10,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  coords: {
    color: '#fff',
    fontSize: 9,
    marginTop: 4,
  },
  eventPoint: {
    position: 'absolute',
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#fbbf24',
    borderWidth: 2,
    borderColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    cursor: 'move',
    zIndex: 101,
  },
  epCoords: {
    color: '#000',
    fontSize: 7,
    fontWeight: 'bold',
    textAlign: 'center',
    lineHeight: 8,
  },
  instructions: {
    padding: 16,
    backgroundColor: '#1f2937',
    gap: 8,
  },
  instructionText: {
    color: '#d1d5db',
    fontSize: 14,
  },
});
