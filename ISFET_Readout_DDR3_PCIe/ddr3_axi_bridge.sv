// File:    ddr3_axi_bridge.sv
// Author:  Lei Kuang
// Date:    2019.01.13
// @ Imperial College London

// Interface for Controlling AXI DDR3 MIG
// !!! Fixed Burst Length, Size and Mode for Both Write and Read !!!

// AXI4 Bus
// Addressing:  [29:0]
// Data:        [7:0]
// Memory:      2^30 * 8 / (1024^3) = 8Gb

module ddr3_axi_bridge
(
    // ----------------------------------------------------------------
    // DDR3 Slave Interface
    // ----------------------------------------------------------------
    // -- Write
    input  logic            ddr3_wd_req         ,   // DDR3 Write Data Request
    input  logic [24:0]     ddr3_wd_addr        ,   // DDR3 Write Data Address
    input  logic [255:0]    ddr3_wd_data        ,   // DDR3 Write Data
    output logic            ddr3_wd_ack         ,   // DDR3 Write Command Acknowledge
    // -- Read
    input  logic            ddr3_rd_req         ,   // DDR3 Read Data Request
    input  logic [24:0]     ddr3_rd_addr        ,   // DDR3 Read Data Address
    output logic [255:0]    ddr3_rd_data        ,   // DDR3 Read Data
    output logic            ddr3_rd_ack         ,   // DDR3 Read Command Acknowledge
    output logic            ddr3_rd_valid       ,   // DDR3 Read Data Valid
    // ----------------------------------------------------------------
    // AXI4 Master Interface
    // ----------------------------------------------------------------
    input  logic            M00_ACLK            ,   // AXI Clock
    output logic [29:0]     m00_axi_awaddr      ,   // Write address.           The write address gives the address of the first transfer in a write burst transaction.
    output logic            m00_axi_awvalid     ,   // Write address valid.     This signal indicates that valid write address and control information are available.
    input  logic            m00_axi_awready     ,   // Write address ready.     This signal indicates that the slave is ready to accept an address and associated control signals.
    // -- Slave Interface Write Data Ports
    output logic [255:0]    m00_axi_wdata       ,   // Write data.
    output logic            m00_axi_wvalid      ,   // Write valid.             This signal indicates that write data and strobe are available.
    input  logic            m00_axi_wready      ,   // Write ready.             This signal indicates that the slave can accept the write data.
    // -- Slave Interface Write Response Ports
    input  logic [1:0]      m00_axi_bresp       ,   // Write response.          This signal indicates the status of the write response.
    input  logic            m00_axi_bvalid      ,   // Write response valid.    This signal indicates that the channel is signaling a valid write response.
    output logic            m00_axi_bready      ,   // Response ready.          This signal indicates that the master can accept a write response.
    // -- Slave Interface Read Address Ports
    output logic [29:0]     m00_axi_araddr      ,   // Read address.            The read address gives the address of the first transfer in a read burst transaction.
    output logic            m00_axi_arvalid     ,   // Read address valid.      This signal indicates that the channel is signaling valid read address and control information.
    input  logic            m00_axi_arready     ,   // Read address ready.      This signal indicates that the slave is ready to accept an address and associated control signals.
    // -- Slave Interface Read Data Ports
    input  logic [255:0]    m00_axi_rdata       ,   // Read data.
    input  logic [1:0]      m00_axi_rresp       ,   // Read response.           This signal indicates the status of the read transfer.
    input  logic            m00_axi_rvalid      ,   // Read valid.              This signal indicates that the channel is signaling the required read data.
    output logic            m00_axi_rready      ,   // Read ready.              This signal indicates that the master can accept the read data and response information.
    // AXI4 Master Interface with constant assignment
    output logic [0:0]      m00_axi_awlock      ,   // Lock type.               This is not used in the current implementation.
    output logic [3:0]      m00_axi_awcache     ,   // Cache type.              This is not used in the current implementation.
    output logic [2:0]      m00_axi_awprot      ,   // Protection type.         Not used in the current implementation.)
    output logic [3:0]      m00_axi_awqos       ,   // Quality of Service,      QoS. The QoS identifier sent for each write transaction.
    output logic [0:0]      m00_axi_arlock      ,   // Lock type.               This is not used in the current implementation.
    output logic [3:0]      m00_axi_arcache     ,   // Cache type.              This is not used in the current implementation.
    output logic [2:0]      m00_axi_arprot      ,   // Protection type.         This is not used in the current implementation.
    output logic [3:0]      m00_axi_arqos       ,   // Quality of Service,      QoS. QoS identifier sent for each read transaction.
    output logic [3:0]      m00_axi_awid        ,   // Write address ID.        This signal is the identification tag for the write address group of signals.
    output logic [3:0]      m00_axi_arid        ,   // Read address ID.         This signal is the identification tag for the read address group of signals.
    input  logic [3:0]      m00_axi_bid         ,   // Response ID.             The identification tag of the write response.
    input  logic [3:0]      m00_axi_rid         ,   // Read ID tag.             This signal is the identification tag for the read data group of signals generated by the slave.
    output logic [31:0]     m00_axi_wstrb       ,   // Write strobes.           This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
    output logic [7:0]      m00_axi_awlen       ,   // Burst length.            This information determines the number of data transfers associated with the address.
    output logic [7:0]      m00_axi_arlen       ,   // Burst length.            This signal indicates the exact number of transfers in a burst.
    output logic [2:0]      m00_axi_awsize      ,   // Burst size.              This signal indicates the size of each transfer in the burst.
    output logic [2:0]      m00_axi_arsize      ,   // Burst size.              This signal indicates the size of each transfer in the burst.
    output logic [1:0]      m00_axi_awburst     ,   // Burst type.              The burst type and the size information, determine how the address for each transfer within the burst is calculated.
    output logic [1:0]      m00_axi_arburst     ,   // Burst type.              The burst type and the size information determine how the address for each transfer within the burst is calculated.
    output logic            m00_axi_wlast       ,   // Write last.              This signal indicates the last transfer in a write burst.
    input  logic            m00_axi_rlast           // Read last.               This signal indicates the last transfer in a read burst.
);

