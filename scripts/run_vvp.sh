#!/usr/bin/env bash
set -euo pipefail

vvp "$@" | sed '/\$finish called/d'
