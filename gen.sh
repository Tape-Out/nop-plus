#!/usr/bin/env bash
# 生成 build/mycpu_top.v，打上时序补丁得到 build/core_top.v
set -euo pipefail
cd "$(dirname "$0")"
sbt "runMain NOP.Main"
patch -o build/core_top.v build/mycpu_top.v < timing-surgery.patch
