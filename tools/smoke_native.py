#!/usr/bin/env python3
"""Observe a newly launched setup window; this does not test gameplay."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from oot import ROOT, launch_command

parser = argparse.ArgumentParser()
selection = parser.add_mutually_exclusive_group()
selection.add_argument("--official", action="store_true")
selection.add_argument("--app", type=Path, help="検証する保存済みMac bundle")
parser.add_argument("--seconds", type=int, default=6, help="描画を観察する秒数（6–120）")
parser.add_argument("--exercise-window", action="store_true", help="自分のテストウィンドウをresize・最小化・復帰する")
args = parser.parse_args()
if not 6 <= args.seconds <= 120:
    parser.error("--seconds must be between 6 and 120")
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
evidence = ROOT / "evidence" / ("native-" + stamp)
evidence.mkdir(parents=True)
test_runtime = evidence / "runtime"
test_runtime.mkdir()
helper = ROOT / "production/window-info"
subprocess.run(["swiftc", str(ROOT / "tools/window-info.swift"), "-o", str(helper)], check=True)
if args.exercise_window:
    subprocess.run(["swiftc", str(ROOT / "tools/exercise-window.swift"), "-o",
                    str(ROOT / "production/exercise-window")], check=True)
command = ([str(args.app.resolve() / "Contents/MacOS/soh")] if args.app
           else launch_command(official=args.official))
binary = Path(command[0])
digest = hashlib.sha256()
with binary.open("rb") as stream:
    for chunk in iter(lambda: stream.read(1024 * 1024), b""):
        digest.update(chunk)
report = {"at_utc": stamp, "command": command, "ship_home": str(test_runtime),
          "binary_sha256": digest.hexdigest(),
          "requested_observation_seconds": args.seconds,
          "gameplay_tested": False, "engine_window_detected": False, "windows": [], "screenshot": None}
with (evidence / "stdout.log").open("w") as output:
    process = subprocess.Popen(command, cwd=test_runtime,
                               env=dict(os.environ, SHIP_HOME=str(test_runtime)),
                               stdout=output, stderr=subprocess.STDOUT)
    report["pid"] = process.pid
    started = time.monotonic()
    try:
        for attempt in range(args.seconds + 9):
            time.sleep(1)
            if process.poll() is not None:
                break
            windows = json.loads(subprocess.check_output([str(helper), str(process.pid)], text=True))
            if args.exercise_window and windows and attempt == 5:
                exercised = subprocess.run([str(ROOT / "production/exercise-window"), str(process.pid)],
                                           capture_output=True, text=True, timeout=15)
                report["window_exercise"] = {"returncode": exercised.returncode,
                                             "stdout": exercised.stdout, "stderr": exercised.stderr}
            if windows and attempt >= args.seconds - 1:
                report["windows"] = windows
                engine_windows = [window for window in windows if
                                  window.get("kCGWindowName", "").startswith("Ship of Harkinian (")]
                report["engine_window_detected"] = bool(engine_windows)
                window_id = str((engine_windows or windows)[0]["kCGWindowNumber"])
                capture = subprocess.run(["/usr/sbin/screencapture", "-x", "-l", window_id,
                                          str(evidence / "window.png")], capture_output=True, text=True)
                report["screenshot_returncode"] = capture.returncode
                report["screenshot_error"] = capture.stderr
                if capture.returncode == 0:
                    report["screenshot"] = str((evidence / "window.png").relative_to(ROOT))
                break
        report["alive_before_cleanup"] = process.poll() is None
        report["observed_seconds"] = round(time.monotonic() - started, 2)
    finally:
        # Only this child belongs to this smoke test. Never signal other apps.
        if process.poll() is None:
            process.terminate()
        try:
            report["returncode"] = process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            report["cleanup"] = "Child did not exit after SIGTERM; left running, PID recorded."
        (evidence / "report.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
exercise_ok = not args.exercise_window or report.get("window_exercise", {}).get("returncode") == 0
sys.exit(0 if report.get("engine_window_detected") and report.get("alive_before_cleanup") and report.get("screenshot") and
         report.get("returncode") in (0, -15) and exercise_ok else 1)
