// File:    range_kernel.sv
// Author:  Lei Kuang
// Date:    20th of August 2019
// @ Imperial College London

// Latency = 10

module range_kernel
(
    input  logic        clk,
    input  logic [9:0]  sigma,
    input  logic [9:0]  local_window [48:0],
    input  logic        local_window_valid,
    output logic [31:0] range_kernel [48:0],
    output logic        range_kernel_valid
);

logic [21:0]    sigma_div;
logic [21:0]    sigma_div_buf = '0;
logic           sigma_div_valid;
logic [31:0]    sigma_div_single;
logic           sigma_div_single_valid;
logic [31:0]    sigma_div_single_lock ='0;

logic [10:0]    range_dis [48:0];
logic [21:0]    range_pro [48:0];

logic [31:0]    range_pro_single [48:0];
logic           range_pro_single_valid [48:0];

logic [31:0]    range_pro_sigma_div [48:0];
logic           range_pro_sigma_div_valid [48:0];

logic           range_kernel_vaid_int [48:0];

// ----------------------------------------------------------------
// Sigma
// ----------------------------------------------------------------

range_kernel_mul sigma_square   // sigma_r^2
(
    .CLK (clk),
    .A({1'b0,sigma}),
    .B({1'b0,sigma}),
    .P(sigma_div)
);

// If sigma changes
always_ff @(posedge clk) begin
    sigma_div_buf <= sigma_div;
end

assign sigma_div_valid = sigma_div!=sigma_div_buf;

fix_to_single sigma_single
(
    .aclk(clk),
    .s_axis_a_tdata({9'd0,sigma_div,1'd0}),   // 2*sigma_r^2
    .s_axis_a_tvalid(sigma_div_valid),
    .m_axis_result_tdata(sigma_div_single),
    .m_axis_result_tvalid(sigma_div_single_valid)
);

// Hold sigma_single
always_ff @(posedge clk) begin
    if(sigma_div_single_valid)
        sigma_div_single_lock <= sigma_div_single;
end

// ----------------------------------------------------------------
// Compute Range Kernel
// ----------------------------------------------------------------

// local_window_valid
logic range_pro_valid;

pipeline_shift #(1, 2) pipeline_valid
(
    .clk(clk),
    .in(local_window_valid),
    .out(range_pro_valid)
);

// Not optimized yet
// R = exp(-(I_local-I(i,j)).^2/(2*sigma_r^2));
genvar i, j;
generate 
begin:range_kernel_gen
    for( i=0; i<7; i++) begin: r
        for( j=0; j<7; j++) begin: c
            range_kernel_sub sub            // I_local-I(i,j)
            (                               // 10bit - 10bit -> 11bit
                //.CLK (clk),
                .A(local_window[i*7+j]),
                .B(local_window[24]),       // Target pixel
                .S(range_dis[i*7+j])
            );
            
            range_kernel_mul squ            // (I_local-I(i,j)).^2
            (                               // 11bit * 11bit -> 22bit
                .CLK (clk),
                .A(range_dis[i*7+j]),
                .B(range_dis[i*7+j]),
                .P(range_pro[i*7+j])
            );
            
            fix_to_single f2s
            (
                .aclk(clk),
                .s_axis_a_tdata({10'd0,range_pro[i*7+j]}),
                .s_axis_a_tvalid(range_pro_valid),
                .m_axis_result_tdata(range_pro_single[i*7+j]),
                .m_axis_result_tvalid(range_pro_single_valid[i*7+j])
            );
            
            range_kernel_div div            //(I_local-I(i,j)).^2/(2*sigma_r^2)
            (
                .aclk(clk),
                .s_axis_a_tdata(range_pro_single[i*7+j]),
                .s_axis_a_tvalid(range_pro_single_valid[0]),
                .s_axis_b_tdata(sigma_div_single_lock),
                .s_axis_b_tvalid(range_pro_single_valid[0]),
                .m_axis_result_tdata(range_pro_sigma_div[i*7+j]),
                .m_axis_result_tvalid(range_pro_sigma_div_valid[i*7+j])
            );
            
            range_kernel_exp exp            // exp(-(I_local-I(i,j)).^2/(2*sigma_r^2))
            (
                .aclk(clk),
                .s_axis_a_tdata({1'd1,range_pro_sigma_div[i*7+j][30:0]}),    // Sign: '-'
                .s_axis_a_tvalid(range_pro_sigma_div_valid[0]),
                .m_axis_result_tdata(range_kernel[i*7+j]),
                .m_axis_result_tvalid(range_kernel_vaid_int[i*7+j])
            );
         
        end
    end
end
endgenerate

assign range_kernel_valid = range_kernel_vaid_int[0];

endmodule
