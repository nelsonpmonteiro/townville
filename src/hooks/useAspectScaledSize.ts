// useAspectScaledSize - Scale sprites preserving aspect ratio.
//
// Resolution order (no flicker on web):
// 1. source.width/height (Metro web injects them into require()) → SYNC
// 2. Native resolveAssetSource → SYNC
// 3. Image.getSize(uri) → async fallback (remote uris only)
import { useState, useEffect, useMemo } from 'react';
import { Image } from 'react-native';

function syncDims(source: any): { width: number; height: number } | null {
  // Web (Metro): require() returns { uri, width, height }
  if (source && typeof source === 'object' && source.width && source.height) {
    return { width: source.width, height: source.height };
  }
  // Native: resolveAssetSource is synchronous
  const resolve = (Image as any).resolveAssetSource;
  if (typeof resolve === 'function') {
    try {
      const r = resolve(source);
      if (r?.width && r?.height) return { width: r.width, height: r.height };
    } catch { /* fall through */ }
  }
  return null;
}

export function useAspectScaledSize(source: any, targetHeight: number) {
  // Synchronous path: correct size on the very first render (no flicker)
  const initial = useMemo(() => {
    const dims = syncDims(source);
    if (dims) {
      const scale = targetHeight / dims.height;
      return { width: dims.width * scale, height: targetHeight };
    }
    return { width: targetHeight, height: targetHeight }; // square fallback
  }, [source, targetHeight]);

  const [size, setSize] = useState(initial);

  useEffect(() => {
    // Keep in sync when source/target changes (sync path)
    const dims = syncDims(source);
    if (dims) {
      const scale = targetHeight / dims.height;
      setSize({ width: dims.width * scale, height: targetHeight });
      return;
    }
    // Async fallback: remote uri without embedded dimensions
    if (source && typeof source === 'object' && source.uri) {
      let cancelled = false;
      Image.getSize(
        source.uri,
        (w, h) => {
          if (cancelled) return;
          const scale = targetHeight / h;
          setSize({ width: w * scale, height: targetHeight });
        },
        () => { /* keep fallback size */ }
      );
      return () => { cancelled = true; };
    }
  }, [source, targetHeight]);

  return size;
}
