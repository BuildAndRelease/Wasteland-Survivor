#!/usr/bin/env python3
"""Subset PingFang SC to only include characters used in the game."""

import subprocess
import sys
import os

FONT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'fonts')
SRC_DIR = os.path.join(os.path.dirname(__file__), '..', 'src')

# Collect all Chinese characters from the codebase
chars = set()

# From locale.gd
locale_path = os.path.join(SRC_DIR, 'core', 'locale.gd')
with open(locale_path, 'r', encoding='utf-8') as f:
    for line in f:
        for ch in line:
            if ord(ch) > 127:
                chars.add(ch)

# From enemy_data.gd, skill_data.gd, camp_data.gd (name_cn fields)
for fname in ['core/enemy_data.gd', 'core/skill_data.gd', 'core/camp_data.gd']:
    fpath = os.path.join(SRC_DIR, fname)
    if os.path.exists(fpath):
        with open(fpath, 'r', encoding='utf-8') as f:
            for line in f:
                for ch in line:
                    if ord(ch) > 127:
                        chars.add(ch)

# Also add common punctuation and numbers
basic = set('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,;:!?/-+=%()[]{}\'\"@#$&*~<>_|\\^`')
# Add common Chinese punctuation
cn_punct = set('，。！？、：；""''（）【】《》—…·')
chars |= basic | cn_punct

# Write character list
char_list = ''.join(sorted(chars))
text_file = os.path.join(FONT_DIR, 'subset_chars.txt')
with open(text_file, 'w', encoding='utf-8') as f:
    f.write(char_list)

print(f"Collected {len(chars)} unique characters")

# Run pyftsubset
for font_name in ['PingFangSC-Regular.ttf', 'PingFangSC-Semibold.ttf']:
    src = os.path.join(FONT_DIR, font_name)
    dst = os.path.join(FONT_DIR, font_name.replace('.ttf', '-subset.ttf'))
    if not os.path.exists(src):
        print(f"  Skip {font_name} (not found)")
        continue
    
    cmd = [
        sys.executable, '-m', 'fontTools.subset',
        src,
        f'--text-file={text_file}',
        f'--output-file={dst}',
        '--layout-features=*',
        '--flavor=',
        '--no-hinting',
        '--desubroutinize',
    ]
    print(f"  Subsetting {font_name}...")
    subprocess.run(cmd, check=True)
    
    orig_size = os.path.getsize(src) / 1024
    new_size = os.path.getsize(dst) / 1024
    print(f"  {font_name}: {orig_size:.0f}KB -> {new_size:.0f}KB")

    # Remove full font, rename subset
    os.remove(src)
    os.rename(dst, src)
    print(f"  Replaced with subset")

print("\nDone!")
