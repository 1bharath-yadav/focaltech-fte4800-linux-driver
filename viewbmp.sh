#!/bin/bash
d=/home/archer/projects/zerobook-focaltech-driver
ls -1t /tmp/20261002145*.bmp 2>/dev/null | head -5 | tac > /tmp/bmp_list.txt
echo "bmps found:"; cat /tmp/bmp_list.txt
python3 - <<'EOF'
import sys
try:
    from PIL import Image
except Exception as e:
    print("NO_PIL", e); sys.exit(0)
files = [l.strip() for l in open('/tmp/bmp_list.txt') if l.strip()][:4]
imgs = []
for f in files:
    im = Image.open(f)
    print(f, im.size, im.mode, im.getextrema())
    im = im.convert('L')
    lo, hi = im.getextrema()
    if hi > lo:  # stretch contrast so we can see structure
        im = im.point(lambda v: int((v-lo)*255/(hi-lo)))
    imgs.append(im.resize((im.width*5, im.height*5), Image.NEAREST))
if imgs:
    W = sum(i.width for i in imgs) + 10*(len(imgs)-1)
    H = max(i.height for i in imgs)
    out = Image.new('L', (W, H), 128)
    x = 0
    for i in imgs:
        out.paste(i, (x, 0)); x += i.width + 10
    out.save('/home/archer/projects/zerobook-focaltech-driver/bmp_view.png')
    print("saved bmp_view.png", out.size)
EOF
file $(cat /tmp/bmp_list.txt | head -1)
