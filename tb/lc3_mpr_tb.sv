`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_mpr_tb;
  localparam logic [15:0] MPR_ADDR = 16'hFE12;

  logic clk = 1'b0;
  logic reset = 1'b1;

  logic [15:0] cpu_addr;
  logic [15:0] cpu_rdata;
  logic [15:0] cpu_wdata;
  logic        cpu_we;

  logic        video_enabled;
  logic [13:0] video_addr;
  logic [15:0] video_pixel;
  logic        machine_halt;

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
    .video_pixel(video_pixel),
    .keyboard_valid(1'b0),
    .keyboard_data(8'h00),
    .keyboard_ready(),
    .machine_halt(machine_halt),
    .display_valid(),
    .display_data(),
    .display_ready(1'b1)
  );

  task automatic write_word(input logic [15:0] addr, input logic [15:0] data);
    begin
      cpu_addr <= addr;
      cpu_wdata <= data;
      cpu_we <= 1'b1;
      @(posedge clk);
      cpu_we <= 1'b0;
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
    end
  endtask

  initial begin
    cpu_addr = 16'h0000;
    cpu_wdata = 16'h0000;
    cpu_we = 1'b0;
    video_enabled = 1'b0;
    video_addr = 14'h0000;

    repeat (2) @(posedge clk);
    reset <= 1'b0;
    repeat (2) @(posedge clk);

    read_expect("mpr_reset", MPR_ADDR, 16'h0000);

    write_word(MPR_ADDR, 16'h0FF8);
    read_expect("mpr_write", MPR_ADDR, 16'h0FF8);

    write_word(MPR_ADDR, 16'hFFFF);
    read_expect("mpr_all_on", MPR_ADDR, 16'hFFFF);

    reset <= 1'b1;
    repeat (2) @(posedge clk);
    reset <= 1'b0;
    repeat (2) @(posedge clk);

    read_expect("mpr_reset2", MPR_ADDR, 16'h0000);

    print_case_pass("mpr");
    $finish;
  end
endmodule
