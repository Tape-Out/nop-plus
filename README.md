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

JDK 17 or older (Scala 2.12.16 crashes on newer ones; set `JAVA` to pick one), sbt 1.9.7 (pinned in `project/build.properties`), Scala 2.12.16 and SpinalHDL 1.8.1. Without sbt installed, `gen.sh` fetches that version's launcher from Maven Central:

```console
$ ./gen.sh      # sbt "runMain NOP.Main", then the timing patch: build/core_top.v
```

The generated Verilog instantiates two Xilinx primitives, the `multiplier` IP (`xilinx_ip/multiplier.xci`) and `xpm_memory_sdpram`. [`vendor/`](vendor) has behavioural models of both, limited to the configurations the core uses, so it simulates and synthesises without Vivado; a Vivado build leaves `vendor/` out and uses the real ones.

Two runs are not byte-identical: besides the date line, SpinalHDL may renumber the `when_*` signals of some plugins. The timing patch is applied with zero fuzz, so a shifted context fails instead of landing in the wrong place.

## With XiRang

Part of the [Tape-Out](https://github.com/Tape-Out) IP library, wired up by [`xirang`](https://github.com/Tape-Out/xirang) as a black box. The top is `core_top`, with an AXI3 manager port, eight interrupt lines and the write-back trace chiplab's difftest reads.

```console
$ ran run nop-plus spinal     # gen.sh
$ ran test nop-plus           # elaborate and check the declaration
```

The gate elaborates the design; it does not run programs on it yet. The configuration is fixed in `src/MyCPUConfig.scala`, and the three hundred or so other difftest outputs are not declared as endpoints.

## License

MIT, see [`LICENSE`](LICENSE). Our changes are offered under the same terms.
