// File:    sipo_256bit.sv
// Author:  Lei Kuang
// Date:    2019.05.20
// @ Imperial College London

// Serial In 10 bits, Parallel Out 6-bit flag + 250-bit data

module sipo_256bit
(
    input  logic            clk         ,
    input  logic            nrst        ,
    input  logic            force_rdy   ,   // The end of one-frame pixles
    input  logic            SIPO_en     ,
    input  logic [9:0]      SIPO_in     ,
    output logic            SIPO_rdy    ,
    output logic [255:0]    SIPO_out
);

logic [4:0]     data_cnt    ;
logic [249:0]   data        ;

// Count how many ADC data have been sifted in
always_ff @ (posedge clk, negedge nrst)
begin
    if(~nrst)
        data_cnt <= '0;
    else
        if(SIPO_en)
            if(data_cnt==5'd25)
                data_cnt <= 5'd1;
            else if(force_rdy)
                data_cnt <= '0;
            else
                data_cnt <= data_cnt + 5'd1;
        else if(data_cnt==5'd25)
            data_cnt <= '0;
end

// Shift ADC data into a 250-bit shift register
always_ff @ (posedge clk, negedge nrst)
begin
    if(~nrst)
        data <= '0;
    else
        if(SIPO_en)
            data[249:0] <= {SIPO_in, data[249:10]};
end

// force_rdy indicated next pixel is the end of current frame
// thus when next pixel is shifted in, the SIPO_rdy must be asserted
logic end_of_frame;
always_ff @ (posedge clk, negedge nrst)
begin
    if(~nrst)
        end_of_frame <= '0;
    else
        end_of_frame <= force_rdy;
end

assign SIPO_rdy = data_cnt==5'd25 | end_of_frame;

// Dynamic Flag
logic [15:0]    frame_cnt = '0;
logic           frame_cnt_lock = '0;

always_ff @ (posedge clk, negedge nrst)
begin
    if(~nrst)
        frame_cnt <= '0;
    else
        if(end_of_frame)
            frame_cnt <= frame_cnt==16'd50000 ? 16'd1 : frame_cnt + 16'd1;
end

logic [5:0] flag_cnt = 6'd1;

always_ff @ (posedge clk, negedge nrst)
begin
    if(~nrst)
        flag_cnt <= 6'd1;
    else
        if(frame_cnt==16'd50000) begin
            if(~frame_cnt_lock) begin
                frame_cnt_lock <= '1;
                flag_cnt <= flag_cnt=='1 ? 6'd1 : flag_cnt + 6'd1;
            end
        end
        else
            frame_cnt_lock <= '0;
end

// Output
assign SIPO_out = {end_of_frame ? flag_cnt : 6'd0, data};

/*
logic [4:0]     cnt         ;
logic [249:0]   SIPO_int    ;

// Count from 0 to 24
always_ff @(posedge clk, negedge nrst)
begin
    if(~nrst)
        cnt <= '0;
    else
        if(SIPO_en)
            if(cnt==5'd24 | force_rdy)
                cnt <= '0;
            else
                cnt <= cnt + 5'd1;
end

// -- Data In
// Data_In =>   [249:240]
//                 ||
// -- Shift Registier
//             [239:230]
//                ||
//              ...
//               ||
//           [009:000]

genvar i,j;
generate 
begin:shift
    for( i=0; i<=23; i++) begin
        always_ff @ (posedge clk, negedge nrst)
        begin
            if(~nrst)
                SIPO_int[i*10+9:i*10] <= '0;
            else
                if(SIPO_en)
                    SIPO_int[i*10+9:i*10] <= SIPO_int[(i+1)*10+9:(i+1)*10];
        end
    end
end
endgenerate

// Data In Register
always_ff @ (posedge clk, negedge nrst)
begin
    if(~nrst)
        SIPO_int[249:240] <= '0;
    else
        if(SIPO_en)
            SIPO_int[249:240] <= SIPO_in;
end

// 25x 10-bit data are ready ?
logic force_rdy_int;

always_ff @ (posedge clk, negedge nrst)
begin
    if(~nrst) begin
        force_rdy_int <= '0;
        SIPO_rdy  <= '0;
    end
    else begin
        force_rdy_int <= force_rdy;
        SIPO_rdy <= (cnt==5'd24 ? 1'b1 : 1'b0) & SIPO_en | force_rdy;
    end
end

// End of frame flag: SIPO_out[255:250]
assign SIPO_out[255:0] = {{6{force_rdy_int}}, SIPO_int[249:0]};
*/

endmodule
