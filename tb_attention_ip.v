module tb_attention_ip;

reg clk,rst_n,start;
reg signed [7:0] q_in,k_in,v_in;
reg q_valid,kv_valid;

wire data_ready,out_valid,done;
wire signed [7:0] out_data;

attention_ip dut(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .q_in(q_in),
    .k_in(k_in),
    .v_in(v_in),
    .q_valid(q_valid),
    .kv_valid(kv_valid),
    .data_ready(data_ready),
    .out_data(out_data),
    .out_valid(out_valid),
    .done(done)
);

initial begin
    clk = 1'b0;
end

always #5 clk = ~clk;

task send_q;
    input signed [7:0] data;

    begin
        @(negedge clk);
        q_in = data;
        q_valid = 1'b1;
        @(negedge clk);
        q_valid = 1'b0;
    end

endtask

task send_kv;
    input signed [7:0] k_data;
    input signed [7:0] v_data;
    begin
        @(negedge clk);
        k_in = k_data;
        v_in = v_data;

        kv_valid = 1'b1;

        @(negedge clk);

        kv_valid = 1'b0;
    end
endtask

initial
begin
    rst_n = 1'b0;
    start = 1'b0;
    q_in = 8'sd0;
    k_in = 8'sd0;
    v_in = 8'sd0;
    q_valid = 1'b0;
    kv_valid = 1'b0;

    #20;

    rst_n = 1'b1;

    @(posedge clk);
    start = 1'b1;

    @(posedge clk);
    start = 1'b0;


// Q
send_q(6);
send_q(2);
send_q(8);
send_q(5);

// K / V
send_kv(-5, -8);
send_kv(-6, -7);
send_kv(-1, -4);
send_kv(-7, -6);
send_kv(-4, 4);
send_kv(-6, 1);
send_kv(-5, -8);
send_kv(1, 0);
send_kv(0, 3);
send_kv(1, 3);
send_kv(-7, -8);
send_kv(-4, 4);
send_kv(3, -1);
send_kv(-6, 1);
send_kv(2, 2);
send_kv(-7, -6);
send_kv(-6, 3);
send_kv(-5, 2);
send_kv(4, -3);
send_kv(-6, 3);
send_kv(-1, 2);
send_kv(-5, -5);
send_kv(-5, -4);
send_kv(-7, -8);
send_kv(7, 7);
send_kv(5, -6);
send_kv(-5, -2);
send_kv(5, 3);
send_kv(-6, -5);
send_kv(6, 8);
send_kv(-5, -1);
send_kv(-3, -7);




    #1100;


    $display("acc_buf[0] = %d", dut.acc_buf[0]);
    $display("acc_buf[1] = %d", dut.acc_buf[1]);
    $display("acc_buf[2] = %d", dut.acc_buf[2]);
    $display("acc_buf[3] = %d", dut.acc_buf[3]);

    $finish;
end



initial
begin
    $dumpfile("attention.vcd");
    $dumpvars(0,tb_attention_ip);
end

endmodule