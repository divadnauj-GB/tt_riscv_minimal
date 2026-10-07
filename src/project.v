/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_riscv (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  //assign uio_out = 1;
  assign uio_oe  = 8'hFF;

  wire hsync, vsync;
  wire [1:0] R,G,B;

  assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  ELDI_SoC SoC(
    .clk(clk),
    .rstn(rst_n),
    .gpio_in(ui_in),
    .gpio_out(uio_out),
    .hsync(hsync), 
    .vsync(vsync),
    .R(R), 
    .G(G), 
    .B(B)
);

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
