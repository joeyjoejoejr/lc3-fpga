`timescale 1ns/1ps

module uart_echo_top(
  input  logic clk,
  input  logic reset_button,
  input  logic rx,
  output logic tx
);
  logic reset;
  logic rx_valid;
  logic [7:0] rx_data;
  logic tx_ready;
  logic tx_start;
  logic [7:0] tx_data;
  logic pending_valid;
  logic [7:0] pending_data;

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
    end
    else begin
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
    end
  end
endmodule
