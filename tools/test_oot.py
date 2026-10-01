import hashlib
import fcntl
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

import oot


class RomChecks(unittest.TestCase):
    def setUp(self):
        # Synthetic bytes only; no game data is used in these tests.
        self.big = bytes.fromhex("80371240") + bytes(range(60))

    def test_all_byte_orders_have_the_same_canonical_content(self):
        swapped = bytearray(len(self.big))
        swapped[0::2], swapped[1::2] = self.big[1::2], self.big[0::2]
        little = b"".join(self.big[i:i + 4][::-1] for i in range(0, len(self.big), 4))
        for data, order in ((self.big, "z64"), (swapped, "v64"), (little, "n64")):
            with self.subTest(order=order):
                self.assertEqual(oot.normalize_rom(data), (self.big, order))

    def test_malformed_inputs_are_rejected(self):
        for data in (b"", self.big[:16], self.big[:-1], b"NOT-ROM!" * 8):
            with self.subTest(size=len(data)):
                with self.assertRaises(ValueError):
                    oot.normalize_rom(data)

    def test_unknown_content_is_rejected_even_with_valid_header_and_filename(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "Ocarina of Time.z64"
            path.write_bytes(self.big)
            before = hashlib.sha256(path.read_bytes()).hexdigest()
            self.assertFalse(oot.verify_rom(path)["supported"])
            with self.assertRaises(ValueError):
                oot.launch_command(path, official=True)
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), before)

    def test_spaces_and_shell_metacharacters_stay_in_one_argument(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "my game $(do-not-execute).z64"
            path.write_bytes(self.big)
            with patch.object(oot, "verify_rom", return_value={"supported": True, "path": str(path)}):
                command = oot.launch_command(path, official=True)
            self.assertEqual(command[1:], [str(path)])

    def test_two_launches_cannot_write_the_same_runtime(self):
        with tempfile.TemporaryDirectory() as temp:
            runtime = Path(temp)
            with (runtime / ".launcher.lock").open("a") as active:
                fcntl.flock(active, fcntl.LOCK_EX | fcntl.LOCK_NB)
                with self.assertRaisesRegex(ValueError, "起動中"):
                    oot.run_game([sys.executable, "-c", "raise SystemExit(0)"], runtime)

    def test_child_uses_local_runtime_and_failure_allows_relaunch(self):
        with tempfile.TemporaryDirectory() as temp:
            runtime = Path(temp)
            command = [sys.executable, "-c",
                       "import os,sys; assert os.environ['SHIP_HOME'] == sys.argv[1]; raise SystemExit(7)", temp]
            self.assertEqual(oot.run_game(command, runtime), 7)
            self.assertEqual(oot.run_game([sys.executable, "-c", "raise SystemExit(0)"], runtime), 0)


if __name__ == "__main__":
    unittest.main()
