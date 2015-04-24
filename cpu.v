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

   reg [31:0] j;
   
   initial begin
       $dumpfile("cpu.vcd");
       $dumpvars(1,main);

   end
   generate
       for(i = 0; i < 16; i = i + 1) begin
           initial begin
               $dumpvars(1, cores[i].inst);
           end
       end
   endgenerate

   
   wire clk;
   clock c0(clk);
   counter count(coreHalted[0], clk, 1, cycle);

   reg [15:0] mem[1023:0];
   initial begin
       $readmemh("mem.hex", mem, 0, 32);
       coreEnable[0] <= 1;
   end

   reg coreEnable[15:0];
   wire coreDoNextIns[15:0];
   wire coreOverwrite[15:0];
   wire [15:0] coreNewPc[15:0];
   wire [15:0] memIn[15:0];
   wire [15:0] memOut[15:0];
   wire memWrite[15:0];
   wire [15:0] memWriteAddr[15:0];
   wire [15:0] memWriteData[15:0];
   wire        coreReady[15:0];
   wire        coreHalted[15:0];
   wire        coreSpawn[15:0];
   wire [3:0]  coreSpawnID[15:0];
   wire [15:0] coreSpawnPC[15:0];
   wire        coreSync[15:0];
   wire [15:0] coreSyncGroup[15:0];

   generate
       for(i = 0; i < 16; i = i + 1) begin : cores
           core inst(clk, coreEnable[i],
                     coreDoNextIns[i], coreReady[i],
                     coreOverwrite[i], coreNewPc[i], coreHalted[i],
                     memIn[i], memOut[i],
                     memWrite[i], memWriteAddr[i], memWriteData[i],
                     coreSpawn[i], coreSpawnID[i], coreSpawnPC[i],
                     coreSync[i], coreSyncGroup[i]);
       end
   endgenerate
   
   genvar      i;
   generate
       for(i = 0; i < 16; i = i + 1) begin
           assign memOut[i] = mem[memIn[i]];
           assign coreOverwrite[i] = 0;
           assign coreDoNextIns[i] = 1;
       end
   endgenerate
   

   always @(posedge clk) begin
       for(j = 0; j < 16; j = j + 1) begin
           if(memWrite[j]) begin
               mem[memWriteAddr[j]] <= memWriteData[j];
           end
       end
   end
   
   
   
endmodule // main
