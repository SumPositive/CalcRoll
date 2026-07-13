#!/usr/bin/env python3
"""
側面キーパッド(左右)のベクトル台形を再生成し、AppIcon-source.svg に埋め込む。

正面 <g id="keypad"> の各キー(rx=16 の fill 付き rect)を読み取り、
ホモグラフィで左右側面の台形へ写像した <path>(角丸なし)を作る。
正面キーの色・配置を変えたら、このスクリプトを実行して側面を同期させる。

生成物は SVG 内の下記コメント行の“間”を置き換える:
  <!-- SIDE_KEYPAD_BEGIN --> ... <!-- SIDE_KEYPAD_END -->

依存: なし(標準ライブラリのみ)
実行: python3 Scripts/gen_side_keypad.py   (その後 build_icon.py で書き出し)
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "AppIcon-source.svg")

# 正面パネル矩形(キーパッドの座標系) = ワープ元
FX0, FY0, FX1, FY1 = 235.7, 536.2, 788.3, 896.2
FRONT = [(FX0, FY0), (FX1, FY0), (FX1, FY1), (FX0, FY1)]  # TL,TR,BR,BL

# 側面台形へのインセット & 面ごとの陰(右面のみ濃いめ)
INSET_IN, INSET_OUT = 0.18, 0.005
RIGHT_SHADE = 0.20   # 右面の各キーに重ねる黒 opacity
LEFT_SHADE = 0.0     # 左面は明るく保つ

# 側面台形の四隅(内=正面と共有, 外=面の一番外)
L_IN_TOP, L_OUT_TOP = (235.7, 536.2), (95.0, 460.8)
L_IN_BOT, L_OUT_BOT = (235.7, 896.2), (95.0, 820.8)
R_IN_TOP, R_OUT_TOP = (788.3, 536.2), (929.0, 460.8)
R_IN_BOT, R_OUT_BOT = (788.3, 896.2), (929.0, 820.8)


def solve8(A, B):
    n = 8
    M = [A[i][:] + [B[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        M[c], M[p] = M[p], M[c]
        piv = M[c][c]
        for k in range(c, n + 1):
            M[c][k] /= piv
        for r in range(n):
            if r != c and M[r][c]:
                f = M[r][c]
                for k in range(c, n + 1):
                    M[r][k] -= f * M[c][k]
    return [M[i][n] for i in range(n)]


def homography(src4, dst4):
    A, B = [], []
    for (sx, sy), (dx, dy) in zip(src4, dst4):
        A.append([sx, sy, 1, 0, 0, 0, -dx * sx, -dx * sy]); B.append(dx)
        A.append([0, 0, 0, sx, sy, 1, -dy * sx, -dy * sy]); B.append(dy)
    return solve8(A, B) + [1.0]


def apply_h(h, x, y):
    X = h[0]*x + h[1]*y + h[2]
    Y = h[3]*x + h[4]*y + h[5]
    W = h[6]*x + h[7]*y + h[8]
    return X / W, Y / W


def lerp(a, b, t):
    return (a[0] + (b[0]-a[0])*t, a[1] + (b[1]-a[1])*t)


def rr(v):
    return round(v, 1)


def read_keys(svg):
    inner = re.search(r'<g id="keypad">(.*?)</g>', svg, re.S).group(1)
    keys = []
    for m in re.finditer(
        r'<rect x="([\d.]+)" y="([\d.]+)" width="([\d.]+)" height="([\d.]+)" '
        r'rx="16" fill="(#[0-9a-fA-F]+)"/>', inner):
        keys.append((float(m[1]), float(m[2]), float(m[3]), float(m[4]), m[5]))
    return keys


def emit(keys, dst, name, clip_id, shade):
    h = homography(FRONT, dst)
    out = [f'  <!-- {name}側面キーパッド(ベクトル台形・角丸なし) -->',
           f'  <g clip-path="url(#{clip_id})">']
    for (x, y, w, hh, fill) in keys:
        c = [(x, y), (x+w, y), (x+w, y+hh), (x, y+hh)]
        pts = [apply_h(h, px, py) for px, py in c]
        d = 'M ' + ' L '.join(f'{rr(px)} {rr(py)}' for px, py in pts) + ' Z'
        out.append(f'    <path d="{d}" fill="{fill}"/>')
        if shade > 0:
            out.append(f'    <path d="{d}" fill="#000000" opacity="{shade}"/>')
    out.append('  </g>')
    return '\n'.join(out)


def main():
    svg = open(SRC).read()
    keys = read_keys(svg)

    left_dst = [lerp(L_IN_TOP, L_OUT_TOP, INSET_IN),
                lerp(L_OUT_TOP, L_IN_TOP, INSET_OUT),
                lerp(L_OUT_BOT, L_IN_BOT, INSET_OUT),
                lerp(L_IN_BOT, L_OUT_BOT, INSET_IN)]
    right_dst = [lerp(R_OUT_TOP, R_IN_TOP, INSET_OUT),
                 lerp(R_IN_TOP, R_OUT_TOP, INSET_IN),
                 lerp(R_IN_BOT, R_OUT_BOT, INSET_IN),
                 lerp(R_OUT_BOT, R_IN_BOT, INSET_OUT)]

    block = ("  <!-- SIDE_KEYPAD_BEGIN (gen_side_keypad.py が生成) -->\n"
             + emit(keys, left_dst, "左", "clipLeft", LEFT_SHADE) + "\n"
             + emit(keys, right_dst, "右", "clipRight", RIGHT_SHADE) + "\n"
             + "  <!-- SIDE_KEYPAD_END -->")

    if "<!-- SIDE_KEYPAD_BEGIN" in svg:
        svg = re.sub(r'  <!-- SIDE_KEYPAD_BEGIN.*?<!-- SIDE_KEYPAD_END -->',
                     block, svg, flags=re.S)
    else:
        # 初回: 正面 keypad グループ直後に挿入
        svg = svg.replace('</g>\n', '</g>\n' + block + '\n', 1)
    open(SRC, "w").write(svg)
    print(f"side keypads regenerated ({len(keys)} keys each).")


if __name__ == "__main__":
    main()
