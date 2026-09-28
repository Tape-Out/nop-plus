// Xilinx mult_gen 的行为模型，参数照 xilinx_ip/multiplier.xci：32×32 无符号、两级流水。
// 流水级数要与 MyCPUConfig 的 multiplyLatency 一致，执行级按它数拍取结果。
module multiplier (
  input             CLK,
  input      [31:0] A,
  input      [31:0] B,
  output reg [63:0] P
);
  reg [63:0] m;
  always @(posedge CLK) begin
    m <= A * B;
    P <= m;
  end
endmodule
