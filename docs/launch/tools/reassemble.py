import re, glob, base64, sys, os
D='/root/.claude/projects/-home-user/771a727a-0bd6-5c72-ab3b-623d4dca9c3a/tool-results'
chunks={}
for f in glob.glob(D+'/*.txt'):
    s=open(f, errors='ignore').read()
    m=re.search(r'CHUNKID (\w+) (\d+)\nBEGINCHUNK\n([A-Za-z0-9+/=]+)', s)
    if m:
        name, idx, b64 = m.group(1), int(m.group(2)), m.group(3)
        chunks.setdefault(name, {})[idx]=b64
out={'home':'01-home','toolkit':'02-toolkit','outage':'03-outage','ready':'05-ready'}
for name, parts in chunks.items():
    idxs=sorted(parts)
    data=''.join(parts[i] for i in idxs)
    print(name, 'parts', idxs, 'chars', len(data))
    try:
        raw=base64.b64decode(data + '=' * (-len(data) % 4))
        p=f'/home/user/lantern/docs/launch/press/{out[name]}.jpg'
        open(p,'wb').write(raw); print('  wrote', p, len(raw), 'bytes', 'JPEG end ok' if raw[-2:]==b'\xff\xd9' else 'INCOMPLETE')
    except Exception as e: print('  fail', e)
