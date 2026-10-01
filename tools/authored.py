#!/usr/bin/env python3
"""Run, verify, or package the independently authored world."""
import argparse
import fcntl
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[1]
GAME=ROOT/'game'
APP=ROOT/'builds/authored-0.5/Ocarina of Time.app'

def engine():
    value=shutil.which('godot')
    if not value:
        value='/Applications/Godot.app/Contents/MacOS/Godot'
    if not Path(value).is_file():
        raise SystemExit('Godot 4.7 is required to build or run the source.')
    return value

def command(packaged=False):
    if packaged:
        return [str(APP/'Contents/MacOS/Ocarina')]
    return [engine(),'--path',str(GAME)]

def verify(packaged=False, capture_only=False, dungeon=False, fixture=False, combat=False, world=False, mountain=False, bomb_test=False, zora=False, metal=False, character=False, jabu=False, time_quest=False, graveyard=False, forest_temple=False, fire_mountain=False, headless=False):
    stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    out=ROOT/'evidence'/('authored-'+stamp)
    out.mkdir(parents=True)
    env=dict(os.environ,OOT_EVIDENCE_DIRECTORY=str(out))
    identity={str(path.relative_to(ROOT)):hashlib.sha256(path.read_bytes()).hexdigest()
              for path in GAME.rglob('*') if path.is_file() and '.godot' not in path.parts}
    fixture_inputs={}
    if env.get('OOT_FIRE_STAGE'): fixture_inputs['fire_stage']=env['OOT_FIRE_STAGE']
    if env.get('OOT_FIRE_SAVE'):
        fixture_path=Path(env['OOT_FIRE_SAVE'])
        fixture_inputs['fire_save']={'path':str(fixture_path),'sha256':hashlib.sha256(fixture_path.read_bytes()).hexdigest()}
    if env.get('OOT_FOREST_STAGE'): fixture_inputs['forest_stage']=env['OOT_FOREST_STAGE']
    if env.get('OOT_FOREST_SAVE'):
        fixture_path=Path(env['OOT_FOREST_SAVE'])
        fixture_inputs['forest_save']={'path':str(fixture_path),'sha256':hashlib.sha256(fixture_path.read_bytes()).hexdigest()}
    args=command(packaged)+['--log-file',str(out/'engine.log')]+(['--headless'] if headless else [])+(['--rendering-method','forward_plus','--rendering-driver','metal'] if metal else [])+(['--script','res://tests/character_inspection.gd'] if character else ['--','--verify'])
    if capture_only: args.append('--capture-only')
    if dungeon: args.append('--dungeon')
    if fixture: args.append('--fixture')
    if combat: args.append('--combat')
    if world: args.append('--world')
    if mountain: args.append('--mountain')
    if bomb_test: args.append('--bomb-test')
    if zora: args.append('--zora')
    if jabu: args.append('--jabu')
    if time_quest: args.append('--time-quest')
    if graveyard: args.append('--graveyard')
    if forest_temple: args.append('--forest-temple')
    if fire_mountain: args.append('--fire-mountain')
    print(str(out),flush=True)
    with (out/'stdout.log').open('w') as log:
        process=subprocess.Popen(args,env=env,stdout=log,stderr=subprocess.STDOUT)
        try:
            code=process.wait(timeout=1800 if jabu and not fixture else 1200)
        except subprocess.TimeoutExpired:
            process.terminate()
            process.wait(timeout=10)
            code=124
        except KeyboardInterrupt:
            process.terminate()
            process.wait(timeout=10)
            code=130
    engine_code=code
    log_lines=(out/'stdout.log').read_text(errors='replace').splitlines()
    log_errors=list(dict.fromkeys(line for line in log_lines if line.startswith(('ERROR:', 'SCRIPT ERROR:'))))
    log_warnings=list(dict.fromkeys(line for line in log_lines if line.startswith('WARNING:')))
    report_path=out/'report.json'
    completed_report=json.loads(report_path.read_text()) if report_path.is_file() else {}
    if not completed_report.get('passed',False):
        log_errors.append('Verification did not produce a completed, passing report.json')
    after={str(path.relative_to(ROOT)):hashlib.sha256(path.read_bytes()).hexdigest()
           for path in GAME.rglob('*') if path.is_file() and '.godot' not in path.parts}
    changed=sorted(name for name in identity.keys() | after.keys() if identity.get(name)!=after.get(name))
    if code==0 and (log_errors or changed): code=1
    pck=APP/'Contents/Resources/world.pck'
    report={'at_utc':stamp,'command':args,'returncode':code,'engine_returncode':engine_code,'log_errors':log_errors,'log_warnings':log_warnings,'source_files':identity,'source_changed_during_run':changed,'fixture_inputs':fixture_inputs}
    if packaged: report['pck_sha256']=hashlib.sha256(pck.read_bytes()).hexdigest()
    (out/'identity.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Headless verification exit' if headless else 'Native verification exit',code,flush=True)
    return code

