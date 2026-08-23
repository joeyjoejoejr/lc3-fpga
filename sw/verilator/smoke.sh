#!/usr/bin/env bash
set -euo pipefail

sim="${1:?usage: smoke.sh PATH_TO_VERILATED_EXECUTABLE}"

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/lc3-verilator-smoke.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

stdout="$tmpdir/stdout.txt"
stderr="$tmpdir/stderr.txt"
memory="$tmpdir/memory.bin"

# Dense 64K-word big-endian memory image.
#   memory[x0025] = x3002 trap vector for HALT
#   memory[x3000] = ADD R0, R0, #1
#   memory[x3001] = TRAP x25
#   memory[x3002] = reserved opcode used by the current core halt path
dd if=/dev/zero of="$memory" bs=131072 count=1 status=none
printf '\x30\x02' | dd of="$memory" bs=1 seek=$((0x0025 * 2)) conv=notrunc status=none
printf '\x10\x21\xf0\x25\xd0\x00' | dd of="$memory" bs=1 seek=$((0x3000 * 2)) conv=notrunc status=none

"$sim" --memory "$memory" --reset-pc 0x3000 --cycles 20 >"$stdout" 2>"$stderr"

if ! grep -q "loaded memory words=65536" "$stdout"; then
  echo "expected simulator to report loading the full memory image" >&2
  echo "stdout:" >&2
  cat "$stdout" >&2
  echo "stderr:" >&2
  cat "$stderr" >&2
  exit 1
fi

if ! grep -q "ir=0xd000" "$stdout"; then
  echo "expected simulator to reach the trap HALT handler" >&2
  echo "stdout:" >&2
  cat "$stdout" >&2
  echo "stderr:" >&2
  cat "$stderr" >&2
  exit 1
fi
