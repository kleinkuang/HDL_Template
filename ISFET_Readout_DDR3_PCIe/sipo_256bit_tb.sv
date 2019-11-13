// File:    sipo_256bit_tb.sv
// Author:  Lei Kuang
// Date:    2019.01.02
// @ Impeial College London

module sipo_256bit_tb;

logic            clk;
logic            nrst;
logic            force_rdy;
logic            SIPO_en;
logic [9:0]      SIPO_in;
logic            SIPO_rdy;
logic [255:0]    SIPO_out;

sipo_256bit s0 (.*);

initial
begin
    clk = '0;
    forever #10ns clk = ~clk;
end

// Stimulus Generation
logic [13:0] pixel_cnt = '0;

assign force_rdy = pixel_cnt=='1 ? '1: '0;
assign SIPO_in = pixel_cnt[9:0];

initial
begin
    nrst = '0;
    #20ns
    nrst = '1;
    forever @(posedge clk) begin
        if(SIPO_en)
            pixel_cnt = pixel_cnt + 10'd1;
    end
end

// Sample SIPO Output data when SIPO_rdy is asserted
logic [9:0] data_cnt = '0;
initial
begin
    forever @(posedge SIPO_rdy) begin
        data_cnt <= data_cnt + 10'd1;
    end
end

always @ (posedge SIPO_rdy)
begin
    #10ns
    $display("%-3d 0x%x", data_cnt-10'd1, SIPO_out);
end

initial
begin
    SIPO_en = '1;
    #1000ns
    SIPO_en = '0;
    #200ns
    SIPO_en = '1;
end

endmodule