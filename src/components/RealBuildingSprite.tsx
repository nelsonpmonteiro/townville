// RealBuildingSprite - Renders building with locked/unlocked state.
// Scales by CONTENT height (targetHeight) preserving aspect ratio —
// building PNGs are trimmed, so canvas == content.
import React from 'react';
import { Image, View, StyleSheet } from 'react-native';
import { crossShadow } from '../utils/shadow';
import { useAspectScaledSize } from '../hooks/useAspectScaledSize';
import { BUILDING_TARGET_HEIGHT } from '../config';

type BuildingState = 'LOCKED' | 'STAGE_1' | 'STAGE_2' | 'STAGE_3' | 'COMPLETE';

interface Props {
  buildingId: string;
  state: BuildingState;
  /** Rendered height in px; width follows the sprite's aspect ratio. */
  targetHeight?: number;
}

// Static requires for Metro bundler
const WORLD1_BUILDINGS = {
  'henhouse': require('../../assets/images/buildings/world1/building-henhouse.png'),
  'henhouse-locked': require('../../assets/images/buildings/world1/building-henhouse-locked.png'),
  'stable': require('../../assets/images/buildings/world1/building-stable.png'),
  'stable-locked': require('../../assets/images/buildings/world1/building-stable-locked.png'),
  'barn': require('../../assets/images/buildings/world1/building-barn.png'),
  'barn-locked': require('../../assets/images/buildings/world1/building-barn-locked.png'),
  'coop': require('../../assets/images/buildings/world1/building-coop.png'),
  'coop-locked': require('../../assets/images/buildings/world1/building-coop-locked.png'),
  'clinic': require('../../assets/images/buildings/world1/building-animal-clinic.png'),
  'clinic-locked': require('../../assets/images/buildings/world1/building-animal-clinic-locked.png'),
  'garden': require('../../assets/images/buildings/world1/building-garden.png'),
  'garden-locked': require('../../assets/images/buildings/world1/building-garden-locked.png'),
  'fence': require('../../assets/images/buildings/world1/building-fence.png'),
  'farm-gate-open': require('../../assets/images/buildings/world1/building-farm-gate-open.png'),
  'farm-gate-closed': require('../../assets/images/buildings/world1/building-farm-gate-closed.png'),
};

const WORLD2_BUILDINGS = {
  'bakery': require('../../assets/images/buildings/world2/building-bakery.png'),
  'bakery-locked': require('../../assets/images/buildings/world2/building-bakery-locked.png'),
  'hardware': require('../../assets/images/buildings/world2/building-hardware-store.png'),
  'hardware-locked': require('../../assets/images/buildings/world2/building-hardware-store-locked.png'),
  'library': require('../../assets/images/buildings/world2/building-library.png'),
  'library-locked': require('../../assets/images/buildings/world2/building-library-locked.png'),
  'town-hall': require('../../assets/images/buildings/world2/building-town-hall.png'),
  'town-hall-locked': require('../../assets/images/buildings/world2/building-town-hall-locked.png'),
  'post-office': require('../../assets/images/buildings/world2/building-post-office.png'),
  'post-office-locked': require('../../assets/images/buildings/world2/building-post-office-locked.png'),
  'park': require('../../assets/images/buildings/world2/building-park.png'),
  'park-locked': require('../../assets/images/buildings/world2/building-park-locked.png'),
  'fountain': require('../../assets/images/buildings/world2/building-fountain.png'),
  'town-gate-open': require('../../assets/images/buildings/world2/building-town-gate-open.png'),
  'town-gate-closed': require('../../assets/images/buildings/world2/building-town-gate-closed.png'),
};

const ALL_BUILDINGS = { ...WORLD1_BUILDINGS, ...WORLD2_BUILDINGS };

