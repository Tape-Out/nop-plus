// Xilinx XPM 简单双口 RAM 的行为模型，让核离开 Vivado 也能仿真与综合。
// 只覆盖 src/blackbox/mem 用到的：同钟、无 ECC、read_first、读写同宽、
// 按字节或整字写、读延迟 0/1/2。
//
// 上游在 FPGA 上跑，块 RAM 上电为零，模型照样清零；流片换 SRAM 宏时要核有没有东西依赖这一点。
module xpm_memory_sdpram #(
  parameter integer ADDR_WIDTH_A = 6,
  parameter integer ADDR_WIDTH_B = 6,
  parameter integer AUTO_SLEEP_TIME = 0,
  parameter integer BYTE_WRITE_WIDTH_A = 32,
  parameter integer CASCADE_HEIGHT = 0,
  parameter CLOCKING_MODE = "common_clock",
  parameter ECC_MODE = "no_ecc",
  parameter MEMORY_INIT_FILE = "none",
  parameter MEMORY_INIT_PARAM = "0",
  parameter MEMORY_OPTIMIZATION = "true",
  parameter MEMORY_PRIMITIVE = "auto",
  parameter integer MEMORY_SIZE = 2048,
  parameter integer MESSAGE_CONTROL = 0,
  parameter integer READ_DATA_WIDTH_B = 32,
  parameter integer READ_LATENCY_B = 2,
  parameter READ_RESET_VALUE_B = "0",
  parameter RST_MODE_A = "SYNC",
  parameter RST_MODE_B = "SYNC",
  parameter integer SIM_ASSERT_CHK = 0,
  parameter integer USE_EMBEDDED_CONSTRAINT = 0,
  parameter integer USE_MEM_INIT = 1,
  parameter WAKEUP_TIME = "disable_sleep",
  parameter integer WRITE_DATA_WIDTH_A = 32,
  parameter WRITE_MODE_B = "no_change"
) (
  input                                              sleep,
  input                                              clka,
  input                                              ena,
  input  [WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-1:0] wea,
  input  [ADDR_WIDTH_A-1:0]                          addra,
  input  [WRITE_DATA_WIDTH_A-1:0]                    dina,
  input                                              injectsbiterra,
  input                                              injectdbiterra,
  input                                              clkb,
  input                                              rstb,
  input                                              enb,
  input                                              regceb,
  input  [ADDR_WIDTH_B-1:0]                          addrb,
  output [READ_DATA_WIDTH_B-1:0]                     doutb,
  output                                             sbiterrb,
  output                                             dbiterrb
);
  localparam integer DEPTH = MEMORY_SIZE / WRITE_DATA_WIDTH_A;
  localparam integer LANES = WRITE_DATA_WIDTH_A / BYTE_WRITE_WIDTH_A;

  reg [WRITE_DATA_WIDTH_A-1:0] mem [0:DEPTH-1];
  integer i;
  initial for (i = 0; i < DEPTH; i = i + 1) mem[i] = {WRITE_DATA_WIDTH_A{1'b0}};

  genvar g;
  generate
    for (g = 0; g < LANES; g = g + 1) begin : lane
      always @(posedge clka)
        if (ena && wea[g])
          mem[addra][g*BYTE_WRITE_WIDTH_A +: BYTE_WRITE_WIDTH_A] <= dina[g*BYTE_WRITE_WIDTH_A +: BYTE_WRITE_WIDTH_A];
    end

    // 与 XPM 一致：common_clock 时不看 clkb
    wire rclk = CLOCKING_MODE == "common_clock" ? clka : clkb;

    if (READ_LATENCY_B == 0) begin : comb
      assign doutb = mem[addrb];
    end else if (READ_LATENCY_B == 1) begin : one
      reg [READ_DATA_WIDTH_B-1:0] q;
      always @(posedge rclk)
        if (rstb) q <= {READ_DATA_WIDTH_B{1'b0}};
        else if (enb) q <= mem[addrb];
      assign doutb = q;
    end else begin : two
      // rstb 与 regceb 只作用于输出寄存器
      reg [READ_DATA_WIDTH_B-1:0] m, q;
      always @(posedge rclk)
        if (enb) m <= mem[addrb];
      always @(posedge rclk)
        if (rstb) q <= {READ_DATA_WIDTH_B{1'b0}};
        else if (regceb) q <= m;
      assign doutb = q;
    end
  endgenerate

  assign sbiterrb = 1'b0;
  assign dbiterrb = 1'b0;
endmodule
