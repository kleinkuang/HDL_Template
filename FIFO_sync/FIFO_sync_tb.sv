// File:    FIFO_sync_tb.sv
// Author:  Lei Kuang
// Date:    19th of September 2019
// @ Home

module FIFO_sync_tb;

logic        clk        ;
logic        nrst       ;
logic [7:0]  data_in    ;
logic        w_en       ;
logic        r_en       ;
logic [7:0]  data_out   ;
logic        valid      ;
logic        empty      ;
logic        full       ;

FIFO_sync dut(.*);

initial begin
    clk = '0;
    forever #5ns clk = ~clk;
end

// Write and then Read
/*
initial begin
    nrst = '0;
    data_in = '0;
    w_en = '0;
    
    #20ns
    @ (negedge clk)
    nrst = '1;
    w_en = '1;
    for (int i=0; i<7; i++) begin
        @ (negedge clk)
        data_in = data_in + 1;
    end
    
    @ (negedge clk)
    w_en = '0;
end

initial begin
    r_en = '0;
    
    @ (posedge full)
    r_en = '1;
    
    @ (posedge empty)
    r_en = '0;
end
*/

// Write and Read at the same time
initial begin
    nrst = '0;
    data_in = '0;
    w_en = '0;
    r_en = '0;
    
    #20ns
    @ (negedge clk)
    nrst = '1;
    w_en = '1;
    for (int i=0; i<6; i++) begin
        @ (negedge clk)
        data_in = data_in + 1;
    end
    
    r_en = '1;
    
    forever begin
        @ (negedge clk)
        data_in = data_in + 1;
    end
end

endmodule
