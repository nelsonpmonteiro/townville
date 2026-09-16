#!/usr/bin/env python3
"""
Re-extract and clean walk frames from GIFs
"""
from PIL import Image, ImageDraw
import os

GIFS = {
    'male-walk-down.gif': 'front',
    'male-walk-up.gif': 'back',
    'male-walk-left.gif': 'left',
    'male-walk-right.gif': 'right',
}

OUTPUT_DIR = 'assets/images/player/walk'
os.makedirs(OUTPUT_DIR, exist_ok=True)

def clean_frame(frame):
    """Remove compression artifacts and ensure clean RGBA"""
    # Convert to RGBA
    if frame.mode != 'RGBA':
        frame = frame.convert('RGBA')
    
    # Get data
    data = frame.load()
    width, height = frame.size
    
    # Clean semi-transparent artifacts (make fully opaque or fully transparent)
    for y in range(height):
        for x in range(width):
            r, g, b, a = data[x, y]
            if a < 128:  # Semi-transparent -> fully transparent
                data[x, y] = (0, 0, 0, 0)
            else:  # Keep opaque
                data[x, y] = (r, g, b, 255)
    
    return frame

def extract_and_normalize(gif_path, direction):
    """Extract, clean, and normalize frames"""
    img = Image.open(gif_path)
    frames = []
    
    # Extract all frames
    try:
        i = 0
        while True:
            frame = img.copy()
            frame = clean_frame(frame)
            frames.append(frame)
            i += 1
            img.seek(i)
    except EOFError:
        pass
    
    print(f'{direction}: extracted {len(frames)} frames')
    
    # Find max dimensions
    max_w = max(f.size[0] for f in frames)
    max_h = max(f.size[1] for f in frames)
    
    # Normalize and save
    for i, frame in enumerate(frames):
        w, h = frame.size
        
        # Create normalized canvas
        canvas = Image.new('RGBA', (max_w, max_h), (0, 0, 0, 0))
        
        # Center horizontally, bottom-align vertically
        x_offset = (max_w - w) // 2
        y_offset = max_h - h
        
        canvas.paste(frame, (x_offset, y_offset), frame)
        
        # Save
        output_path = os.path.join(OUTPUT_DIR, f'boy-walk-{direction}-{i}.png')
        canvas.save(output_path, 'PNG', optimize=True)
        
        print(f'  Frame {i}: {w}×{h} → {max_w}×{max_h}')
    
    return len(frames), max_w, max_h

if __name__ == '__main__':
    print('Re-extracting walk frames from GIFs...\n')
    
    for gif_file, direction in GIFS.items():
        count, w, h = extract_and_normalize(gif_file, direction)
        print(f'  ✅ {direction}: {count} frames at {w}×{h}\n')
    
    print('Done!')
