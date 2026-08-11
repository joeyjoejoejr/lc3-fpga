`timescale 1ns/1ps

module lc3_core
#(parameter logic [15:0] start_ssp = 16'h3000)
(
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
  input logic [15:0] mpr,
  output logic [15:0] psr,

  // Interrupts
  input logic irq_pending,
  input logic [2:0] irq_priority,
  input logic [7:0] irq_vector,

  // Configuration
  input logic pennsim_privilege_mode
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
    STATE_HALT,
    STATE_PC_WRITE,
    STATE_PSR_WRITE,
    STATE_INT_PUSH_PSR,
    STATE_INT_PUSH_PC,
    STATE_INT_FETCH_VECTOR,
    STATE_INT_WRITE_COMPLETE,
    STATE_INT_SET_PC
  } state_t;

  localparam logic[3:0] OP_BR = 4'b0000;
  localparam logic[3:0] OP_ADD = 4'b0001;
  localparam logic[3:0] OP_LD = 4'b0010;
  localparam logic[3:0] OP_ST = 4'b0011;
  localparam logic[3:0] OP_JSR = 4'b0100;
  localparam logic[3:0] OP_AND = 4'b0101;
  localparam logic[3:0] OP_LDR = 4'b0110;
  localparam logic[3:0] OP_STR = 4'b0111;
  localparam logic[3:0] OP_RTI = 4'b1000;
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
  logic pc_loaded;

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

  // stack pointers
  logic [15:0] ssp;
  logic [15:0] usp;

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

  function automatic logic user_can_access(input logic [15:0] addr);
    user_can_access = is_supervisor_psr(psr) || mpr[addr[15:12]];
  endfunction

  function automatic logic is_supervisor_psr(input logic [15:0] value);
    is_supervisor_psr = pennsim_privilege_mode ? value[15] : !value[15];
  endfunction

  function automatic logic user_mode_bit();
    user_mode_bit = ~pennsim_privilege_mode;
  endfunction

  function automatic logic privilege_mode_bit();
    privilege_mode_bit = pennsim_privilege_mode;
  endfunction

  task automatic issue_read(input logic [15:0] addr, input state_t next_state);
    if (!user_can_access(addr)) begin
      mem_we <= 1'b0;
      state <= STATE_HALT;
    end else begin
      mem_addr <= addr;
      return_state <= next_state;
      state <= STATE_MEM_WAIT;
    end
  endtask;

  task automatic issue_write(
    input logic [15:0] addr,
    input logic [15:0] data,
    input state_t next_state
  );
    if (!user_can_access(addr)) begin
      mem_we <= 1'b0;
      state <= STATE_HALT;
    end else begin
      mem_addr <= addr;
      mem_wdata <= data;
      mem_we <= 1'b1;
      state <= next_state;
    end
  endtask;

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
      psr <= 16'h0002;
      psr[15] <= privilege_mode_bit();
      pc_loaded <= 1'b0;
      ssp <= start_ssp;
      usp <= '0;
    end else if (machine_halt) begin
    end else begin
      case (state)
        STATE_FETCH: begin
          // Interrupt handling
          if (irq_pending && irq_priority > psr[10:8]) begin
            if (!is_supervisor_psr(psr)) begin
              usp <= regs[6];
              regs[6] <= ssp;
            end

            state <= STATE_INT_PUSH_PSR;
          end else issue_read(pc, STATE_LATCH_IR);
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
            OP_RTI:
              if(!is_supervisor_psr(psr)) state <= STATE_HALT;
              else state <= STATE_FETCH_MEM;
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
          if (opcode == OP_LD) issue_read(pc_offset_addr, STATE_REG_WRITEBACK);
          else if (opcode == OP_LDI) issue_read(mem_rdata, STATE_REG_WRITEBACK);
          else if (opcode == OP_RTI && !pc_loaded) issue_read(regs[6], STATE_PC_WRITE);
          else if (opcode == OP_RTI && pc_loaded) issue_read(regs[6] + 1, STATE_PSR_WRITE);
          else issue_read(abs_addr, STATE_REG_WRITEBACK);
        end

        STATE_MEM_WAIT: state <= return_state;

        STATE_PC_WRITE: begin
          pc <= mem_rdata;
          pc_loaded <= 1'b1;
          state <= STATE_FETCH_MEM;
        end

        STATE_PSR_WRITE: begin
          if (!is_supervisor_psr(mem_rdata)) begin
            ssp <= regs[6] + 2;
            regs[6] <= usp;
          end else regs[6] <= regs[6] + 2;
          psr <= mem_rdata;
          pc_loaded <= 1'b0;
          state <= STATE_FETCH;
        end

        STATE_REG_WRITEBACK: begin
          psr[2:0] <= flags_for(mem_rdata);
          regs[dr] <= mem_rdata;
          state <= STATE_FETCH;
        end

        STATE_EXEC_STORE: begin
          if (opcode == OP_ST) issue_write(pc_offset_addr, regs[sr], STATE_WRITE_STORE);
          else if (opcode == OP_STI) issue_write(mem_rdata, regs[sr], STATE_WRITE_STORE);
          else issue_write(abs_addr, regs[sr], STATE_WRITE_STORE);
        end

        STATE_WRITE_STORE: begin
          mem_we <= 1'b0;
          state <= STATE_FETCH;
        end

        STATE_EXEC_JMP: begin
          pc <= regs[br];
          state <= STATE_FETCH;
          if(is_jmpt_or_rtt) psr[15] <= user_mode_bit();
        end

        STATE_EXEC_JSR: begin
          regs[7] <= pc;
          if(is_jsr) pc <= pc_offset_11_addr;
          else pc <= regs[br];
          state <= STATE_FETCH;
        end

        STATE_FETCH_INDIRECT_PTR: begin
          if(opcode == OP_LDI) issue_read(pc_offset_addr, STATE_FETCH_MEM);
          else if(opcode == OP_TRAP) begin
            mem_addr <= trap_vec;
            return_state <= STATE_EXEC_TRAP;
            state <= STATE_MEM_WAIT;
          end
          else issue_read(pc_offset_addr, STATE_EXEC_STORE);
        end

        STATE_EXEC_TRAP: begin
          regs[7] <= pc;
          pc <= mem_rdata;
          state <= STATE_FETCH;
          psr[15] <= privilege_mode_bit();
        end

        STATE_INT_PUSH_PSR: begin
          regs[6] <= regs[6] - 1;
          issue_write(regs[6] - 1, psr, STATE_INT_PUSH_PC);
        end

        STATE_INT_PUSH_PC: begin
          regs[6] <= regs[6] - 1;
          issue_write(regs[6] - 1, pc, STATE_INT_WRITE_COMPLETE);
        end

        STATE_INT_WRITE_COMPLETE: begin
          mem_we <= 0;
          issue_read(16'h0100 + irq_vector, STATE_INT_SET_PC);
        end

        STATE_INT_SET_PC: begin
          pc <= mem_rdata;
          psr[10:8] <= irq_priority;
          psr[15] <= privilege_mode_bit();
          state <= STATE_FETCH;
        end

        default: begin
          state <= STATE_HALT;
        end
      endcase
    end
  end
endmodule
