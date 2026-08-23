`timescale 1ns/1ps

module lc3_verilator_top #(
  parameter string INIT_FILE = ""
) (
  input  logic        clk,
  input  logic        reset,
  input  logic [15:0] reset_pc,

  output logic [15:0] pc,
  output logic [15:0] ir,
  output logic [15:0] psr,
  output logic [15:0] mem_addr,
  output logic        mem_we,

  // Loader
  input logic        loader_we,
  input logic [15:0] loader_addr, 
  input logic [15:0] loader_wdata 

);
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;

  logic [15:0] wdata;
  logic [15:0] addr;
  logic we;

  assign wdata = loader_we ? loader_wdata : mem_wdata;
  assign addr = loader_we ? loader_addr : mem_addr;
  assign we = loader_we || mem_we;

  lc3_core core (
    .clk(clk),
    .reset(reset),
    .machine_halt(1'b0),
    .reset_pc(reset_pc),
    .mem_addr(mem_addr),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_we(mem_we),
    .pc(pc),
    .ir(ir),
    .mpr(16'hffff),
    .psr(psr),
    .irq_pending(1'b0),
    .irq_priority(3'b000),
    .irq_vector(8'h00),
    .pennsim_privilege_mode(1'b1)
  );

  lc3_memory #(
    .INIT_FILE(INIT_FILE)
  ) memory (
    .clk(clk),
    .addr(addr),
    .rdata(mem_rdata),
    .wdata(wdata),
    .we(we)
  );
endmodule
