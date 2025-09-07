module mySynth(
    input reset, sysclk, ps2clk, ps2data,
    output H_SYNC, V_SYNC, PWM,
    output[8:0] RGB
);
    
    // scancode inputs from keyboard
	wire[7:0] scancode;
    
    kbd_protocol kbd_in (
        .reset(reset),
        .clk(sysclk),
        .ps2clk(ps2clk),
        .ps2data(ps2data),
        .scancode(scancode)
    );

    // handle scancode inputs for sound
    sound_cntrl snd_hndlr (
        .reset(reset),
        .sysclk(sysclk),
        .character(scancode),
        .PWM(PWM)
    );
    
    // 25 MHz
    wire pxlclk;
    
    cnt2b pxlclk_gen (
        .reset(reset),
        .clk(sysclk),
        .enable(1'b1),
        .clkdiv4(pxlclk)
    );

    // handle scancode inputs for display
    display_cntrl #(
        .spacing(10'd25),
        .thickness(10'd5),
        .top(10'd100)
        ) disp_hndlr (
        .reset(reset),
        .pxlclk(pxlclk),
        .character(scancode),
        .H_SYNC(H_SYNC),
        .V_SYNC(V_SYNC),
        .RGB(RGB)
    );

endmodule

module cnt2b(
  input reset, clk, enable,
  output  clkdiv4
  );

  reg[1:0] cnt;
  assign  clkdiv4 = (cnt == 2'd3);
  always @(posedge clk or posedge reset) begin
      if(reset) cnt <= 2'd0;
      else if(enable)
           if(clkdiv4) cnt <= 2'd0;
           else cnt <= cnt + 2'd1;
  end
endmodule