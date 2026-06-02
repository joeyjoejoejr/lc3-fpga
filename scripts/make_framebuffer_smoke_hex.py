#!/usr/bin/env python3
from pathlib import Path

FB_WIDTH = 128
FB_HEIGHT = 124

BLACK = 0x0000
RED = 0x7C00
GREEN = 0x03E0
BLUE = 0x001F
YELLOW = 0x7FED
WHITE = 0x7FFF


def pixel(x, y):
    if x == y or x == FB_WIDTH - 1 - y:
        return WHITE

    if 8 <= x < 120 and 8 <= y < 116:
        if x < 40:
            return RED
        if x < 72:
            return GREEN
        if x < 104:
            return BLUE
        return YELLOW

    if x < 2 or x >= FB_WIDTH - 2 or y < 2 or y >= FB_HEIGHT - 2:
        return WHITE

    return BLACK


def main():
    out = Path("programs/top/framebuffer_smoke.hex")
    out.parent.mkdir(parents=True, exist_ok=True)

    with out.open("w") as f:
        for y in range(FB_HEIGHT):
            row = [f"{pixel(x, y):04X}" for x in range(FB_WIDTH)]
            f.write(" ".join(row))
            f.write("\n")


if __name__ == "__main__":
    main()
