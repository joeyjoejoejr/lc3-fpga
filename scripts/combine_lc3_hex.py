#!/usr/bin/env python3
import argparse
from pathlib import Path


def read_obj(path: Path) -> tuple[int, list[int]]:
    data = path.read_bytes()
    if len(data) % 2:
        raise ValueError(f"{path} has odd byte count")

    words = [
        int.from_bytes(data[index:index + 2], "big")
        for index in range(0, len(data), 2)
    ]
    return words[0], words[1:]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("objects", nargs="+", type=Path)
    args = parser.parse_args()

    sections = []
    for obj in args.objects:
        origin, words = read_obj(obj)
        last = origin + len(words) - 1
        sections.append((origin, last, words, obj))

    for index, (start_a, end_a, _, obj_a) in enumerate(sections):
        for start_b, end_b, _, obj_b in sections[index + 1:]:
            if max(start_a, start_b) <= min(end_a, end_b):
                raise ValueError(f"{obj_a} overlaps {obj_b}")

    with args.output.open("w") as output:
        for origin, _, words, obj in sections:
            output.write(f"// {obj}\n")
            output.write(f"@{origin:04X}\n")
            for word in words:
                output.write(f"{word:04X}\n")
            output.write("\n")


if __name__ == "__main__":
    main()
