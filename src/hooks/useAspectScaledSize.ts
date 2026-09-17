// useAspectScaledSize - Scale sprites preserving aspect ratio
import { useState, useEffect } from 'react';
import { Image } from 'react-native';

export function useAspectScaledSize(source: any, targetHeight: number) {
  const [size, setSize] = useState({ width: targetHeight, height: targetHeight });
  
  useEffect(() => {
    try {
      const resolved = Image.resolveAssetSource(source);
      if (!resolved) {
        console.warn('useAspectScaledSize: Could not resolve source');
        return;
      }
      
      Image.getSize(
        resolved.uri,
        (nativeW, nativeH) => {
          const scale = targetHeight / nativeH;
          setSize({ width: nativeW * scale, height: targetHeight });
        },
        (error) => {
          console.warn('useAspectScaledSize: getSize failed', error);
        }
      );
    } catch (error) {
      console.warn('useAspectScaledSize: Error resolving asset', error);
    }
  }, [source, targetHeight]);
  
  return size;
}
