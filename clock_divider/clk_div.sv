// File:    clk_div.sv
// Author:  Lei Kuang
// Date:    8th of July 2019
// @ Imperial College London

// Arbitrary Integrater Clock Divider
// E.g.,
//          div = 32'd1, 200MHz -> 200MHz
//          div = 32'd2, 200MHz -> 100MHz
//          div = 32'd3, 200MHz -> 66.67MHz

module clk_div
(
    input  logic        clk     ,   // Reference clock
    input  logic        nrst    ,   // Low reset
    input  logic [31:0] div     ,   // Integer Divider 1~4294967294
    output logic        clk_div     // Divided clock
);

// Synchronize the externel reset
// - Ensure cnt_p counts first
logic nrst_ext_sync;

always_ff @ (negedge clk)
begin
    nrst_ext_sync <= nrst;
end

// ----------------------------------------------------------------
// Main Logic
// ----------------------------------------------------------------
logic [30:0] cnt_p;
logic [30:0] cnt_n;
logic [31:0] cnt_sum;
logic        cnt_nrst;

// Internel asynchronous reset
// - Reset cnt_p and cnt_n simultaneously
logic nrst_int;

assign cnt_nrst = ~(cnt_sum==div);
assign nrst_int = nrst_ext_sync & cnt_nrst;

// Sum of edges
assign cnt_sum = cnt_p + cnt_n;

// Count the positive and negative edge repectively
always_ff @ (posedge clk, negedge nrst_int)
begin
    if(~nrst_int)
        cnt_p <= '0;
    else
        cnt_p <= cnt_p + 31'b1;
end

always_ff @ (negedge clk, negedge nrst_int)
begin
    if(~nrst_int)
        cnt_n <= '0;
    else
        cnt_n <= cnt_n + 31'b1;
end

// Output clock
logic clk_div_p;
logic clk_div_n;

always_ff @ (posedge clk, negedge nrst_ext_sync)
begin
    if(~nrst_ext_sync)
        clk_div_p <= '0;
    else
        if(cnt_sum==(div-32'd1))
            clk_div_p <= ~clk_div_p;
end

always_ff @ (negedge clk, negedge nrst_ext_sync)
begin
    if(~nrst_ext_sync)
        clk_div_n <= '1;
    else
        if(cnt_sum==(div-32'd1))
            clk_div_n <= ~clk_div_n;
end

assign clk_div = clk_div_p ^ clk_div_n;

endmodule
