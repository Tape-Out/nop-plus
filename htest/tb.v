`timescale 1ns/1ps
// 冒烟测试台：一块 64 KiB 的 AXI3 存储（地址只看低 16 位），盯 0xbffffff0 上的那次写。
// 读与写各一次只服务一笔突发、按序应答，是 AXI 允许的最简从机。
module tb;
  localparam [31:0] DONE = 32'hbffffff0;
  localparam integer LIMIT = 50000;

  reg clk = 1'b0, rstn = 1'b0;
  always #5 clk = ~clk;

  wire [3:0]  arid, awid, wid;
  wire [31:0] araddr, awaddr, wdata;
  wire [7:0]  arlen, awlen;
  wire [2:0]  arsize, awsize, arprot, awprot;
  wire [1:0]  arburst, awburst;
  wire [0:0]  arlock, awlock;
  wire [3:0]  arcache, awcache, wstrb;
  wire        arvalid, rready, awvalid, wvalid, wlast, bready;
  // 退休与例外取自 chiplab difftest 的端口；debug0_wb_* 在这颗核上不报
  wire [2:0]  cv;
  wire [63:0] cpc0, cpc1, cpc2, epc;
  wire [31:0] cause;
  wire        excp;
  reg  [31:0] last_pc = 32'd0;

  reg  [31:0] mem [0:16383];

  // 读通道
  reg         rbusy = 1'b0;
  reg  [31:0] raddr, rwrap;
  reg  [7:0]  rleft;
  reg  [1:0]  rkind;
  reg  [3:0]  rid_q;
  wire [31:0] rnext = rkind == 2'd0 ? raddr
                    : rkind == 2'd2 ? (raddr & ~rwrap) | ((raddr + 32'd4) & rwrap)
                    : raddr + 32'd4;

  // 写通道
  reg         wbusy = 1'b0, bpend = 1'b0;
  reg  [31:0] waddr, wwrap;
  reg  [1:0]  wkind;
  reg  [3:0]  bid_q;
  wire [31:0] wnext = wkind == 2'd0 ? waddr
                    : wkind == 2'd2 ? (waddr & ~wwrap) | ((waddr + 32'd4) & wwrap)
                    : waddr + 32'd4;

  core_top dut (
    .aclk(clk), .aresetn(rstn), .intrpt(8'd0),
    .arid(arid), .araddr(araddr), .arlen(arlen), .arsize(arsize), .arburst(arburst),
    .arlock(arlock), .arcache(arcache), .arprot(arprot), .arvalid(arvalid), .arready(!rbusy),
    .rid(rid_q), .rdata(mem[raddr[15:2]]), .rresp(2'd0), .rlast(rleft == 8'd0),
    .rvalid(rbusy), .rready(rready),
    .awid(awid), .awaddr(awaddr), .awlen(awlen), .awsize(awsize), .awburst(awburst),
    .awlock(awlock), .awcache(awcache), .awprot(awprot), .awvalid(awvalid),
    .awready(!wbusy && !bpend),
    .wid(wid), .wdata(wdata), .wstrb(wstrb), .wlast(wlast), .wvalid(wvalid), .wready(wbusy),
    .bid(bid_q), .bresp(2'd0), .bvalid(bpend), .bready(bready),
    .DifftestBundle_DifftestInstrCommitValid_0(cv[0]),
    .DifftestBundle_DifftestInstrCommitValid_1(cv[1]),
    .DifftestBundle_DifftestInstrCommitValid_2(cv[2]),
    .DifftestBundle_DifftestInstrCommitPC_0(cpc0),
    .DifftestBundle_DifftestInstrCommitPC_1(cpc1),
    .DifftestBundle_DifftestInstrCommitPC_2(cpc2),
    .DifftestBundle_DifftestExcpEventExcpValid(excp),
    .DifftestBundle_DifftestExcpEventCause(cause),
    .DifftestBundle_DifftestExcpEventEPC(epc),
    .break_point(1'b0), .infor_flag(1'b0), .reg_num(5'd0)
  );

  always @(posedge clk)
    if (!rstn) rbusy <= 1'b0;
    else if (!rbusy && arvalid) begin
      rbusy <= 1'b1;
      raddr <= araddr;
      rleft <= arlen;
      rkind <= arburst;
      rwrap <= ({24'd0, arlen} + 32'd1) * 32'd4 - 32'd1;
      rid_q <= arid;
    end else if (rbusy && rready) begin
      if (rleft == 8'd0) rbusy <= 1'b0;
      else begin
        raddr <= rnext;
        rleft <= rleft - 8'd1;
      end
    end

  integer cyc = 0, limit = LIMIT;
  always @(posedge clk) begin
    cyc <= cyc + 1;
    if (cv[2]) last_pc <= cpc2[31:0];
    else if (cv[1]) last_pc <= cpc1[31:0];
    else if (cv[0]) last_pc <= cpc0[31:0];
    if (!rstn) begin
      wbusy <= 1'b0;
      bpend <= 1'b0;
    end else begin
      if (awvalid && !wbusy && !bpend) begin
        wbusy <= 1'b1;
        waddr <= awaddr;
        wkind <= awburst;
        wwrap <= ({24'd0, awlen} + 32'd1) * 32'd4 - 32'd1;
        bid_q <= awid;
      end
      if (wbusy && wvalid) begin
        if (waddr == DONE) begin
          if (wdata == 32'd1) $display("PASS %0d 拍", cyc);
          else $display("FAIL 第 %0d 项，%0d 拍", wdata, cyc);
          $finish;
        end
        if (wstrb[0]) mem[waddr[15:2]][7:0]   <= wdata[7:0];
        if (wstrb[1]) mem[waddr[15:2]][15:8]  <= wdata[15:8];
        if (wstrb[2]) mem[waddr[15:2]][23:16] <= wdata[23:16];
        if (wstrb[3]) mem[waddr[15:2]][31:24] <= wdata[31:24];
        if (wlast) begin
          wbusy <= 1'b0;
          bpend <= 1'b1;
        end else waddr <= wnext;
      end
      if (bpend && bready) bpend <= 1'b0;
    end
    if (cyc == limit) begin
      $display("FAIL 超时，%0d 拍没写到 %h；最后退休的 pc %h", limit, DONE, last_pc);
      $finish;
    end
  end

  initial begin
    $readmemh("smoke.hex", mem);
    if (!$value$plusargs("limit=%d", limit)) limit = LIMIT;
    if ($test$plusargs("trace")) forever @(posedge clk) begin
      if (cv[0]) $display("%0d 退休 %h", cyc, cpc0[31:0]);
      if (cv[1]) $display("%0d 退休 %h", cyc, cpc1[31:0]);
      if (cv[2]) $display("%0d 退休 %h", cyc, cpc2[31:0]);
      if (excp) $display("%0d 例外 cause %h epc %h", cyc, cause, epc[31:0]);
      if (arvalid && !rbusy) $display("%0d 读 %h len %0d burst %0d id %0d", cyc, araddr, arlen, arburst, arid);
      if (awvalid && !wbusy && !bpend) $display("%0d 写 %h len %0d", cyc, awaddr, awlen);
    end
  end
  initial begin
    repeat (8) @(posedge clk);
    rstn <= 1'b1;
  end
endmodule
