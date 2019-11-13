// File:    fifo_256x512_tb.sv
// Author:  Lei Kuang
// Date:    2019.01.02
// @ Impeial College London

module fifo_256x512_tb;

logic           clk;
logic           nrst;
logic [255:0]   din;
logic           wr_en;
logic           rd_en;
logic [255:0]   dout;
logic           full;
logic           empty;
logic           rdy;

fifo_256x512 f0 (.*);

initial
begin
    clk = '0;
    forever #10ns clk = ~clk;
end

assign rd_en = ~empty;

initial
begin
    nrst = '1;
    din = '0;
    wr_en = '0;
    
    #20ns
    nrst = '0;
    
    #20ns
    nrst = '1;
     
    @ (posedge rdy)
    
    // Write
    forever begin
        #20ns
        wr_en = '1;
        din = din + 256'd1;
    end
end

endmodule
