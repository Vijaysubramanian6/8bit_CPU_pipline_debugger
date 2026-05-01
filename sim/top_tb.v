// `timescale 1ns/1ps
// module top_tb();
//     reg clk, rst,debug_halt, external_step_btn;
//     reg [2:0] debug_reg;
//     wire [7:0] debug_data;

//     top_piplined uut (.clk(clk), .rst(rst), .debug_halt(debug_halt), .external_step_btn(external_step_btn), .debug_data(debug_data), .debug_reg(debug_reg));

//     always #0.005 clk = ~clk;
	
//     initial begin
//         clk = 0; rst = 0; debug_halt =0;
//         external_step_btn =0;
//         repeat(1) @(posedge clk);
//          rst = 1; // Release reset
//         repeat(3) @(posedge clk);

//         debug_halt =1;
//         repeat(2) @(posedge clk);

//         repeat(3) begin
//             external_step_btn = 1;
//             repeat(2) @(negedge clk);

//             external_step_btn =0;
//             repeat(1) @(negedge clk);

//         end
//         // // 3. Loop through all 8 registers and print their values
//         // for (integer i = 0; i < 8; i = i + 1) begin
//         //     debug_reg = i;
//         //     repeat(2) @(posedge clk); // Small delay to let the combinational read port update
//         //     $display("DEBUG: Register R%0d = %h", i, debug_data);
//         // end

//         repeat(10) @(posedge clk);

//         debug_halt = 0;

//          repeat(3) begin
//             external_step_btn = 1;
//             repeat(2) @(negedge clk);

//             external_step_btn =0;
//             repeat(1) @(negedge clk);

//         end

//         #10;

//          $finish;
//     end

//     initial begin
//         $dumpfile("cpu_sim.vcd");
//         $dumpvars(0, top_tb);
//         // $monitor("Time: %0t | PC: %h | Instr: %h | Reg0: %h", $time, uut.pc, uut.instruction, uut.reg_file.registers[0]);
//     end
// endmodule





