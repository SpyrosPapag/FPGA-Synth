module sound_cntrl(
    input reset, sysclk,
    input[7:0] character,
    output PWM
);
    // genarate all needed notes
    wire[11:0] notes;

    frequency_generator fr_gen (
        .reset(reset),
        .sysclk(sysclk),
        .notes(notes)
    );

    // select the requested note
    assign PWM = (character == 8'h23)? notes[0]                      : // DO
                 (character == 8'h2D)? notes[1]                      : // RE
				 (character == 8'h3A)? notes[2]                      : // MI
				 (character == 8'h2B)? notes[3]                      : // FA
				 (character == 8'h1B)? notes[4]                      : // SOL
                 (character == 8'h4B)? notes[5]                      : // LA
                 (character == 8'h21)? notes[6]                      : // SI
				 (character == 8'h16)? notes[0] | notes[2] | notes[4]: // DO/C major
                 (character == 8'h1E)? notes[2] | notes[4] | notes[6]: // MI/E major
                 (character == 8'h26)? notes[3] | notes[5] | notes[0]: // FA/F major
                 (character == 8'h25)? notes[4] | notes[6] | notes[1]: // SOL/G major
                 (character == 8'h2E)? notes[7]                      : // C#/Db
                 (character == 8'h36)? notes[8]                      : // D#/Eb
                 (character == 8'h3D)? notes[9]                      : // F#/Gb
                 (character == 8'h3E)? notes[10]                     : // G#/Ab
                 (character == 8'h46)? notes[11]                     : // A#/Bb
                 1'b0; // ESC
endmodule

module frequency_generator(
    input reset, sysclk,
    output[11:0] notes
    );
    // octave 4 notes in Hz
    // DIV = 100k/(2*F)
    // (0)DO:  C -> 261.63 -> DIV ~= 191
    // (1)RE:  D -> 293.66 -> DIV ~= 170
    // (2)MI:  E -> 329.63 -> DIV ~= 152
    // (3)FA:  F -> 349.23 -> DIV ~= 143
    // (4)SOL: G -> 392    -> DIV ~= 128
    // (5)LA:  A -> 440    -> DIV ~= 114
    // (6)SI:  B -> 493.88 -> DIV ~= 101
    
    // (7)  C#/Db -> 277.18 -> DIV ~= 180
    // (8)  D#/Eb -> 311.13 -> DIV ~= 161
    // (9)  F#/Gb -> 369.99 -> DIV ~= 135
    // (10) G#/Ab -> 415.30 -> DIV ~= 120
    // (11) A#/Bb -> 466.16 -> DIV ~= 107
    wire[7:0] DIV[11:0];

    assign DIV[0] = 8'd191;
    assign DIV[1] = 8'd170;
    assign DIV[2] = 8'd152;
    assign DIV[3] = 8'd143;
    assign DIV[4] = 8'd128;
    assign DIV[5] = 8'd114;
    assign DIV[6] = 8'd101;

    assign DIV[7]  = 8'd180;
    assign DIV[8]  = 8'd161;
    assign DIV[9]  = 8'd135;
    assign DIV[10] = 8'd120;
    assign DIV[11] = 8'd107;

    wire clk100kHz;

    counter #(.width(10)) sampling (
        .reset(reset),
        .clk(sysclk),
        .enable(1'b1),
        .div(10'd1000),
        .clkdiv(clk100kHz)
    );

    genvar i;
    generate 
        for (i = 0; i < 12; i = i + 1) begin : counters
            counter #(.width(8)) note (
                .reset(reset),
                .clk(sysclk),
                .enable(clk100kHz),
                .div(DIV[i]),
                .clkdiv(notes[i])
            );
        end
    endgenerate
endmodule

module counter#(
  parameter width = 8 
  )(
  input reset, clk, enable,
  input[width-1:0] div,
  output  clkdiv
  );
    
  reg[width-1:0] cnt;
  assign  clkdiv = (cnt == div - {{(width-1){1'b0}},1'b1});
  always @(posedge clk or posedge reset) begin
      if(reset) cnt <= {width{1'b0}};
      else if(enable)
           if(clkdiv) cnt <= {width{1'b0}};
           else cnt <= cnt + {{(width-1){1'b0}},1'b1};
  end
endmodule