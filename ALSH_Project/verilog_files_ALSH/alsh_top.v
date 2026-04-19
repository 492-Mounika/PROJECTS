// ============================================================
// Module: alsh_top (Top-Level Integration)
// Description: Integrates all sub-modules into the complete
//              Always-On Sensor Hub (ALSH) pipeline:
//
//   [sensor_if] → [moving_avg_4tap] → [threshold_compare]
//                                           ↓
//                                      [alsh_fsm] → wake_up
//
//   1. sensor_if     : Synchronizes raw sensor input
//   2. moving_avg_4tap: Filters noise via 4-sample averaging
//   3. threshold_compare: Checks if average exceeds threshold
//   4. alsh_fsm      : Generates a clean one-cycle wake pulse
// ============================================================
module alsh_top (
    input        clk,         // System clock
    input        rst,         // Active-high reset
    input        valid,       // Valid strobe from sensor
    input [11:0] sample_in,   // Raw 12-bit sensor sample
    input [11:0] threshold,   // 12-bit programmable wake threshold
    output       wake_up      // Final wake-up signal to the system
);

    // Internal wires connecting the sub-modules
    wire [11:0] sample_sync;   // Synchronized sensor data (output of sensor_if)
    wire        valid_sync;    // Synchronized valid signal (output of sensor_if)
    wire [11:0] avg_data;      // Moving average result (output of moving_avg_4tap)
    wire        wake_condition;// High when avg_data > threshold (output of threshold_compare)

    // Stage 1: Synchronize raw sensor data and valid strobe
    sensor_if m1 (
        .clk          (clk),
        .rst          (rst),
        .sensor_in    (sample_in),
        .sensor_valid (valid),
        .sample_out   (sample_sync),
        .valid_out    (valid_sync)
    );

    // Stage 2: Compute 4-tap moving average to filter out noise
    moving_avg_4tap m2 (
        .clk       (clk),
        .rst       (rst),
        .sample_in (sample_sync),
        .valid     (valid_sync),
        .avg_out   (avg_data)
    );

    // Stage 3: Compare smoothed average against the threshold (combinational)
    threshold_compare m3 (
        .avg_data    (avg_data),
        .threshold   (threshold),
        .wake_signal (wake_condition)
    );

    // Stage 4: FSM decides when to issue the wake signal
    alsh_fsm m4 (
        .clk            (clk),
        .rst            (rst),
        .valid          (valid_sync),
        .wake_condition (wake_condition),
        .wake_up        (wake_up)
    );

endmodule