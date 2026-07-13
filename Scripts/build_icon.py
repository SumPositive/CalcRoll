#!/usr/bin/env python3
"""
Calclin アプリアイコン ビルドスクリプト

AppIcon-source.svg (完全ベクトル・自己完結) から成果物を書き出す:
  - AppIcon-base-1024.png … 1024px プレビュー/確認用
  - AppIcon.pdf           … ベクトルマスター(影のぼかしのみ画像埋め込み)
  - AppIcon.appiconset/AppIcon-1024.png … 実機用(単一サイズ・Xcodeが各サイズ自動生成)

側面キーパッドについて:
  五角柱の左右側面には、正面 3x3 キーパッドを「透視(台形)」で貼っている。
  以前は SVG の transform では台形にできず PNG 合成していたが、現在は
  各キーの4隅をホモグラフィ計算して <path> の台形(角丸なし)として SVG に直接
  埋め込み済み。よって SVG は自己完結で、rsvg-convert 単体で完成する。
  ※ 側面キーの座標は Scripts/gen_side_keypad.py で再生成できる(色や配置を変えた時用)。

Xcode の App Icon は PDF ベクトルをサポートしないため、実機は 1024 単一 PNG。

依存: rsvg-convert (Homebrew: librsvg)
実行: python3 Scripts/build_icon.py
"""
import os
import shutil
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "AppIcon-source.svg")
PNG = os.path.join(HERE, "AppIcon-base-1024.png")
PDF = os.path.join(HERE, "AppIcon.pdf")
APPICON = os.path.normpath(os.path.join(
    HERE, "..", "Calclin", "Resources", "Assets.xcassets",
    "AppIcon.appiconset", "AppIcon-1024.png"))
SIZE = 1024


def main():
    subprocess.run(
        ["rsvg-convert", "-w", str(SIZE), "-h", str(SIZE), SRC, "-o", PNG],
        check=True)
    print("wrote", PNG)

    subprocess.run(["rsvg-convert", "-f", "pdf", SRC, "-o", PDF], check=True)
    print("wrote", PDF)

    if os.path.isdir(os.path.dirname(APPICON)):
        shutil.copyfile(PNG, APPICON)
        print("wrote", APPICON)
    else:
        print("appiconset not found, skipped:", APPICON)


if __name__ == "__main__":
    main()
