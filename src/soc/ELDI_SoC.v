module ELDI_SoC(
    input wire clk,
    input wire rstn,
    input wire [7:0] gpio_in,
    output wire [7:0] gpio_out,
    output wire hsync, 
    output wire vsync,
    output wire [1:0] R, 
    output wire [1:0] G, 
    output wire [1:0] B
);


wire [31:0] ibus_addr;
wire [31:0] ibus_data;

wire [31:0] dbus_addr;
reg [31:0] dbus_rd_data;
wire [31:0] dbus_wr_data;
wire dbus_we;
wire [3:0] dbus_ByteEnable;



wire [31:0] dmem_rd_data;
wire [31:0] gpio_rd_data;
reg dmem_we;
reg gpio_we;

wire [7:0] vga_mem_addr;
wire [7:0] vga_rd_data;

reg clk_cpu;


always @(posedge clk, negedge rstn) begin
    if(!rstn) clk_cpu <= 0;
    else clk_cpu <= ~clk_cpu;
end

rom imem(
    .mem_addr(ibus_addr[7:0]),
    .rd_data(ibus_data)
);

RiscvCore CPU(
    .clk(clk_cpu),
    .rstn(rstn),
    /*Instruction Memory Interface*/
    .ibus_addr(ibus_addr),
    .ibus_rd_idata(ibus_data),
    /*Data Memory Interface*/
    .dbus_rd_data(dbus_rd_data),
    .dbus_wr_data(dbus_wr_data),    
    .dbus_addr(dbus_addr),
    .dbus_we(dbus_we),
    .dbus_ByteEnable(dbus_ByteEnable)
);

ram dmem(
    .clk(clk_cpu),
    .we(dmem_we),
    .bytesel(dbus_ByteEnable),
    .mem_addr(dbus_addr[7:0]),
    .wr_data(dbus_wr_data),
    .rd_data(dmem_rd_data),
    .vga_mem_addr(vga_mem_addr),
    .vga_rd_data(vga_rd_data)
);


/*Address Decoder*/
always @(*) begin
    casez (dbus_addr)
        32'h00000???: begin
            dbus_rd_data =  dmem_rd_data;
            dmem_we = dbus_we;
            gpio_we = 1'b0;
        end 
        32'h4000000?: begin
            dbus_rd_data =  gpio_rd_data;
            dmem_we = 1'b0;
            gpio_we = dbus_we;
        end 
        default: begin
            dbus_rd_data =  32'h00000000;
            dmem_we = 1'b0;
            gpio_we = 1'b0;
        end 
    endcase
end


gpio GPIO(
    .clk(clk_cpu),
    .rstn(rstn),
    .we(gpio_we),
    .bytesel(dbus_ByteEnable),
    .addr(dbus_addr),
    .wdata(dbus_wr_data),
    .rdata(gpio_rd_data),
    .gpio_port_in(gpio_in),
    .gpio_port_out(gpio_out)
);


vga_controller VGA(
    .clk(clk), 
    .reset(~rstn), 
    .hsync(hsync), 
    .vsync(vsync),
    .mem_addr(vga_mem_addr), 
    .data_in(vga_rd_data), 
    .R(R), 
    .G(G), 
    .B(B));
endmodule