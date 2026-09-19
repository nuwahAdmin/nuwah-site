"""Nuwah Interiors - produce styles.min.css and site.min.js from the readable sources.
Run after editing styles.css or site.js:   python minify.py
Then bump the ?v= version in the pages (the script does this for you)."""
import os, re, glob, datetime
try:
    import rcssmin, rjsmin
except ImportError:
    raise SystemExit("run:  python -m pip install rcssmin rjsmin")

root = os.path.dirname(os.path.abspath(__file__))
v = datetime.datetime.now().strftime("%Y%m%d%H%M")

def build(src, dst, fn):
    with open(os.path.join(root, src), encoding="utf-8") as f: s = f.read()
    out = fn(s)
    with open(os.path.join(root, dst), "w", encoding="utf-8") as f: f.write(out)
    print(f"{src:<12} {len(s):>6} -> {dst:<14} {len(out):>6} bytes")

build("styles.css", "styles.min.css", rcssmin.cssmin)
build("site.js", "site.min.js", rjsmin.jsmin)

pages = ["index.html", "404.html"] + glob.glob(os.path.join(root, "*", "index.html"))
for p in pages:
    path = p if os.path.isabs(p) else os.path.join(root, p)
    with open(path, encoding="utf-8") as f: h = f.read()
    n = re.sub(r'href="/styles(?:\.min)?\.css(?:\?v=[^"]*)?"', f'href="/styles.min.css?v={v}"', h)
    n = re.sub(r'src="/site(?:\.min)?\.js(?:\?v=[^"]*)?"', f'src="/site.min.js?v={v}"', n)
    if n != h:
        with open(path, "w", encoding="utf-8", newline="") as f: f.write(n)
    print(f"{os.path.relpath(path, root):<22} css:{'styles.min.css' in n} js:{'site.min.js' in n}")
print("version", v)
