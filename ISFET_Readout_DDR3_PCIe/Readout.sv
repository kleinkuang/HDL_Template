// File:    Readout.sv
// Author:  Lei Kuang
// Date:    2019.01.08
// @ Imperial College London

module Readout
(
    // System Ports
    input  logic            sys_clk     ,
    input  logic            sys_nrst    ,
    output logic            sys_rdy     ,
    input  logic            sys_start   ,
    // SPI Master Interface
    output logic            SCK         ,
    output logic            CS          ,
    output logic            MOSI        ,   // Master Output, Slave In
    input  logic            MISO        ,   // Master Input, Slave Out
    // ISFET Chip Interface
    input  logic            chip_clk    ,
    output logic            chip_nrst   ,
    input  logic            cali_done   ,   // Calibration Done
    input  logic            mux_update  ,   // Mux out Next Data
    input  logic [9:0]      ADC_DATA    ,
    // FIFO Interface
    input  logic            data_rd_en  ,
    output logic [255:0]    data_out    ,
    output logic            data_avail  ,
    // Indicator
    output                  readout_LED ,
    // Debug
    input  logic            ila_clk     ,
    output                  end_of_frame
);

// ----------------------------------------------------------------
// Internal Signal
// ----------------------------------------------------------------
// SPI
logic           spi_clk         ;
logic           spi_nrst        ;   
logic           spi_rdy         ;
logic           spi_req         ;
logic           spi_ack         ;
logic [15:0]    SPI_IN          ;
logic [15:0]    SPI_OUT         ;
// Readout
logic           readout_nrst    ;
// SIPO
logic           force_rdy      ;
logic           SIPO_en        ;
logic [9:0]     SIPO_in        ;
logic           SIPO_rdy       ;
logic [255:0]   SIPO_out       ;
// FIFO
logic           fifo_rdy       ;

