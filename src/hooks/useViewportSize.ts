// Viewport size hook - responsive window dimensions.
// Capped at the map size: a viewport larger than the map would invert
// the camera clamp range (Animated inputRange crash) and stretch the
// letterbox; excess space stays as black margins around the viewport.
import { useState, useEffect } from 'react';
import { MAP_WIDTH, MAP_HEIGHT } from '../config';

const HEADER_HEIGHT = 60; // GameHeader height

function measure() {
  const w = typeof window !== 'undefined' ? window.innerWidth : 1200;
  const h = typeof window !== 'undefined' ? window.innerHeight - HEADER_HEIGHT : 800;
  return {
    width: Math.min(w, MAP_WIDTH),
    height: Math.min(h, MAP_HEIGHT),
  };
}

export function useViewportSize() {
  const [size, setSize] = useState(measure);

  useEffect(() => {
    if (typeof window === 'undefined') return;

    const onResize = () => setSize(measure());

    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);

  return size;
}
