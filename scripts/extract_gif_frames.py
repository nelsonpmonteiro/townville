#!/usr/bin/env python3
"""
Extract frames from protagonist walk animation GIFs
"""
from PIL import Image
import os

# GIF files and their corresponding directions
GIFS = {
    'male-walk-down.gif': 'front',
    'male-walk-up.gif': 'back',
    'male-walk-left.gif': 'left',
    'male-walk-right.gif': 'right',
}

OUTPUT_DIR = 'assets/images/player/walk'

def extract_frames(gif_path, direction):
    """Extract all frames from a GIF and save as individual PNGs"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    img = Image.open(gif_path)
    frame_count = 0
    
    try:
        while True:
            # Save current frame
            frame_path = os.path.join(OUTPUT_DIR, f'boy-walk-{direction}-{frame_count}.png')
            
            # Convert to RGBA if needed
            if img.mode != 'RGBA':
                frame = img.convert('RGBA')
            else:
                frame = img.copy()
            
            frame.save(frame_path, 'PNG')
            print(f'  Frame {frame_count}: {frame_path} ({frame.size[0]}×{frame.size[1]})')
            
            frame_count += 1
            img.seek(img.tell() + 1)  # Move to next frame
    except EOFError:
        pass  # End of GIF
    
    return frame_count

if __name__ == '__main__':
    print('Extracting walk animation frames from GIFs...\n')
    
    total_frames = 0
    for gif_file, direction in GIFS.items():
        print(f'Processing {gif_file} → direction={direction}')
        frame_count = extract_frames(gif_file, direction)
        print(f'  Extracted {frame_count} frames\n')
        total_frames += frame_count
    
    print(f'✅ Done! Extracted {total_frames} frames total to {OUTPUT_DIR}/')
