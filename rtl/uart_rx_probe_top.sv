`timescale 1ns/1ps

module uart_rx_probe_top(
  input  logic       clk,
  input  logic       reset_button,
  input  logic       rx,
  output logic [5:0] led
);
  localparam logic [23:0] PULSE_HOLD_CYCLES = 24'd6750000;

  logic reset;
  logic rx_meta;
  logic rx_sync;
  logic rx_prev;
  logic [23:0] pulse_counter;

  assign reset = reset_button;

  always_ff @(posedge clk) begin
    if (reset) begin
      rx_meta <= 1'b1;
      rx_sync <= 1'b1;
      rx_prev <= 1'b1;
      pulse_counter <= 24'd0;
      led <= 6'b111111;
    end
    else begin
      rx_meta <= rx;
      rx_sync <= rx_meta;
      rx_prev <= rx_sync;

      if (rx_prev && !rx_sync) begin
        pulse_counter <= PULSE_HOLD_CYCLES;
      end
      else if (pulse_counter != 24'd0) begin
        pulse_counter <= pulse_counter - 1'b1;
      end

      led[0] <= rx_sync;
      led[1] <= !rx_sync;
      led[2] <= pulse_counter == 24'd0;
      led[5:3] <= 3'b111;
    end
  end
endmodule
