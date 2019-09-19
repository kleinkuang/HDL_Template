// File:    leading_zeros_tb.sv
// Author:  Lei Kuang
// Date:    19th of September 2019
// @ Home

module leading_zeros_tb;

parameter DATA_WIDTH = 10;
parameter CNT_WIDTH = $clog2(DATA_WIDTH+1);

logic [DATA_WIDTH-1:0]  data    ;
logic [CNT_WIDTH-1:0]   cnt     ;

leading_zeros #(DATA_WIDTH) dvt (.*);

initial begin
    data = 1 << (DATA_WIDTH-1);

    forever begin
        #10ns
        data = data >> 1;
    end
end

endmodule
