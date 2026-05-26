`timescale 1ns/1ps

module tx_top(
  input logic clk,
  input logic reset_button,
  output logic tx
);
  logic reset;
  logic start;
  logic [7:0] data;
  logic [7:0] data_reg;
  logic ready;
  logic [2:0] index;

  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_START,
    STATE_WAIT_BUSY,
    STATE_WAIT_READY
  } state_t;

  state_t state;

  assign reset = reset_button;

  uart_tx uart (
    .clk(clk),
    .reset(reset),
    .start(start),
    .data(data_reg),
    .tx(tx),
    .ready(ready)
  );

  always_comb
    case(index)
      3'd0: data = "H";
      3'd1: data = "e";
      3'd2: data = "l";
      3'd3: data = "l";
      3'd4: data = "o";
      3'd5: data = 8'h0D;
      3'd6: data = 8'h0A;
      default: data = 8'h00;
    endcase

  always_ff @(posedge clk) begin
    if (reset) begin
      index <= 3'd0;
      start <= 1'b0;
      data_reg <= 8'h00;
      state <= STATE_IDLE;
    end
    else begin
      start <= 1'b0;

      case (state)
        STATE_IDLE: begin
          if (ready && index < 3'd7) begin
            data_reg <= data;
            state <= STATE_START;
          end
        end

        STATE_START: begin
          start <= 1'b1;
          index <= index + 1'b1;
          state <= STATE_WAIT_BUSY;
        end

        STATE_WAIT_BUSY: begin
          if (!ready) state <= STATE_WAIT_READY;
        end

        STATE_WAIT_READY: begin
          if (ready) state <= STATE_IDLE;
        end

        default: state <= STATE_IDLE;
      endcase
    end
  end
endmodule 
