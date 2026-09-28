// Xilinx mult_gen 的行为模型，参数照 xilinx_ip/multiplier.xci：32×32 无符号、两级流水。
// 级数不能多于 MyCPUConfig 的 multiplyLatency：执行级数够这么多拍就取结果，其间输入不变，少了无妨。
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
