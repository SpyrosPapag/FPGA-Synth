`timescale 1ns/1ps

module tb_display_cntrl;
  // Parameters
  localparam H_PIXELS = 800;
  localparam V_LINES  = 449;
  localparam VISIBLE_H = 640;
  localparam VISIBLE_V = 400;

  // Clock & reset
  reg reset = 1;
  reg pxlclk = 0;

  // DUT inputs
  reg  [7:0] character = 8'h00;  // no note → just pentagram
  wire       H_SYNC, V_SYNC;
  wire [8:0] RGB;
  wire       display_en;
  wire[9:0] px,py;
  // Drive pixel clock
  always #1 pxlclk = ~pxlclk;

  // Release reset after a few cycles
  initial begin
    #5;
    reset = 0;
  end

  // Instantiate your display controller
  display_cntrl dut (
    .reset(reset),
    .pxlclk(pxlclk),
    .character(character),
    .H_SYNC(H_SYNC),
    .V_SYNC(V_SYNC),
    .RGB(RGB),

    .display_en(display_en),
    .px(px),
    .py(py)
  );

  // Frame capture
  integer   frame_file;
  integer   x, y;
  reg [9:0] pixel_count = 0;
  reg [8:0] black = 9'd0;

  // We know H display for 640, V display for 400
  always @(posedge pxlclk) begin
    if (reset) begin
      pixel_count <= 0;
    end else begin
      pixel_count <= pixel_count + 1;
    end
  end

  // Horizontal position: count[8:0] mod 800  → pixel_in_line
  // Vertical position:   count / 800        → line_number
  wire [9:0] pixel_in_line = pixel_count % H_PIXELS;
  wire [9:0] line_number   = pixel_count / H_PIXELS;
  wire display_en_old = (pixel_in_line < VISIBLE_H) && (line_number < VISIBLE_V);

  // Main capture process
  initial begin
    // Open the output file
    frame_file = $fopen("frame.txt", "w");
    if (frame_file == 0) begin
      $display("ERROR: cannot open frame.txt for writing");
      $finish;
    end

    // Wait for end of reset
    @(negedge reset);

    // Wait for start of first visible pixel
    wait (display_en);

    // Now capture exactly 400 lines × 640 pixels
    for (y = 0; y < VISIBLE_V; ) begin
      for (x = 0; x < VISIBLE_H; ) begin
        @(posedge pxlclk);
        if (display_en && px == x && py == y) begin
          // now we know exactly we're looking at pixel (x,y)
          if (RGB != black)
            $fwrite(frame_file, "1");
          else
            $fwrite(frame_file, "0");
          x = x + 1;    // only advance once you’ve captured this pixel
        end
        // otherwise we’re either in blanking or haven't yet reached (x,y) → wait
      end
      $fwrite(frame_file, "\n");
      y = y + 1;       // move to next line only after x done
    end

    $fclose(frame_file);
    $display("Frame capture complete: frame.txt");
    $finish;
  end

  // Stop simulation after one full frame + a few cycles
  initial begin
    #((H_PIXELS * V_LINES + 100) * 40);
    $display("Timeout: ending sim");
    $finish;
  end
endmodule


module timing_tb;
  reg reset, pxlclk;
  wire H_SYNC, V_SYNC;

  disp_timing DUT (
      .reset(reset),
      .pxlclk(pxlclk),
      .H_SYNC(H_SYNC),
      .V_SYNC(V_SYNC)
  );

  always #1 pxlclk = ~pxlclk;

  initial begin
      pxlclk = 0;
      reset = 1;
      #5 reset = 0;

    #1400000 $finish;
  end
endmodule
