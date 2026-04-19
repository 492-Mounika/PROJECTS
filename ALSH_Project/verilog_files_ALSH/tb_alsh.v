`timescale 1ns/1ps
module tb_alsh;
reg clk;
reg rst;
reg valid;
reg [11:0] sample_in;
reg [11:0] threshold;
wire wake_up;
// DUT (ALSH)
alsh_top dut (
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .sample_in(sample_in),
    .threshold(threshold),
    .wake_up(wake_up)
);
// Clock generation
always #5 clk = ~clk;
// ----------------------
// WAVEFORM DUMP
// ----------------------
initial begin
    $dumpfile("alsh.vcd");
    $dumpvars(0, tb_alsh);
end
// ----------------------
// TEST SEQUENCE
// ----------------------
initial begin
    // Initialize
    clk = 0;
    rst = 1;
    valid = 0;
    sample_in = 0;
    threshold = 12'd100;
    // ------------------
    // 1. RESET TEST
    // ------------------
    #10 rst = 0;
    // ------------------
    // 2. NO VALID INPUT
    // ------------------
    valid = 0;
    sample_in = 12'd150;
    #20;
    // ------------------
    // Enable valid
    // ------------------
    valid = 1;
    // ------------------
    // 3. LOW VALUES
    // ------------------
    #10 sample_in = 12'd20;
    #10 sample_in = 12'd30;
    #10 sample_in = 12'd40;
    #10 sample_in = 12'd50;
    // ------------------
    // 4. SINGLE SPIKE
    // ------------------
    #10 sample_in = 12'd200; // noise spike
    #10 sample_in = 12'd30;
    #10 sample_in = 12'd40;
    // ------------------
    // 5. CONTINUOUS HIGH
    // ------------------
    #10 sample_in = 12'd120;
    #10 sample_in = 12'd130;
    #10 sample_in = 12'd140;
    #10 sample_in = 12'd150;
    // ------------------
    // 6. THRESHOLD EDGE
    // ------------------
    #10 sample_in = 12'd100;
    #10 sample_in = 12'd100;
    #10 sample_in = 12'd100;
    #10 sample_in = 12'd100;
    // ------------------
    // 7. SUDDEN DROP
    // ------------------
    #10 sample_in = 12'd150;
    #10 sample_in = 12'd160;
    #10 sample_in = 12'd20;
    #10 sample_in = 12'd20;
    // ------------------
    // 8. ALTERNATING NOISE
    // ------------------
    #10 sample_in = 12'd150;
    #10 sample_in = 12'd20;
    #10 sample_in = 12'd150;
    #10 sample_in = 12'd20;
    // ------------------
    // 9. CONSTANT VALUE
    // ------------------
    #10 sample_in = 12'd100;
    #10 sample_in = 12'd100;
    #10 sample_in = 12'd100;
    #10 sample_in = 12'd100;
    // ------------------
    // 10. MAX VALUE TEST
    // ------------------
    #10 sample_in = 12'd4095;
    #10 sample_in = 12'd4095;
    // ------------------
    // 11. MIN VALUE TEST
    // ------------------
    #10 sample_in = 12'd0;
    #10 sample_in = 12'd0;
    // ------------------
    // 12. VALID GLITCH
    // ------------------
    #10 valid = 0;
    #10 valid = 1;
    #10 sample_in = 12'd150;
    // End simulation
    #50 $stop;
end
endmodule