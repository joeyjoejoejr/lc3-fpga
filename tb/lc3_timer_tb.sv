`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_timer_tb;
  localparam logic [15:0] TMR_ADDR = 16'hFE08;
  localparam logic [15:0] TMI_ADDR = 16'hFE0A;

  // The LC-3 extended timer treats TMI as milliseconds. At the Tang Nano
  // 20K's 27 MHz clock, one millisecond is 27,000 system-clock cycles.
  localparam int CYCLES_PER_MS = 27000;

  logic clk = 1'b0;
  logic reset;

  logic [15:0] cpu_addr;
  logic [15:0] cpu_rdata;
  logic [15:0] cpu_wdata;
  logic        cpu_we;

  logic        video_enabled;
  logic [13:0] video_addr;
  logic [15:0] video_pixel;

  always #5 clk = ~clk;

  lc3_memory_controller dut (
    .clk(clk),
    .reset(reset),
    .cpu_addr(cpu_addr),
    .cpu_rdata(cpu_rdata),
    .cpu_wdata(cpu_wdata),
    .cpu_we(cpu_we),
    .video_clk(clk),
    .video_enabled(video_enabled),
    .video_addr(video_addr),
    .video_pixel(video_pixel)
  );

  task automatic write_word(input logic [15:0] addr, input logic [15:0] data);
    begin
      cpu_addr <= addr;
      cpu_wdata <= data;
      cpu_we <= 1'b1;
      @(posedge clk);
      cpu_we <= 1'b0;
      @(posedge clk);
    end
  endtask

  task automatic read_expect(
    input string name,
    input logic [15:0] addr,
    input logic [15:0] expected
  );
    begin
      cpu_addr <= addr;
      cpu_we <= 1'b0;
      @(posedge clk);
      @(posedge clk);

      if (cpu_rdata !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       addr     %04h", addr);
        $display("       actual   %04h", cpu_rdata);
        $display("       expected %04h", expected);
        $fatal(1);
      end

      cpu_addr <= 16'h0000;
      @(posedge clk);
    end
  endtask

  task automatic wait_cycles(input int cycles);
    repeat (cycles) @(posedge clk);
  endtask

  initial begin
    reset = 1'b1;
    cpu_addr = 16'h0000;
    cpu_wdata = 16'h0000;
    cpu_we = 1'b0;
    video_enabled = 1'b0;
    video_addr = 14'h0000;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    read_expect("timer_initial", TMR_ADDR, 16'h0000);

    write_word(TMI_ADDR, 16'd1);

    // Writing TMI arms/restarts the timer, but should not immediately set TMR.
    read_expect("timer_not_immediate", TMR_ADDR, 16'h0000);

    wait_cycles(CYCLES_PER_MS / 2);
    read_expect("timer_not_early", TMR_ADDR, 16'h0000);

    wait_cycles((CYCLES_PER_MS / 2) + 8);
    read_expect("timer_first_tick", TMR_ADDR, 16'h8000);

    // Reading TMR clears the ready bit.
    read_expect("timer_read_clears", TMR_ADDR, 16'h0000);

    // The timer keeps running after the clear without rewriting TMI.
    wait_cycles(CYCLES_PER_MS);
    read_expect("timer_repeats", TMR_ADDR, 16'h8000);
    read_expect("timer_second_clear", TMR_ADDR, 16'h0000);

    // A zero interval disables the timer and clears any pending tick.
    write_word(TMI_ADDR, 16'd0);
    wait_cycles(CYCLES_PER_MS + 8);
    read_expect("timer_disabled", TMR_ADDR, 16'h0000);

    print_case_pass("timer");
    $finish;
  end
endmodule
