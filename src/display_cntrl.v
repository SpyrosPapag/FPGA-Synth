module display_cntrl #(
    parameter[9:0] spacing = 25,//20,
    parameter[9:0] thickness = 5,
    parameter[9:0] top = 50//135
    )(
    input reset, pxlclk,
    input[7:0] character,
    output H_SYNC, V_SYNC,
    output[8:0] RGB,
 
    output display_en, // for testing
    output[9:0] px, py // for testing
);


    // display timing
    // wire display_en; // commented for testing
    wire[18:0] position;
    
    assign px = position[18:9]; // for testing
    assign py = position[8:0]; // for testing

    disp_timing timing (
        .reset(reset),
        .pxlclk(pxlclk),
        .H_SYNC(H_SYNC),
        .V_SYNC(V_SYNC),
        .display(display_en),
        .position(position)
    );

    // display output
    wire[8:0] buff_RGB;

    // send black if in blanking zone
    assign RGB = (display_en)? buff_RGB : 9'd0;

    disp_out #(
        .spacing(spacing),
        .thickness(thickness),
        .top(top)
    ) out (
        .character(character),
        .position(position),
        .buff_RGB(buff_RGB)
    );
    
endmodule

module disp_out #(
    parameter[9:0] spacing = 20,
    parameter[9:0] thickness = 10,
    parameter[9:0] top = 135
    )(
    input[7:0] character,
    input[18:0] position,
    output[8:0] buff_RGB
    );

    wire signed[9:0] px, py;
    assign px = position[18:9];
    assign py = position[8:0];
    
    // constant pentagram
    wire[8:0] pentagram;
    assign pentagram = ((py >= top)                        & (py <= (top+thickness)))                      | // line 1
                       ((py >= (top+spacing))              & (py <= (top+spacing+thickness)))              | // line 2
                       ((py >= (top+(spacing<<1)))         & (py <= (top+(spacing<<1)+thickness)))         | // line 3
                       ((py >= (top+(spacing<<1)+spacing)) & (py <= (top+(spacing<<1)+spacing+thickness))) | // line 4
                       ((py >= (top+(spacing<<2)))         & (py <= (top+(spacing<<2)+thickness)))         ? // line 5
                       9'b111111111 : 9'd0;

    // notes
    wire[3:0] note;
    wire[8:0] mask;

    note_mask #(
        .spacing(spacing),
        .thickness(thickness),
        .top(top)     
    ) masks (
        .note(note),
        .position(position),
        .mask(mask)
    );

    assign note = (character == 8'h23)? 4'd0  : // DO
                  (character == 8'h2D)? 4'd1  : // RE
                  (character == 8'h3A)? 4'd2  : // MI
                  (character == 8'h2B)? 4'd3  : // FA
                  (character == 8'h1B)? 4'd4  : // SOL
                  (character == 8'h4B)? 4'd5  : // LA
                  (character == 8'h21)? 4'd6  : // SI
				  (character == 8'h16)? 4'd7  : // DO/C major
				  (character == 8'h1E)? 4'd8  : // MI/E major
				  (character == 8'h26)? 4'd9  : // FA/F major
				  (character == 8'h25)? 4'd10 : // SOL/G major
                                        4'd11 ; // ESC
	
    assign buff_RGB = pentagram | mask;
endmodule

module note_mask#(
    parameter[9:0] spacing = 20,
    parameter[9:0] thickness = 10,
    parameter[9:0] top = 135
    )(
    input[3:0] note,
    input[18:0] position,
    output[8:0] mask
    );

    wire signed[9:0] px, py;
    assign px = position[18:9];
    assign py = position[8:0];
	 
	localparam signed h = 10'd320;   // horizontal center
	wire signed[9:0] v; // circle vertical center

    // circles
	wire circle0, circle1, circle2;
	wire[8:0] notes; // for chords
	
	assign notes = ((note == 4'd0)|(note == 4'd1)|(note == 4'd2)|(note == 4'd3)|(note == 4'd4)|(note == 4'd5)|(note == 4'd6))? {5'd0,note}: // single notes
				   (note == 4'd7)? 9'b100010000 :
				   (note == 4'd8)? 9'b110100010 :
				   (note == 4'd9)? 9'b000101011 :
					  			   9'b001110100 ; // chords
	 
    circle_mask #(
	    .spacing(spacing),
		.thickness(thickness),
        .top(top),
		.h(h)
	) base_circle_mask (
		.note(notes[2:0]),
		.position(position),
		.v(v),
		.circle(circle0)
	);
	 
    circle_mask #(
	    .spacing(spacing),
		.thickness(thickness),
        .top(top),
		.h(h)    
	) chord_mask1 (
		.note(notes[5:3]),
		.position(position),
		.v(),
		.circle(circle1)
	);

    circle_mask #(
	    .spacing(spacing),
	    .thickness(thickness),
        .top(top),
		.h(h) 
	) chord_mask2 (
		.note(notes[8:6]),
		.position(position),
		.v(),
		.circle(circle2)
	);

    // rectangle
    wire signed[9:0] r_height = v - 10'd60; // rectangle height
    wire signed[9:0] r_left = h + 10'd3; // rectangle left border 
    wire signed[9:0] r_right = r_left + 10'd12; // rectangle right border
        
    wire rectangle = (py>r_height & py<v) & (px>r_left & px<r_right);

    wire signed[9:0] si_r_height = v + 10'd60;
    wire signed[9:0] si_r_right = h - 10'd3;
    wire signed[9:0] si_r_left = si_r_right - 10'd12;
    wire si_rectangle = (py>v & py<si_r_height) & (px>si_r_left & px<si_r_right);

    // diag
    wire signed[9:0] d_left = r_right-(v-10'd49);
    wire signed[9:0] d_top = r_height+r_right;

	wire diag = (py>(d_top-px) & py<(d_top+10'd40-px)) & (px>(d_left+py) & px<(d_left+10'd10+py));

    wire[9:0] si_d_bot = si_r_height + si_r_right; 
    wire[9:0] si_d_left = si_r_right-(v+10'd69);

    wire si_diag = (py<(si_d_bot-px) & py>(si_d_bot-10'd10-px)) & (px>(si_d_left+py) & px<(si_d_left+10'd55+py));

    // borders
    localparam v_border = 10'd60;
    localparam h_border = 10'd30;
    wire borders = (py>(v-v_border) & py<(v+v_border)) & (px>(h-h_border) & px<(h+h_border));

    // full kernel
    wire[8:0] note_kernel = ((circle0 | rectangle | diag) & borders)? 9'b111111111 : 9'd0;

    // SI
    wire[8:0] si = ((circle0 | si_rectangle | si_diag) & borders)? 9'b111111111 : 9'd0;
	 
	// chord
	wire[8:0] chord = (circle0 | circle1 | circle2)? 9'b111111111 : 9'd0;

    // output
    assign mask = (note == 4'd0) ? note_kernel 	    : // DO
                  (note == 4'd1) ? note_kernel      : // RE
                  (note == 4'd2) ? note_kernel      : // MI
                  (note == 4'd3) ? note_kernel      : // FA
                  (note == 4'd4) ? note_kernel      : // SOL
                  (note == 4'd5) ? note_kernel      : // LA
                  (note == 4'd6) ? si               : // SI
				  ((note == 4'd7) |(note == 4'd8) | (note == 4'd9) | (note == 4'd10))? chord : // chords
                  9'd0          					; // ESC
endmodule

module circle_mask #(
     parameter[9:0] spacing = 20,
	 parameter[9:0] thickness = 10,
     parameter[9:0] top = 135,
	 parameter signed[9:0] h = 10'd320
	)(
	 input[2:0] note,
	 input[18:0] position,
	 output signed[9:0] v,
	 output circle
	);
	wire[9:0] tmp_note = {6'd0,note};
    
	assign v = top+(spacing<<2)+spacing-(spacing>>1)*tmp_note;
	wire[21:0] d = 22'd224;
    
    wire signed[9:0] px = position[18:9];
    wire signed[9:0] py = position[8:0];
    
	wire signed[10:0] dx = px - h;
    wire signed[10:0] dy = py - v;
    wire[21:0] dist = dx*dx + dy*dy;

	wire tmp_circle = dist <= d;
	 
    // DO 
    wire do_note = ((py >= (top+(spacing<<2)+spacing)) & (py <= (top+(spacing<<2)+spacing+thickness)) & ((px>(h-10'd35) & px<(h+10'd35)))) ? 9'b111111111 : 9'd0;
	 
	assign circle = (note == 4'd0)? tmp_circle | do_note : tmp_circle; 
endmodule

module disp_timing(
    input reset, pxlclk,
    output H_SYNC, V_SYNC, display,
    output[18:0] position
    );

    // count pixels
    wire pos_H_SYNC;
    wire[9:0] px,py;

    disp_counter #(
        .front(10'd640),
        .pls(10'd656),
        .back(10'd752),
        .per(10'd800)
    ) pxlcnt (
        .reset(reset),
        .clk(pxlclk),
        .enable(1'b1),
        .display(pxldisplay),
        .pulse(pos_H_SYNC),
        .ripple(V_SYNC_en),
        .cnt(px)
    );

    // negative logic
    assign H_SYNC = ~pos_H_SYNC;

    // count lines
    disp_counter #(
        .front(10'd400),
        .pls(10'd412),
        .back(10'd414),
        .per(10'd449)
    ) rowcnt (
        .reset(reset),
        .clk(pxlclk),
        .enable(V_SYNC_en),
        .display(rowdisplay),
        .pulse(V_SYNC),
        .ripple(),
        .cnt(py)
    );

    // display enable
    assign display = pxldisplay & rowdisplay;

    // position
    assign position = {px, py[8:0]};
endmodule

module disp_counter #(
    parameter[9:0] front = 10'd640,
    parameter[9:0] pls = 10'd656,
    parameter[9:0] back = 10'd752,
    parameter[9:0] per = 10'd800
  )(
  input reset, clk, enable,
  output  display, pulse, ripple,
  output[9:0] cnt
  );

  reg[9:0] tmp_cnt;

  assign display = tmp_cnt < front;
  assign pulse = (tmp_cnt > (pls-10'd1)) & (tmp_cnt < back);
  assign ripple = (tmp_cnt == per-10'd1);
  assign cnt = tmp_cnt;

  always @(posedge clk or posedge reset) begin
      if(reset) tmp_cnt <= 10'd0;
      else if(enable)
           if(ripple) tmp_cnt <= 10'd0;
           else tmp_cnt <= tmp_cnt + 10'd1;
  end
endmodule