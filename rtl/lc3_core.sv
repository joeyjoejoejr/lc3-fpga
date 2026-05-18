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
  typedef enum logic [2:0] {
    STATE_FETCH,
    STATE_LATCH_IR,
    STATE_DECODE,
    STATE_EXEC_ADD,
    STATE_EXEC_AND,
    STATE_HALT
  } state_t;

  localparam logic[3:0] OP_ADD = 4'b0001;
  localparam logic[3:0] OP_AND = 4'b0101;

  state_t state;
  logic [15:0] regs [0:7];
  logic n;
  logic z;
  logic p;
  logic halted;
  integer i;


  // Instruction extraction
  logic [3:0] opcode;
  logic [2:0] dr;
  logic [2:0] sr1;
  logic [2:0] sr2;
  logic is_imm;
  logic [15:0] imm5;

  logic [15:0] add_rhs;
  logic [15:0] add_result;

  logic [15:0] and_rhs;
  logic [15:0] and_result;

  assign opcode = ir[15:12];
  assign dr = ir[11:9];
  assign sr1 = ir[8:6];
  assign is_imm = ir[5];
  assign sr2 = ir[2:0];
  assign imm5 = {{11{ir[4]}}, ir[4:0]};

  // ADD
  assign add_rhs = is_imm ? imm5 : regs[sr2];
  assign add_result = regs[sr1] + add_rhs;

  // AND
  assign and_rhs = is_imm ? imm5 : regs[sr2];
  assign and_result = regs[sr1] & and_rhs;

  assign mem_addr = pc;
  assign mem_wdata = 16'h0000;
  assign mem_we = 1'b0;
  assign halted = state == STATE_HALT;

  always_ff @(posedge clk) begin
    if (reset) begin
      pc <= 16'h3000;
      ir <= 16'h0000;
      state <= STATE_FETCH;
      n <= 1'b0;
      z <= 1'b1;
      p <= 1'b0;
      for (i = 0; i < 8; i = i + 1) begin
        regs[i] <= 16'h0000;
      end
    end else begin
      case (state)
        STATE_FETCH: begin
          state <= STATE_LATCH_IR;
        end

        STATE_LATCH_IR: begin
          ir <= mem_rdata;
          pc <= pc + 16'd1;
          state <= STATE_DECODE;
        end

        STATE_DECODE: begin
          case (opcode)
            OP_ADD: state <= STATE_EXEC_ADD;
            OP_AND: state <= STATE_EXEC_AND;
            default: state <= STATE_HALT;
          endcase
        end

        STATE_EXEC_ADD: begin
          n <= add_result[15];
          z <= add_result == 16'h0000;
          p <= add_result != 16'h0000 && !add_result[15];
          regs[dr] <= add_result;
          state <= STATE_FETCH;
        end

        STATE_EXEC_AND: begin
          n <= and_result[15];
          z <= and_result == 16'h0000;
          p <= and_result != 16'h0000 && !and_result[15];
          regs[dr] <= and_result;
          state <= STATE_FETCH;
        end

        default: begin
          state <= STATE_HALT;
        end
      endcase
    end
  end
endmodule
