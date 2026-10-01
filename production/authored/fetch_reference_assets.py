"""Restore licensed inputs from the checked manifest without changing existing sources.
Run from ocarina-of-time/: python3 production/authored/fetch_reference_assets.py
"""
from pathlib import Path
import concurrent.futures
import hashlib
import json
import urllib.request
import zipfile

ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'production/reference-assets'
DEST.mkdir(exist_ok=True)
manifest_path=DEST/'manifest.json'
if not manifest_path.exists(): manifest_path=Path(__file__).with_name('reference-manifest.json')
manifest=json.loads(manifest_path.read_text())

def restore(item):
    target=DEST/item['path']
    if not target.resolve().is_relative_to(DEST.resolve()):raise ValueError('Unsafe manifest path')
    data=target.read_bytes() if target.exists() else urllib.request.urlopen(item['url'],timeout=180).read()
    if hashlib.sha256(data).hexdigest()!=item['sha256']:raise ValueError('SHA-256 mismatch: '+item['path'])
    if not target.exists():
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(data)
    return len(data)

with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
    sizes=list(executor.map(restore,manifest))
# The authoring source uses this small selection from the untouched CC0 archive.
selected=('skins/young_caucasian_male/','hair/short01/','eyes/high-poly/','eyes/materials/','clothes/male_casualsuit04/')
with zipfile.ZipFile(DEST/'makehuman_system_assets_cc0.zip') as archive:
    for name in archive.namelist():
        if name.endswith('/') or not name.startswith(selected):continue
        target=DEST/'makehuman-system'/name
        if not target.resolve().is_relative_to((DEST/'makehuman-system').resolve()):raise ValueError('Unsafe archive member')
        data=archive.read(name)
        if target.exists():
            if target.read_bytes()!=data:raise ValueError('Existing extracted asset differs: '+name)
        else:
            target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
print('Verified',len(sizes),'licensed input files;',sum(sizes),'bytes. Existing files preserved.')
