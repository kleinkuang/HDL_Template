// File:    Readout_fake_tb.sv
// Author:  Lei Kuang
// Date:    2019.06.22
// @ Imperial College London

module Readout_fake_tb;

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
    forever #1.25ns chip_clk = ~chip_clk;
end

fake_chip fake_chip_inst
(
    // ISFET Chip Interface
    .chip_clk       ( chip_clk      ),
    .chip_nrst      ( readout_LED   ),
    .cali_done      ( cali_done     ),
    .mux_update     ( mux_update    ),
    // ADC MUX
    .ADC_DATA       ( ADC_DATA      )
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
