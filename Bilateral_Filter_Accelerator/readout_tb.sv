// File:    readout_tb.sv
// Author:  Lei Kuang
// Date:    20th of August 2019
// @ Imperial College London

module readout_tb;

logic       sys_clk;
logic       sys_nrst;
logic [9:0] data;
logic       data_valid;
logic [9:0] denoised_data;
logic       denoised_data_valid;

readout readout_inst(.*);

logic [9:0]     Lena [16383:0];
logic [13:0]    cnt ='0;

initial begin
    sys_clk = '0;
    forever #2.5ns sys_clk = ~sys_clk;
end

assign data = Lena[cnt];

initial begin
    $readmemb("BRAM_Lena.mem", Lena);
    
    sys_nrst = '0;
    data_valid = '0;
    
    @(posedge sys_clk)
    @(negedge sys_clk)
    sys_nrst = '1;
    @(negedge sys_clk)
    @(negedge sys_clk)
    data_valid = '1;
    
    for(int i=0; i<16384; i++) begin
        @(negedge sys_clk)
        cnt = cnt + 14'd1;
    end
    
    for(int i=0; i<16384; i++) begin
        @(negedge sys_clk)
        cnt = cnt + 14'd1;
    end
    
    data_valid = '0;
end

integer f;

initial begin
    f = $fopen("Lena_Bilteral.txt","w");
    
    for(int i=0; i<128; i++) begin
        for(int j=0; j<128; j++) begin
            forever begin
                @(posedge sys_clk)
                #1ns
                if(denoised_data_valid) begin
                    $write("%4d,",denoised_data);
                    $fwrite(f,"%4d,",denoised_data);
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
