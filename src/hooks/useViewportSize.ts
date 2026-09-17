// Viewport size hook - responsive window dimensions.
// Capped at the map size: a viewport larger than the map would invert
// the camera clamp range (Animated inputRange crash) and stretch the
// letterbox; excess space stays as black margins around the viewport.
import { useState, useEffect } from 'react';
import { MAP_WIDTH, MAP_HEIGHT } from '../config';

const HEADER_HEIGHT = 60; // GameHeader height

function measure(mapWidth: number, mapHeight: number) {
  const w = typeof window !== 'undefined' ? window.innerWidth : 1200;
  const h = typeof window !== 'undefined' ? window.innerHeight - HEADER_HEIGHT : 800;
  return {
    width: Math.min(w, mapWidth),
    height: Math.min(h, mapHeight),
  };
}

export function useViewportSize(mapWidth = MAP_WIDTH, mapHeight = MAP_HEIGHT) {
  const [size, setSize] = useState(() => measure(mapWidth, mapHeight));

  useEffect(() => {
    if (typeof window === 'undefined') return;

    const onResize = () => setSize(measure(mapWidth, mapHeight));
    onResize();

    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, [mapWidth, mapHeight]);

  return size;
}
