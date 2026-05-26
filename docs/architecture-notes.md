# Architecture Notes

## Behavioral vs. Textbook Datapath

For a first FPGA LC-3, prefer a synthesizable behavioral RTL design over a
literal reproduction of the textbook datapath.

Good first shape:

```text
registers + PC + IR + condition codes
        |
        v
multi-cycle control FSM
        |
        v
single memory interface
```

This still builds real hardware. It just lets SystemVerilog express some muxing
and control decisions directly instead of forcing every textbook bus and gate to
be named on day one.

The textbook datapath is still useful as the reference for state transitions:

```text
FETCH -> DECODE -> EVAL_ADDR/EXECUTE -> MEMORY -> WRITEBACK
```

## First CPU Feature

Start with `ADD` register/immediate form. It exercises:

- instruction decoding
- register reads
- ALU operation
- register writeback
- condition-code update

Then add `AND`, because it has the same instruction shape. Then add `NOT`,
because it is the simplest unary operation.

After that, add `BR`; branches force you to trust the condition codes and PC
update path.

## RGB LCD Video Path

The RGB LCD is not a memory-mapped device by itself. It is a continuously
running video pipeline that reads pixels from video memory and drives the LCD
pins every pixel clock.

A good first architecture is:

```text
LC-3 core
  |
  | CPU reads/writes
  v
memory controller
  |
  | video read port
  v
framebuffer scanout -> RGB pixel -> LCD pins
```

The LC-3-visible framebuffer can stay small:

```text
xC000-xFDFF: 128-wide framebuffer, 16-bit pixels
```

The LCD is larger than the LC-3 framebuffer. During scanout, convert the current
LCD pixel coordinate into an LC-3 framebuffer coordinate:

```text
fb_x = (video_x - left_margin) / scale
fb_y = (video_y - top_margin) / scale
```

For the 480x272 LCD and a 128x128 LC-3 framebuffer:

```text
scale 2: 128x128 becomes 256x256
left/right margin: (480 - 256) / 2 = 112
top/bottom margin: (272 - 256) / 2 = 8
```

Pixels outside the scaled framebuffer can be black or a border color. This
avoids storing a full 480x272 framebuffer.

## LCD Timing

The LCD expects raw parallel video timing. The FPGA must generate:

```text
pixel clock
active x/y coordinates
horizontal sync
vertical sync
data enable / active-video region
RGB pixel data
backlight / display enable, if required by the panel
```

For the common Sipeed 4.3-inch panel, the active resolution is:

```text
active:       480 x 272
pixel clock:  about 9 MHz
```

The visible area is only part of each line/frame. The rest is blanking time,
just like VGA/HDMI timing:

```text
horizontal: active pixels + front porch + sync + back porch
vertical:   active lines  + front porch + sync + back porch
```

Your timing generator counts through the full totals. It asserts active-video
or data-enable only inside the 480x272 region and asserts sync during the sync
intervals. The RGB pins should generally be driven with valid color during the
active region and black during blanking.

Start from a known-good Sipeed RGB LCD example for the exact timing and pinout.
Then replace its test pattern with your framebuffer scanout.

Even if the desired LCD pixel clock divides evenly from the 27 MHz board clock,
using the example PLL is still reasonable. The PLL creates a proper clock on
the FPGA clock network and provides a `lock` signal for reset sequencing.

## LCD Color Demo Split

Keep the first LCD demo independent of the LC-3. A clean split is:

```text
lcd_color_top
  board clock/reset pins
  Gowin_rPLL_9MHz
  lcd_timing
  lcd_color_bars
  LCD output pins
```

Suggested responsibilities:

```text
lcd_color_top
  Wire the board pins to the internal modules. Keep board-specific polarity,
  PLL lock, and reset combination here.

Gowin_rPLL_9MHz
  Vendor PLL wrapper. 27 MHz board clock in, 9 MHz LCD pixel clock out.

lcd_timing
  Generate x/y counters, data-enable, and any LCD sync/control signals. This
  module should not know about color bars or the LC-3.

lcd_color_bars
  Convert x/y/de into RGB565 color output. This is the throwaway/demo pixel
  source.
```

That split makes the next step simple: keep `lcd_color_top`, the PLL, and
`lcd_timing`, then replace `lcd_color_bars` with an LC-3 framebuffer scanout
module.

## Display vs. Console

Keep these separate at first:

```text
LC-3 graphics framebuffer -> RGB LCD
LC-3 console DDR/DSR      -> UART over USB
```

The RGB LCD panel is a raw pixel panel, not a terminal. If the project later
needs console text on-screen, add a text renderer as a separate video layer
after the framebuffer path works. HDMI can remain an optional later display
target using the same framebuffer scanout idea with a different output encoder.
