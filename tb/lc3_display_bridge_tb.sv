`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_display_bridge_tb;
  logic sys_clk = 1'b0;
  logic lcd_clk = 1'b0;
  logic sys_reset;
  logic lcd_reset;
  logic sys_valid;
  logic [7:0] sys_data;
  logic sys_ready;
  logic lcd_valid;
  logic [7:0] lcd_data;
  logic lcd_ready;

  always #5 sys_clk = ~sys_clk;
  always #17 lcd_clk = ~lcd_clk;

  lc3_display_bridge dut (
    .sys_clk(sys_clk),
    .sys_reset(sys_reset),
    .sys_valid(sys_valid),
    .sys_data(sys_data),
    .sys_ready(sys_ready),
    .lcd_clk(lcd_clk),
    .lcd_reset(lcd_reset),
    .lcd_valid(lcd_valid),
    .lcd_data(lcd_data),
    .lcd_ready(lcd_ready)
  );

  task automatic send_char(input logic [7:0] value);
    begin
      @(posedge sys_clk);
      if (!sys_ready) begin
        $display("%s[FAIL]%s %-14s bridge was not ready", TB_RED, TB_RESET, "bridge_ready");
        $fatal(1);
      end

      sys_data <= value;
      sys_valid <= 1'b1;
      @(posedge sys_clk);
      sys_valid <= 1'b0;
    end
  endtask

  task automatic expect_lcd_char(input string name, input logic [7:0] expected);
    bit seen;
    begin
      seen = 1'b0;
      for (int i = 0; i < 20; i++) begin
        @(posedge lcd_clk);
        if (!seen && lcd_valid) begin
          if (lcd_data !== expected) begin
            $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
            $display("       actual   %02h", lcd_data);
            $display("       expected %02h", expected);
            $fatal(1);
          end
          seen = 1'b1;
        end
      end

      if (!seen) begin
        $display("%s[FAIL]%s %-14s timed out", TB_RED, TB_RESET, name);
        $fatal(1);
      end
    end
  endtask

  initial begin
    sys_reset = 1'b1;
    lcd_reset = 1'b1;
    sys_valid = 1'b0;
    sys_data = 8'h00;
    lcd_ready = 1'b1;

    repeat (3) @(posedge sys_clk);
    repeat (2) @(posedge lcd_clk);
    sys_reset = 1'b0;
    lcd_reset = 1'b0;

    send_char("A");
    expect_lcd_char("bridge_A", "A");

    lcd_ready = 1'b0;
    send_char("B");

    repeat (4) @(posedge sys_clk);
    if (sys_ready) begin
      $display("%s[FAIL]%s %-14s bridge accepted while LCD was blocked",
               TB_RED, TB_RESET, "bridge_backpressure");
      $fatal(1);
    end

    repeat (3) @(posedge lcd_clk);
    lcd_ready = 1'b1;
    expect_lcd_char("bridge_B", "B");

    repeat (6) @(posedge sys_clk);
    if (!sys_ready) begin
      $display("%s[FAIL]%s %-14s bridge did not return ready",
               TB_RED, TB_RESET, "bridge_ready");
      $fatal(1);
    end

    print_case_pass("display_bridge");
    $finish;
  end
endmodule
