module existing_aon_baseline (
    input  wire        clk,        // AON Clock (typically 32kHz)
    input  wire        rst_n,      // Active low asynchronous reset
    input  wire [11:0] sensor_in,  // Raw 12-bit ADC input
    input  wire [11:0] threshold,  // Wake-up limit
    output reg         wakeup_irq  // Interrupt to CPU
);

    // Internal signals for synchronization
    reg [11:0] sync_reg_1;
    reg [11:0] sync_reg_2;

    // --- STEP 1: 2-Stage Synchronizer ---
    // Essential for 28nm industrial design to avoid metastability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg_1 <= 12'b0;
            sync_reg_2 <= 12'b0;
        end else begin
            sync_reg_1 <= sensor_in;
            sync_reg_2 <= sync_reg_1;
        end
    end

    // --- STEP 2: Threshold Comparison ---
    // Simple combinational logic with a registered output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wakeup_irq <= 1'b0;
        end else begin
            if (sync_reg_2 > threshold)
                wakeup_irq <= 1'b1;
            else
                wakeup_irq <= 1'b0;
        end
    end

endmodule