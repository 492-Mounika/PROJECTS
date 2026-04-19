// ============================================================
// Module: sensor_if (Sensor Interface)
// Description: Acts as a synchronization buffer between the
//              raw sensor input and the internal digital logic.
//              It captures the sensor data and valid signal into
//              flip-flops to ensure clean, glitch-free signals
//              before they propagate deeper into the design.
//
//  Pipeline stages (2-cycle latency on valid signal):
//    Cycle 1: sample_out and sensor_valid_ff1 are registered
//    Cycle 2: sensor_valid_ff2 = delayed valid (valid_out)
//
//  This ensures that valid_out aligns with the stabilized
//  sample_out data after the register stage.
// ============================================================
module sensor_if(
    input        clk,           // System clock
    input        rst,           // Asynchronous active-high reset
    input [11:0] sensor_in,     // Raw 12-bit sensor data input
    input        sensor_valid,  // Raw valid strobe from sensor
    output reg [11:0] sample_out, // Registered (synchronized) sensor data
    output            valid_out   // Valid signal delayed by 2 cycles to match sample_out
);

    // Two flip-flop stages for the valid signal to handle synchronization
    reg sensor_valid_ff1; // Stage 1: first register of the valid signal
    reg sensor_valid_ff2; // Stage 2: second register (used as the output valid)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers to known safe state
            sample_out       <= 12'd0;
            sensor_valid_ff1 <= 1'b0;
            sensor_valid_ff2 <= 1'b0;
        end else begin
            // Register the sensor data: delays it by 1 clock cycle
            sample_out       <= sensor_in;

            // Pipeline the valid signal through two flip-flops
            sensor_valid_ff1 <= sensor_valid;     // FF1: 1-cycle delayed valid
            sensor_valid_ff2 <= sensor_valid_ff1; // FF2: 2-cycle delayed valid
        end
    end

    // valid_out is the twice-registered valid signal.
    // It aligns with sample_out to ensure downstream modules
    // only process data when it is truly stable.
    assign valid_out = sensor_valid_ff2;

endmodule