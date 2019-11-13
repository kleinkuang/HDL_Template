// File:    spi_master.sv
// Author:  Lei Kuang
// Date:    2019.02.01
// @ Impeial College London

// Golden Version for ISFET Chip
// !!! Failing Edge for both SDI & SDO !!!

module spi_master
(
    // Physical SPI Interface
    output logic        SCK         ,   // Clock for slave
    output logic        CS          ,   // Chip select, low-active
    output logic        MOSI        ,   // Master output, Slave input
    input  logic        MISO        ,   // Master input, Slave output
    // Designer Interface
    input  logic        spi_nrst    ,   // SPI reset, send out aLL 0s then become ready
    input  logic        spi_clk     ,   // SPI clock
    output logic        spi_rdy     ,   // SPI is ready to accept command
    input  logic        spi_req     ,   // SPI request
    output logic        spi_ack     ,   // SPI acknowledge (done) for current request
    output logic [15:0] SPI_IN      ,   // SPI data read from slave
    input  logic [15:0] SPI_OUT         // SPI data write to slave
);

// Internal Signals
logic [15:0]    SPI_OUT_int         ;
logic [15:0]    SPI_IN_int          ;
logic [4:0]     spi_out_cnt = '0    ;
logic           spi_out_done        ;
logic           spi_in_done         ;

logic           SCK_int;

assign SCK = ~SCK_int;

// SCK_int
always_ff @ (posedge spi_clk, posedge CS)
begin
    if(CS)
        SCK_int <= '1;
    else
        if(~CS)
            SCK_int <= ~SCK_int;
end

// Master Out Slave In
assign spi_out_done = spi_out_cnt=='0;
assign MOSI = spi_out_cnt==5'd16 ? '0 : SPI_OUT_int[spi_out_cnt];

always_ff @ (posedge spi_clk, posedge CS)
begin
    if(CS)
        spi_out_cnt <= 5'd16;
    else
        if(~spi_out_done & SCK_int)
            spi_out_cnt <= spi_out_cnt - 4'd1;
end

// Master In Slave Out
always_ff @ (posedge CS)
begin
    SPI_IN <= SPI_IN_int;
end

always_ff @ (posedge SCK_int)
begin
    if(~CS)
        SPI_IN_int <= {SPI_IN_int[14:0], MISO};
end

// Designer Controller
enum {S_INIT, S_RESET, S_IDLE, S_OUT, S_DONE} state;

always_ff @ (posedge spi_clk, negedge spi_nrst)
begin
    if(~spi_nrst) begin
        CS      <= '1;
        state   <= S_INIT;
    end
    else
        case(state)
            S_INIT:     state <= S_RESET;
            S_RESET:    begin
                            CS <= '0;
                            if(spi_out_done)
                                state <= S_IDLE;
                        end
            S_IDLE:     begin
                            CS <= '1;
                            if(spi_req)
                                state   <= S_OUT;
                        end
            S_OUT:      begin
                            CS <= '0;
                            if(spi_out_done)
                                state <= S_DONE;
                        end
            S_DONE:     begin
                            CS <= '1;
                            if(~spi_req)
                                state <= S_IDLE;
                        end
        endcase
end

assign SPI_OUT_int  = state==S_RESET ? '0 : SPI_OUT;
assign spi_rdy      = state==S_IDLE & CS;
assign spi_ack      = state==S_DONE & CS;

endmodule
