`timescale 1ns/1ps

module lc3_keyboard(
    input logic clk,
    input logic reset,
    input logic keyboard_valid,
    input logic [7:0] keyboard_data,
    input logic kbdr_read,

    output logic kb_ready_bit,
    output logic [15:0] kbdr_value
);
  always_ff @(posedge clk) begin
    if(reset) begin
      kb_ready_bit <= 1'b0;
      kbdr_value <= 16'h0000;
    end else begin
      if(kbdr_read) kb_ready_bit <= 1'b0;

      if(!kb_ready_bit && keyboard_valid) begin
        kb_ready_bit <= 1'b1;
        kbdr_value <= { 8'd0, keyboard_data };
      end
    end
  end
endmodule
