// Cross-platform shadow helper
// React Native Web deprecated shadow* props in favor of boxShadow (CSS string).
// Native platforms still require shadowColor/Offset/Opacity/Radius.
import { Platform } from 'react-native';

interface NativeShadow {
  shadowColor: string;
  shadowOffset: { width: number; height: number };
  shadowOpacity: number;
  shadowRadius: number;
}

/**
 * Returns the platform-appropriate shadow style.
 * @param css   CSS box-shadow string used on web (e.g. '0px 4px 8px rgba(0,0,0,0.5)')
 * @param native shadow* props used on iOS/Android
 */
export const crossShadow = (css: string, native: NativeShadow): object =>
  Platform.OS === 'web' ? ({ boxShadow: css } as object) : native;
