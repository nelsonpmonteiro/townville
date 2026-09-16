#!/usr/bin/env python3
"""
Trim transparent margins from all sprite PNGs.
Run once before implementing sprite scaling system.
"""
from PIL import Image
import numpy as np
import os
import sys

def trim_to_content(path):
    """Crop image to non-transparent content bounds."""
    img = Image.open(path).convert('RGBA')
    arr = np.array(img)
    alpha = arr[:,:,3]
    ys, xs = np.where(alpha > 10)
    
    if len(ys) == 0:
        print(f"  ⚠️  {os.path.basename(path)}: completely transparent, skipping")
        return False
    
    cropped = img.crop((xs.min(), ys.min(), xs.max()+1, ys.max()+1))
    cropped.save(path)
    return True

def process_folder(folder):
    """Process all PNG files in folder recursively."""
    if not os.path.exists(folder):
        print(f"⚠️  Folder not found: {folder}")
        return
    
    trimmed_count = 0
    for root, _, files in os.walk(folder):
        for f in files:
            if f.endswith('.png') and not f.startswith('map-'):  # Skip map chunks
                path = os.path.join(root, f)
                before = Image.open(path).size
                if trim_to_content(path):
                    after = Image.open(path).size
                    if before != after:
                        print(f"✂️  {f}: {before} → {after}")
                        trimmed_count += 1
    
    return trimmed_count

if __name__ == '__main__':
    base = 'assets/images'
    folders = ['characters', 'buildings', 'scenery', 'player']
    
    print("🔧 Trimming sprite margins...\n")
    total = 0
    for sub in folders:
        folder_path = os.path.join(base, sub)
        print(f"📁 {sub}/")
        count = process_folder(folder_path)
        total += count
        print()
    
    print(f"✅ Done! Trimmed {total} sprites.")
