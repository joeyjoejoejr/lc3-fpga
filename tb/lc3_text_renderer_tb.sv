`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_text_renderer_tb;
  localparam int LCD_WIDTH = 480;
  localparam int LCD_HEIGHT = 272;
  localparam int CHAR_WIDTH = 8;
  localparam int CHAR_HEIGHT = 8;
  localparam int COLS = LCD_WIDTH / CHAR_WIDTH;
  localparam int ROWS = LCD_HEIGHT / CHAR_HEIGHT;
  localparam int COL_WIDTH = $clog2(COLS);
  localparam int ROW_WIDTH = $clog2(ROWS);

  logic clk = 1'b0;
  logic reset;
  logic lcd_en;
  logic [8:0] lcd_x;
  logic [8:0] lcd_y;
  logic [COL_WIDTH-1:0] cell_read_col;
  logic [ROW_WIDTH-1:0] cell_read_row;
  logic [7:0] cell_read_data;
  logic text_pixel_on;
  logic [4:0] lcd_r;
  logic [5:0] lcd_g;
  logic [4:0] lcd_b;

  always #5 clk = ~clk;

  lc3_text_renderer #(
    .LCD_WIDTH(LCD_WIDTH),
    .LCD_HEIGHT(LCD_HEIGHT),
    .CHAR_WIDTH(CHAR_WIDTH),
    .CHAR_HEIGHT(CHAR_HEIGHT)
  ) dut (
    .clk(clk),
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

  task automatic expect_cell_request(
    input string name,
    input logic [COL_WIDTH-1:0] expected_col,
    input logic [ROW_WIDTH-1:0] expected_row
  );
    begin
      @(posedge clk);
      #1;

      if (cell_read_col !== expected_col || cell_read_row !== expected_row) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       actual   col=%0d row=%0d", cell_read_col, cell_read_row);
        $display("       expected col=%0d row=%0d", expected_col, expected_row);
        $fatal(1);
      end
    end
  endtask

  task automatic expect_text_pixel(
    input string name,
    input logic expected_on,
    input logic [4:0] expected_r,
    input logic [5:0] expected_g,
    input logic [4:0] expected_b
  );
    begin
      @(posedge clk);
      #1;

      if (text_pixel_on !== expected_on ||
          lcd_r !== expected_r ||
          lcd_g !== expected_g ||
          lcd_b !== expected_b) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       actual   on=%0b rgb=%02h/%02h/%02h",
                 text_pixel_on, lcd_r, lcd_g, lcd_b);
        $display("       expected on=%0b rgb=%02h/%02h/%02h",
                 expected_on, expected_r, expected_g, expected_b);
        $fatal(1);
      end
    end
  endtask

  task automatic expect_text_pixel_now(
    input string name,
    input logic expected_on,
    input logic [4:0] expected_r,
    input logic [5:0] expected_g,
    input logic [4:0] expected_b
  );
    begin
      #1;

      if (text_pixel_on !== expected_on ||
          lcd_r !== expected_r ||
          lcd_g !== expected_g ||
          lcd_b !== expected_b) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       actual   on=%0b rgb=%02h/%02h/%02h",
                 text_pixel_on, lcd_r, lcd_g, lcd_b);
        $display("       expected on=%0b rgb=%02h/%02h/%02h",
                 expected_on, expected_r, expected_g, expected_b);
        $fatal(1);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    lcd_en = 1'b0;
    lcd_x = 9'd0;
    lcd_y = 9'd0;
    cell_read_data = 8'h00;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    lcd_en = 1'b0;
    lcd_x = 9'd18;
    lcd_y = 9'd8;
    cell_read_data = "A";

    expect_cell_request("blank_request", 0, 0);
    expect_text_pixel("blank_pixel", 1'b0, 5'h00, 6'h00, 5'h00);

    lcd_en = 1'b1;
    lcd_x = 9'd18;
    lcd_y = 9'd8;
    cell_read_data = "A";

    expect_cell_request("cell_request", 2, 1);
    expect_text_pixel("draw_A_pixel", 1'b1, 5'h1F, 6'h3F, 5'h1F);

    lcd_x = 9'd17;
    lcd_y = 9'd8;
    cell_read_data = "A";

    expect_cell_request("off_cell_request", 2, 1);
    expect_text_pixel("draw_A_off_pixel", 1'b0, 5'h00, 6'h00, 5'h00);

    lcd_x = 9'd18;
    lcd_y = 9'd8;
    cell_read_data = " ";

    expect_cell_request("space_cell_request", 2, 1);
    expect_text_pixel("draw_space_pixel", 1'b0, 5'h00, 6'h00, 5'h00);

    lcd_x = 9'd18;
    lcd_y = 9'd8;
    cell_read_data = "A";

    expect_cell_request("pipe_request_on", 2, 1);

    lcd_x = 9'd17;
    lcd_y = 9'd8;
    cell_read_data = "A";

    expect_text_pixel_now("pipe_first_on", 1'b1, 5'h1F, 6'h3F, 5'h1F);
    expect_cell_request("pipe_request_off", 2, 1);
    expect_text_pixel("pipe_second_off", 1'b0, 5'h00, 6'h00, 5'h00);

    print_case_pass("text_renderer");
    $finish;
  end
endmodule
