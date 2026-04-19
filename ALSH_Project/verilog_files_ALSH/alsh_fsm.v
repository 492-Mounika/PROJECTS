// ============================================================
// Module: alsh_fsm
// Description: A 3-state Finite State Machine (FSM) that
//              controls the wake-up decision logic.
//
//  States:
//    IDLE  (00) — Waiting for a valid sample to arrive
//    CHECK (01) — Evaluates whether the wake condition is met
//    WAKE  (10) — Asserts the wake_up signal for one clock cycle
//
//  Transitions:
//    IDLE  → CHECK : when valid = 1
//    CHECK → WAKE  : when wake_condition = 1
//    CHECK → IDLE  : when wake_condition = 0
//    WAKE  → IDLE  : always (wake pulse is one cycle wide)
// ============================================================
module alsh_fsm (
    input       clk,            // System clock
    input       rst,            // Asynchronous active-high reset
    input       valid,          // Indicates a new averaged sample is ready
    input       wake_condition, // High when averaged value exceeds threshold
    output reg  wake_up         // Wake signal output (pulses high for one cycle)
);

    // State encoding using 2-bit localparams for readability
    localparam IDLE  = 2'b00;  // Idle: waiting for valid data
    localparam CHECK = 2'b01;  // Check: evaluate threshold result
    localparam WAKE  = 2'b10;  // Wake: issue a one-cycle wake pulse

    reg [1:0] current_state; // Holds the current FSM state (registered)
    reg [1:0] next_state;    // Holds the computed next state (combinational)

    // -------------------------------------------------------
    // Sequential Block: State Register
    // Updates current_state on every rising clock edge.
    // Resets to IDLE on asynchronous reset.
    // -------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;       // Reset forces FSM back to idle
        else
            current_state <= next_state; // Advance to next state each cycle
    end

    // -------------------------------------------------------
    // Combinational Block: Next-State Logic
    // Determines what state to go to based on current state
    // and input signals. Runs any time inputs change.
    // -------------------------------------------------------
    always @(*) begin
        next_state = current_state; // Default: stay in current state

        case (current_state)

            IDLE: begin
                // Wait here until a valid sample arrives
                if (valid)
                    next_state = CHECK; // Move to CHECK when data is ready
            end

            CHECK: begin
                // Decide based on whether threshold was exceeded
                if (wake_condition)
                    next_state = WAKE;  // Threshold exceeded → go wake the system
                else
                    next_state = IDLE;  // No threshold breach → go back to idle
            end

            WAKE: begin
                // Wake pulse lasts exactly one cycle, then return to idle
                next_state = IDLE;
            end

            default: next_state = IDLE; // Safety net for undefined states
        endcase
    end

    // -------------------------------------------------------
    // Combinational Block: Output Logic (Moore FSM)
    // Output depends only on current_state, not on inputs.
    // wake_up is high only when the FSM is in the WAKE state.
    // -------------------------------------------------------
    always @(*) begin
        wake_up = 1'b0; // Default output is low

        case (current_state)
            WAKE:    wake_up = 1'b1; // Assert wake signal for one cycle
            default: wake_up = 1'b0; // All other states: no wake
        endcase
    end

endmodule