// File:    fifo_256x16.sv
// Author:  Lei Kuang
// Date:    2019.01.02
// @ Impeial College London

// Wrapper for IP FIFO (First In First Out)
// Data Width 256 bit
// Depth 16

module fifo_256x16
(
    input  logic            clk,
    input  logic            nrst,
    input  logic [255:0]    din,
    input  logic            wr_en,
    input  logic            rd_en,
    output logic [255:0]    dout,
    output logic            full,
    output logic            empty,
    output logic            rdy
);

// Separate full signal from IP into full and ready
logic rst_int   ;
logic full_int  ;

shift_fifo_256x16 shift_fifo_256x16_inst
(
    .clk    ( clk       ),
    .rst    ( rst_int   ),
    .din    ( din       ),
    .wr_en  ( wr_en     ),
    .rd_en  ( rd_en     ),
    .dout   ( dout      ),
    .full   ( full_int  ),
    .empty  ( empty     )
);

// Signal full indicates whether reset process is done

enum {RESET, DELAY, READY} state;

always_ff @ (posedge clk, posedge rst_int)
begin
    if(rst_int)
        state <= RESET;
    else
        case(state)
            RESET:  state <= DELAY;
            DELAY:  if(~full_int)
                        state <= READY;
            READY:  state <= READY;
        endcase
end

assign rst_int  = ~nrst;
assign full     = state==READY ? full_int : '0;
assign rdy      = state==READY;

endmodule
