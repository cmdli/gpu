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
`define ST 12

`define F0 0
`define E0 1
`define H0 2
`define L0 3
`define W0 4

module core(input clk, input [4:0] coreID, input enable, 
            input  doNextIns, output nextInsReady,
            input  overwrite, input [15:0] newPc, output halted,
            output memRead1, output [15:0] memIn1, input memReady1, input [15:0] memOut1,
            output memWrite, output [15:0] memWriteAddr, output [15:0] memWriteData,
            output spawnNewProcess, output [3:0] spawnID, output [15:0] spawnPC,
            output sync, output [15:0] syncGroup);

   reg [15:0] state = 16'h0000;
   reg [15:0] pc = 16'h0000;
   reg [15:0] inst;
   wire [3:0] op = inst[15:12];
   wire [3:0] a = inst[11:8];
   wire [3:0] b = inst[7:4];
   wire [3:0] t = inst[3:0];
   wire [7:0] ii = inst[11:4];
   wire [11:0] jjj = inst[11:0];
   wire [7:0]  ss = inst[7:0];

   assign spawnNewProcess = state == 1 && op == `SPWN;
   assign spawnID = a;
   assign spawnPC = ss;

   assign sync = state == 1 & op == `SYNC;
   assign syncGroup = jjj;
   
   assign memWrite = state == 1 && op == `ST;
   assign memWriteAddr = ss;
   assign memWriteData = regs[a];
   
   assign nextInsReady = state == 0;
   assign memRead1 = state == 0 ? 1 : 
                     state == 1 ? 1 :
                     16'hxxxx;
   assign memIn1 = state == 0 ? pc : 
                   state == 1 ? (op == `LD ? ii : op == `LDR ? regs[a]+regs[b] : 16'hxxxx) : 
                   16'hxxxx;
   assign halted = state == 2;

   reg [15:0]  regs[15:0];

   genvar      i;
   generate
       for(i = 0; i < 16; i = i + 1) begin
           always @(regs[i])
             $display("#(%d) regs[%d]: %d", coreID, i, regs[i]);
       end
   endgenerate
   
   always @(posedge clk) begin
       if(overwrite) begin
           pc <= newPc;
           state <= 0;
       end
       else if(enable) begin
           case(state)
             `F0: begin
                 if(doNextIns) begin
                     state <= 1;
                     inst <= memOut1;
                 end
             end
             `E0: begin
                 case(op)
                   `MOV: begin
                       regs[t] <= ii;
                       pc <= pc + 1;
                       state <= `F0;
                   end
                   `ADD: begin
                       regs[t] <= regs[a] + regs[b];
                       pc <= pc + 1;
                       state <= `F0;
                   end
                   `JMP: begin
                       pc <= jjj;
                       state <= `F0;
                   end
                   `HALT: begin
                       state <= `H0;
                   end
                   `LD: begin
                       if(memReady1) begin
                           regs[t] <= memOut1;
                           pc <= pc + 1;
                           state <= `F0;
                       end
                       else
                         state <= `L0;
                   end
                   `LDR: begin
                       if(memReady1) begin
                           regs[t] <= memOut1;
                           pc <= pc + 1;
                           state <= `F0;
                       end
                       else
                         state <= `L0;
                   end
                   `JEQ: begin
                       if(regs[a] == regs[b]) pc <= pc + t;
                       else pc <= pc + 1;
                       state <= `F0;
                   end
                   `JLT: begin
                       if(regs[a] < regs[b]) pc <= pc + t;
                       else pc <= pc + 1;
                       state <= `F0;
                   end
                   `JGT: begin
                       if(regs[a] > regs[b]) pc <= pc + t;
                       else pc <= pc + 1;
                       state <= `F0;
                   end
                   default: begin
                       pc <= pc + 1;
                       state <= `F0;
                   end
                 endcase // case (op)
             end // case: 1
             `H0: begin // Halting
             end
             `L0: begin // Reading
                 if(memReady1) begin
                     regs[t] <= memOut1;
                     pc <= pc + 1;
                     state <= `F0;
                 end
             end
             `W0: begin // writing
             end
           endcase // case (state)
       end
       
   end
   

endmodule // core

