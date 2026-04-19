`timescale 1ns/1ps
module tb_existing_aon;

    // Signals
    reg         clk;
    reg         rst_n;
    reg  [11:0] sensor_in;
    reg  [11:0] threshold;
    wire        wakeup_irq;

    // Instantiate the Unit Under Test (UUT)
    existing_aon_baseline uut (
        .clk(clk),
        .rst_n(rst_n),
        .sensor_in(sensor_in),
        .threshold(threshold),
        .wakeup_irq(wakeup_irq)
    );

    // Clock Generation: 32.768 kHz (Standard AON Clock)
    // Period is approx 30517 ns
    always #15258 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        sensor_in = 12'd0;
        threshold = 12'd1000; // Set threshold to 1000

        // Reset Sequence
        $display("--- Starting Simulation ---");
        #40000;
        rst_n = 1;
        #40000;

        // CASE 1: Stable signal below threshold (No Wakeup)
        $display("Testing Case 1: Stable signal below threshold...");
        sensor_in = 12'd500;
        #100000; // Wait for synchronizer delay (2 clock cycles)

        // CASE 2: Single Noise Spike (Existing Baseline WILL wakeup - This is the flaw!)
        $display("Testing Case 2: Noise spike above threshold...");
        sensor_in = 12'd2500; // Spike!
        #31000;               // Stay for ~1 clock cycle
        sensor_in = 12'd500;  // Back to normal
        #100000;

        // CASE 3: Real Event (Sustained High Value)
        $display("Testing Case 3: Real sustained event...");
        sensor_in = 12'd1500;
        #200000;

        // CASE 4: Signal drops back below threshold
        $display("Testing Case 4: Signal drops...");
        sensor_in = 12'd200;
        #100000;

        $display("--- Simulation Complete ---");
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t | Sensor=%d | Threshold=%d | Wakeup=%b", 
                 $time, sensor_in, threshold, wakeup_irq);
    end

endmodule