// Viewport size hook - responsive window dimensions
import { useState, useEffect } from 'react';

const HEADER_HEIGHT = 60; // GameHeader height

export function useViewportSize() {
  const [size, setSize] = useState({
    width: typeof window !== 'undefined' ? window.innerWidth : 1200,
    height: typeof window !== 'undefined' ? window.innerHeight - HEADER_HEIGHT : 800,
  });

  useEffect(() => {
    if (typeof window === 'undefined') return;

    const onResize = () => {
      setSize({
        width: window.innerWidth,
        height: window.innerHeight - HEADER_HEIGHT,
      });
    };

    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);

  return size;
}
