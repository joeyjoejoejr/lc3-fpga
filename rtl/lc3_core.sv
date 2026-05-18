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
  typedef enum logic [3:0] {
    STATE_FETCH,
    STATE_FETCH_WAIT,
    STATE_LATCH_IR,
    STATE_DECODE,
    STATE_EXEC_ALU,
    STATE_EXEC_BR,
    STATE_EXEC_LEA,
    STATE_FETCH_LD,
    STATE_FETCH_LD_WAIT,
    STATE_EXEC_LD,
    STATE_HALT
  } state_t;

  localparam logic[3:0] OP_BR = 4'b0000;
  localparam logic[3:0] OP_ADD = 4'b0001;
  localparam logic[3:0] OP_LD = 4'b0010;
  localparam logic[3:0] OP_AND = 4'b0101;
  localparam logic[3:0] OP_NOT = 4'b1001;
  localparam logic[3:0] OP_LEA = 4'b1110;

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

  // BR
  logic [2:0] nzp;
  logic [15:0] pc_offset9;

  logic [15:0] add_rhs;
  logic [15:0] add_result;

  logic [15:0] and_rhs;
  logic [15:0] and_result;

  logic [15:0] not_result;
  logic [15:0] alu_result;

  logic [15:0] lea_result;

  assign opcode = ir[15:12];
  assign dr = ir[11:9];
  assign sr1 = ir[8:6];
  assign is_imm = ir[5];
  assign sr2 = ir[2:0];
  assign imm5 = {{11{ir[4]}}, ir[4:0]};

  // BR
  assign nzp = ir[11:9];
  assign pc_offset9 = {{7{ir[8]}}, ir[8:0]};

  // ADD
  assign add_rhs = is_imm ? imm5 : regs[sr2];
  assign add_result = regs[sr1] + add_rhs;

  // AND
  assign and_rhs = is_imm ? imm5 : regs[sr2];
  assign and_result = regs[sr1] & and_rhs;

  // NOT
  assign not_result = ~regs[sr1];

  assign alu_result = opcode == OP_ADD ?
    add_result : (opcode == OP_AND) ?
    and_result : (opcode == OP_NOT) ?
    not_result : 16'hxxxx;

  // LEA
  assign lea_result = pc + pc_offset9;

  assign mem_wdata = 16'h0000;
  assign mem_we = 1'b0;
  assign halted = state == STATE_HALT;

  function automatic logic[2:0] flags_for(input logic [15:0] value);
    flags_for[2] = value[15]; //N
    flags_for[1] = value == 16'h0000; //Z
    flags_for[0] = value != 16'h0000 && !value[15]; //P
  endfunction

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
      mem_addr <= 16'h0000;
    end else begin
      case (state)
        STATE_FETCH: begin
          mem_addr <= pc;
          state <= STATE_FETCH_WAIT;
        end

        STATE_FETCH_WAIT: state <= STATE_LATCH_IR;

        STATE_LATCH_IR: begin
          ir <= mem_rdata;
          pc <= pc + 16'd1;
          state <= STATE_DECODE;
        end

        STATE_DECODE: begin
          case (opcode)
            OP_BR: state <= STATE_EXEC_BR;
            OP_ADD, OP_AND, OP_NOT: state <= STATE_EXEC_ALU;
            OP_LEA: state <= STATE_EXEC_LEA;
            OP_LD: state <= STATE_FETCH_LD;
            default: state <= STATE_HALT;
          endcase
        end

        STATE_EXEC_BR: begin
          if(|(nzp & {n,z,p})) pc <= pc + pc_offset9;
          state <= STATE_FETCH;
        end

        STATE_EXEC_ALU: begin
          { n, z, p } <= flags_for(alu_result);
          regs[dr] <= alu_result;
          state <= STATE_FETCH;
        end

        STATE_EXEC_LEA: begin
          { n, z, p } <= flags_for(lea_result);
          regs[dr] <= lea_result;
          state <= STATE_FETCH;
        end

        STATE_FETCH_LD: begin
          mem_addr <= pc + pc_offset9;
          state <= STATE_FETCH_LD_WAIT;
        end

        STATE_FETCH_LD_WAIT: state <= STATE_EXEC_LD;

        STATE_EXEC_LD: begin
          { n, z, p } <= flags_for(mem_rdata);
          regs[dr] <= mem_rdata;
          state <= STATE_FETCH;
        end

        default: begin
          state <= STATE_HALT;
        end
      endcase
    end
  end
endmodule
