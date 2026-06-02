`timescale 1ns/1ps

module lc3_timer(
  input logic clk,
  input logic reset,
  input logic tmr_read,
  input logic tmi_we,
  input logic [15:0] tmi_wdata,
  output logic [15:0] tmi_value,
  output logic [15:0] tmr_value
);

  localparam CLOCKS_PER_MILLISECOND = 27_000;
  
  logic [15:0] clock_count;
  logic [15:0] remaining_ticks;
  logic timer_ready;

  assign tmr_value = timer_ready ? 16'h8000 : 16'h0000;

  always_ff @(posedge clk) begin
    if (reset) begin
      clock_count <= 16'd0;
      remaining_ticks <= 16'd0;
      tmi_value <= 16'd0;
      timer_ready <= 1'b0;
    end else begin
      if (tmr_read) timer_ready <= 1'b0;

      if (tmi_we) begin
        tmi_value <= tmi_wdata;
        timer_ready <= 1'b0;
        remaining_ticks <= tmi_wdata;
        clock_count <= CLOCKS_PER_MILLISECOND - 1;
      end
      else if (tmi_value == 16'd0) begin
        timer_ready <= 1'b0;
        remaining_ticks <= 16'd0;
        clock_count <= 16'd0;
      end
      else if (clock_count != 16'd0) begin
        clock_count <= clock_count - 1'b1;
      end
      else if (remaining_ticks > 16'd1) begin
        remaining_ticks <= remaining_ticks - 1;
        clock_count <= CLOCKS_PER_MILLISECOND - 1;
      end
      else begin
        timer_ready <= 1'b1;
        remaining_ticks <= tmi_value;
        clock_count <= CLOCKS_PER_MILLISECOND - 1;
      end
    end
  end
endmodule