// ----------------------------------------------------------------
// Constant Signals Assignment
// ----------------------------------------------------------------
// Not used in current AXI4 implementation
assign m00_axi_awlock    = '0    ;   // Lock type.       (This is not used in the current implementation.)
assign m00_axi_awcache   = '0    ;   // Cache type.      (This is not used in the current implementation.)
assign m00_axi_awprot    = '0    ;   // Protection type. (Not used in the current implementation.)
assign m00_axi_awqos     = '0    ;   // Quality of Service, QoS. The QoS identifier sent for each write transaction.
assign m00_axi_arlock    = '0    ;   // Lock type.       (This is not used in the current implementation.)
assign m00_axi_arcache   = '0    ;   // Cache type.      (This is not used in the current implementation.)
assign m00_axi_arprot    = '0    ;   // Protection type. (This is not used in the current implementation.)
assign m00_axi_arqos     = '0;       // Quality of Service, QoS. QoS identifier sent for each read transaction.
// Constant Configuration
// -- No Read or Write Ordering
assign m00_axi_awid      = '0    ;   // Write address ID.    This signal is the identification tag for the write address group of signals.
assign m00_axi_arid      = '0    ;   // Read address ID.     This signal is the identification tag for the read address group of signals.
// -- All Bytes [255:0] are Valid
assign m00_axi_wstrb     = '1    ;   // Write strobes.       This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
// -- Fixed Burst Length
assign m00_axi_awlen     = '0    ;   // Burst length.        This information determines the number of data transfers associated with the address.
assign m00_axi_arlen     = '0    ;   // Burst length.        This signal indicates the exact number of transfers in a burst.
// --- Fixed Burst Size which is 32 Bytes (2^5 * 8 = 256 bits)
assign m00_axi_awsize    = 3'b101;   // Burst size.          This signal indicates the size of each transfer in the burst.
assign m00_axi_arsize    = 3'b101;   // Burst size.          This signal indicates the size of each transfer in the burst.
// -- Fixed Burst Mode, The address is the same for every transfer in the burst
assign m00_axi_awburst   = 2'b00 ;   // Burst type.          The burst type and the size information, determine how the address for each transfer within the burst is calculated.
assign m00_axi_arburst   = 2'b00 ;   // Burst type.          The burst type and the size information determine how the address for each transfer within the burst is calculated.
// -- As Burst Length is Fixed, Last Transfter Indicators are Fixed too
assign m00_axi_wlast     = '1    ;   // Write last.          This signal indicates the last transfer in a write burst.

