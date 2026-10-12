module exp_lut(
    input signed [17:0] x,
    output reg [4:0] weight
);

always @(*) begin
    case (x)

    18'sd0:
        weight = 5'd16;//结果乘16再四舍五入

    -18'sd1:
        weight = 5'd6;

    -18'sd2:
        weight = 5'd2;

    -18'sd3:
        weight = 5'd1;

    default:
        weight = 5'd0;


    endcase
end

endmodule