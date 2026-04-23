#!/usr/bin/env python3
"""Build PingFang subsets safely for Wasteland Survivor.

Key guarantees:
1) Always include baseline ASCII + common whitespace/symbols.
2) Collect chars from all gameplay/UI text sources (not only a few files).
3) Prefer FULL fonts as source (never rely on already-subset font if avoidable).
4) Validate required glyphs after subsetting.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
FONT_DIR = PROJECT_ROOT / "assets" / "fonts"
SUBSET_TEXT_FILE = FONT_DIR / "subset_chars.txt"

# Scan major text-bearing files in project.
TEXT_GLOBS = [
    "src/**/*.gd",
    "src/**/*.tscn",
    "assets/**/*.json",
    "assets/**/*.tscn",
    "project.godot",
    "README.md",
]

# Must-have baseline chars (prevents the classic "space becomes tofu" bug).
BASELINE_ASCII = "".join(chr(i) for i in range(0x20, 0x7F))  # includes U+0020 space
BASELINE_EXTRA = "".join(
    [
        "\u00A0",  # NBSP
        "\u3000",  # Ideographic space
        "\u2022",  # bullet
        "\u2026",  # ellipsis
        "\u2014",  # em dash
        "\u2013",  # en dash
        "\u00B7",  # middle dot
        "\u2192",  # arrow
        "\u25CF",  # black circle
    ]
)

# Minimal post-build validation set.
REQUIRED_CODEPOINTS = [
    0x20,   # space
    0x2F,   # /
    0x41,   # A
    0x61,   # a
    0x00A0, # nbsp
    0x3000, # ideographic space
]


def iter_text_files() -> list[Path]:
    files: list[Path] = []
    for pattern in TEXT_GLOBS:
        matches = list(PROJECT_ROOT.glob(pattern))
        files.extend(p for p in matches if p.is_file())
    return sorted(set(files))


def collect_chars() -> set[str]:
    chars: set[str] = set(BASELINE_ASCII)
    chars.update(BASELINE_EXTRA)

    for path in iter_text_files():
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue

        for ch in text:
            code = ord(ch)
            if ch in "\n\r\t":
                continue
            if code >= 0x20:  # visible-ish chars
                chars.add(ch)

    return chars


def pick_source_font(style: str, target_font: Path) -> Path:
    """Pick a source font for subsetting.

    Priority:
    1) explicit env override (WS_FONT_SOURCE_<STYLE>)
    2) project local full font backup (assets/fonts/full/*.ttf)
    3) /tmp full font copy (current local workflow)
    4) target font itself (last resort, may lose future glyph growth)
    """
    env_key = f"WS_FONT_SOURCE_{style.upper()}"
    candidates = []

    env_path = os.getenv(env_key)
    if env_path:
        candidates.append(Path(env_path).expanduser())

    candidates.extend(
        [
            FONT_DIR / "full" / f"PingFangSC-{style}-full.ttf",
            Path("/tmp") / f"PingFangSC-{style}-full.ttf",
            target_font,
        ]
    )

    for c in candidates:
        if c.exists():
            return c

    raise FileNotFoundError(f"No source font found for {style}. Checked: {candidates}")


def run_subset(style: str, chars_file: Path) -> None:
    target = FONT_DIR / f"PingFangSC-{style}.ttf"
    if not target.exists():
        print(f"[skip] missing target font: {target}")
        return

    source = pick_source_font(style, target)
    if source.resolve() == target.resolve():
        print(
            f"[warn] {style}: using current subset font as source ({source}). "
            "Future unseen glyphs may be missing. Prefer a full-font source."
        )

    out_tmp = FONT_DIR / f"PingFangSC-{style}.subset.tmp.ttf"

    cmd = [
        sys.executable,
        "-m",
        "fontTools.subset",
        str(source),
        f"--text-file={chars_file}",
        f"--output-file={out_tmp}",
        "--layout-features=*",
        "--no-hinting",
        "--desubroutinize",
    ]

    print(f"[subset] {style}: source={source}")
    subprocess.run(cmd, check=True)

    before_kb = target.stat().st_size / 1024
    after_kb = out_tmp.stat().st_size / 1024

    shutil.move(str(out_tmp), str(target))
    print(f"[done]   {style}: {before_kb:.0f}KB -> {after_kb:.0f}KB")


def validate_required_glyphs() -> None:
    try:
        from fontTools.ttLib import TTFont  # type: ignore
    except Exception:
        print("[warn] fontTools.ttLib unavailable; skip glyph validation")
        return

    failed = False
    for style in ("Regular", "Semibold"):
        font_path = FONT_DIR / f"PingFangSC-{style}.ttf"
        if not font_path.exists():
            continue
        cmap = TTFont(font_path).getBestCmap() or {}
        missing = [cp for cp in REQUIRED_CODEPOINTS if cp not in cmap]
        if missing:
            failed = True
            missing_desc = ", ".join(f"U+{cp:04X}" for cp in missing)
            print(f"[error] {font_path.name} missing required glyphs: {missing_desc}")
        else:
            print(f"[check] {font_path.name} required glyphs OK")

    if failed:
        raise SystemExit(2)


def main() -> None:
    FONT_DIR.mkdir(parents=True, exist_ok=True)

    chars = collect_chars()
    SUBSET_TEXT_FILE.write_text("".join(sorted(chars)), encoding="utf-8")
    print(f"[info] collected {len(chars)} chars -> {SUBSET_TEXT_FILE}")

    for style in ("Regular", "Semibold"):
        run_subset(style, SUBSET_TEXT_FILE)

    validate_required_glyphs()
    print("\nAll done.")


if __name__ == "__main__":
    main()
