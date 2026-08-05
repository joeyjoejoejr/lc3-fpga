`timescale 1ns/1ps

module lc3_text_console #(
  parameter int COLS = 60,
  parameter int ROWS = 34,
  parameter int CELL_COUNT = COLS * ROWS,
  parameter int CELL_ADDR_WIDTH = $clog2(CELL_COUNT),
  parameter int COL_WIDTH = $clog2(COLS),
  parameter int ROW_WIDTH = $clog2(ROWS)
) (
  input  logic                         clk,
  input  logic                         reset,

  input  logic                         char_valid,
  input  logic [7:0]                   char_data,
  output logic                         char_ready,

  input  logic [COL_WIDTH-1:0]         cell_read_col,
  input  logic [ROW_WIDTH-1:0]         cell_read_row,
  output logic [7:0]                   cell_read_data
);
  localparam logic [7:0] ASCII_BS = 8'h08;
  localparam logic [7:0] ASCII_LF = 8'h0A;
  localparam logic [7:0] ASCII_CR = 8'h0D;

  logic [7:0] cells [0:CELL_COUNT-1];
  logic [COL_WIDTH-1:0] cursor_col;
  logic [ROW_WIDTH-1:0] cursor_row;
  logic [CELL_ADDR_WIDTH-1:0] cursor_addr;
  logic [CELL_ADDR_WIDTH-1:0] cell_read_addr;
  logic [ROW_WIDTH-1: 0] top_row;
  logic [ROW_WIDTH-1: 0] physical_read_row;
  logic [ROW_WIDTH-1: 0] physical_cursor_row;
  logic [COL_WIDTH-1: 0] clear_col;
  logic clearing;

  function automatic logic[ROW_WIDTH-1:0] next_row(
    input logic [ROW_WIDTH-1:0] row
  );
    if (row == ROWS - 1) next_row = '0;
    else next_row = row + 1'b1;
  endfunction

  assign char_ready = ~clearing;
  assign physical_read_row = top_row + cell_read_row < ROWS 
    ? top_row + cell_read_row
    : top_row + cell_read_row - ROWS;
  assign physical_cursor_row = top_row + cursor_row < ROWS 
    ? top_row + cursor_row
    : top_row + cursor_row - ROWS;

  assign cell_read_addr = physical_read_row * COLS + cell_read_col;
  assign cursor_addr = physical_cursor_row * COLS + cursor_col;

  initial begin
    for (int i = 0; i < CELL_COUNT; i++)
      cells[i] = 8'h00;
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      cursor_col <= '0;
      cursor_row <= '0;
      top_row <= '0;
      clearing <= '0;
      clear_col <= '0;
    end
    else if(clearing) begin
      cells[physical_cursor_row * COLS + clear_col] <= '0;
      clear_col <= clear_col + 1'b1;
      if (clear_col + 1'b1 == COLS) begin
        clearing <= '0;
        clear_col <= '0;
      end
    end
    else if(char_valid && char_ready) begin
      case (char_data)
        ASCII_BS: if(cursor_col != '0) begin
          cursor_col <= cursor_col - 1'b1;
          cells[cursor_addr - 1'b1] <= '0;
        end
        ASCII_LF: begin
          cursor_col <= '0;
          if (cursor_row == ROWS - 1) begin
            top_row <= next_row(top_row);
            clearing <= 1'b1;
          end
          else cursor_row <= cursor_row + 1'b1;
        end
        ASCII_CR: cursor_col <= '0;
        default: begin
          cells[cursor_addr] <= char_data;
          if (cursor_col == COLS - 1) begin
            cursor_col <= '0;
            if (cursor_row == ROWS - 1) begin
              top_row <= next_row(top_row);
              clearing <= 1'b1;
            end
            else cursor_row <= cursor_row + 1'b1;
          end
          else cursor_col <= cursor_col + 1'b1;
        end
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (reset) cell_read_data <= '0;
    else cell_read_data <= cells[cell_read_addr];
  end
endmodule
