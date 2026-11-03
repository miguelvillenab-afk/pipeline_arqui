`timescale 1ns / 1ps

module regfile_dual(
    input  clk,
    input  reset,

    // vía A
    input         we3_A,
    input  [4:0]  a3_A,
    input  [31:0] wd3_A,

    // vía B
    input         we3_B,
    input  [4:0]  a3_B,
    input  [31:0] wd3_B,

    // A
    input  [4:0]  a1_A, a2_A,
    output [31:0] rd1_A, rd2_A,

    // B
    input  [4:0]  a1_B, a2_B,
    output [31:0] rd1_B, rd2_B
    );

    reg [31:0] rf [0:31];
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                rf[i] <= 32'b0;
        end else begin
            if (we3_A && (a3_A != 5'd0))
                rf[a3_A] <= wd3_A;
            if (we3_B && (a3_B != 5'd0))
                rf[a3_B] <= wd3_B;
        end
    end

    assign rd1_A = (a1_A != 5'd0) ? rf[a1_A] : 32'b0;
    assign rd2_A = (a2_A != 5'd0) ? rf[a2_A] : 32'b0;
    assign rd1_B = (a1_B != 5'd0) ? rf[a1_B] : 32'b0;
    assign rd2_B = (a2_B != 5'd0) ? rf[a2_B] : 32'b0;

endmodule