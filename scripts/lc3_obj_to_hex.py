#!/usr/bin/env python3
import argparse
from pathlib import Path


def read_words(path: Path) -> list[int]:
    data = path.read_bytes()
    if len(data) < 2 or len(data) % 2 != 0:
        raise SystemExit(f"{path}: LC-3 object file must contain 16-bit words")

    return [int.from_bytes(data[i:i + 2], "big") for i in range(0, len(data), 2)]


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a PennSim/lc3as .obj file to an Icarus $readmemh file."
    )
    parser.add_argument("obj", type=Path)
    parser.add_argument("hex", type=Path)
    args = parser.parse_args()

    words = read_words(args.obj)
    origin, body = words[0], words[1:]

    args.hex.parent.mkdir(parents=True, exist_ok=True)
    with args.hex.open("w", encoding="ascii") as out:
      out.write(f"@{origin:04X}\n")
      for word in body:
          out.write(f"{word:04X}\n")


if __name__ == "__main__":
    main()
