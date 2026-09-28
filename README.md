# nop-plus

NOP, the five-issue out-of-order LoongArch32 Reduced core, improved by our team for the NSCSCC 2026 (Loongson Cup) final.

This repository is a fork of [NOP-Processor/NOP-Core](https://github.com/NOP-Processor/NOP-Core) (MIT; Mingdao Liu, Huan-ang Gao, Bowen Wang, Jiacheng Hua; NSCSCC 2023 special prize), with its history kept up to `1a5986d`. Every commit after that one is ours. The original README is in [`docs/README.NOP.md`](docs/README.NOP.md), and [`NOTICE.md`](NOTICE.md) states the provenance in full.

## What changed

| Change | Files | Why |
|:--:|:--|:--|
| `cpucfg` is decoded | `LoongArch.scala`, `DecoderArrayPlugin.scala` | Upstream had no decode for it, and the performance bench's cache init stalled on it; the bench went from 0/20 to 20/20. It returns the high half of the stable counter, which is 0 after reset: enough for the bench, not yet a real CPUCFG |
| Uncached accesses share the AXI path of the other reads | `MyCPU.scala` | The `AxiBuffer` on the uncached bus is gone |
| BTB line size 4 → 64 | `MyCPUConfig.scala` | |
| A dcache refill ends on the accepted last beat (`r.fire`) | `DCachePlugin.scala` | It used to end on `r.valid`, before the beat was taken |
| `timing-surgery.patch` | generated Verilog | A reset fan-out synchroniser and one register stage on the load wake-up broadcast. It takes the core from about 90 to 100 MHz. Functionally equivalent, not cycle-equivalent: the team's notes measured 6.7% lower IPC |

## Results

For the build submitted to the final (the `cpucfg` fix plus the timing patch, before the three later fixes), the team's design report gives 100 MHz with setup and hold WNS +0.038 / +0.059 ns, 20/20 functional tests, and a system-counter ratio of 3.5545 on the performance bench. The limit was about 107.5 MHz. The three later fixes have not been run through chiplab's tests yet.

## Building

JDK 11, sbt 1.9.7 (pinned in `project/build.properties`), Scala 2.12.16 and SpinalHDL 1.8.1:

```console
$ ./gen.sh      # sbt "runMain NOP.Main", then the timing patch: build/core_top.v
```

Synthesis needs Vivado for the multiplier IP (`xilinx_ip/multiplier.xci`) and the XPM memories. The generated file carries a date line, so compare outputs from the fifth line on.

## License

MIT, see [`LICENSE`](LICENSE). Our changes are offered under the same terms.
