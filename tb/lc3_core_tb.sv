`timescale 1ns/1ps

module lc3_core_tb;
  logic clk = 1'b0;
  logic reset = 1'b1;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;

  always #5 clk = ~clk;

  lc3_core dut (
    .clk(clk),
    .reset(reset),
    .mem_addr(mem_addr),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_we(mem_we),
    .pc(pc),
    .ir(ir)
  );

  lc3_memory #(
    .INIT_FILE("programs/fetch_smoke.hex")
  ) memory (
    .clk(clk),
    .addr(mem_addr),
    .rdata(mem_rdata),
    .wdata(mem_wdata),
    .we(mem_we)
  );

  initial begin
    $dumpfile("sim/lc3_core_tb.vcd");
    $dumpvars(0, lc3_core_tb);

    repeat (2) @(posedge clk);
    reset <= 1'b0;

    repeat (4) @(posedge clk);

    if (ir !== 16'h1021) begin
      $display("FAIL: expected IR x1021, got x%04h", ir);
      $finish(1);
    end

    if (pc !== 16'h3001) begin
      $display("FAIL: expected PC x3001, got x%04h", pc);
      $finish(1);
    end

    $display("PASS: fetched instruction x%04h from x3000", ir);
    $finish;
  end
endmodule
