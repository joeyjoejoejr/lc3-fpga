#!/usr/bin/env python3
from pathlib import Path


HEX = """\
@0021
3100
@3000
A004
07FE
A003
F021
0FFB
FE00
FE02
@3100
3205
A205
07FE
B004
2201
C1C0
0000
FE04
FE06
"""


def main() -> None:
    Path("programs/top/lc3_uart_echo.hex").write_text(HEX)


if __name__ == "__main__":
    main()
