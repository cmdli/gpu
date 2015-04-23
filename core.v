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

module core(input clk, input doNextIns, input enable,
            input overwrite, input [15:0] newPc, output halted,
            output [15:0] memIn1, input [15:0] memOut1);

   reg [15:0] state = 16'h0000;
   reg [15:0] pc = 16'h0000;
   reg [15:0] inst;
   wire [3:0] op = inst[15:12];
   wire [3:0] a = inst[11:8];
   wire [3:0] b = inst[7:4];
   wire [3:0] t = inst[3:0];
   wire [7:0] ii = inst[11:4];
   wire [11:0] jjj = inst[11:0];
   
   assign memIn1 = state == 0 ? pc : 
                   state == 1 ? (op == `LD ? ii : op == `LDR ? regs[a]+regs[b] : 16'hxxxx) : 
                   16'hxxxx;
   assign halted = state == 2;

   reg [15:0]  regs[15:0];
   
   always @(posedge clk) begin
       if(overwrite) begin
           pc <= newPc;
           state <= 0;
       end
       else if(enable) begin
           case(state)
             0: begin
                 if(doNextIns) begin
                     state <= 1;
                     inst <= memOut1;
                 end
             end
             1: begin
                 case(op)
                   `MOV: begin
                       regs[t] <= ii;
                       pc <= pc + 1;
                       state <= 0;
                   end
                   `ADD: begin
                       regs[t] <= regs[a] + regs[b];
                       pc <= pc + 1;
                       state <= 0;
                   end
                   `JMP: begin
                       pc <= jjj;
                       state <= 0;
                   end
                   `HALT: begin
                       state <= 2;
                   end
                   `LD: begin
                       regs[t] <= memOut1;
                       pc <= pc + 1;
                       state <= 0;
                   end
                   `LDR: begin
                       regs[t] <= memOut1;
                       pc <= pc + 1;
                       state <= 0;
                   end
                   `JEQ: begin
                       if(regs[a] == regs[b]) pc <= pc + t;
                       else pc <= pc + 1;
                       state <= 0;
                   end
                   `JLT: begin
                       if(regs[a] < regs[b]) pc <= pc + t;
                       else pc <= pc + 1;
                       state <= 0;
                   end
                   `JGT: begin
                       if(regs[a] > regs[b]) pc <= pc + t;
                       else pc <= pc + 1;
                       state <= 0;
                   end
                 endcase // case (op)
             end // case: 1
             2: begin // Halting
             end
             
           endcase // case (state)
       end
       
   end
   

endmodule // core

