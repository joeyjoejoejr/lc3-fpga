`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_top_tb;
  logic clk = 1'b0;
  logic reset_button = 1'b1;
  logic [5:0] led;
  integer cycle;

  always #5 clk = ~clk;

  lc3_top dut (
    .clk(clk),
    .reset_button(reset_button),
    .led(led)
  );

  initial begin
    repeat (2) @(posedge clk);
    reset_button <= 1'b0;

    for (cycle = 0; cycle < 120; cycle = cycle + 1) begin
      @(posedge clk);

      if (led === ~6'b000001) begin
        print_case_pass("top_led");
        $finish;
      end
    end

    $display("%s[FAIL]%s %-14s LEDs did not show expected value", TB_RED, TB_RESET, "top_led");
    $display("       actual led pins %06b", led);
    $display("       expected        %06b", ~6'b000001);
    $fatal(1);
  end
endmodule
