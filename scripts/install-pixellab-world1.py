"""Archive superseded Townville assets, then install one coherent PixelLab set."""
from pathlib import Path
import shutil,json,hashlib
ROOT=Path('/Users/nelsonmonteiro/Documents/Townville')
ARCH=ROOT/'artifacts/asset-archive/20260917-104807-before-pixellab-world1'
ARCH.mkdir(parents=True,exist_ok=True)
manifest=[]
def archive(path):
 p=ROOT/path
 if not p.exists():return
 dst=ARCH/path;dst.parent.mkdir(parents=True,exist_ok=True)
 if p.is_dir():shutil.move(str(p),str(dst));manifest.append({'source':path,'archive':str(dst.relative_to(ROOT)),'kind':'directory'})
 else:
  h=hashlib.sha256(p.read_bytes()).hexdigest();shutil.move(str(p),str(dst));manifest.append({'source':path,'archive':str(dst.relative_to(ROOT)),'sha256':h})
# Old World 1 map icons are no longer referenced; current idles now serve map + portrait.
for n in ['mae','chester','lily','farmer-joe','grandma-rose','billy','vera','old-mac']:
 archive(f'assets/images/characters/map-icons/{n}-map.png')
# Superseded map and preview files.
for p in sorted((ROOT/'assets/images/maps').glob('map-w1-*.png')):archive(str(p.relative_to(ROOT)))
for n in ['_preview-world1-assembled.png','_preview-world2-assembled.png']:archive('assets/images/maps/'+n)
# Inert source backups and obsolete renderer; active renderer is WorldMapRenderer + RealBuildingSprite.
for n in ['src/WorldMapRenderer.tsx.bak','src/WorldMapRenderer.tsx.backup-images','src/core.ts.backup','src/components/BuildingSprite.tsx']:archive(n)
# Unused historical data/reference/reserve assets, preserved outside runtime assets.
for n in ['townville-pixel-data','assets/images/protagonist/_reference-only','assets/images/scenery/world2','assets/images/{characters']:
 archive(n)
# Install fresh generated map chunks only after old chunks are out of runtime assets.
src=ROOT/'artifacts/pixellab-world1-map/chunks';dst=ROOT/'assets/images/maps';dst.mkdir(parents=True,exist_ok=True)
installed=[]
for p in sorted(src.glob('map-w1-*.png')):
 target=dst/p.name;shutil.copy2(p,target);installed.append({'path':str(target.relative_to(ROOT)),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
assert len(installed)==12
# Validate current generated character/building families and absence of archived World 1 icons.
assert len(list((ROOT/'assets/images/characters/world1').glob('*-idle.png')))==8
assert all(not (ROOT/f'assets/images/characters/map-icons/{n}-map.png').exists() for n in ['mae','chester','lily','farmer-joe','grandma-rose','billy','vera','old-mac'])
for n in ['henhouse','stable','barn','coop','animal-clinic','garden','fence','farm-gate-open']:
 assert (ROOT/f'assets/images/buildings/world1/building-{n}.png').exists()
report={'archive':str(ARCH.relative_to(ROOT)),'archived':manifest,'installed':installed,'preserved':['World 1 happy/sad portraits','World 1 locked buildings','farm gate closed','all World 2 map chunks and runtime sprites']}
(ARCH/'manifest.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'archived_entries':len(manifest),'installed_chunks':len(installed),'archive':str(ARCH)},indent=2))
