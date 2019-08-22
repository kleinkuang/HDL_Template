// File:    bilateral_filter_tb.sv
// Author:  Lei Kuang
// Date:    21th of August 2019
// @ Imperial College London

module bilateral_filter_tb;

logic       clk;
logic [9:0] local_window [48:0];
logic       local_window_valid;
logic [9:0] smoothed_pixel;
logic       smoothed_pixel_valid;

bilateral_filter bilateral_filter_inst(.*);

logic [6:0]      row_r           ;
logic [6:0]      col_r           ;
logic            addr_r_valid    ;

frame_blk_mem frame_blk_mem_inst
(
    .clk_r(clk),
    .clk_en_r('1),
    .row_r(row_r),
    .col_r(col_r),
    .addr_r_valid(addr_r_valid),
    .pixel_r(local_window),
    .pixel_r_valid(local_window_valid)
);

initial begin
    clk = '0;
    forever #2.5ns clk = ~clk;
end

initial begin
    row_r = '0;
    col_r = '0;
    addr_r_valid = '0;
    #100ns
    for(int i=0; i<128; i++) begin
        for(int j=0; j<128;j++) begin
            @(negedge clk)
            addr_r_valid = '1;
            @(negedge clk)
            addr_r_valid = '0;
            if(col_r==7'd127) begin
                row_r = row_r + 7'd1;
            end
            col_r = col_r + 7'd1;
        end
    end
end

integer f;

initial begin
    f = $fopen("output.txt","w");
    
    for(int i=0; i<128; i++) begin
        for(int j=0; j<128; j++) begin
            forever begin
                @(posedge clk)
                #1ns
                if(smoothed_pixel_valid) begin
                    $write("%4d,",smoothed_pixel);
                    $fwrite(f,"%4d,",smoothed_pixel);
                    break;
                end
            end
        end
        $write("\n");
        $fwrite(f,"\n");
    end
    
    $fclose(f);
end

endmodule