// ----------------------------------------------------------------
// AXI Clock
// ----------------------------------------------------------------
// Each AXI component uses a single clock signal, ACLK. All input signals are sampled on the rising edge of ACLK.
// All output signal changes must occur after the rising edge of ACLK.
// On master and slave interfaces there must be no combinatorial paths between input and output signals.
// PS. ddr3_clk is ACLK

// ----------------------------------------------------------------
// AXI Write Address, Write Data, Write Response
// ----------------------------------------------------------------
// Address and Data Assignment
assign m00_axi_awaddr = {ddr3_wd_addr, 5'd0}  ;
assign m00_axi_wdata  = ddr3_wd_data          ;

// Write Response
assign m00_axi_bready = '1;

assign ddr3_wd_ack = m00_axi_bvalid & (m00_axi_bresp==2'b00 ? '1 : '0);

// Write Address, Write Data
enum {W_REQ, W_DONE} wd_state;

logic axi_aw_ack    ;  // Indicate the Write Address has been accepted
logic axi_w_ack     ;  // Indicate the Write Data have been accepted

always_ff @ (posedge M00_ACLK, negedge ddr3_wd_req)
begin
    if(~ddr3_wd_req) begin
        wd_state    <= W_REQ;
        axi_aw_ack  <= '0;
        axi_w_ack   <= '0;
    end
    else
        case(wd_state)
            W_REQ:  begin
                        if(ddr3_wd_req) begin
                            if(~axi_aw_ack)
                                axi_aw_ack  <= m00_axi_awready    ;
                            if(~axi_w_ack)
                                axi_w_ack   <= m00_axi_wready     ;
                            if(axi_aw_ack & axi_w_ack)
                                wd_state    <= W_DONE           ;
                        end
                    end
            W_DONE: wd_state <= W_DONE;
        endcase
end

// Write Operation Signals
always_comb
begin
    m00_axi_awvalid   = '0;
    m00_axi_wvalid    = '0;
    case(wd_state)
        W_REQ:  begin
                    m00_axi_awvalid   = ddr3_wd_req & ~axi_aw_ack ;
                    m00_axi_wvalid    = ddr3_wd_req & ~axi_w_ack  ;
                end
    endcase
end

// ----------------------------------------------------------------
// AXI Read Address, Read Data
// ----------------------------------------------------------------
// Address and Data Assignment
assign m00_axi_araddr = {ddr3_rd_addr, 5'd0}          ;
assign ddr3_rd_data = m00_axi_rdata                   ;

// Read Data
assign m00_axi_rready     = '1                        ;
assign ddr3_rd_valid    = m00_axi_rvalid              ;

// Read Address
always_ff @ (posedge M00_ACLK, negedge ddr3_rd_req)
begin
    if(~ddr3_rd_req)
        ddr3_rd_ack <= '0                           ;
    else
        if(~ddr3_rd_ack)
            ddr3_rd_ack <= m00_axi_arready            ;
end

assign m00_axi_arvalid    = ddr3_rd_req & ~ddr3_rd_ack;

endmodule