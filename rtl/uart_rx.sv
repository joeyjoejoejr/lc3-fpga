`timescale 1ns/1ps

module uart_rx #(
  parameter int DELAY_FRAMES = 234
) (
  input  logic       clk,
  input  logic       reset,
  input  logic       rx,
  output logic       valid,
  output logic [7:0] data
);
  // Skeleton for now: implement start-bit detection, mid-bit sampling, eight
  // data bits, and stop-bit validation here.
  always_ff @(posedge clk) begin
    if (reset) begin
      valid <= 1'b0;
      data <= 8'h00;
    end
    else begin
      valid <= 1'b0;
    end
  end
endmodule
