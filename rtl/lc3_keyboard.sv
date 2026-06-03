`timescale 1ns/1ps

module lc3_keyboard(
    input logic clk,
    input logic reset,
    input logic keyboard_valid,
    input logic [7:0] keyboard_data,
    input logic kbdr_read,

    output logic [15:0] kbsr_value,
    output logic [15:0] kbdr_value
);
  always_ff @(posedge clk) begin
    if(reset) begin
      kbsr_value <= 16'h0000;
      kbdr_value <= 16'h0000;
    end else begin
      if(kbdr_read) kbsr_value <= 16'h0000;

      if(!kbsr_value[15] && keyboard_valid) begin
        kbsr_value <= 16'h8000;
        kbdr_value <= { 8'd0, keyboard_data };
      end
    end
  end
endmodule
