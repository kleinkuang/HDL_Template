// File:    bilateral_filter.sv
// Author:  Lei Kuang
// Date:    21th of August 2019
// @ Imperial College London

// Latency = 30

module bilateral_filter
(
    input  logic            clk,
    input  logic [9:0]      local_window [48:0],    // Read data
    input  logic            local_window_valid,     // Read valid
    output logic [9:0]      smoothed_pixel,
    output logic            smoothed_pixel_valid
);

// ----------------------------------------------------------------
// Compute Range Kernel (Latency=6)
// ----------------------------------------------------------------
logic [31:0]    range_kernel [48:0];
logic           range_kernel_valid;

range_kernel range_kernel_inst
(
    .clk(clk),
    .sigma(10'd40),
    .local_window(local_window),
    .local_window_valid(local_window_valid),
    .range_kernel(range_kernel),
    .range_kernel_valid(range_kernel_valid)
);

// ----------------------------------------------------------------
// Pipeline for Local Window
// ----------------------------------------------------------------
logic [31:0]    local_window_single [48:0];
logic           local_window_single_valid[48:0];
logic [31:0]    local_window_single_p1 [48:0];
logic           local_window_single_valid_p1[48:0];

genvar i, j;
generate 
begin: pipeline_gen1
    for( i=0; i<7; i++) begin: r
        for( j=0; j<7; j++) begin: c
            fix_to_single f2s
            (
                .aclk(clk),
                .s_axis_a_tdata({22'd0,local_window[i*7+j]}),
                .s_axis_a_tvalid(local_window_valid),
                .m_axis_result_tdata(local_window_single[i*7+j]),
                .m_axis_result_tvalid(local_window_single_valid[i*7+j])
            );
            
            pipeline_shift #(32, 10) pipeline_local_window_single
            (
                .clk(clk),
                .in(local_window_single[i*7+j]),
                .out(local_window_single_p1[i*7+j])
            );
            
            pipeline_shift #(1, 10) pipeline_local_window_single_valid
            (
                .clk(clk),
                .in(local_window_single_valid[i*7+j]),
                .out(local_window_single_valid_p1[i*7+j])
            );
        end
    end
end
endgenerate

// ----------------------------------------------------------------
// Compute Bilateral Kernel (Latency=2)
// ----------------------------------------------------------------
logic [31:0]    bilateral_kernel [48:0];
logic           bilateral_kernel_valid;

bilateral_kernel bilateral_kernel_inst
(
    .clk(clk),
    .range_kernel(range_kernel),
    .range_kernel_valid(range_kernel_valid),
    .bilateral_kernel(bilateral_kernel),
    .bilateral_kernel_valid(bilateral_kernel_valid)
);

// ----------------------------------------------------------------
// Apply Bilateral Kernel on Local Window (Latency=2)
// ----------------------------------------------------------------
logic [31:0]    pixel_kernel [48:0];
logic           pixel_kernel_valid;

kernel_product kernel_product_inst
(
    .clk(clk),
    .kernel_a(local_window_single_p1),
    .kernel_b(bilateral_kernel),
    .kernel_valid(local_window_single_valid_p1[0] & bilateral_kernel_valid),
    .product(pixel_kernel),
    .product_valid(pixel_kernel_valid)
);

// ----------------------------------------------------------------
// Pipeline for Bilateral Kernel
// ----------------------------------------------------------------
logic [31:0]    bilateral_kernel_p1 [48:0];
logic           bilateral_kernel_valid_p1;

genvar m, n;
generate 
begin: pipeline_gen2
    for( m=0; m<7; m++) begin: r
        for( n=0; n<7; n++) begin: c
            pipeline_shift #(32, 2) pipeline_bilateral_kernel
            (
                .clk(clk),
                .in(bilateral_kernel[m*7+n]),
                .out(bilateral_kernel_p1[m*7+n])
            );
        end
    end
end
endgenerate

pipeline_shift #(1, 2) pipeline_bilateral_kernel_valid
(
    .clk(clk),
    .in(bilateral_kernel_valid),
    .out(bilateral_kernel_valid_p1)
);

// ----------------------------------------------------------------
// Sum of weighted pixel and bilateral kernel (Latency=6)
// ----------------------------------------------------------------
logic [31:0]    weighted_pixel;
logic           weighted_pixel_valid;
logic [31:0]    weighted_sum;
logic           weighted_sum_valid;

kernel_sum pixel_kernel_sum
(
    .clk(clk),
    .kernel(pixel_kernel),
    .kernel_valid(pixel_kernel_valid),
    .sum(weighted_pixel),
    .sum_valid(weighted_pixel_valid)
);

kernel_sum bilateral_kernel_sum
(
    .clk(clk),
    .kernel(bilateral_kernel_p1),
    .kernel_valid(bilateral_kernel_valid_p1),
    .sum(weighted_sum),
    .sum_valid(weighted_sum_valid)
);

// ----------------------------------------------------------------
// Normialization
// ----------------------------------------------------------------

logic [31:0]    pixel_single;
logic           pixel_single_valid;
logic [15:0]    pixel;
logic           pixel_valid;

normialization_div final_div
(
    .aclk(clk),
    .s_axis_a_tdata(weighted_pixel),
    .s_axis_a_tvalid(weighted_pixel_valid),
    .s_axis_b_tdata(weighted_sum),
    .s_axis_b_tvalid(weighted_sum_valid),
    .m_axis_result_tdata(pixel_single),
    .m_axis_result_tvalid(pixel_single_valid)
);

single_to_fix s2f
(
    .s_axis_a_tdata(pixel_single),
    .s_axis_a_tvalid(pixel_single_valid),
    .m_axis_result_tdata(pixel),
    .m_axis_result_tvalid(pixel_valid)
);

assign smoothed_pixel = pixel[9:0];
assign smoothed_pixel_valid = pixel_valid;

endmodule
