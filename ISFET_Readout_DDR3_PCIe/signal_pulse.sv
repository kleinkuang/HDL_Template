// File:    signal_pulse.sv
// Author:  Lei Kuang
// Date:    2019.01.02
// @ Impeial College London

// Generate Signal Pulse for Different Clock Domain

module signal_pulse
(
    input  logic    clk,
    input  logic    signal,
    output logic    pulse
);

logic lock = '0;

always_ff @ (posedge clk, negedge signal)
begin
    if(~signal)
        lock <= '0;
    else
        if(~lock)
            lock <= '1;
end

assign pulse = signal & ~lock;

endmodule
