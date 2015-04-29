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

   reg started = 0;
   always @(posedge clk)
     started <= 1;
   
   reg [31:0] j;
   reg [31:0] k;
   
   initial begin
       $dumpfile("cpu.vcd");
       $dumpvars(1,main);
       $dumpvars(1,count);
       syncGroups[0] = 16'hFFFF;
       for(j = 1; j < 16; j = j + 1)
         syncGroups[j] <= 0;
       $readmemh("mem.hex", mem, 0, 32);
       coreEnable[0] <= 1;
   end
   generate
       for(i = 0; i < 16; i = i + 1) begin
           initial begin
               $dumpfile("cpu.vcd");
               $dumpvars(1, cores[i].inst);
               $dumpvars(1, coreReadTimer[i]);
               coreEnable[i] <= 0;
           end
       end
   endgenerate

   wire [15:0] insDoneThisCycle = (coreEnable[0] && coreDoNextIns[0] && coreReady[0]) +
                           (coreEnable[1] && coreDoNextIns[1] && coreReady[1]) +
                           (coreEnable[2] && coreDoNextIns[2] && coreReady[2]) +
                           (coreEnable[3] && coreDoNextIns[3] && coreReady[3]) +
                           (coreEnable[4] && coreDoNextIns[4] && coreReady[4]) +
                           (coreEnable[5] && coreDoNextIns[5] && coreReady[5]) +
                           (coreEnable[6] && coreDoNextIns[6] && coreReady[6]) +
                           (coreEnable[7] && coreDoNextIns[7] && coreReady[7]) +
                           (coreEnable[8] && coreDoNextIns[8] && coreReady[8]) +
                           (coreEnable[9] && coreDoNextIns[9] && coreReady[9]) +
                           (coreEnable[10] && coreDoNextIns[10] && coreReady[10]) +
                           (coreEnable[11] && coreDoNextIns[11] && coreReady[11]) +
                           (coreEnable[12] && coreDoNextIns[12] && coreReady[12]) +
                           (coreEnable[13] && coreDoNextIns[13] && coreReady[13]) +
                           (coreEnable[14] && coreDoNextIns[14] && coreReady[14]) +
                           (coreEnable[15] && coreDoNextIns[15] && coreReady[15]);
   wire clk;
   clock c0(clk);
   counter count(coreHalted[0], clk, insDoneThisCycle != 0, insDoneThisCycle, cycle);

   reg [15:0] mem[1023:0];

   reg coreEnable[15:0];
   wire coreDoNextIns[15:0];
   wire coreOverwrite[15:0];
   wire [15:0] coreNewPC[15:0];
   wire        memRead[15:0];
   wire [15:0] memIn[15:0];
   wire [15:0] memOut[15:0];
   wire        memReady[15:0];
   wire        memWrite[15:0];
   wire [15:0] memWriteAddr[15:0];
   wire [15:0] memWriteData[15:0];
   wire [15:0] coreReady;
   wire        coreHalted[15:0];
   wire        coreSpawn[15:0];
   wire [3:0]  coreSpawnID[15:0];
   wire [15:0] coreSpawnPC[15:0];
   wire        coreSync[15:0];
   wire [15:0] coreSyncGroup[15:0];
   wire        coreDoingIns[15:0];
   generate
       for(i = 0; i < 16; i = i + 1) begin : cores
           core inst(clk, i, coreEnable[i],
                     coreDoNextIns[i], coreReady[i],
                     coreOverwrite[i], coreNewPC[i], coreHalted[i],
                     memRead[i], memIn[i], memReady[i], memOut[i],
                     memWrite[i], memWriteAddr[i], memWriteData[i],
                     coreSpawn[i], coreSpawnID[i], coreSpawnPC[i],
                     coreSync[i], coreSyncGroup[i]);
       end
   endgenerate

   
   reg [15:0] coreReadAddr[15:0];
   reg [15:0] coreReadTimer[15:0];
   initial begin
       for(j = 0; j < 16; j = j + 1) begin
           coreReadTimer[j] <= 0;
           coreReadAddr[j] <= 0;
       end
   end
   genvar      i;
   generate
       for(i = 0; i < 16; i = i + 1) begin
           always @(posedge clk) begin
               if(memRead[i]) begin
                   coreReadAddr[i] <= memIn[i];
                   coreReadTimer[i] <= 12;
               end
               else if(coreReadTimer[i] != 0)
                 coreReadTimer[i] <= coreReadTimer[i] - 1;
           end
           assign memOut[i] = coreReadTimer[i] == 1 ? mem[coreReadAddr[i]] : 16'hxxxx;
           assign memReady[i] = coreReadTimer[i] == 1;
       end
   endgenerate
   always @(posedge clk) begin
       for(j = 0; j < 16; j = j + 1) begin
           if(memWrite[j]) begin
               mem[memWriteAddr[j]] <= memWriteData[j];
               $display("#mem[%d]: %d", memWriteAddr[j], memWriteData[j]);
           end
       end
   end

   wire parentCore[15:0];
   wire [3:0] parentSyncGroup[15:0];
   generate
       for(i = 0; i < 16; i = i + 1) begin
           assign parentCore[i] = (coreSpawn[0] && coreSpawnID[0] == i) ? 0 :
                                  (coreSpawn[1] && coreSpawnID[1] == i) ? 1 :
                                  (coreSpawn[2] && coreSpawnID[2] == i) ? 2 :
                                  (coreSpawn[3] && coreSpawnID[3] == i) ? 3 :
                                  (coreSpawn[4] && coreSpawnID[4] == i) ? 4 :
                                  (coreSpawn[5] && coreSpawnID[5] == i) ? 5 :
                                  (coreSpawn[6] && coreSpawnID[6] == i) ? 6 :
                                  (coreSpawn[7] && coreSpawnID[7] == i) ? 7 :
                                  (coreSpawn[8] && coreSpawnID[8] == i) ? 8 :
                                  (coreSpawn[9] && coreSpawnID[9] == i) ? 9 :
                                  (coreSpawn[10] && coreSpawnID[10] == i) ? 10 :
                                  (coreSpawn[11] && coreSpawnID[11] == i) ? 11 :
                                  (coreSpawn[12] && coreSpawnID[12] == i) ? 12 :
                                  (coreSpawn[13] && coreSpawnID[13] == i) ? 13 :
                                  (coreSpawn[14] && coreSpawnID[14] == i) ? 14 :
                                  (coreSpawn[15] && coreSpawnID[15] == i) ? 15 : 0;
           assign coreOverwrite[i] = coreSpawn[parentCore[i]] && 
                                     coreSpawnID[parentCore[i]] == i;
           assign coreNewPC[i] = coreSpawnPC[parentCore[i]];
           always @(posedge clk) begin
               if(coreOverwrite[i]) begin
                   coreEnable[i] <= 1;
                   for(j = 0; j < 16; j = j + 1) begin
                       if(syncGroups[j][parentCore[i]]) syncGroups[j][i] <= 1;
                       else syncGroups[j][i] <= 0;
                   end
               end
           end
       end // for (i = 0; i < 16; i = i + 1)
   endgenerate

   
   reg [15:0] syncGroups[15:0];
   
   reg [15:0] coresGo = 0;
   /*always @(posedge clk) begin
       coresGo <= 0;
   end*/
   generate
       //Add a core to a specific group if it requests it
       for(i = 0; i < 16; i = i + 1) begin
            always @(posedge clk) begin
                if(coreSync[i]) begin
                    for(j = 0; j < 16; j = j + 1) begin
                        if(j != i)
                          syncGroups[j][i] <= 0;
                    end
                    syncGroups[coreSyncGroup[i]][i] <= 1;
                end
            end
       end // for (i = 0; i < 16; i = i + 1)

       //If all cores in a group are ready let them go
       for(i = 1; i < 16; i = i + 1) begin
           always @(posedge clk) begin
               coresGo = 0;
               if(syncGroups[i] & coreReady == syncGroups[i]) begin
                   for(j = 0; j < 16; j = j + 1)
                     if(syncGroups[i][j]) coresGo[j] <= 1;
               end

           end
       end
       for(i = 0; i < 16; i = i + 1) begin
           assign coreDoNextIns[i] = coresGo[i];
       end
   endgenerate

   //Sync group 0 always goes
   always @(posedge clk) begin
       for(j = 0; j < 16; j = j + 1)
           if(syncGroups[0][j]) coresGo[j] <= 1;
   end

   //Print changes to syncGroups
   generate
       for(i = 0; i < 16; i = i + 1) begin
            always @(syncGroups[i])
                if(started)
                  $display("#syncGroup(%d):%b",i,syncGroups[i]);
       end
   endgenerate
   
endmodule // main
