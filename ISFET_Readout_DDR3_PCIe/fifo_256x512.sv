// File:    fifo_256x512.sv
// Author:  Lei Kuang
// Date:    2019.01.05
// @ Imperial College London

// Wrapper for IP FIFO (Built-in FIFO)
// Data Width 256 bit
// Depth 512

module fifo_256x512
(
    input  logic            clk     ,
    input  logic            nrst    ,
    input  logic [255:0]    din     ,
    input  logic            wr_en   ,  
    input  logic            rd_en   ,
    output logic [255:0]    dout    ,
    output logic            full    ,
    output logic            empty   ,
    output logic            rdy
);

builtin_fifo_256x512 f0
(
    .clk    ( clk   ),
    .rst    ( ~nrst ),
    .din    ( din   ),
    .wr_en  ( wr_en ),  
    .rd_en  ( rd_en ),
    .dout   ( dout  ),
    .full   ( full  ),
    .empty  ( empty )
);

logic [3:0] cnt;

always_ff @ (posedge clk, negedge nrst)
begin
    if(~nrst)
        cnt <= '0;
    else
        if(~rdy)
            cnt <= cnt + 4'd1;
end

assign rdy = cnt=='1 ? '1 : '0;

endmodule
