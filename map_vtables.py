#!/usr/bin/env python3
"""Map vtable slots in ftWbioUmdfDriverV2.dll to function-name strings each function logs.
Usage: map_vtables.py <dll> <asm> <vt_addr_hex> [...]"""
import re, subprocess, sys

dll, asm = sys.argv[1], sys.argv[2]
vts = [int(a, 16) for a in sys.argv[3:]]

def r2(cmds):
    return subprocess.run(['r2', '-q', '-e', 'scr.color=0', '-e', 'bin.relocs.apply=true', '-c', cmds, dll],
                          capture_output=True, text=True).stdout

res = {}
for vt in vts:
    qs = []
    for line in r2(f'pxq 200 @ {vt:#x}').splitlines():
        m = re.match(r'0x[0-9a-f]+\s+((?:0x[0-9a-f]{16}\s*)+)', line)
        if m:
            qs += [int(x, 16) for x in m.group(1).split()]
    res[vt] = qs

lines = open(asm).read().splitlines()
idx = {}
for i, l in enumerate(lines):
    m = re.match(r'\s*([0-9a-f]+):', l)
    if m:
        idx[int(m.group(1), 16)] = i

def func_strings(addr):
    i = idx.get(addr)
    out = []
    if i is None:
        return out
    for n, l in enumerate(lines[i:i + 1200]):
        if n > 30 and 'int3' in l:
            break
        m = re.search(r'lea\s+r\w+,\[rip\+0x[0-9a-f]+\]\s+# (0x[0-9a-f]+)', l)
        if m:
            out.append(int(m.group(1), 16))
    return out

want = {}
for qs in res.values():
    for q in qs[:24]:
        if 0x180001000 <= q < 0x180032000:
            want[q] = func_strings(q)

allstr = sorted({s for v in want.values() for s in v})
out = r2('; '.join(f'?e ==={s:#x}; ps @ {s:#x}' for s in allstr)) if allstr else ''
strs, cur = {}, None
for l in out.splitlines():
    m = re.match(r'===(0x[0-9a-f]+)', l)
    if m:
        cur = int(m.group(1), 16); strs[cur] = ''
    elif cur is not None:
        strs[cur] += l

for vt, qs in res.items():
    print(f'=== vtable {vt:#x}')
    for k, q in enumerate(qs[:24]):
        if not (0x180001000 <= q < 0x180032000):
            if k > 2: break
            print(f'  +{k*8:#04x}  {q:#x}  (non-code)'); continue
        names = [strs[s] for s in want.get(q, []) if strs.get(s, '').startswith(('cls', 'ft_', 'IInterface'))]
        print(f'  +{k*8:#04x}  {q:#x}  {names[0] if names else ""}')
