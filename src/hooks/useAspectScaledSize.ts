// useAspectScaledSize - Scale sprites preserving aspect ratio
import { useState, useEffect } from 'react';
import { Image } from 'react-native';

export function useAspectScaledSize(source: any, targetHeight: number) {
  const [size, setSize] = useState({ width: targetHeight, height: targetHeight });
  
  useEffect(() => {
    // If source is already an object with uri/width/height (from require())
    if (typeof source === 'object' && source.uri) {
      // React Native Web includes dimensions in the require() result
      if (source.width && source.height) {
        const scale = targetHeight / source.height;
        setSize({ width: source.width * scale, height: targetHeight });
        return;
      }
      
      // Fallback: try Image.getSize with the uri directly
      Image.getSize(
        source.uri,
        (nativeW, nativeH) => {
          const scale = targetHeight / nativeH;
          setSize({ width: nativeW * scale, height: targetHeight });
        },
        (error) => {
          console.warn('useAspectScaledSize: getSize failed', error);
        }
      );
      return;
    }
    
    // Native: try resolveAssetSource (only exists on native platforms)
    try {
      const resolveAssetSource = (Image as any).resolveAssetSource;
      if (typeof resolveAssetSource === 'function') {
        const resolved = resolveAssetSource(source);
        if (resolved) {
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
          return;
        }
      }
    } catch (error) {
      console.warn('useAspectScaledSize: Error resolving asset', error);
    }
  }, [source, targetHeight]);
  
  return size;
}
