// File:    kernel_product.sv
// Author:  Lei Kuang
// Date:    21th of August 2019
// @ Imperial College London

// Latency = 2

module kernel_product
(
    input  logic        clk,
    input  logic [31:0] kernel_a [48:0],
    input  logic [31:0] kernel_b [48:0],
    input  logic        kernel_valid,
    output logic [31:0] product [48:0],
    output logic        product_valid
);

logic product_valid_int [48:0];
assign product_valid = product_valid_int[0];

genvar i, j;
generate 
begin: product_gen
    for( i=0; i<7; i++) begin: r
        for( j=0; j<7; j++) begin: c
            kernel_product_mul mul
            (
                .aclk(clk),
                .s_axis_a_tdata(kernel_a[i*7+j]),
                .s_axis_a_tvalid(kernel_valid),
                .s_axis_b_tdata(kernel_b[i*7+j]),
                .s_axis_b_tvalid(kernel_valid),
                .m_axis_result_tdata(product[i*7+j]),
                .m_axis_result_tvalid(product_valid_int[i*7+j])
            );
        end
    end
end
endgenerate

endmodule
