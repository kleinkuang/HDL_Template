// File:    frame_blk_mem.sv
// Author:  Lei Kuang
// Date:    20th of August 2019
// @ Imperial College London

// 7x7 BRAMs for holding one frame of size 128x128
// Pixel -> 7x7 BRAMs -> 7x7 Ports

// Write pixel data into the same address
// Read pixel data from a 7x7 local window with symmetric padding
/*
        1   2   3
        4   5   6       =>
        7   8   9
*/

/*
    9     8     7     7     8     9     9     8     7
    6     5     4     4     5     6     6     5     4
    3     2     1     1     2     3     3     2     1
    3     2     1    \1     2     3\    3     2     1
    6     5     4    \4     5     6\    6     5     4
    9     8     7    \7     8     9\    9     8     7
    9     8     7     7     8     9     9     8     7
    6     5     4     4     5     6     6     5     4
    3     2     1     1     2     3     3     2     1
*/

module frame_blk_mem
(
    // Port A for Write
    input  logic            clk_w           ,   // Clock for write port
    input  logic            clk_en_w        ,   // Clock enable
    input  logic            en_w            ,   // Write enable
    input  logic [6:0]      row_w           ,   // Write row address
    input  logic [6:0]      col_w           ,   // Write column address
    input  logic [9:0]      pixel_w         ,   // Write data
    // Port B for Read
    input  logic            clk_r           ,   // Clock for read port
    input  logic            clk_en_r        ,   // Clock enable
    input  logic [6:0]      row_r           ,   // Read row address
    input  logic [6:0]      col_r           ,   // Read column address
    input  logic            addr_r_valid    ,   // Address valid
    output logic [9:0]      pixel_r [48:0]  ,   // Read data
    output logic            pixel_r_valid       // Read valid
);

// Read address for 7x7 local window
// Address for padded array
logic [7:0] row_pad [48:0];
logic [7:0] col_pad [48:0];
// Address after symmetric mapping
logic [6:0] row_sym [48:0];
logic [6:0] col_sym [48:0];

genvar i, j;
generate 
begin:pixel_blk
    for( i=0; i<7; i++) begin: r
        for( j=0; j<7; j++) begin: c
            // Compute address for local window
            always_comb begin
                row_pad[i*7+j] = {1'b0,row_r} - 8'd3 + i;
                col_pad[i*7+j] = {1'b0,col_r} - 8'd3 + j;
                row_sym[i*7+j] = row_pad[i*7+j][7] ? 7'd127 - row_pad[i*7+j][6:0] : row_pad[i*7+j][6:0];
                col_sym[i*7+j] = col_pad[i*7+j][7] ? 7'd127 - col_pad[i*7+j][6:0] : col_pad[i*7+j][6:0];
            end
        
            pixel_blk_mem inst
            (
                // Port A for Write
                .clka   (clk_w),
                .ena    (clk_en_w),
                .wea    (en_w),
                .addra  ({row_w,col_w}),    // 2D addr -> 1D addr
                .dina   (pixel_w),
                // Port B for Read
                .clkb   (clk_r),
                .enb    (clk_en_r),
                .addrb  ({row_sym[i*7+j],col_sym[i*7+j]}),
                .doutb  (pixel_r[i*7+j])
            );
        end
    end
end
endgenerate

// Valid Signal

pipeline_shift #(1,2) pipeline_valid
(
    .clk(clk_r),
    .in(addr_r_valid),
    .out(pixel_r_valid)
);

endmodule
