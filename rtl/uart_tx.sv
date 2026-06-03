`timescale 1ns/1ps

module uart_tx #(parameter DELAY_FRAMES = 234)( // 27MHz/115200baude
  input logic clk,
  input logic reset,
  input logic start,
  input logic [7:0] data,
  output logic tx,
  output logic ready
);
  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_START_BIT,
    STATE_DATA,
    STATE_STOP_BIT
  } state_t;

  logic [1:0] state = STATE_IDLE;
  logic [7:0] tx_counter = 8'd0;
  logic [2:0] tx_bit = 3'd0;
  logic [7:0] data_reg = 8'h00;
  initial tx = 1'b1;

  assign ready = state == STATE_IDLE;

  always_ff @(posedge clk) begin
    if (reset) begin
      tx <= 1'b1;
      state <= STATE_IDLE;
      tx_counter <= 0;
      tx_bit <= 0;
    end
    else begin
      case(state)
        STATE_IDLE: begin
          if (start) begin
            data_reg <= data;
            state <= STATE_START_BIT;
          end
        end

        STATE_START_BIT: begin
          tx <= 0;

          if (tx_counter == DELAY_FRAMES - 1) begin
            tx_counter <= 0;
            tx_bit <= 0;
            state <= STATE_DATA;
          end
          else tx_counter <= tx_counter + 1;
        end

        STATE_DATA: begin
          tx <= data_reg[tx_bit];

          if (tx_counter == DELAY_FRAMES - 1) begin
            tx_counter <= 0;
            tx_bit <= tx_bit + 1;
            if (tx_bit == 3'd7) state <= STATE_STOP_BIT;
          end
          else tx_counter <= tx_counter + 1;
        end

        STATE_STOP_BIT: begin
          tx <= 1;

          if (tx_counter == DELAY_FRAMES - 1) begin
            tx_counter <= 0;
            state <= STATE_IDLE;
          end
          else tx_counter <= tx_counter + 1;
        end

        default: state <= STATE_IDLE;
      endcase
    end
  end

endmodule
