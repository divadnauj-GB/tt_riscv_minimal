module vga_controller(clk, reset, hsync, vsync, mem_addr, data_in, R, G, B);

  input clk;
  input reset;
  output reg hsync, vsync;
  output wire [7:0] mem_addr;
  input wire [7:0] data_in;
  output reg [1:0] R;
  output reg [1:0] G;
  output reg [1:0] B;

  // declarations for TV-simulator sync parameters
  // horizontal constants
  parameter H_DISPLAY       = 640; // horizontal display width
  parameter H_BACK          =  48; // horizontal left border (back porch)
  parameter H_FRONT         =  16; // horizontal right border (front porch)
  parameter H_SYNC          =  96; // horizontal sync width
  // vertical constants
  parameter V_DISPLAY       = 480; // vertical display height
  parameter V_TOP           =  33; // vertical top border
  parameter V_BOTTOM        =  10; // vertical bottom border
  parameter V_SYNC          =   2; // vertical sync # lines
  // derived constants
  parameter H_SYNC_START    = H_DISPLAY + H_FRONT;
  parameter H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
  parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  parameter V_SYNC_START    = V_DISPLAY + V_BOTTOM;
  parameter V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  wire display_on;
  reg [9:0] hpos;
  reg [9:0] vpos;
  
  wire hmaxxed = (hpos == H_MAX) || reset;	// set when hpos is maximum
  wire vmaxxed = (vpos == V_MAX) || reset;	// set when vpos is maximum
  
  // horizontal position counter
  always @(posedge clk)
  begin
    hsync <= ~(hpos>=H_SYNC_START && hpos<=H_SYNC_END);
    if(hmaxxed)
      hpos <= 0;
    else
      hpos <= hpos + 1;
  end

  // vertical position counter
  always @(posedge clk)
  begin
    vsync <= ~(vpos>=V_SYNC_START && vpos<=V_SYNC_END);
    if(hmaxxed)
      if (vmaxxed)
        vpos <= 0;
      else
        vpos <= vpos + 1;
  end

    wire [4:0] cell_x = hpos[9:5] ;
    wire [3:0] cell_y = vpos[8:5] ;
    wire [9:0] linear_pixel,linear_pixel_mem;

    reg [7:0] prev_vl;
  
    always @(posedge clk) begin
          if(hpos[4:0]==5'b11111) begin
            prev_vl <= data_in;
          end
    end
  
  // display_on is set when beam is in "safe" visible frame
    assign display_on = (hpos<H_DISPLAY) && (vpos<V_DISPLAY);


    assign linear_pixel = (cell_y*20+cell_x) ;
    assign linear_pixel_mem = linear_pixel*3;
    assign mem_addr = linear_pixel_mem[9:2]+(linear_pixel[0]^linear_pixel[1]);

    always @(*) begin
      casez({display_on,linear_pixel[1:0]})
        3'b100 : begin R = data_in[1:0]; G = data_in[3:2]; B = data_in[5:4]; end
        3'b101 : begin R = prev_vl[7:6]; G = data_in[1:0]; B = data_in[3:2]; end
        3'b110 : begin R = prev_vl[5:4]; G = prev_vl[7:6]; B = data_in[1:0]; end
        3'b111 : begin R = prev_vl[3:2]; G = prev_vl[5:4]; B = prev_vl[7:6]; end
      default: begin R = 2'b00; G = 2'b00; B = 2'b00; end
      endcase
    end
    //assign R = display_on ? data_in[1:0] : 2'b00;
    //assign G = display_on ? data_in[3:2] : 2'b00;
    //assign B = display_on ? data_in[5:4] : 2'b00;

endmodule