#!/usr/bin/env bash
# 汇编 smoke.S、链到复位地址 0x1c000000，在 core_top 上跑，输出里没有 PASS 就算不过
set -euo pipefail
cd "$(dirname "$0")/.."
X=${CROSS:-loongarch64-linux-gnu-}
O=build/smoke
[ -f build/core_top.v ] || { echo "没有 build/core_top.v，先跑 gen.sh" >&2; exit 1; }
mkdir -p $O
"${X}as" -mno-relax -o $O/smoke.o htest/smoke.S
"${X}ld" -Ttext=0x1c000000 -o $O/smoke.elf $O/smoke.o
"${X}objcopy" -O binary -j .text $O/smoke.elf $O/smoke.bin
od -An -v -tx4 $O/smoke.bin > $O/smoke.hex
iverilog -g2005 -s tb -o $O/tb.vvp htest/tb.v build/core_top.v vendor/xpm_memory_sdpram.v vendor/multiplier.v
(cd $O && vvp -n tb.vvp "$@") | tee $O/smoke.log | grep -v '^WARNING: .*readmemh'
grep -q '^PASS' $O/smoke.log
