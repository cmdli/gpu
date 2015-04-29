module counter(input isHalt, input clk, input W_v, input [15:0] numIns, output cycle);

   reg [31:0] count = 0;
   reg [31:0] insCount = 0;

    always @(posedge clk) begin
        if(W_v)
          insCount <= insCount + numIns;
        if (isHalt) begin
            $display("@%d cycles\t%d instrs\tCPI=%f",count, insCount, count / insCount);
            $finish;
        end
        if (count == 100000) begin
            $display("#ran for 100000 cycles");
            $finish;
        end
        count <= count + 1;
    end

    assign cycle = count;

endmodule

