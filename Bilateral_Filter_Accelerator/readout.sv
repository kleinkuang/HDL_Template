// File:    readout.sv
// Author:  Lei Kuang
// Date:    20th of August 2019
// @ Imperial College London

module readout
(
    input  logic        sys_clk,
    input  logic        sys_nrst,
    input  logic [9:0]  data,
    input  logic        data_valid,
    output logic [9:0]  denoised_data,
    output logic        denoised_data_valid
);

// ----------------------------------------------------------------
// Bus
// ----------------------------------------------------------------

// Count the number of pixels
logic [13:0] data_cnt; // 0~16384
always_ff @ (posedge sys_clk, negedge sys_nrst) begin
    if(~sys_nrst)
        data_cnt <= '0;
    else
        if(data_valid)
            data_cnt <= data_cnt + 14'd1;
end

// One frame has been collected, bilateral filtering can start
logic filter_start;
logic bus_mux;
logic bus_mux_buf;
logic bus_mux_pulse;

always_ff @ (posedge sys_clk, negedge sys_nrst) begin
    if(~sys_nrst) begin
        filter_start <= '0;
        bus_mux <= '0;
        bus_mux_buf <= '0;
    end
    else
        if(data_cnt=='1) begin
            filter_start <= '1;
            bus_mux <= ~bus_mux;
        end
        bus_mux_buf <= bus_mux;
end

assign bus_mux_pulse = bus_mux ^ bus_mux_buf;

// Bus multiplexer
logic [9:0]     data_for_blk_0;
logic [9:0]     data_for_blk_1;
logic           valid_for_blk_0;
logic           valid_for_blk_1;

logic [9:0]     lw_from_blk_0 [48:0];
logic           valid_from_blk_0;
logic [9:0]     lw_from_blk_1 [48:0];
logic           valid_from_blk_1;
logic [9:0]     local_window [48:0];
logic           local_window_valid;

// Write bus
assign data_for_blk_0 = bus_mux=='0 ? data : '0;
assign valid_for_blk_0 = bus_mux=='0 ? data_valid : '0;
assign data_for_blk_1 = bus_mux=='1 ? data : '0;
assign valid_for_blk_1 = bus_mux=='1 ? data_valid : '0;
// Read bus
assign local_window = valid_from_blk_0=='0 ? lw_from_blk_1 : lw_from_blk_0;
assign local_window_valid = valid_from_blk_0=='0 ? valid_from_blk_1 : valid_from_blk_0;

// ----------------------------------------------------------------
// Frame Buffering
// ----------------------------------------------------------------
// ---->---- X ---- BRAMs 0 ---- X          Buffering
//          X                   X
//         X ---- BRAMs 1 ---- X ---->---- Processing

frame_blk_mem frame_buffer_0
(
    // Port A for Write
    .clk_w(sys_clk),
    .clk_en_w(~bus_mux),
    .en_w(valid_for_blk_0),
    .row_w(data_cnt[13:7]),
    .col_w(data_cnt[6:0]),
    .pixel_w(data_for_blk_0),
    // Port B for Read
    .clk_r(sys_clk),
    .clk_en_r(bus_mux & filter_start | valid_from_blk_0),
    .row_r(data_cnt[13:7]),
    .col_r(data_cnt[6:0]),
    .addr_r_valid(bus_mux & filter_start),
    .pixel_r(lw_from_blk_0),
    .pixel_r_valid(valid_from_blk_0)
);

frame_blk_mem frame_buffer_1
(
    // Port A for Write
    .clk_w(sys_clk),
    .clk_en_w(bus_mux),
    .en_w(valid_for_blk_1),
    .row_w(data_cnt[13:7]),
    .col_w(data_cnt[6:0]),
    .pixel_w(data_for_blk_1),
    // Port B for Read
    .clk_r(sys_clk),
    .clk_en_r(~bus_mux & filter_start | valid_from_blk_1),
    .row_r(data_cnt[13:7]),
    .col_r(data_cnt[6:0]),
    .addr_r_valid(~bus_mux & filter_start),
    .pixel_r(lw_from_blk_1),
    .pixel_r_valid(valid_from_blk_1)
);

// ----------------------------------------------------------------
// Bilateral Filter
// ----------------------------------------------------------------

bilateral_filter bilateral_filter_inst
(
    .clk(sys_clk),
    .local_window(local_window),
    .local_window_valid(local_window_valid),
    .smoothed_pixel(denoised_data),
    .smoothed_pixel_valid(denoised_data_valid)
);

endmodule
