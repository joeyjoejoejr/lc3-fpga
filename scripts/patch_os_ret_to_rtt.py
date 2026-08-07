#!/usr/bin/env python3
import argparse
from pathlib import Path


RET = 0xC1C0
RTT = 0xC1C1


def read_words(path: Path) -> list[int]:
    data = path.read_bytes()
    if len(data) % 2:
        raise ValueError(f"{path} has odd byte count")

    return [
        int.from_bytes(data[index:index + 2], "big")
        for index in range(0, len(data), 2)
    ]


def write_words(path: Path, words: list[int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"".join(word.to_bytes(2, "big") for word in words))


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Patch an LC-3 OS object so RET/JMP R7 encodings become RTT."
    )
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    words = read_words(args.input)
    if not words:
        raise ValueError(f"{args.input} is empty")

    patched = [words[0]]
    replacements = 0
    for word in words[1:]:
        if word == RET:
            patched.append(RTT)
            replacements += 1
        else:
            patched.append(word)

    if replacements == 0:
        raise ValueError(f"{args.input} did not contain any RET/JMP R7 words")

    write_words(args.output, patched)
    print(f"{args.output}: replaced {replacements} RET word(s) with RTT")


if __name__ == "__main__":
    main()
