"""Rebuild World 1 terrain from PixelLab Wang tiles, preserving game data."""
from pathlib import Path
import json,re,hashlib
from PIL import Image
ROOT=Path('/Users/nelsonmonteiro/Documents/Townville')
OUT=ROOT/'artifacts/pixellab-world1-map';OUT.mkdir(parents=True,exist_ok=True)
SOURCE=OUT/'source-reference.png'
if not SOURCE.exists():
 old=Image.new('RGB',(1920,1440))
 for y in range(3):
  for x,col in enumerate('abcd'):
   im=Image.open(ROOT/f'assets/images/maps/map-w1-{col}{y+1}.png').convert('RGB').resize((480,480),Image.Resampling.NEAREST)
   old.paste(im,(x*480,y*480))
 old.save(SOURCE)
old=Image.open(SOURCE).resize((640,480),Image.Resampling.NEAREST)
walk=json.loads(re.sub(r',\s*\]', ']', (ROOT/'src/data/collision_w1.ts').read_text().split('= ',1)[1].strip().rstrip(';')))
assert len(walk)==30 and all(len(row)==40 for row in walk)

def load(folder):
 p=ROOT/'artifacts'/folder;m=json.loads((p/'metadata.json').read_text());s=Image.open(p/'tileset.png').convert('RGB');d={}
 for t in m['tileset_data']['tiles']:
  b=t['bounding_box'];d[tuple(t['corners'][k] for k in ('NW','NE','SW','SE'))]=s.crop((b['x'],b['y'],b['x']+b['width'],b['y']+b['height']))
 assert len(d)==16
 return d
land=load('pixellab-terrain-grass-dirt');water=load('pixellab-terrain-water-grass')
# Corner fields use the old terrain's layout, never old pixels in output.
dirt=[[False]*41 for _ in range(31)];pond=[[False]*41 for _ in range(31)]
for y in range(31):
 for x in range(41):
  px=min(639,x*16);py=min(479,y*16);r,g,b=old.getpixel((px,py))
  dirt[y][x]=r>g*1.12 and g>b*1.25 and r>115
  pond[y][x]=b>r*1.3 and b>g*1.02 and b>110
# Every existing walkable tile retains a clear soil surface.
for y,row in enumerate(walk):
 for x,ok in enumerate(row):
  if ok:
   for dy,dx in [(0,0),(0,1),(1,0),(1,1)]:dirt[y+dy][x+dx]=True;pond[y+dy][x+dx]=False
# Reserve dry terrain for the clinic footprint, Vera's event point and the
# short approach from the central path. The old painted pond and current
# gameplay placement otherwise overlap here.
clinic_dry_tiles = {
 9: range(23,26),
 10: range(22,27),
 11: range(22,27),
 12: range(22,27),
 13: range(23,26),
}
for y,xs in clinic_dry_tiles.items():
 for x in xs:
  for dy,dx in [(0,0),(0,1),(1,0),(1,1)]:
   dirt[y+dy][x+dx]=True;pond[y+dy][x+dx]=False
# Remove tiny disconnected dirt flecks inherited from the old reference image.
# Keep only components that touch a real walkable cell or have meaningful area.
seen=set()
for sy in range(31):
 for sx in range(41):
  if not dirt[sy][sx] or (sx,sy) in seen:continue
  stack=[(sx,sy)];component=[];seen.add((sx,sy))
  while stack:
   cx,cy=stack.pop();component.append((cx,cy))
   for nx,ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
    if 0<=nx<41 and 0<=ny<31 and dirt[ny][nx] and (nx,ny) not in seen:
     seen.add((nx,ny));stack.append((nx,ny))
  if len(component)<8:
   for cx,cy in component:dirt[cy][cx]=False
im=Image.new('RGB',(640,480));placements=[]
for y in range(30):
 for x in range(40):
  offsets=[(0,0),(0,1),(1,0),(1,1)]; wet=any(pond[y+dy][x+dx] for dy,dx in offsets)
  field=pond if wet else dirt
  key=tuple('lower' if field[y+dy][x+dx] else 'upper' for dy,dx in offsets)
  tile=(water if wet else land)[key];im.paste(tile,(x*16,y*16));placements.append({'x':x,'y':y,'set':'water' if wet else 'land','corners':key})
im.save(OUT/'terrain-native.png')
# Retain the separate scenery tree asset; do not extract baked-in old trees.
tree=Image.open(ROOT/'assets/images/scenery/world1/scenery-tree.png').convert('RGBA');tree=tree.resize((29,48),Image.Resampling.NEAREST)
positions=[]
for x in range(-8,640,23):positions.append((x,-21+(x%3)*2))
for y in range(10,440,27):positions.extend([(-15,y),(622,y)])
for x in range(-8,640,22):
 if not 226<x<276:positions.append((x,439+(x%3)*2))
for x,y in sorted(positions,key=lambda p:p[1]):im.paste(tree,(x,y),tree)
# Replace the old baked-in fence by the newly generated fence, same bands.
fence=Image.open(ROOT/'artifacts/pixellab-world1-buildings-idle/building-fence.png').convert('RGBA');fence=fence.resize((28,19),Image.Resampling.NEAREST)
for start,end in [(96,230),(270,333),(455,580)]:
 for x in range(start,end,27):im.paste(fence,(x,267),fence)
full=im.resize((1920,1440),Image.Resampling.NEAREST);full.save(OUT/'world1-map.png');im.resize((960,720),Image.Resampling.NEAREST).save(OUT/'preview.png')
chunks=OUT/'chunks';chunks.mkdir(exist_ok=True)
for y in range(3):
 for x,col in enumerate('abcd'):full.crop((x*480,y*480,(x+1)*480,(y+1)*480)).save(chunks/f'map-w1-{col}{y+1}.png')
# Reassembly proves no chunk gaps and verifies installed renderer dimensions.
reassembled=Image.new('RGB',full.size)
for y in range(3):
 for x,col in enumerate('abcd'):
  chunk=Image.open(chunks/f'map-w1-{col}{y+1}.png');assert chunk.size==(480,480);reassembled.paste(chunk,(x*480,y*480))
assert reassembled.tobytes()==full.tobytes()
assert len(placements)==1200
for p in placements:
 if walk[p['y']][p['x']]:assert p['set']=='land' and all(v=='lower' for v in p['corners'])
report={'tiles':len(placements),'chunks':12,'dimensions':full.size,'walkable_cells':sum(sum(row) for row in walk),'walkable_surface_verified':True,'chunk_reassembly_verified':True,'collision_sha256':hashlib.sha256((ROOT/'src/data/collision_w1.ts').read_bytes()).hexdigest(),'reused_scenery':['scenery-tree.png'],'tilesets':['8d6201db-8f60-4ea0-89c1-d5cca4ad413b','09bcbd29-bd14-4253-81d0-92412a0f6d74']}
(OUT/'report.json').write_text(json.dumps(report,indent=2));(OUT/'placements.json').write_text(json.dumps(placements));print(json.dumps(report,indent=2))
