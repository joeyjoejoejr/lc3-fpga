`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_top_tb;
  logic clk = 1'b0;
  logic reset_button = 1'b1;
  logic [4:0] lcd_b;
  logic [5:0] lcd_g;
  logic [4:0] lcd_r;
  logic lcd_en;
  logic lcd_clk;
  logic rx;
  logic tx;
  integer cycle;

  always #5 clk = ~clk;

  lc3_top #(
    .INIT_FILE("programs/top/framebuffer_cpu_smoke.hex")
  ) dut (
    .clk(clk),
    .reset_button(reset_button),
    .rx(rx),
    .tx(tx),
    .lcd_b(lcd_b),
    .lcd_g(lcd_g),
    .lcd_r(lcd_r),
    .lcd_en(lcd_en),
    .lcd_clk(lcd_clk)
  );

  initial begin
    rx = 1'b1;
    repeat (2) @(posedge clk);
    reset_button <= 1'b0;

    for (cycle = 0; cycle < 20000; cycle = cycle + 1) begin
      @(posedge clk);

      if (lcd_en && {lcd_r, lcd_g, lcd_b} !== 16'h0000) begin
        print_case_pass("top_lcd");
        $finish;
      end
    end

    $display("%s[FAIL]%s %-14s LCD did not produce a non-black enabled pixel", TB_RED, TB_RESET, "top_lcd");
    $display("       lcd_en %0b", lcd_en);
    $display("       rgb565 %04h", {lcd_r, lcd_g, lcd_b});
    $fatal(1);
  end
endmodule
