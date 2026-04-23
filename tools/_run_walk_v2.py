#!/usr/bin/env python3
"""
Wrapper: set token then exec the actual walk generator.
Usage: python3 tools/_run_walk_v2.py
"""
import os
import sys
import runpy
from pathlib import Path

os.environ.setdefault("PIXELLAB_TOKEN", "d5e04aca-3ce0-4357-9257-e33efb6889c2")
os.chdir(Path(__file__).resolve().parents[1])
runpy.run_path(str(Path(__file__).parent / "pixellab_walk_v2.py"), run_name="__main__")
