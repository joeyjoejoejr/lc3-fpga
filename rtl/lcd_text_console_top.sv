`timescale 1ns/1ps

module lcd_text_console_top #(
  parameter int CHAR_PERIOD = 50000
) (
  input  logic       clk,
  input  logic       reset,
  output logic [4:0] lcd_b,
  output logic [5:0] lcd_g,
  output logic [4:0] lcd_r,
  output logic       lcd_en,
  output logic       lcd_clk
);
  localparam int LCD_WIDTH = 480;
  localparam int LCD_HEIGHT = 272;
  localparam int CHAR_WIDTH = 8;
  localparam int CHAR_HEIGHT = 8;
  localparam int COLS = LCD_WIDTH / CHAR_WIDTH;
  localparam int ROWS = LCD_HEIGHT / CHAR_HEIGHT;
  localparam int COL_WIDTH = $clog2(COLS);
  localparam int ROW_WIDTH = $clog2(ROWS);
  localparam int MESSAGE_LEN = 65;

  logic [8:0] lcd_x;
  logic [8:0] lcd_y;
  logic [COL_WIDTH-1:0] cell_read_col;
  logic [ROW_WIDTH-1:0] cell_read_row;
  logic [7:0] cell_read_data;
  logic char_valid;
  logic [7:0] char_data;
  logic char_ready;
  logic [$clog2(CHAR_PERIOD)-1:0] char_delay;
  logic [$clog2(MESSAGE_LEN)-1:0] message_index;
  logic message_done;
  logic pll_lock;
  logic text_pixel_on;

  function automatic logic [7:0] message_char(
    input logic [$clog2(MESSAGE_LEN)-1:0] index
  );
    case (index)
      0: message_char = "L";
      1: message_char = "C";
      2: message_char = "-";
      3: message_char = "3";
      4: message_char = " ";
      5: message_char = "F";
      6: message_char = "P";
      7: message_char = "G";
      8: message_char = "A";
      9: message_char = " ";
      10: message_char = "T";
      11: message_char = "E";
      12: message_char = "X";
      13: message_char = "T";
      14: message_char = " ";
      15: message_char = "C";
      16: message_char = "O";
      17: message_char = "N";
      18: message_char = "S";
      19: message_char = "O";
      20: message_char = "L";
      21: message_char = "E";
      22: message_char = " ";
      23: message_char = "D";
      24: message_char = "E";
      25: message_char = "M";
      26: message_char = "O";
      27: message_char = 8'h0A;
      28: message_char = "T";
      29: message_char = "H";
      30: message_char = "E";
      31: message_char = " ";
      32: message_char = "Q";
      33: message_char = "U";
      34: message_char = "I";
      35: message_char = "C";
      36: message_char = "K";
      37: message_char = " ";
      38: message_char = "B";
      39: message_char = "R";
      40: message_char = "O";
      41: message_char = "W";
      42: message_char = "N";
      43: message_char = " ";
      44: message_char = "F";
      45: message_char = "O";
      46: message_char = "X";
      47: message_char = " ";
      48: message_char = "0";
      49: message_char = "1";
      50: message_char = "2";
      51: message_char = "3";
      52: message_char = "4";
      53: message_char = "5";
      54: message_char = "6";
      55: message_char = "7";
      56: message_char = "8";
      57: message_char = "9";
      58: message_char = 8'h0A;
      59: message_char = "S";
      60: message_char = "C";
      61: message_char = "R";
      62: message_char = "O";
      63: message_char = "L";
      64: message_char = 8'h0A;
      default: message_char = 8'h0A;
    endcase
  endfunction

  Gowin_rPLL_9MHz Gowin_rPLL_9Mhz(
    .clkout(lcd_clk),
    .lock(pll_lock),
    .clkin(clk)
  );

  lcd_timing timing (
    .lcd_clk(lcd_clk),
    .reset(reset),
    .x(lcd_x),
    .y(lcd_y),
    .lcd_en(lcd_en)
  );

  lc3_text_console #(
    .COLS(COLS),
    .ROWS(ROWS)
  ) console (
    .clk(lcd_clk),
    .reset(reset),
    .char_valid(char_valid),
    .char_data(char_data),
    .char_ready(char_ready),
    .cell_read_col(cell_read_col),
    .cell_read_row(cell_read_row),
    .cell_read_data(cell_read_data)
  );

  lc3_text_renderer #(
    .LCD_WIDTH(LCD_WIDTH),
    .LCD_HEIGHT(LCD_HEIGHT),
    .CHAR_WIDTH(CHAR_WIDTH),
    .CHAR_HEIGHT(CHAR_HEIGHT)
  ) renderer (
    .clk(lcd_clk),
    .reset(reset),
    .lcd_en(lcd_en),
    .lcd_x(lcd_x),
    .lcd_y(lcd_y),
    .cell_read_col(cell_read_col),
    .cell_read_row(cell_read_row),
    .cell_read_data(cell_read_data),
    .text_pixel_on(text_pixel_on),
    .lcd_r(lcd_r),
    .lcd_g(lcd_g),
    .lcd_b(lcd_b)
  );

  always_ff @(posedge lcd_clk) begin
    if (reset || !pll_lock) begin
      char_valid <= 1'b0;
      char_data <= 8'h00;
      char_delay <= '0;
      message_index <= '0;
      message_done <= 1'b0;
    end else begin
      char_valid <= 1'b0;
      if (!message_done && char_delay == CHAR_PERIOD - 1) begin
        char_delay <= '0;
        if (char_ready) begin
          char_valid <= 1'b1;
          char_data <= message_char(message_index);
          if (message_index == MESSAGE_LEN - 1) message_done <= 1'b1;
          else message_index <= message_index + 1'b1;
        end
      end else if (!message_done) begin
        char_delay <= char_delay + 1'b1;
      end
    end
  end
endmodule