export default function RealBuildingSprite({ buildingId, state, targetHeight = BUILDING_TARGET_HEIGHT }: Props) {
  // Determine sprite key
  let spriteKey = buildingId;
  
  // Special cases
  if (buildingId === 'farm-gate' || buildingId === 'town-gate') {
    spriteKey = state === 'COMPLETE' ? `${buildingId}-open` : `${buildingId}-closed`;
  } else if (state === 'LOCKED') {
    spriteKey = `${buildingId}-locked`;
  }
  
  const sprite = ALL_BUILDINGS[spriteKey as keyof typeof ALL_BUILDINGS];

  // Hook must run unconditionally (React rules); safe with null sprite
  const scaled = useAspectScaledSize(sprite, targetHeight);

  if (!sprite) {
    console.warn(`RealBuildingSprite: Missing sprite for ${spriteKey}`);
    return (
      <View style={[styles.placeholder, { width: targetHeight, height: targetHeight }]}>
        <View style={styles.placeholderInner} />
      </View>
    );
  }

  // Render base sprite (aspect-true: width follows source proportions)
  const baseImage = (
    <Image
      source={sprite}
      style={{ width: scaled.width, height: scaled.height }}
      resizeMode="contain"
      fadeDuration={0}
    />
  );

  // Apply overlay for intermediate stages (STAGE_1, STAGE_2, STAGE_3)
  if (state === 'STAGE_1' || state === 'STAGE_2' || state === 'STAGE_3') {
    return (
      <View style={{ width: scaled.width, height: scaled.height }}>
        {baseImage}
        {renderStageOverlay(state, scaled.height)}
      </View>
    );
  }

  // For garden/fountain without -locked sprites, apply grayscale overlay
  if (state === 'LOCKED' && (buildingId === 'garden' || buildingId === 'fountain')) {
    return (
      <View style={{ width: scaled.width, height: scaled.height }}>
        <Image
          source={sprite}
          style={{ width: scaled.width, height: scaled.height, opacity: 0.4 }}
          resizeMode="contain"
        />
        <View style={styles.lockedOverlay}>
          <View style={styles.lockIcon} />
        </View>
      </View>
    );
  }

  return baseImage;
}

// Render construction overlays for intermediate stages
function renderStageOverlay(state: BuildingState, size: number) {
  const opacity = state === 'STAGE_1' ? 0.55 : state === 'STAGE_2' ? 0.8 : 1.0;
  const showScaffolding = state === 'STAGE_1' || state === 'STAGE_2';
  const showBoxes = state === 'STAGE_2';
  const showGlow = state === 'STAGE_3';

  return (
    <View style={[StyleSheet.absoluteFill, { opacity }]} pointerEvents="none">
      {showScaffolding && (
        <View style={styles.scaffolding}>
          {/* Diagonal lines to simulate scaffolding */}
          <View style={[styles.scaffoldLine, { transform: [{ rotate: '45deg' }] }]} />
          <View style={[styles.scaffoldLine, { transform: [{ rotate: '-45deg' }] }]} />
        </View>
      )}
      
      {showBoxes && (
        <View style={styles.boxes}>
          <View style={styles.box} />
          <View style={[styles.box, { left: 12 }]} />
          <View style={[styles.box, { left: 24 }]} />
        </View>
      )}
      
      {showGlow && (
        <View style={styles.glow} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  placeholder: {
    backgroundColor: '#666',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 4,
  },
  placeholderInner: {
    width: '70%',
    height: '70%',
    backgroundColor: '#888',
    borderRadius: 2,
  },
  lockedOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
  },
  lockIcon: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    borderWidth: 3,
    borderColor: '#fff',
  },
  scaffolding: {
    ...StyleSheet.absoluteFillObject,
  },
  scaffoldLine: {
    position: 'absolute',
    width: 2,
    height: '120%',
    backgroundColor: 'rgba(139, 69, 19, 0.5)',
    left: '50%',
    top: '-10%',
  },
  boxes: {
    position: 'absolute',
    bottom: 4,
    left: 4,
    flexDirection: 'row',
  },
  box: {
    width: 8,
    height: 8,
    backgroundColor: 'rgba(139, 69, 19, 0.8)',
    marginRight: 2,
    borderWidth: 1,
    borderColor: 'rgba(101, 67, 33, 1)',
  },
  glow: {
    position: 'absolute',
    top: '20%',
    right: '20%',
    width: 12,
    height: 12,
    backgroundColor: 'rgba(255, 215, 0, 0.6)',
    borderRadius: 6,
    ...crossShadow('0px 0px 6px rgba(255, 215, 0, 0.8)', {
      shadowColor: '#FFD700',
      shadowOffset: { width: 0, height: 0 },
      shadowOpacity: 0.8,
      shadowRadius: 6,
    }),
  },
});