// ----------------------------------------------------------------
// SPI Master
// ----------------------------------------------------------------
// 100MHz -> 10MHz for SPI
clkdiv_N #(6) clkdiv_for_spi
(
    .clk        ( sys_clk   ),
    .enable     ( '1        ),
    .N          ( 6'd4     ),
    .clk_div    ( spi_clk   )
);

spi_master spi_master_inst
(
    // Physical SPI Interface
    .SCK        ( SCK       ),
    .CS         ( CS        ),
    .MOSI       ( MOSI      ),
    .MISO       ( MISO      ),
    // Designer Interface
    .spi_nrst   ( spi_nrst  ),   // SPI Reset, Send Out ALL 0s
    .spi_clk    ( spi_clk   ),
    .spi_rdy    ( spi_rdy   ),   // SPI is ready to accept command
    .spi_req    ( spi_req   ),
    .spi_ack    ( spi_ack   ),
    .SPI_IN     ( SPI_IN    ),
    .SPI_OUT    ( SPI_OUT   )
);

// ----------------------------------------------------------------
// Chip Initialization
// ----------------------------------------------------------------
enum {C_RESET, C_WAIT, C_CALI, C_DELAY, C_READ, C_DONE} c_state;

// Internal Delay for Cali and Readout
logic [15:0]    delay_cnt;
logic           delay_nrst;
logic           delay_rdy;

always_ff @ (posedge sys_clk, negedge delay_nrst)
begin
    if(~delay_nrst)
        delay_cnt <= '0;
    else
        if(~delay_rdy)
            delay_cnt <= delay_cnt + 16'd1;
end

assign delay_rdy = delay_cnt=='1;

always_ff @ (posedge spi_clk, negedge sys_nrst)
begin
    if(~sys_nrst) begin
        spi_nrst        <= '0       ;
        chip_nrst       <= '0       ;
        delay_nrst      <= '0       ;
        readout_nrst    <= '0       ;
        spi_req         <= '0       ; 
        SPI_OUT         <= '0       ;
        c_state         <= C_RESET  ;
    end
    else
        case(c_state)
            C_RESET:    begin
                            spi_nrst    <= '1;              // Reset SPI
                            chip_nrst   <= '0;              // Reset Chip
                            if(spi_rdy)
                                c_state <= C_WAIT;
                        end
            C_WAIT:         if(sys_rdy & sys_start) begin   // Require trigger from user
                                c_state     <= C_CALI;
                                chip_nrst   <= '1;
                            end
            C_CALI:     begin
                            SPI_OUT[15:13] <= 3'b011;       // Command for Calibration OneOff
                            spi_req <= ~cali_done;          // !!! spi_req must be deasserted for 1 spi_clk cycle !!!
                            delay_nrst <= '0;
                            if(cali_done & spi_rdy) begin
                                c_state <= C_DELAY;
                            end
                        end
            C_DELAY:    begin
                            delay_nrst <= '1;
                            if(delay_rdy)
                                c_state <= C_READ;
                        end
            C_READ:     begin
                            readout_nrst <= '1;
                            SPI_OUT[15:14] <= 2'b11;        // Command for ISFET Readout
                            spi_req <= '1;
                            delay_nrst <= '0;
                            if(spi_ack)
                                c_state <= C_DONE;
                        end
            C_DONE:     begin
                            spi_req <= '0;
                            if(spi_rdy)
                                if(sys_start)
                                    c_state <= C_DONE;
                        end
        endcase
end

assign sys_rdy = c_state!=C_RESET & fifo_rdy;
assign readout_LED = c_state==C_DONE;

// ----------------------------------------------------------------
// Count ADC Data Samples through Mux_update
// ----------------------------------------------------------------
logic mux_update_flag;

always_ff @ (negedge chip_clk)
begin
    mux_update_flag <= mux_update;
end

logic [3:0] readout_cnt = '0;

always_ff @ (posedge chip_clk, negedge readout_nrst)
begin
    if(~readout_nrst)
        readout_cnt <= '0;
    else 
        if(~(readout_cnt==4'd0) | mux_update_flag)
            readout_cnt <= readout_cnt==4'd8 ? '0 : readout_cnt + 4'd1;
end

assign SIPO_en = readout_cnt!=4'd0;

// ----------------------------------------------------------------
// ISFET ADC Data Readout
// ----------------------------------------------------------------
logic [13:0]    pixel_cnt;

always_ff @ (posedge chip_clk, negedge sys_nrst)
begin
    if(~sys_nrst)
        pixel_cnt <= '0;
    else
        if(SIPO_en)
            pixel_cnt <= pixel_cnt + 14'd1;
end

assign force_rdy    = pixel_cnt=='1 ;
assign end_of_frame = force_rdy     ;
assign SIPO_in      = ADC_DATA      ;

sipo_256bit sipo_256bit_inst
(
    .clk        ( chip_clk  ),
    .nrst       ( sys_nrst  ),
    .force_rdy  ( force_rdy ),
    .SIPO_en    ( SIPO_en   ),
    .SIPO_in    ( SIPO_in   ),
    .SIPO_rdy   ( SIPO_rdy  ),
    .SIPO_out   ( SIPO_out  )
);

// ----------------------------------------------------------------
// FIFO
// ----------------------------------------------------------------
// Hand Shake between SIPO and FIFO
logic           SIPO_lock = '0      ;
logic           SIPO_rdy_buf = '0   ;
logic [255:0]   SIPO_out_buf = '0   ;

always_ff @ (posedge chip_clk, negedge empty)
begin
    if(~empty) begin
        SIPO_lock <= '0;
        SIPO_rdy_buf <= '0;
        SIPO_out_buf <= '0;
    end
    else begin
        if(SIPO_rdy & ~SIPO_lock) begin
            SIPO_lock <= '1;
            SIPO_rdy_buf <= '1;
            SIPO_out_buf <= SIPO_out;
        end
    end
end

/*
logic SIPO_rdy_p100;
signal_pulse signal_pulse_inst_0
(
    .clk    ( sys_clk       ),
    .signal ( SIPO_rdy      ),
    .pulse  ( SIPO_rdy_p100 )
);
*/

logic full;
logic empty;

fifo_256x16 fifo_256x16_inst
(
    .clk    ( sys_clk       ),
    .nrst   ( sys_nrst      ),
    .din    ( SIPO_out_buf  ),
    .wr_en  ( SIPO_rdy_buf  ),
    .rd_en  ( data_rd_en    ),
    .dout   ( data_out      ),
    .full   ( full          ),
    .empty  ( empty         ),
    .rdy    ( fifo_rdy      )
);

assign data_avail = ~empty;

// ----------------------------------------------------------------
// Internal Debug Logic
// ----------------------------------------------------------------

ila_readout ila_readout_inst
(
    .clk        ( ila_clk               ),
    .probe0     ( sys_clk               ),
    // SPI
    .probe1     ( SCK                   ),
    .probe2     ( CS                    ),
    .probe3     ( MISO                  ),
    .probe4     ( MOSI                  ),
    // Chip Bring Up
    .probe5     ( chip_clk              ),
    .probe6     ( chip_nrst             ),
    .probe7     ( cali_done             ),
    // Max Update
    .probe8     ( mux_update            ),
    .probe9     ( ADC_DATA[9:0]         ),
    .probe10    ( mux_update_flag       ),
    .probe11    ( readout_nrst          ),
    .probe12    ( readout_cnt[3:0]      ),
    .probe13    ( pixel_cnt[13:0]       ),
    .probe14    ( force_rdy             ),
    // Serial In Parallel Out
    .probe15    ( SIPO_en               ),
    .probe16    ( SIPO_rdy              ),
    .probe17    ( SIPO_out[255:0]       ),
    .probe18    ( SIPO_rdy_buf          ),
    .probe19    ( SIPO_lock             ),
    // FIFO
    .probe20    ( data_avail            ),
    .probe21    ( data_rd_en            ),
    .probe22    ( data_out[255:0]       )
);

endmodule
