`timescale 1ns/1ps

module lc3_memory #(
  parameter string INIT_FILE = ""
) (
  input  logic        clk,
  input  logic [15:0] addr,
  output logic [15:0] rdata,
  input  logic [15:0] wdata,
  input  logic        we
);
  logic [15:0] mem [0:65535];

  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end
  end

  always_ff @(posedge clk) begin
    if (we) begin
      mem[addr] <= wdata;
    end

    rdata <= mem[addr];
  end
endmodule
