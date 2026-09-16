#!/usr/bin/env python3
"""
Fix inconsistent vertical alignment in walk frames
"""
from PIL import Image
import numpy as np
import os

WALK_DIR = 'assets/images/player/walk'

print('Fixing vertical alignment...\n')

for direction in ['front', 'back', 'left', 'right']:
    print(f'=== {direction.upper()} ===')
    
    frames = []
    min_y_offset = 999
    
    # First pass: find minimum y offset
    for i in range(8):
        path = os.path.join(WALK_DIR, f'boy-walk-{direction}-{i}.png')
        img = Image.open(path).convert('RGBA')
        data = np.array(img)
        alpha = data[:, :, 3]
        
        rows = np.any(alpha > 0, axis=1)
        if rows.any():
            y_min = np.where(rows)[0][0]
            min_y_offset = min(min_y_offset, y_min)
            frames.append((path, img, y_min))
        else:
            frames.append((path, img, 0))
    
    print(f'  Min Y offset: {min_y_offset}')
    
    # Second pass: align all to min offset
    fixed_count = 0
    for path, img, y_offset in frames:
        if y_offset != min_y_offset:
            # Need to shift up
            shift = y_offset - min_y_offset
            
            # Create new canvas
            canvas = Image.new('RGBA', img.size, (0, 0, 0, 0))
            
            # Paste image shifted up
            canvas.paste(img, (0, -shift), img)
            canvas.save(path, 'PNG')
            
            print(f'  ✂️  Frame {os.path.basename(path)}: shifted up {shift}px')
            fixed_count += 1
    
    if fixed_count == 0:
        print(f'  ✓ All frames already aligned')
    else:
        print(f'  ✅ Fixed {fixed_count} frames')
    print()

print('Done!')
