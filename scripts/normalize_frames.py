#!/usr/bin/env python3
"""
Normalize walk animation frames to consistent dimensions
"""
from PIL import Image
import os

WALK_DIR = 'assets/images/player/walk'

# Find max dimensions across all frames
max_w = 0
max_h = 0

frames = []
for f in os.listdir(WALK_DIR):
    if f.endswith('.png'):
        path = os.path.join(WALK_DIR, f)
        img = Image.open(path)
        frames.append((path, img.size))
        max_w = max(max_w, img.size[0])
        max_h = max(max_h, img.size[1])

print(f'Max dimensions: {max_w}×{max_h}')
print(f'Processing {len(frames)} frames...\n')

# Normalize all frames
for path, (w, h) in frames:
    if w == max_w and h == max_h:
        print(f'✓ {os.path.basename(path)}: already {w}×{h}')
        continue
    
    img = Image.open(path).convert('RGBA')
    
    # Create canvas with max dimensions
    canvas = Image.new('RGBA', (max_w, max_h), (0, 0, 0, 0))
    
    # Center the image on canvas (bottom-aligned for character sprites)
    x_offset = (max_w - w) // 2
    y_offset = max_h - h  # Bottom-align
    
    canvas.paste(img, (x_offset, y_offset), img)
    canvas.save(path, 'PNG')
    
    print(f'✂️  {os.path.basename(path)}: {w}×{h} → {max_w}×{max_h} (offset: {x_offset}, {y_offset})')

print(f'\n✅ Done! All frames normalized to {max_w}×{max_h}')
