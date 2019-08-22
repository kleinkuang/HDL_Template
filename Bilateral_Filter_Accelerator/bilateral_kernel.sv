// File:    bilateral_kernel.sv
// Author:  Lei Kuang
// Date:    20th of August 2019
// @ Imperial College London

// Latency = 2

module bilateral_kernel
(
    input  logic        clk,
    input  logic [31:0] range_kernel [48:0],
    input  logic        range_kernel_valid,
    output logic [31:0] bilateral_kernel [48:0],
    output logic        bilateral_kernel_valid
);

logic           bilateral_kernel_valid_int [48:0];
logic [31:0]    space_kernel [48:0];

gaussian_kernel space_kernel_inst
(
    .gaussian_kernel(space_kernel)
);

genvar i, j;
generate 
begin:bilater_process
    for( i=0; i<7; i++) begin: r
        for( j=0; j<7; j++) begin: c

            bilateral_kernel_mul mul
            (
                .aclk(clk),
                .s_axis_a_tdata(range_kernel[i*7+j]),
                .s_axis_a_tvalid(range_kernel_valid),
                .s_axis_b_tdata(space_kernel[i*7+j]),
                .s_axis_b_tvalid(range_kernel_valid),
                .m_axis_result_tdata(bilateral_kernel[i*7+j]),
                .m_axis_result_tvalid(bilateral_kernel_valid_int[i*7+j])
            );
            
        end
    end
end
endgenerate

assign bilateral_kernel_valid = bilateral_kernel_valid_int[0];

endmodule
