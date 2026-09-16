#!/usr/bin/env python3
"""
Check for corruption in walk frames
"""
from PIL import Image
import numpy as np

directions = ['front', 'right']
issues = []

for direction in directions:
    print(f'\n=== {direction.upper()} ===')
    for i in range(8):
        path = f'assets/images/player/walk/boy-walk-{direction}-{i}.png'
        img = Image.open(path).convert('RGBA')
        data = np.array(img)
        
        # Check dimensions
        h, w = data.shape[:2]
        
        # Check for fully transparent rows/cols
        alpha = data[:, :, 3]
        empty_rows = np.sum(alpha, axis=1) == 0
        empty_cols = np.sum(alpha, axis=0) == 0
        
        # Check for black pixels (corruption artifacts)
        rgb = data[:, :, :3]
        black_pixels = np.all(rgb == 0, axis=2) & (alpha > 0)
        black_count = np.sum(black_pixels)
        
        status = '✓' if black_count == 0 else f'⚠️  {black_count} black pixels'
        print(f'  Frame {i}: {w}×{h} - {status}')
        
        if black_count > 0:
            issues.append((direction, i, black_count))

if issues:
    print(f'\n❌ Found {len(issues)} corrupted frames')
    for direction, frame, count in issues:
        print(f'  - {direction}-{frame}: {count} black pixels')
else:
    print('\n✅ All frames OK')
