// File:    ddr3_master.sv
// Author:  Lei Kuang
// Date:    2019.01.16
// @ Imperial College London

module ddr3_master
(
    // System
    input  logic            sys_clk         ,
    input  logic            sys_nrst        ,
    // FIFO Interface
    output logic            data_rd_en      ,
    input  logic [255:0]    data_out        ,
    input  logic            data_avail      ,
    // DDR3 Interface
    output logic            ddr3_wd_req     ,   // DDR3 Write Data Request
    output logic [24:0]     ddr3_wd_addr    ,   // DDR3 Write Data Address
    output logic [255:0]    ddr3_wd_data    ,   // DDR3 Write Data
    input  logic            ddr3_wd_ack     ,   // DDR3 Write Command Acknowledge
    output logic            ddr3_rd_req     ,   // DDR3 Read Data Request
    output logic [24:0]     ddr3_rd_addr    ,   // DDR3 Read Data Address
    input  logic [255:0]    ddr3_rd_data    ,   // DDR3 Read Data
    input  logic            ddr3_rd_ack     ,   // DDR3 Read Command Acknowledge
    input  logic            ddr3_rd_valid   ,   // DDR3 Read Data Valid
    // Debug
    input  logic            end_of_frame    
);

assign ddr3_wd_data = data_out;

enum {IDLE, R_REQ, R_ACK, W_REQ, W_ACK, W_DONE} rd_state, wd_state;

always_ff @ (posedge sys_clk, negedge sys_nrst)
begin
    if(~sys_nrst) begin
        data_rd_en  <= '0;
        ddr3_wd_req <= '0;
        ddr3_wd_addr<= '0;
        wd_state    <= IDLE;
    end
    else
        case(wd_state)
            IDLE:   if(data_avail)              // Data available ?
                        wd_state    <= R_REQ;
            R_REQ:  begin                       // Read from FIFO
                        data_rd_en  <= '1;
                        wd_state    <= W_REQ;
                    end
            W_REQ:  begin
                        data_rd_en  <= '0;
                        ddr3_wd_req <= '1;      // Write data to DDR3
                        wd_state    <= W_ACK;
                    end
            W_ACK:  if(ddr3_wd_ack) begin       // Acknowledge
                        ddr3_wd_req <= '0;
                        // Number of frames:    50000
                        // 1 frame:             656 x 256 bits
                        // Number of 256 bits:  50000 x 656 = 3280_0000 (Max addressing)
                        if(ddr3_wd_addr==25'd32799999)
                            ddr3_wd_addr<= '0;
                        else
                            ddr3_wd_addr<= ddr3_wd_addr + 25'd1;
                        wd_state    <= IDLE;
                    end
            W_DONE:     wd_state    <= W_DONE;
        endcase
end

assign ddr3_rd_req = '0;
assign ddr3_rd_addr = '0;

ila_for_ddr3_master ila_for_ddr3_masterinst
(
    .clk    ( sys_clk               ),
    .probe0 ( data_avail            ),
    .probe1 ( data_rd_en            ),
    .probe2 ( data_out[255:0]       ),
    .probe3 ( ddr3_wd_req           ),
    .probe4 ( ddr3_wd_addr[24:0]    ),
    .probe5 ( ddr3_wd_ack           ),
    .probe6 ( end_of_frame          )
);

endmodule
