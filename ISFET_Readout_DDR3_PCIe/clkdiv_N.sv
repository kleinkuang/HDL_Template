// File:    clkdiv_N.sv
// Author:  Lei Kuang
// Date:    2018.10.25
// @Imperial College London

// Function:
// Clock Divider
// Divide clock frequency by (N+1)*2

module clkdiv_N
#(  
    parameter N_bit = 16
)
(
    input  logic clk,
    input  logic enable,
    input  logic [N_bit-1:0] N,
    output logic clk_div
);

logic [N_bit-1:0] count_int = '0;
logic div_int = '0;

always_ff @ (posedge clk)
begin
    if(enable)
        if(count_int==N)
        begin
            div_int <= ~ div_int;
            count_int <= '0;
        end
    else
        count_int <= count_int + 1'b1;
end
    
assign clk_div = div_int;

endmodule