def build():
    source_identity={str(path.relative_to(ROOT)):hashlib.sha256(path.read_bytes()).hexdigest()
                     for path in GAME.rglob('*') if path.is_file() and '.godot' not in path.parts}
    target=APP/'Contents'
    (target/'MacOS').mkdir(parents=True,exist_ok=True)
    (target/'Resources').mkdir(exist_ok=True)
    subprocess.run([engine(),'--headless','--path',str(GAME),'--export-pack','macOS',str(target/'Resources/world.pck')],check=True)
    shutil.copy2(Path(engine()).resolve(),target/'MacOS/Godot')
    shutil.copy2(ROOT/'production/authored/GODOT-LICENSE.txt',target/'Resources/GODOT-LICENSE.txt')
    shutil.copy2(ROOT/'production/authored/THIRD_PARTY_ASSETS.md',target/'Resources/THIRD_PARTY_ASSETS.md')
    launcher=target/'MacOS/Ocarina'
    launcher.write_text('''#!/bin/zsh
set -eu
app_contents="${0:A:h:h}"
project_root="${app_contents:h:h:h:h}"
if [[ -f "$project_root/tools/authored.py" ]]; then
  save_directory="$project_root/runtime"
else
  save_directory="${app_contents:h:h}/Ocarina Saves"
fi
mkdir -p -- "$save_directory"
export OOT_SAVE_PATH="${OOT_SAVE_PATH:-$save_directory/authored-save.json}"
exec "$app_contents/MacOS/Godot" --main-pack "$app_contents/Resources/world.pck" --log-file "$save_directory/godot.log" "$@"
''')
    launcher.chmod(0o755)
    info={'CFBundleName':'Ocarina of Time','CFBundleDisplayName':'Ocarina of Time — Authored World',
          'CFBundleIdentifier':'local.astra.ocarina.authored','CFBundleExecutable':'Ocarina',
          'CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.5','CFBundleVersion':'5',
          'NSHighResolutionCapable':True}
    (target/'Info.plist').write_bytes(plistlib.dumps(info))
    identity={'version':'0.5','built_at_utc':datetime.now(timezone.utc).isoformat(),
              'source_files':source_identity,
              'pck_sha256':hashlib.sha256((target/'Resources/world.pck').read_bytes()).hexdigest()}
    (target/'Resources/BUILD_IDENTITY.json').write_text(json.dumps(identity,indent=2)+'\n')
    subprocess.run(['codesign','--force','--deep','--sign','-',str(APP)],check=True)
    subprocess.run(['codesign','--verify','--deep','--strict',str(APP)],check=True)
    print(APP)
    return 0

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('action',choices=['play','verify','build','assets','import'])
    parser.add_argument('--packaged',action='store_true')
    parser.add_argument('--headless',action='store_true',help='Verify gameplay without a window; does not validate rendering or native performance')
    parser.add_argument('--capture-only',action='store_true')
    parser.add_argument('--dungeon',action='store_true')
    parser.add_argument('--combat',action='store_true')
    parser.add_argument('--character',action='store_true',help='Run the input-driven skeletal motion and equipment inspection fixture')
    parser.add_argument('--world',action='store_true')
    parser.add_argument('--mountain',action='store_true')
    parser.add_argument('--bomb-test',action='store_true')
    parser.add_argument('--zora',action='store_true')
    parser.add_argument('--jabu',action='store_true')
    parser.add_argument('--time-quest',action='store_true',help='Test the castle-to-adult story using an explicit post-Sapphire fixture')
    parser.add_argument('--fire-mountain',action='store_true',help='Adult Goron City, crater and first Fire Temple cells')
    parser.add_argument('--forest-temple',action='store_true',help='Post-Hookshot fixture through the Forest Temple')
    parser.add_argument('--graveyard',action='store_true',help='Adult awakening fixture through Dampe, Hookshot and windmill')
    parser.add_argument('--metal',action='store_true',help='Verify the Forward+ renderer using the native Metal driver')
    parser.add_argument('--fixture',action='store_true',help='Start dungeon verification with explicitly recorded test equipment')
    args=parser.parse_args()
    if args.action=='verify': return verify(args.packaged,args.capture_only,args.dungeon,args.fixture,args.combat,args.world,args.mountain,args.bomb_test,args.zora,args.metal,args.character,args.jabu,args.time_quest,args.graveyard,args.forest_temple,args.fire_mountain,args.headless)
    if args.action=='build': return build()
    if args.action=='import': return subprocess.call([engine(),'--headless','--editor','--path',str(GAME),'--import'])
    if args.action=='assets':
        stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        archive=ROOT/'builds'/('authored-data-'+stamp+'.zip')
        files=[]
        for folder in [GAME,ROOT/'production/authored']:
            files.extend(path for path in folder.rglob('*') if path.is_file()
                         and not {'.godot','__pycache__'}.intersection(path.parts)
                         and path.suffix not in ('.import','.blend1','.pyc'))
        files.extend(ROOT/name for name in ['tools/authored.py','Play Source Preview.command','README.md','AGENTS.md','docs/PROGRESS.md','production/reference-assets/makehuman-license.md'])
        manifest={str(path.relative_to(ROOT)):hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(set(files))}
        readme="""# Authored Ocarina of Time — source preview

This is an unfinished reconstruction, not an original ROM or Shipwright archive.
The archive includes the game project, editable authoring sources, ten player motions,
independently authored equipment, licensed runtime inputs and their provenance.
The source connects the forest, mountain and water regions to an authored Jabu-Jabu
route with Ruto carrying, the boomerang, two bosses and the Zora Sapphire.
It continues through the castle escape, the Ocarina of Time, the Temple of Time,
the Master Sword and the adult awakening with the Light Medallion. The ruined Market,
Kakariko refugees, graveyard, Dampe race, Hookshot, windmill, Hylian Shield,
Sun's Song and Song of Storms are also authored. The Lost Woods and Forest Temple
add the Fairy Bow, four Poe sisters, Phantom Ganon and Saria's Forest Medallion.
The sprout's story, Prelude of Light and earned time-travel unlock follow.
The next segment adds adult Goron City, the Goron Tunic, Death Mountain Crater,
Bolero of Fire and the first three Fire Temple cells (five areas). Upper floors,
the Hammer, Volvagia, other adult temples, remaining regions and endgame are outstanding.
Room layout, creature models and character motion still need substantial work.
Full-game implementation and near-photorealistic quality are incomplete.

Use Godot 4.7.2. From this extracted folder:

    python3 tools/authored.py import
    python3 tools/authored.py play

For the post-water Jabu test fixture (with assisted combat target selection):

    python3 tools/authored.py verify --jabu --fixture

For the new story segment, with explicitly prepared post-Sapphire inventory:

    python3 tools/authored.py verify --time-quest --fixture

For the graveyard route, with explicitly prepared adult awakening inventory:

    python3 tools/authored.py verify --graveyard --fixture

For the Forest Temple route, with explicitly prepared post-Hookshot inventory:

    python3 tools/authored.py verify --forest-temple

For the first Fire Temple cells, with prepared adult gear:

    python3 tools/authored.py verify --fire-mountain

On macOS, Play Source Preview.command imports a fresh project and starts the source.
This archive contains neither the older packaged app nor existing saves.
Save data is created in runtime/authored-save.json; test saves are isolated in evidence/.

To recreate the anatomical model, first run the documented CC0 asset fetcher:

    python3 production/authored/fetch_reference_assets.py
    blender --background --python production/authored/make_link_anatomical.py -- --no-render
    blender --background --python production/authored/make_equipment.py
    blender --background --python production/authored/make_link_anatomical.py -- --adult --no-render
    blender --background --python production/authored/make_master_sword.py
    blender --background --python production/authored/make_hookshot.py
    blender --background --python production/authored/make_gravestone.py
    blender --background --python production/authored/make_forest_equipment.py

Copy production/authored/link-study/link-anatomical.glb to game/assets/link_anatomical.glb
and production/authored/adult-link-study/link-adult.glb to game/assets/link_adult.glb.
Run the import command again after changing models. The external fetcher checks
recorded hashes. No ROMs are fetched. See production/authored/THIRD_PARTY_ASSETS.md.

source-manifest.json identifies every included source file. The workspace progress
record is retained; historical evidence images and older apps linked there are not
bundled in this source archive. The default source renderer is OpenGL Compatibility;
--metal selects native Metal / Forward+ for a separately identified verification run.
"""
        with zipfile.ZipFile(archive,'x',zipfile.ZIP_DEFLATED) as out:
            for name in manifest: out.write(ROOT/name,name)
            out.writestr('source-manifest.json',json.dumps(manifest,indent=2)+'\n')
            out.writestr('ARCHIVE_README.md',readme)
        with zipfile.ZipFile(archive) as saved:
            if saved.testzip() is not None: raise RuntimeError('Archive CRC check failed')
            for name,digest in manifest.items():
                if hashlib.sha256(saved.read(name)).hexdigest()!=digest: raise RuntimeError('Archive source mismatch: '+name)
        print(str(archive),flush=True)
        print(f'{len(manifest)} source files; CRC and SHA-256 verified; {archive.stat().st_size:,} bytes')
        return 0
    runtime=ROOT/'runtime'
    runtime.mkdir(exist_ok=True)
    env=dict(os.environ,OOT_SAVE_PATH=str(runtime/'authored-save.json'))
    with (runtime/'.authored.lock').open('a') as lock:
        try:
            fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            print('The authored game is already using this save folder.',file=sys.stderr)
            return 2
        return subprocess.call(command(args.packaged)+['--log-file',str(runtime/'godot.log')],env=env,pass_fds=(lock.fileno(),))

if __name__=='__main__': sys.exit(main())
