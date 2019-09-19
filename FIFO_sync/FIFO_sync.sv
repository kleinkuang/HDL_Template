// File:    FIFO_sync.sv
// Author:  Lei Kuang
// Date:    19th of September 2019
// @ Home

module FIFO_sync
(
    input  logic        clk,
    input  logic        nrst,
    input  logic [7:0]  data_in,
    input  logic        w_en,
    input  logic        r_en,
    output logic [7:0]  data_out,
    output logic        valid,
    output logic        empty,
    output logic        full
);

logic [7:0] FIFO_RAM [7:0];
logic [2:0] cnt_r;
logic [2:0] cnt_w;

// Write Data
always_ff @ (posedge clk, negedge nrst) begin
    if(~nrst)
        cnt_w <= '0;
    else
        if(w_en) begin
            cnt_w <= cnt_w + 3'd1;
            FIFO_RAM [cnt_w] <= data_in;
        end
end

// Read Data
always_ff @ (posedge clk, negedge nrst) begin
    if(~nrst)
        cnt_r <= '0;
    else
        if(r_en) begin
            cnt_r <= cnt_r + 3'd1;
            data_out = FIFO_RAM [cnt_r];
        end
end

// Flag
logic data_avail;

always_ff @ (posedge clk, negedge nrst) begin
    if(~nrst) begin
        data_avail <= '0;
    end
    else
        if(w_en & ~r_en)                                // Write Data Only
            data_avail <= '1;
        else if(r_en & ~w_en & cnt_w == cnt_r + 3'd1)   // Read Last Buffered Data
            data_avail <= '0;
        else
            data_avail <= data_avail;
end

assign empty = ~data_avail;
assign full = cnt_w == cnt_r & data_avail;

always_ff @ (posedge clk, negedge nrst)
    if(~nrst)
        valid <= '0;
    else
        valid <= r_en;

endmodule
