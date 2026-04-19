// ============================================================
// Module: moving_avg_4tap
// Description: Computes a 4-tap moving average of 12-bit input
//              samples. Each new valid sample shifts the delay
//              line and the output is the average of the last
//              4 samples (sum divided by 4 using right shift).
// ============================================================
module moving_avg_4tap(
    input clk,              // System clock
    input rst,              // Synchronous active-high reset
    input [11:0] sample_in, // 12-bit incoming data sample
    input valid,            // High when sample_in holds a new valid sample
    output reg [11:0] avg_out // 12-bit averaged output
);

    // Delay registers: x1 = previous sample, x2 = two samples ago, etc.
    reg [11:0] x1, x2, x3, x4;

    // 14-bit wire to hold the sum of 4 twelve-bit values without overflow
    // Max sum = 4 * 4095 = 16380, which fits in 14 bits
    wire [13:0] new_sum;

    // Combinational sum of the current sample and the last 3 stored samples
    // Note: x4 is not included in the sum — it is the oldest sample being
    // shifted out of the delay line and is no longer used in the average
    assign new_sum = sample_in + x1 + x2 + x3;

    always @(posedge clk) begin
        if (rst) begin
            // On reset, clear all delay registers and output
            x1 <= 0;
            x2 <= 0;
            x3 <= 0;
            x4 <= 0;
            avg_out <= 0;
        end
        else if (valid) begin
            // Shift the delay line: each sample moves one step older
            x4 <= x3;          // x3 becomes the oldest (shifted out next cycle)
            x3 <= x2;          // x2 moves to x3
            x2 <= x1;          // x1 moves to x2
            x1 <= sample_in;   // New sample enters as the most recent

            // Divide the sum by 4 using arithmetic right shift by 2 bits
            // This gives the average of the 4 most recent samples
            avg_out <= new_sum >> 2;
        end
        // If valid is low, hold all registers unchanged (no new sample)
    end

endmodule