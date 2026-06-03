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
  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_START_BIT,
    STATE_RECEIVE,
    STATE_STOP_BIT
  } state_t;

  localparam int HALF_DELAY = DELAY_FRAMES / 2;

  state_t state = STATE_IDLE;
  logic [7:0] rx_counter = 8'h00;
  logic [2:0] bit_count = 3'd0;
  logic rx_meta = 1'b1;
  logic rx_sync = 1'b1;
  initial valid = 1'b0;
  initial data = 8'h00;

  always_ff @(posedge clk) begin
    if (reset) begin
      state <= STATE_IDLE;
      valid <= 1'b0;
      data <= 8'h00;
      rx_counter <= 8'h00;
      bit_count <= 0;
      rx_meta <= 1'b1;
      rx_sync <= 1'b1;
    end
    else begin
      rx_meta <= rx;
      rx_sync <= rx_meta;
      valid <= 1'b0;
      case(state)
        STATE_IDLE: if(!rx_sync) state <= STATE_START_BIT;

        STATE_START_BIT: begin
          if(rx_counter == HALF_DELAY - 1) begin
            rx_counter <= 8'h00;
            if (!rx_sync) state <= STATE_RECEIVE;
            else state <= STATE_IDLE;
          end
          else rx_counter <= rx_counter + 1;
        end

        STATE_RECEIVE: begin
          if(rx_counter == DELAY_FRAMES - 1) begin
            rx_counter <= 8'h00;
            data[bit_count] <= rx_sync;
            bit_count <= bit_count + 1;
            if(bit_count == 7) state <= STATE_STOP_BIT;
          end
          else rx_counter <= rx_counter + 1;
        end

        STATE_STOP_BIT: begin
          if(rx_counter == DELAY_FRAMES - 1) begin
            rx_counter <= 8'h00;
            if(rx_sync) valid <= 1'b1;
            state <= STATE_IDLE;
          end
          else rx_counter <= rx_counter + 1;
        end

        default: state <= STATE_IDLE;
      endcase
    end
  end
endmodule
