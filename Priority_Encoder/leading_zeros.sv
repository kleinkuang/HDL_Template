// File:    leading_zeros.sv
// Author:  Lei Kuang
// Date:    19th of September 2019
// @ Home

module leading_zeros #
(
    parameter DATA_WIDTH = 8
)
(
    input  logic [DATA_WIDTH-1:0] data,
    output logic [$clog2(DATA_WIDTH):0] cnt
);

parameter CNT_WIDTH = $clog2(DATA_WIDTH+1);

// Case
always_comb begin
    cnt = DATA_WIDTH;
    for(int i=DATA_WIDTH-1; i>=0; i--) begin
        if(data[i])
            cnt = DATA_WIDTH - 1 - i;
    end
end

endmodule
