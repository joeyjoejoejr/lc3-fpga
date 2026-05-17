`timescale 1ns/1ps

module lc3_core (
  input  logic        clk,
  input  logic        reset,

  output logic [15:0] mem_addr,
  input  logic [15:0] mem_rdata,
  output logic [15:0] mem_wdata,
  output logic        mem_we,

  output logic [15:0] pc,
  output logic [15:0] ir
);
  typedef enum logic [1:0] {
    STATE_FETCH,
    STATE_LATCH_IR,
    STATE_HALT
  } state_t;

  state_t state;

  assign mem_addr = pc;
  assign mem_wdata = 16'h0000;
  assign mem_we = 1'b0;

  always_ff @(posedge clk) begin
    if (reset) begin
      pc <= 16'h3000;
      ir <= 16'h0000;
      state <= STATE_FETCH;
    end else begin
      case (state)
        STATE_FETCH: begin
          state <= STATE_LATCH_IR;
        end

        STATE_LATCH_IR: begin
          ir <= mem_rdata;
          pc <= pc + 16'd1;
          state <= STATE_HALT;
        end

        STATE_HALT: begin
          state <= STATE_HALT;
        end

        default: begin
          state <= STATE_HALT;
        end
      endcase
    end
  end
endmodule
