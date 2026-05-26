`timescale 1ns/1ps
`include "tb_helpers.svh"

module uart_tx_tb;
  localparam int CLKS_PER_BIT = 4;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic start = 1'b0;
  logic [7:0] data = 8'h00;
  logic tx;
  logic ready;

  always #5 clk = ~clk;

  uart_tx #(
    .DELAY_FRAMES(CLKS_PER_BIT)
  ) dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .data(data),
    .tx(tx),
    .ready(ready)
  );

  task automatic expect_line(
    input string name,
    input logic actual,
    input logic expected
  );
    begin
      if (actual !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       actual   %0b", actual);
        $display("       expected %0b", expected);
        $fatal(1);
      end
    end
  endtask

  task automatic expect_ready(
    input string name,
    input logic expected_ready
  );
    begin
      if (ready !== expected_ready) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       actual   ready=%0b", ready);
        $display("       expected ready=%0b", expected_ready);
        $fatal(1);
      end
    end
  endtask

  task automatic wait_bit_center;
    begin
      repeat (CLKS_PER_BIT / 2) @(posedge clk);
    end
  endtask

  task automatic wait_one_bit;
    begin
      repeat (CLKS_PER_BIT) @(posedge clk);
    end
  endtask

  task automatic send_byte(input logic [7:0] value);
    begin
      data <= value;
      start <= 1'b1;
      @(posedge clk);
      start <= 1'b0;
    end
  endtask

  task automatic expect_byte(input string name, input logic [7:0] value);
    integer bit_index;
    begin
      send_byte(value);

      wait_bit_center();
      expect_line({name, "_start"}, tx, 1'b0);
      expect_ready({name, "_not_ready"}, 1'b0);

      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        wait_one_bit();
        expect_line({name, "_data"}, tx, value[bit_index]);
      end

      wait_one_bit();
      expect_line({name, "_stop"}, tx, 1'b1);

      wait_one_bit();
      expect_line({name, "_idle"}, tx, 1'b1);
      expect_ready({name, "_ready"}, 1'b1);
    end
  endtask

  initial begin
    repeat (2) @(posedge clk);
    reset <= 1'b0;
    repeat (2) @(posedge clk);

    expect_line("idle_tx", tx, 1'b1);
    expect_ready("idle_status", 1'b1);

    expect_byte("tx_55", 8'h55);
    expect_byte("tx_A", 8'h41);

    print_case_pass("uart_tx");
    $finish;
  end
endmodule
