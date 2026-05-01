

// ********For interactive Debugging display 
`timescale 1ns/1ps

module top_tb();
    // --- Signals ---
    reg clk, rst;
    reg debug_halt;
    reg external_step_btn;
    reg [2:0] debug_reg;
    wire [7:0] debug_data;

    // --- File I/O Variables ---
    integer cmd_file, status_file, scan_status;

    // --- UUT Instantiation ---
    top_piplined uut (
        .clk(clk), 
        .rst(rst), 
        .debug_halt(debug_halt), 
        .external_step_btn(external_step_btn), 
        .debug_data(debug_data), 
        .debug_reg(debug_reg)
    );

    // --- Clock Generation (100MHz approx) ---
    always #0.005 clk = ~clk;
    
    // --- Main Control Logic ---
    initial begin
        // 1. Initialize Signals
        clk = 0; 
        rst = 0; 
        debug_halt = 0;
        external_step_btn = 0;
        debug_reg = 0;

        // 2. Power-on Reset Sequence
        repeat(5) @(posedge clk);
        rst = 1; 
        $display("--- CPU Reset Released. Entering Interactive Mode ---");

        // 3. The Interactive Loop (The Bridge to Python)
        // This loop runs forever, checking 'cmd.txt' for instructions from Python
        forever begin
            repeat(1) @(posedge clk); // Poll every clock cycle for responsiveness
            
            cmd_file = $fopen("cmd.txt", "r");
            if (cmd_file) begin
                // Format in cmd.txt: [halt_bit] [step_bit] [reg_address]
                // Example: 1 0 3 (Halt the CPU and show Register 3)
                scan_status = $fscanf(cmd_file, "%b %b %d", debug_halt, external_step_btn, debug_reg);
                $fclose(cmd_file);
                
                // Every time we read a command, we write the result back to status.txt
                // Python reads this file to update your console UI
                status_file = $fopen("status.txt", "w");
                if (status_file) begin
                    $fdisplay(status_file, "%h", debug_data);
                    $fclose(status_file);
                end
            end
        end
    end

    // --- Waveform Generation ---
    initial begin
        $dumpfile("cpu_sim.vcd");
        $dumpvars(0, top_tb);
        
        // Optional: Auto-finish after a very long time if Python crashes
        #1000000; 
        $display("Simulation timeout safety triggered.");
        $finish;
    end

endmodule
