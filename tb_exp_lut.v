`timescale 1ns/1ps

module tb_exp_lut;

reg  signed [17:0] x;
wire [4:0] weight;

exp_lut u_exp_lut (
    .x(x),
    .weight(weight)
);

initial begin

    x = 18'sd0;
    #10;
    $display("x = %0d, weight = %0d", x, weight);

    x = -18'sd1;
    #10;
    $display("x = %0d, weight = %0d", x, weight);

    x = -18'sd2;
    #10;
    $display("x = %0d, weight = %0d", x, weight);

    x = -18'sd3;
    #10;
    $display("x = %0d, weight = %0d", x, weight);

    x = -18'sd4;
    #10;
    $display("x = %0d, weight = %0d", x, weight);

    x = -18'sd100;
    #10;
    $display("x = %0d, weight = %0d", x, weight);

    $display("----- TEST FINISH -----");

    $finish;
end

endmodule