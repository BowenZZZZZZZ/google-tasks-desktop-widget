#!/usr/bin/env python3
import math
import os
import struct
import zlib

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ICONSET = os.path.join(ROOT, "Assets", "AppIcon.iconset")


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def write_png(path, width, height, pixels):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        start = y * width * 4
        raw.extend(pixels[start:start + width * 4])
    data = b"\x89PNG\r\n\x1a\n"
    data += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    data += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(data)


def blend(dst, src):
    sr, sg, sb, sa = src
    if sa == 255:
        return src
    dr, dg, db, da = dst
    a = sa / 255.0
    ia = 1.0 - a
    return (
        int(sr * a + dr * ia),
        int(sg * a + dg * ia),
        int(sb * a + db * ia),
        int(255 * (a + da / 255.0 * ia)),
    )


def set_pixel(pixels, width, height, x, y, color):
    if 0 <= x < width and 0 <= y < height:
        i = (y * width + x) * 4
        pixels[i:i + 4] = bytes(blend(tuple(pixels[i:i + 4]), color))


def rounded_rect(pixels, width, height, x0, y0, x1, y1, r, color):
    for y in range(max(0, y0), min(height, y1)):
        for x in range(max(0, x0), min(width, x1)):
            cx = min(max(x, x0 + r), x1 - r - 1)
            cy = min(max(y, y0 + r), y1 - r - 1)
            if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
                set_pixel(pixels, width, height, x, y, color)


def circle(pixels, width, height, cx, cy, radius, color, stroke=None):
    r2 = radius * radius
    inner2 = (radius - stroke) * (radius - stroke) if stroke else -1
    for y in range(cy - radius - 1, cy + radius + 2):
        for x in range(cx - radius - 1, cx + radius + 2):
            d2 = (x - cx) * (x - cx) + (y - cy) * (y - cy)
            if d2 <= r2 and d2 >= inner2:
                set_pixel(pixels, width, height, x, y, color)


def line(pixels, width, height, x0, y0, x1, y1, thickness, color):
    dx = x1 - x0
    dy = y1 - y0
    steps = max(abs(dx), abs(dy), 1)
    for i in range(steps + 1):
        t = i / steps
        x = int(round(x0 + dx * t))
        y = int(round(y0 + dy * t))
        circle(pixels, width, height, x, y, max(1, thickness // 2), color)


def make_icon(size):
    pixels = bytearray([0, 0, 0, 0] * size * size)
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            r = int(38 + 32 * t)
            g = int(122 + 42 * t)
            b = int(222 + 18 * (1 - t))
            set_pixel(pixels, size, size, x, y, (r, g, b, 255))

    pad = int(size * 0.13)
    rounded_rect(pixels, size, size, pad, pad, size - pad, size - pad, int(size * 0.16), (255, 255, 255, 235))

    title_y = int(size * 0.25)
    for i, color in enumerate([(255, 69, 88, 255), (255, 204, 0, 255), (52, 199, 89, 255)]):
        circle(pixels, size, size, int(size * (0.27 + i * 0.11)), title_y, int(size * 0.027), color)

    rows = [0.43, 0.56, 0.69]
    for idx, row in enumerate(rows):
        cy = int(size * row)
        circle(pixels, size, size, int(size * 0.31), cy, int(size * 0.035), (80, 92, 105, 255), stroke=max(2, int(size * 0.01)))
        line(pixels, size, size, int(size * 0.40), cy - int(size * 0.018), int(size * 0.74), cy - int(size * 0.018), max(2, int(size * 0.015)), (55, 65, 81, 245))
        line(pixels, size, size, int(size * 0.40), cy + int(size * 0.027), int(size * (0.62 + idx * 0.04)), cy + int(size * 0.027), max(2, int(size * 0.011)), (125, 135, 148, 210))

    line(pixels, size, size, int(size * 0.285), int(size * 0.56), int(size * 0.31), int(size * 0.585), max(2, int(size * 0.014)), (22, 106, 214, 255))
    line(pixels, size, size, int(size * 0.31), int(size * 0.585), int(size * 0.36), int(size * 0.525), max(2, int(size * 0.014)), (22, 106, 214, 255))
    return pixels


def main():
    os.makedirs(ICONSET, exist_ok=True)
    specs = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    for name, size in specs.items():
        write_png(os.path.join(ICONSET, name), size, size, make_icon(size))
    print(ICONSET)


if __name__ == "__main__":
    main()
