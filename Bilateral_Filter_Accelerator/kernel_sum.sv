// File:    kernel_sum.sv
// Author:  Lei Kuang
// Date:    20th of August 2019
// @ Imperial College London

// Latency = 12

module kernel_sum
(
    input  logic        clk,
    input  logic [31:0] kernel [48:0],
    input  logic        kernel_valid,
    output logic [31:0] sum,
    output logic        sum_valid
);

// ----------------------------------------------------------------
// Sum Level 1
// ----------------------------------------------------------------

logic [31:0]    sum_1       [23:0];
logic           sum_1_valid [23:0];

genvar i_1;
generate 
begin:sum_level_1
    for(i_1=0; i_1<24; i_1++) begin
        kernel_add add
        (
            .aclk(clk),
            .s_axis_a_tdata(kernel[i_1*2]),
            .s_axis_a_tvalid(kernel_valid),
            .s_axis_b_tdata(kernel[i_1*2+1]),
            .s_axis_b_tvalid(kernel_valid),
            .m_axis_result_tdata(sum_1[i_1]),
            .m_axis_result_tvalid(sum_1_valid[i_1])
        );
    end
end
endgenerate

// ----------------------------------------------------------------
// Sum Level 2
// ----------------------------------------------------------------

logic [31:0]    sum_2       [11:0];
logic           sum_2_valid [11:0];

genvar i_2;
generate 
begin:sum_level_2
    for(i_2=0; i_2<12; i_2++) begin
        kernel_add add
        (
            .aclk(clk),
            .s_axis_a_tdata(sum_1[i_2*2]),
            .s_axis_a_tvalid(sum_1_valid[i_2*2]),
            .s_axis_b_tdata(sum_1[i_2*2+1]),
            .s_axis_b_tvalid(sum_1_valid[i_2*2+1]),
            .m_axis_result_tdata(sum_2[i_2]),
            .m_axis_result_tvalid(sum_2_valid[i_2])
        );
    end
end
endgenerate

// ----------------------------------------------------------------
// Sum Level 3
// ----------------------------------------------------------------

logic [31:0]    sum_3       [5:0];
logic           sum_3_valid [5:0];

genvar i_3;
generate 
begin:sum_level_3
    for(i_3=0; i_3<6; i_3++) begin
        kernel_add add
        (
            .aclk(clk),
            .s_axis_a_tdata(sum_2[i_3*2]),
            .s_axis_a_tvalid(sum_2_valid[i_3*2]),
            .s_axis_b_tdata(sum_2[i_3*2+1]),
            .s_axis_b_tvalid(sum_2_valid[i_3*2+1]),
            .m_axis_result_tdata(sum_3[i_3]),
            .m_axis_result_tvalid(sum_3_valid[i_3])
        );
    end
end
endgenerate

// ----------------------------------------------------------------
// Sum Level 4
// ----------------------------------------------------------------
logic [31:0]    sum_4       [2:0];
logic           sum_4_valid [2:0];

genvar i_4;
generate 
begin:sum_level_4
    for(i_4=0; i_4<3; i_4++) begin
        kernel_add add
        (
            .aclk(clk),
            .s_axis_a_tdata(sum_3[i_4*2]),
            .s_axis_a_tvalid(sum_3_valid[i_4*2]),
            .s_axis_b_tdata(sum_3[i_4*2+1]),
            .s_axis_b_tvalid(sum_3_valid[i_4*2+1]),
            .m_axis_result_tdata(sum_4[i_4]),
            .m_axis_result_tvalid(sum_4_valid[i_4])
        );
    end
end
endgenerate

// ----------------------------------------------------------------
// Pipeline for last kernel weight
// ----------------------------------------------------------------
logic [31:0]    kernel_48;
logic           kernel_48_valid;

pipeline_shift #(32, 8) pipeline_kernel_48
(
    .clk(clk),
    .in(kernel[48]),
    .out(kernel_48)
);

pipeline_shift #(1, 8) pipeline_kernel_48_valid
(
    .clk(clk),
    .in(kernel_valid),
    .out(kernel_48_valid)
);

// ----------------------------------------------------------------
// Sum Level 5
// ----------------------------------------------------------------

logic [31:0]    sum_5       [2];
logic           sum_5_valid [2];

kernel_add add_sum4_1
(
    .aclk(clk),
    .s_axis_a_tdata(sum_4[0]),
    .s_axis_a_tvalid(sum_4_valid[0]),
    .s_axis_b_tdata(sum_4[1]),
    .s_axis_b_tvalid(sum_4_valid[1]),
    .m_axis_result_tdata(sum_5[0]),
    .m_axis_result_tvalid(sum_5_valid[0])
);

kernel_add add_sum4_2
(
    .aclk(clk),
    .s_axis_a_tdata(sum_4[2]),
    .s_axis_a_tvalid(sum_4_valid[2]),
    .s_axis_b_tdata(kernel_48),
    .s_axis_b_tvalid(kernel_48_valid),
    .m_axis_result_tdata(sum_5[1]),
    .m_axis_result_tvalid(sum_5_valid[1])
);

// ----------------------------------------------------------------
// Final Sum
// ----------------------------------------------------------------

kernel_add final_sum
(
    .aclk(clk),
    .s_axis_a_tdata(sum_5[0]),
    .s_axis_a_tvalid(sum_5_valid[0]),
    .s_axis_b_tdata(sum_5[1]),
    .s_axis_b_tvalid(sum_5_valid[1]),
    .m_axis_result_tdata(sum),
    .m_axis_result_tvalid(sum_valid)
);

endmodule
