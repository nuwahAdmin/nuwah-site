"""Nuwah Interiors - convert assets/web JPEGs to WebP, plus 800px grid versions.
Run from the nuwah-site folder:  python make-webp.py
Keeps og-image.jpg (social crawlers prefer JPEG). Deletes the JPEG originals it replaced
(they can be regenerated with prepare-work-photos.ps1 / prepare-images.ps1 / hero.ps1)."""
import os, glob
from PIL import Image

web = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "web")
KEEP_JPG = {"og-image.jpg"}
GRID_PREFIXES = ("work-",)          # get an extra -800 version for gallery / home strip
total_before = total_after = 0
rows = []

for path in sorted(glob.glob(os.path.join(web, "*.jpg"))):
    name = os.path.basename(path)
    if name in KEEP_JPG:
        continue
    stem = name[:-4]
    im = Image.open(path).convert("RGB")
    before = os.path.getsize(path)

    full = os.path.join(web, stem + ".webp")
    im.save(full, "WEBP", quality=80, method=6)
    after = os.path.getsize(full)

    small = ""
    if stem.startswith(GRID_PREFIXES):
        s = im.copy()
        s.thumbnail((800, 800), Image.LANCZOS)
        sp = os.path.join(web, stem + "-800.webp")
        s.save(sp, "WEBP", quality=78, method=6)
        small = f"  -800: {os.path.getsize(sp)//1024} KB"

    os.remove(path)
    total_before += before; total_after += after
    rows.append(f"{name:<16} {before//1024:>4} KB -> {after//1024:>4} KB{small}")

print("\n".join(rows))
print(f"\n{len(rows)} images: {total_before//1024} KB -> {total_after//1024} KB full-size WebP")
