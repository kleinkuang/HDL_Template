// File:    Readout_tb.sv
// Author:  Lei Kuang
// Date:    2019.01.08
// @ Impeial College London

module Readout_tb;

// System Ports
logic           sys_clk         ;
logic           sys_nrst        ;
logic           sys_rdy         ;
logic           sys_start       ;
// SPI Master Interface
logic           SCK             ;
logic           CS              ;
logic           MOSI            ;   // Master Output, Slave In
logic           MISO            ;   // Master Input, Slave Out
// ISFET Chip Interface
logic           chip_clk        ;
logic           chip_nrst       ;
logic           cali_done       ;   // Calibration Done
logic           mux_update      ;   // Mux out Next Data
logic [9:0]     ADC_DATA        ;
// FIFO Interface
logic           data_rd_en      ;
logic [255:0]   data_out        ;
logic           data_avail      ;
// Debug
logic           readout_LED     ;
// ILA
logic           ila_clk         ;
logic           end_of_frame    ;

Readout Readout_inst (.*);

initial
begin
    sys_clk = '0;
    forever #5ns sys_clk = ~sys_clk;
end

initial
begin
    chip_clk = '0;
    forever #2.5ns chip_clk = ~chip_clk;
end

ISFET_chip ISFET_chip_inst
(
    // SPI Interface
    .SCK            ( SCK           ),
    .CS             ( CS            ),
    .SDI            ( MOSI          ),
    .SDO            ( MISO          ),
    // ISFET Chip Interface
    .chip_clk       ( chip_clk      ),
    .chip_nrst      ( chip_nrst     ),
    .Calibration    ( cali_done     ),
    .Framefinished  (               ),
    .MuxUpdate      ( mux_update    ),
    // ADC MUX
    .ADC_OUT        ( ADC_DATA      )
);

assign data_rd_en = data_avail;

initial
begin
    sys_nrst = '0;
    sys_start = '0;
    
    #100ns
    sys_nrst = '1;
    
    @(posedge sys_rdy)
    #20ns
    sys_start = '1;
    
    #200ns
    sys_start = '0;
end

logic [9:0] data_cnt = 10'd0;
initial
begin
    forever @(posedge data_avail) begin
        data_cnt <= data_cnt==10'd656 ? 10'd1 : data_cnt + 10'd1;
    end
end

always @ (negedge data_avail)
begin
    #20ns
    $display("%-3d 0x%x", data_cnt-10'd1, data_out);
end

endmodule
