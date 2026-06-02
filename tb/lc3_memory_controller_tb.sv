`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_memory_controller_tb;
  logic clk = 1'b0;

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

    write_word(16'h3000, 16'h1234);
    read_expect("ram_readwrite", 16'h3000, 16'h1234);

    write_word(16'hBFFF, 16'hABCD);
    read_expect("ram_top", 16'hBFFF, 16'hABCD);

    write_word(16'hC000, 16'h7C00);
    read_expect("fb_as_ram", 16'hC000, 16'h7C00);

    video_addr <= 14'h0000;
    video_enabled <= 1'b1;
    @(posedge clk);
    @(posedge clk);

    if (video_pixel !== 16'h7C00) begin
      $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "video_read");
      $display("       actual   %04h", video_pixel);
      $display("       expected %04h", 16'h7C00);
      $fatal(1);
    end

    cpu_addr <= 16'hFE00;
    @(posedge clk);
    @(posedge clk);

    if (cpu_rdata !== 16'h0000) begin
      $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "device_stub");
      $display("       actual   %04h", cpu_rdata);
      $display("       expected %04h", 16'h0000);
      $fatal(1);
    end

    print_case_pass("memory_ctl");
    $finish;
  end
endmodule
