// File:    clk_div_tb.sv
// Author:  Lei Kuang
// Date:    8th of July 2019
// @ Imperial College London

module clk_div_tb;

logic           clk     ;
logic           nrst    ;
logic [31:0]    div     ;
logic           clk_div ;

clk_div clk_div_inst(.*);
    
initial
begin
    clk = '0;
    forever #5ns clk = ~clk;
end

initial
begin
    nrst = '0;
    div = 32'd1;
    #20ns
    nrst = '1;
    #100ns
    div = 32'd2;
    #200ns
    div = 32'd3;
    #400ns
    div = 32'd4;
end

endmodule
