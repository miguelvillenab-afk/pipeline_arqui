module regfile(input  clk,
               input  reset,
               input  we3, 
               input  [4:0] a1, a2, a3, 
               input  [31:0] wd3, 
               output [31:0] rd1, rd2); 

  reg [31:0] rf[0:31]; 
  integer i;

  always @(posedge clk or posedge reset) begin 
    if (reset) begin

      for (i = 0; i < 32; i = i + 1)
        rf[i] <= 32'b0;
    end else if (we3) begin
      rf[a3] <= wd3; 
    end
  end
  
  assign rd1 = (a1 != 0) ? rf[a1] : 32'b0; 
  assign rd2 = (a2 != 0) ? rf[a2] : 32'b0; 
endmodule