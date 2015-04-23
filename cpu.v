`timescale 1ps/1ps

`define MOV 0
`define ADD 1
`define JMP 2
`define HALT 3
`define LD 4
`define LDR 5
`define JEQ 6
`define JLT 7
`define JGT 8
`define NOP 9
`define SYNC 10
`define SPWN 11

module main();

   initial begin
       $dumpfile("cpu.vcd");
       $dumpvars(1,main);
       $dumpvars(1,core0);
   end

   wire clk;
   clock c0(clk);
   counter count(core0halted, clk, 1, cycle);

   reg [15:0] mem[1023:0];
   initial begin
       $readmemh("mem.hex", mem, 0, 32);
   end

   wire [15:0] memIn1;
   wire [15:0] memOut1 = mem[memIn1];
   core core0(clk, 1, 1, 0, 0, core0halted, memIn1, memOut1);
   
   
endmodule // main
