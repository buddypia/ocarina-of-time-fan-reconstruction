#!/usr/bin/env python3
"""Local entry point for the pinned Ocarina of Time native port."""

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "vendor/Shipwright"
RUNTIME = ROOT / "runtime"
UPSTREAM_COMMIT = "cb71e22a79bc5d1f688fa881795bbd93094895fc"


def normalize_rom(data: bytes) -> tuple[bytes, str]:
    """Convert the three standard N64 dump byte orders to big endian."""
    if len(data) < 64 or len(data) % 4:
        raise ValueError("N64 ROMのサイズが不正です（64 bytes以上、4の倍数が必要）。")
    magic = data[:4]
    if magic == bytes.fromhex("80371240"):
        return data, "z64"
    normalized = bytearray(len(data))
    if magic == bytes.fromhex("37804012"):
        normalized[0::2], normalized[1::2] = data[1::2], data[0::2]
        return bytes(normalized), "v64"
    if magic == bytes.fromhex("40123780"):
        for i in range(4):
            normalized[i::4] = data[3 - i::4]
        return bytes(normalized), "n64"
    raise ValueError("N64 ROMのヘッダーを確認できません。.z64 / .n64 / .v64 を指定してください。")


def verify_rom(path: Path) -> dict:
    path = path.expanduser().resolve(strict=True)
    if not path.is_file() or path.stat().st_size > 64 * 1024 * 1024:
        raise ValueError("64 MiB以下のROMファイルを指定してください。")
    data, byte_order = normalize_rom(path.read_bytes())
    digest = hashlib.sha1(data).hexdigest()
    supported = json.loads((SOURCE / "docs/supportedHashes.json").read_text())
    match = next((item for item in supported if item["sha1"] == digest), None)
    return {
        "path": str(path), "bytes": len(data), "byte_order": byte_order,
        "canonical_sha1": digest, "supported": match is not None,
        "version": match["name"] if match else None,
        "port_release": "9.2.3",
    }


def app_path(official=False):
    local = ROOT / "builds/local/soh.app"
    return ROOT / "builds/official/soh.app" if official or not (local / "Contents/MacOS/soh").is_file() else local


def launch_command(rom=None, official=False):
    binary = app_path(official) / "Contents/MacOS/soh"
    if not binary.is_file():
        raise ValueError("実行ファイルがありません。READMEのbuild手順を確認してください。")
    command = [str(binary)]
    if rom is not None:
        report = verify_rom(rom)
        if not report["supported"]:
            raise ValueError("このreleaseが対応するROMではありません。SHA-1: " + report["canonical_sha1"])
        command.append(report["path"])
    return command


def status():
    head = subprocess.check_output(
        ["git", "-C", str(SOURCE), "rev-parse", "HEAD"], text=True).strip()
    archives = [str(p.relative_to(ROOT)) for p in RUNTIME.glob("oot*.o2r")]
    return {
        "source_commit": head, "expected_source_commit": UPSTREAM_COMMIT,
        "source_pin_matches": head == UPSTREAM_COMMIT,
        "selected_app": str(app_path().relative_to(ROOT)),
        "binary_present": (app_path() / "Contents/MacOS/soh").is_file(),
        "game_archive_files": archives,
        "game_archive_validated": False,
        "gameplay_verified": False,
        "full_game_completion_verified": False,
        "next_step": "ゲームデータを読み込み、実プレイと全編の検証を行う。",
    }


def run_game(command, runtime=RUNTIME):
    runtime.mkdir(exist_ok=True)
    with (runtime / ".launcher.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError("このセーブフォルダーのゲームは起動中です。開いているゲームを使用してください。") from None
        # The child inherits the lock so an interrupted launcher cannot permit a
        # second game process to write these saves while the first is still alive.
        return subprocess.call(command, cwd=runtime, env=dict(os.environ, SHIP_HOME=str(runtime)),
                               pass_fds=(lock.fileno(),))


def main():
    parser = argparse.ArgumentParser(description="時のオカリナ / Ship of Harkinian 9.2.3")
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("status")
    check = sub.add_parser("verify-rom", help="ROMを変更せずに対応状況を調べる")
    check.add_argument("rom", type=Path)
    play = sub.add_parser("play", help="起動。ROM未指定ならアプリの選択画面を使う")
    play.add_argument("rom", type=Path, nargs="?")
    play.add_argument("--official", action="store_true", help="公式配布版を明示的に使う")
    args = parser.parse_args()
    try:
        if args.action == "status":
            print(json.dumps(status(), ensure_ascii=False, indent=2))
            return 0
        if args.action == "verify-rom":
            report = verify_rom(args.rom)
            print(json.dumps(report, ensure_ascii=False, indent=2))
            return 0 if report["supported"] else 2
        command = launch_command(args.rom, args.official)
        # Launch the executable directly: Launch Services would apply the bundle's
        # default LSEnvironment and redirect saves outside this deliverable.
        return run_game(command)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
