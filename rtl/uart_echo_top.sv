`timescale 1ns/1ps

module uart_echo_top(
  input  logic clk,
  input  logic reset_button,
  input  logic rx,
  output logic tx,
  output logic [5:0] led
);
  localparam logic [23:0] PULSE_HOLD_CYCLES = 24'd6750000;
  logic reset;
  logic rx_valid;
  logic [7:0] rx_data;
  logic tx_ready;
  logic tx_start = 1'b0;
  logic [7:0] tx_data = 8'h00;
  logic pending_valid = 1'b0;
  logic [7:0] pending_data = 8'h00;
  logic rx_meta = 1'b1;
  logic rx_sync = 1'b1;
  logic rx_prev = 1'b1;
  logic [23:0] rx_edge_counter = 24'd0;
  logic [23:0] rx_valid_counter = 24'd0;
  logic [23:0] tx_start_counter = 24'd0;
  initial led = 6'b111111;

  assign reset = reset_button;

  uart_rx rx_uart (
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .valid(rx_valid),
    .data(rx_data)
  );

  uart_tx tx_uart (
    .clk(clk),
    .reset(reset),
    .start(tx_start),
    .data(tx_data),
    .tx(tx),
    .ready(tx_ready)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      tx_start <= 1'b0;
      tx_data <= 8'h00;
      pending_valid <= 1'b0;
      pending_data <= 8'h00;
      rx_meta <= 1'b1;
      rx_sync <= 1'b1;
      rx_prev <= 1'b1;
      rx_edge_counter <= 24'd0;
      rx_valid_counter <= 24'd0;
      tx_start_counter <= 24'd0;
      led <= 6'b111111;
    end
    else begin
      rx_meta <= rx;
      rx_sync <= rx_meta;
      rx_prev <= rx_sync;
      tx_start <= 1'b0;

      if (rx_valid) begin
        if (tx_ready && !pending_valid) begin
          tx_data <= rx_data;
          tx_start <= 1'b1;
        end
        else begin
          pending_data <= rx_data;
          pending_valid <= 1'b1;
        end
      end
      else if (tx_ready && pending_valid) begin
        tx_data <= pending_data;
        tx_start <= 1'b1;
          pending_valid <= 1'b0;
      end

      if (rx_prev && !rx_sync) rx_edge_counter <= PULSE_HOLD_CYCLES;
      else if (rx_edge_counter != 24'd0) rx_edge_counter <= rx_edge_counter - 1'b1;

      if (rx_valid) rx_valid_counter <= PULSE_HOLD_CYCLES;
      else if (rx_valid_counter != 24'd0) rx_valid_counter <= rx_valid_counter - 1'b1;

      if (tx_start) tx_start_counter <= PULSE_HOLD_CYCLES;
      else if (tx_start_counter != 24'd0) tx_start_counter <= tx_start_counter - 1'b1;

      led[0] <= !rx_sync;
      led[1] <= rx_edge_counter == 24'd0;
      led[2] <= rx_valid_counter == 24'd0;
      led[3] <= tx_start_counter == 24'd0;
      led[4] <= !tx_ready;
      led[5] <= !tx;
    end
  end
endmodule
