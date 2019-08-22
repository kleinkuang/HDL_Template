// File:    pipeline_shift.sv
// Author:  Lei Kuang
// Date:    20th of August 2019
// @ Imperial College London

module pipeline_shift_tb;

parameter DATA_WIDTH = 32;
parameter PIPELINE_N = 2;

logic                    clk    ;
logic [DATA_WIDTH-1:0]   in     ;
logic [DATA_WIDTH-1:0]   out    ;

pipeline_shift #(DATA_WIDTH, PIPELINE_N) pipeline_shift_intst (.*);

initial begin
    clk = '0;
    forever #2.5ns clk = ~clk;
end

initial begin
    in = 32'b0;
    
    forever begin
        @(negedge clk)
        in = in + 32'b1;
    end
end

endmodule
