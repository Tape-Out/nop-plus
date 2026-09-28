# 来源与许可声明

## NOP

本仓以 [NOP-Processor/NOP-Core](https://github.com/NOP-Processor/NOP-Core) 为起点，保留其提交历史至 `1a5986d`。

- 项目：NOP，五发射乱序 LoongArch32 精简版（LA32R）处理器核
- 作者：Mingdao Liu、Huan-ang Gao、Bowen Wang、Jiacheng Hua
- 来源背景：NSCSCC 2023（第七届「龙芯杯」全国大学生计算机系统能力培养大赛）特等奖
- 许可：MIT，全文见 [`LICENSE`](LICENSE)，版权与许可声明按 MIT 要求原样保留

## 我方的修改

`1a5986d` 之后的提交都是我方为 NSCSCC 2026（龙芯杯）决赛所做，按同一 MIT 许可提供：

- `cpucfg` 译码（`src/constants/LoongArch.scala`、`src/pipeline/decode/DecoderArrayPlugin.scala`）
- 非缓存访问的 AXI 通路、BTB 行宽、DCache 回填的握手（`src/MyCPU.scala`、`src/MyCPUConfig.scala`、`src/pipeline/mem/DCachePlugin.scala`）
- 生成后的时序补丁 `timing-surgery.patch` 与生成脚本 `gen.sh`

## 集成环境

决赛时核集成在龙芯的 [chiplab](https://gitee.com/loongson-edu/chiplab)（木兰宽松许可证第 2 版）里，评测与 SoC 用的是它；本仓不含 chiplab 的任何文件。`xilinx_ip/multiplier.xci` 是 Xilinx Vivado 乘法器 IP 的配置，综合时由 Vivado 按 AMD 的条款生成。
