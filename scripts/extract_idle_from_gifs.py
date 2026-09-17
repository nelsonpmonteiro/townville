#!/usr/bin/env python3
"""
Extract GIF frames at FULL 128×128px (no trim), then resize to 64×64px
"""
from PIL import Image
import os

GIFS = {
    'male-walk-down.gif': 'front',
    'male-walk-up.gif': 'back',
    'male-walk-left.gif': 'left',
    'male-walk-right.gif': 'right',
}

OUTPUT_DIR = 'assets/images/player'
os.makedirs(OUTPUT_DIR, exist_ok=True)

for gif_file, direction in GIFS.items():
    # Extract frame 0 (idle pose)
    gif = Image.open(gif_file)
    frame = gif.convert('RGBA')
    
    # Resize from 128×128 to 64×64 (high quality)
    resized = frame.resize((64, 64), Image.Resampling.LANCZOS)
    
    # Save
    output_path = os.path.join(OUTPUT_DIR, f'boy-{direction}.png')
    resized.save(output_path, 'PNG')
    
    print(f'✅ {direction}: {gif_file} → boy-{direction}.png (64×64px)')

print('\n✅ Done! All 4 idle sprites created at 64×64px')
