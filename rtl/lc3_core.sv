`timescale 1ns/1ps

module lc3_core (
  input  logic        clk,
  input  logic        reset,
  input  logic        machine_halt,
  input  logic [15:0] reset_pc,

  output logic [15:0] mem_addr,
  input  logic [15:0] mem_rdata,
  output logic [15:0] mem_wdata,
  output logic        mem_we,

  output logic [15:0] pc,
  output logic [15:0] ir,
  output logic [15:0] psr
);
  typedef enum logic [4:0] {
    STATE_FETCH,
    STATE_LATCH_IR,
    STATE_DECODE,
    STATE_EXEC_ALU,
    STATE_EXEC_BR,
    STATE_EXEC_LEA,
    STATE_FETCH_MEM,
    STATE_MEM_WAIT,
    STATE_REG_WRITEBACK,
    STATE_EXEC_STORE,
    STATE_WRITE_STORE,
    STATE_EXEC_JMP,
    STATE_EXEC_JSR,
    STATE_FETCH_INDIRECT_PTR,
    STATE_EXEC_TRAP,
    STATE_HALT
  } state_t;

  localparam logic[3:0] OP_BR = 4'b0000;
  localparam logic[3:0] OP_ADD = 4'b0001;
  localparam logic[3:0] OP_LD = 4'b0010;
  localparam logic[3:0] OP_ST = 4'b0011;
  localparam logic[3:0] OP_JSR = 4'b0100;
  localparam logic[3:0] OP_AND = 4'b0101;
  localparam logic[3:0] OP_LDR = 4'b0110;
  localparam logic[3:0] OP_STR = 4'b0111;
  localparam logic[3:0] OP_NOT = 4'b1001;
  localparam logic[3:0] OP_LDI = 4'b1010;
  localparam logic[3:0] OP_STI = 4'b1011;
  localparam logic[3:0] OP_JMP = 4'b1100;
  localparam logic[3:0] OP_LEA = 4'b1110;
  localparam logic[3:0] OP_TRAP = 4'b1111;

  state_t state, return_state;
  logic [15:0] regs [0:7];
  logic halted;
  integer i;


  // Instruction extraction
  logic [3:0] opcode;
  logic [2:0] dr;
  logic [2:0] sr;
  logic [2:0] sr1;
  logic [2:0] br;
  logic [2:0] sr2;
  logic is_imm;
  logic [15:0] imm5;
  logic is_jsr;
  logic is_jmpt_or_rtt;

  // BR
  logic [2:0] nzp;

  logic [15:0] pc_offset9;
  logic [15:0] pc_offset_addr;

  logic [15:0] pc_offset11;
  logic [15:0] pc_offset_11_addr;

  logic [15:0] offset6;
  logic [15:0] abs_addr;

  logic [15:0] trap_vec;

  logic [15:0] add_rhs;
  logic [15:0] add_result;

  logic [15:0] and_rhs;
  logic [15:0] and_result;

  logic [15:0] not_result;
  logic [15:0] alu_result;

  logic [15:0] lea_result;

  assign opcode = ir[15:12];
  assign dr = ir[11:9];
  assign sr = ir[11:9];
  assign sr1 = ir[8:6];
  assign br = ir[8:6];
  assign is_imm = ir[5];
  assign sr2 = ir[2:0];
  assign imm5 = {{11{ir[4]}}, ir[4:0]};
  assign is_jsr = ir[11];
  assign is_jmpt_or_rtt = ir[0];

  assign nzp = ir[11:9];
  assign pc_offset9 = {{7{ir[8]}}, ir[8:0]};
  assign pc_offset_addr = pc + pc_offset9;

  assign pc_offset11 = {{5{ir[10]}}, ir[10:0]};
  assign pc_offset_11_addr = pc + pc_offset11;

  assign offset6 = {{10{ir[5]}}, ir[5:0]};
  assign abs_addr = regs[br] + offset6;

  assign trap_vec = {8'h00, ir[7:0]};

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
  assign lea_result = pc_offset_addr;

  assign halted = state == STATE_HALT;

  function automatic logic[2:0] flags_for(input logic [15:0] value);
    flags_for[2] = value[15]; //N
    flags_for[1] = value == 16'h0000; //Z
    flags_for[0] = value != 16'h0000 && !value[15]; //P
  endfunction

  always_ff @(posedge clk) begin
    if (reset) begin
      pc <= reset_pc;
      ir <= 16'h0000;
      state <= STATE_FETCH;
      for (i = 0; i < 8; i = i + 1) begin
        regs[i] <= 16'h0000;
      end
      mem_addr <= 16'h0000;
      mem_wdata <= 16'h0000;
      mem_we <= 1'b0;
      return_state <= STATE_HALT;
      psr <= 16'h8002;
    end else if (machine_halt) begin
    end else begin
      case (state)
        STATE_FETCH: begin
          mem_addr <= pc;
          return_state <= STATE_LATCH_IR;
          state <= STATE_MEM_WAIT;
        end

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
            OP_LD, OP_LDR: state <= STATE_FETCH_MEM;
            OP_ST, OP_STR: state <= STATE_EXEC_STORE;
            OP_LDI, OP_STI: state <= STATE_FETCH_INDIRECT_PTR;
            OP_JMP: state <= STATE_EXEC_JMP;
            OP_JSR: state <= STATE_EXEC_JSR;
            OP_TRAP: state <= STATE_FETCH_INDIRECT_PTR;
            default: state <= STATE_HALT;
          endcase
        end

        STATE_EXEC_BR: begin
          if(|(nzp & psr[2:0])) pc <= pc_offset_addr;
          state <= STATE_FETCH;
        end

        STATE_EXEC_ALU: begin
          psr[2:0] <= flags_for(alu_result);
          regs[dr] <= alu_result;
          state <= STATE_FETCH;
        end

        STATE_EXEC_LEA: begin
          psr[2:0] <= flags_for(lea_result);
          regs[dr] <= lea_result;
          state <= STATE_FETCH;
        end

        STATE_FETCH_MEM: begin
          if (opcode == OP_LD) mem_addr <= pc_offset_addr;
          else if (opcode == OP_LDI) mem_addr <= mem_rdata;
          else mem_addr <= abs_addr;
          return_state <= STATE_REG_WRITEBACK;
          state <= STATE_MEM_WAIT;
        end

        STATE_MEM_WAIT: state <= return_state;

        STATE_REG_WRITEBACK: begin
          psr[2:0] <= flags_for(mem_rdata);
          regs[dr] <= mem_rdata;
          state <= STATE_FETCH;
        end

        STATE_EXEC_STORE: begin
          mem_wdata <= regs[sr];
          if (opcode == OP_ST) mem_addr <= pc_offset_addr;
          else if (opcode == OP_STI) mem_addr <= mem_rdata;
          else mem_addr <= abs_addr;
          mem_we <= 1'b1;
          state <= STATE_WRITE_STORE;
        end

        STATE_WRITE_STORE: begin
          mem_we <= 1'b0;
          state <= STATE_FETCH;
        end

        STATE_EXEC_JMP: begin
          pc <= regs[br];
          state <= STATE_FETCH;
          if(is_jmpt_or_rtt) psr[15] <= 1'b0;
        end

        STATE_EXEC_JSR: begin
          regs[7] <= pc;
          if(is_jsr) pc <= pc_offset_11_addr;
          else pc <= regs[br];
          state <= STATE_FETCH;
        end

        STATE_FETCH_INDIRECT_PTR: begin
          mem_addr <= pc_offset_addr;
          if(opcode == OP_LDI) return_state <= STATE_FETCH_MEM;
          else if(opcode == OP_TRAP) begin
            mem_addr <= trap_vec;
            return_state <= STATE_EXEC_TRAP;
          end
          else return_state <= STATE_EXEC_STORE;
          state <= STATE_MEM_WAIT;
        end

        STATE_EXEC_TRAP: begin
          regs[7] <= pc;
          pc <= mem_rdata;
          state <= STATE_FETCH;
          if(is_jmpt_or_rtt) psr[15] <= 1'b1;
        end

        default: begin
          state <= STATE_HALT;
        end
      endcase
    end
  end
endmodule
