#!/usr/bin/env python3
"""Compile the pinned source and assemble a signed local macOS bundle."""
from datetime import datetime, timezone
import hashlib
import json
import os
import shutil
import subprocess
import sys

from oot import ROOT, SOURCE, UPSTREAM_COMMIT


def main():
    head = subprocess.check_output(["git", "-C", str(SOURCE), "rev-parse", "HEAD"], text=True).strip()
    if head != UPSTREAM_COMMIT:
        raise SystemExit("Source version differs from the pinned release; review it before building.")
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    logs = ROOT / "production/logs" / ("build-" + stamp)
    logs.mkdir(parents=True)
    build = ROOT / "builds/source"
    staged = ROOT / "builds/staging" / stamp / "soh.app"
    commands = [
        ("configure", ["cmake", "-S", str(SOURCE), "-B", str(build), "-G", "Ninja",
                       "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                       "-DCMAKE_PROJECT_Ship_INCLUDE=" + str(ROOT / "tools/macos-runtime.cmake")]),
        ("compile", ["cmake", "--build", str(build), "--parallel", str(min(8, os.cpu_count() or 2))]),
        ("port-assets", ["cmake", "--build", str(build), "--target", "GenerateSohOtr"]),
    ]
    for name, command in commands:
        print(name + ": " + str(logs / (name + ".log")), flush=True)
        with (logs / (name + ".log")).open("w") as log:
            log.write(json.dumps(command) + "\n")
            log.flush()
            subprocess.run(command, cwd=ROOT,
                           stdout=log, stderr=subprocess.STDOUT, check=True)
    resources = staged / "Contents/Resources"
    resources.mkdir(parents=True)
    shutil.copy2(build / "macosx/Info.plist", staged / "Contents/Info.plist")
    shutil.copy2(build / "macosx/soh.icns", resources / "soh.icns")
    with (logs / "package.log").open("w") as log:
        subprocess.run(["cmake", "--install", str(build), "--prefix", str(resources)],
                       cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, check=True)
        subprocess.run(["codesign", "--force", "--deep", "--sign", "-", str(staged)],
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    if not (staged / "Contents/MacOS/soh").is_file():
        raise SystemExit("CMake did not produce the expected bundle: " + str(staged))
    with (logs / "startup.log").open("w") as log:
        subprocess.run([sys.executable, str(ROOT / "tools/smoke_native.py"), "--app", str(staged)],
                       cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, check=True)
    app = ROOT / "builds/local/soh.app"
    subprocess.run(["ditto", str(staged), str(app)], check=True)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    digest = hashlib.sha256()
    with (app / "Contents/MacOS/soh").open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    report = {"at_utc": stamp, "source_commit": head, "app": str(app.relative_to(ROOT)),
              "binary_sha256": digest.hexdigest(), "logs": str(logs.relative_to(ROOT)),
              "codesign_verified": True, "engine_window_verified": True, "gameplay_verified": False}
    (ROOT / "evidence" / ("build-" + stamp + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
