`timescale 1ns/1ps

module lc3_not_tb;
  logic clk = 1'b0;
  logic reset = 1'b1;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;
  integer      cycle;
  logic        saw_halt;

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

  lc3_memory memory (
    .clk(clk),
    .addr(mem_addr),
    .rdata(mem_rdata),
    .wdata(mem_wdata),
    .we(mem_we)
  );

  initial begin
    $readmemh("programs/not/not_smoke.hex", memory.mem);
  end

  initial begin
    $dumpfile("sim/lc3_not_tb.vcd");
    $dumpvars(0, lc3_not_tb);

    saw_halt = 1'b0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 100; cycle = cycle + 1) begin
      @(posedge clk);
      if (dut.halted) begin
        saw_halt = 1'b1;

        if (dut.regs[1] !== 16'hFFFF ||
            dut.regs[2] !== 16'h0000 ||
            dut.n !== 1'b0 ||
            dut.z !== 1'b1 ||
            dut.p !== 1'b0) begin
          $display("FAIL not_smoke");
          $display("  regs: R1=x%04h R2=x%04h", dut.regs[1], dut.regs[2]);
          $display("  cc  : N=%0b Z=%0b P=%0b", dut.n, dut.z, dut.p);
          $fatal(1);
        end

        $display("PASS not_smoke");
        $finish;
      end
    end

    if (!saw_halt) begin
      $display("FAIL not_smoke: CPU did not halt");
      $fatal(1);
    end
  end
endmodule
