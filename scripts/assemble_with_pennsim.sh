#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 path/to/program.asm" >&2
  exit 2
fi

asm_file=$1
project_root=$(cd "$(dirname "$0")/.." && pwd)
script_file=$(mktemp)

cleanup() {
  rm -f "$script_file"
}
trap cleanup EXIT

printf 'as %s\nquit\n' "$asm_file" > "$script_file"
java -jar "$project_root/tools/PennSim.jar" -t -s "$script_file"
