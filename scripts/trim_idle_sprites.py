#!/usr/bin/env python3
from PIL import Image
import numpy as np

idle_sprites = [
    'assets/images/player/boy-front.png',
    'assets/images/player/boy-back.png',
    'assets/images/player/boy-left.png',
    'assets/images/player/boy-right.png',
]

for path in idle_sprites:
    img = Image.open(path).convert('RGBA')
    data = np.array(img)
    
    # Find non-transparent pixels
    alpha = data[:, :, 3]
    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)
    
    if not rows.any() or not cols.any():
        print(f'⚠️  {path}: fully transparent, skipping')
        continue
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    old_size = img.size
    cropped = img.crop((x_min, y_min, x_max + 1, y_max + 1))
    new_size = cropped.size
    
    cropped.save(path, 'PNG')
    print(f'✂️  {path}: {old_size} → {new_size}')

print('\n✅ Done!')
