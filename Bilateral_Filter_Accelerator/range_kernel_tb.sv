// File:    range_kernel.sv
// Author:  Lei Kuang
// Date:    20th of August 2019
// @ Imperial College London

module range_kernel_tb;

logic        clk                    ;
logic [9:0]  sigma                  ;
logic [9:0]  local_window [48:0]    ;
logic        local_window_valid     ;
logic [31:0] range_kernel [48:0]    ;
logic        range_kernel_valid     ;

range_kernel range_kernel_inst (.*);

initial begin
    clk = '0;
    forever #2.5ns clk = ~clk;
end

initial begin
    sigma = 10'd0;
    local_window_valid = '0;
    
    @(posedge clk)
    @(negedge clk)
    sigma = 10'd40;
    @(negedge clk)
    @(negedge clk)
    @(negedge clk)
    local_window_valid = '1;
    @(negedge clk)
    local_window_valid = '0;
end

assign local_window [ 0] = 10'd172;
assign local_window [ 1] = 10'd123;
assign local_window [ 2] = 10'd91;
assign local_window [ 3] = 10'd91;
assign local_window [ 4] = 10'd123;
assign local_window [ 5] = 10'd172;
assign local_window [ 6] = 10'd146;
assign local_window [ 7] = 10'd93;
assign local_window [ 8] = 10'd95;
assign local_window [ 9] = 10'd167;
assign local_window [10] = 10'd167;
assign local_window [11] = 10'd95;
assign local_window [12] = 10'd93;
assign local_window [13] = 10'd163;
assign local_window [14] = 10'd172;
assign local_window [15] = 10'd148;
assign local_window [16] = 10'd147;
assign local_window [17] = 10'd147;
assign local_window [18] = 10'd148;
assign local_window [19] = 10'd172;
assign local_window [20] = 10'd114;
assign local_window [21] = 10'd172;
assign local_window [22] = 10'd148;
assign local_window [23] = 10'd147;
assign local_window [24] = 10'd147;
assign local_window [25] = 10'd148;
assign local_window [26] = 10'd172;
assign local_window [27] = 10'd114;
assign local_window [28] = 10'd93;
assign local_window [29] = 10'd95;
assign local_window [30] = 10'd167;
assign local_window [31] = 10'd167;
assign local_window [32] = 10'd95;
assign local_window [33] = 10'd93;
assign local_window [34] = 10'd163;
assign local_window [35] = 10'd172;
assign local_window [36] = 10'd123;
assign local_window [37] = 10'd91;
assign local_window [38] = 10'd91;
assign local_window [39] = 10'd123;
assign local_window [40] = 10'd172;
assign local_window [41] = 10'd146;
assign local_window [42] = 10'd137;
assign local_window [43] = 10'd115;
assign local_window [44] = 10'd147;
assign local_window [45] = 10'd147;
assign local_window [46] = 10'd115;
assign local_window [47] = 10'd137;
assign local_window [48] = 10'd144;

endmodule
