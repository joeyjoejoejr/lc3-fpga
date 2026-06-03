`timescale 1ns/1ps
`include "tb_helpers.svh"

module uart_rx_tb;
  localparam int CLKS_PER_BIT = 4;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic rx = 1'b1;
  logic valid;
  logic [7:0] data;

  always #5 clk = ~clk;

  uart_rx #(
    .DELAY_FRAMES(CLKS_PER_BIT)
  ) dut (
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .valid(valid),
    .data(data)
  );

  task automatic wait_one_bit;
    begin
      repeat (CLKS_PER_BIT) @(posedge clk);
    end
  endtask

  task automatic drive_rx_byte(input logic [7:0] value);
    integer bit_index;
    begin
      rx <= 1'b0;
      wait_one_bit();

      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        rx <= value[bit_index];
        wait_one_bit();
      end

      rx <= 1'b1;
      wait_one_bit();
    end
  endtask

  task automatic expect_rx_byte(input string name, input logic [7:0] expected);
    integer cycles_waited;
    begin
      drive_rx_byte(expected);

      cycles_waited = 0;
      while (!valid && cycles_waited < CLKS_PER_BIT * 12) begin
        cycles_waited = cycles_waited + 1;
        @(posedge clk);
      end

      if (!valid || data !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       valid    %0b", valid);
        $display("       actual   %02h", data);
        $display("       expected %02h", expected);
        $fatal(1);
      end

      @(posedge clk);
      if (valid) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, {name, "_pulse"});
        $display("       valid stayed high after receive pulse");
        $fatal(1);
      end
    end
  endtask

  initial begin
    repeat (2) @(posedge clk);
    reset <= 1'b0;
    repeat (2) @(posedge clk);

    if (valid !== 1'b0) begin
      $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "idle_valid");
      $fatal(1);
    end

    expect_rx_byte("rx_A", 8'h41);
    expect_rx_byte("rx_55", 8'h55);

    print_case_pass("uart_rx");
    $finish;
  end
endmodule
