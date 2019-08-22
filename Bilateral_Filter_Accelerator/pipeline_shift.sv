// File:    pipeline_shift.sv
// Author:  Lei Kuang
// Date:    20th of August 2019
// @ Imperial College London

// Shift register only...

module pipeline_shift #
(
    parameter DATA_WIDTH,
    parameter PIPELINE_N
)
(
    input  logic                    clk,
    input  logic [DATA_WIDTH-1:0]   in,
    output logic [DATA_WIDTH-1:0]   out
);

logic [DATA_WIDTH-1:0] shift_reg [PIPELINE_N-1:0];
//logic [DATA_WIDTH-1:0] shift_reg [PIPELINE_N-1:0] = {default: '0}; // For simulation

always_ff @ (posedge clk)
    shift_reg[0] <= in;

genvar i;
generate 
begin:shift_loop
    if(PIPELINE_N>1) begin
        for(i=0; i<PIPELINE_N-1; i++) begin
            always_ff @(posedge clk)
                shift_reg[i+1] <= shift_reg[i];
        end
    end
end
endgenerate

assign out = shift_reg[PIPELINE_N-1];

endmodule
