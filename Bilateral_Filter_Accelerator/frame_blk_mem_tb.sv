module frame_blk_mem_tb;

// Port A for Write
logic            clk_w           ;
logic            clk_en_w        ;
logic            en_w            ;
logic [6:0]      row_w           ;
logic [6:0]      col_w           ;
logic [9:0]      pixel_w         ;
// Port B for Read
logic            clk_r           ;
logic            clk_en_r        ;
logic [6:0]      row_r           ;
logic [6:0]      col_r           ;
logic            addr_r_valid    ;
logic [9:0]      pixel_r [48:0]  ;
logic            pixel_r_valid   ;

frame_blk_mem frame_blk_mem_inst(.*);

initial begin
    clk_w = '0;
    forever #7.5ns clk_w = ~clk_w;
end

initial begin
    clk_r = '0;
    forever #2.5ns clk_r = ~clk_r;
end

initial begin
    clk_en_w = '0;
    en_w = '0;
    row_w = '0;
    col_w = '0;
end

initial begin
    clk_en_r = '1;
    row_r = 7'd1;
    col_r = 7'd0;
    addr_r_valid = '0;

    @(posedge clk_r)
    for(int i=0; i<5; i++) begin
        @(negedge clk_r)
        col_r = col_r + 7'd1;
        addr_r_valid = '1;
        @(negedge clk_r)
        addr_r_valid = '0;
    end
    
    @(posedge clk_r)
    @(negedge clk_r)
    addr_r_valid = '1;
    for(int i=0; i<5; i++) begin
        @(negedge clk_r)
        col_r = col_r + 7'd1;
    end
end
    
initial begin
    forever begin
        @ (posedge clk_r)
        #1ns
        if(pixel_r_valid) begin
            for(int i=0; i<49; i++) begin
                $write("%4d", pixel_r[i]);
            end
            $write("\n");
        end
    end
end

endmodule
