module attention_ip(
    input clk, rst_n, start,
    input signed [7:0] q_in, k_in, v_in,
    input q_valid, kv_valid,
    output data_ready,
    output reg signed [7:0] out_data,
    output reg out_valid, done
);

//FSM definition
parameter IDLE = 4'd0;
parameter LOAD_Q =4'd1;
parameter LOAD_KV = 4'd2;
parameter DOT = 4'd3;
parameter EXP = 4'd4;
parameter UPDATE = 4'd5;
parameter NORM =4'd6;
parameter OUTPUT = 4'd7;

reg signed [7:0] q_buf [0:3];
reg signed [7:0] k_buf [0:7][0:3];
reg signed [7:0] v_buf [0:7][0:3];
reg signed [17:0] score_acc;
reg signed [17:0] score_buf [0:7];

reg [1:0] q_cnt;
reg [2:0] token_cnt;
reg [1:0] dim_cnt;
reg [2:0] max_cnt;
reg [2:0] exp_cnt;
reg signed [17:0] max_score;
reg [3:0] state;
reg exp_phase;
reg signed [17:0] exp_x;
wire [4:0] exp_weight;
reg [4:0] weight_buf [0:7];
reg [7:0] L;
reg [2:0] update_cnt;
reg [1:0] judge_L;

reg signed [15:0] acc_acc;
reg signed [15:0] acc_buf [0:3];
reg [2:0] acc_cnt;

reg [1:0]norm_cnt;

assign data_ready = ((state == LOAD_Q) || (state == LOAD_KV));

exp_lut u_exp_lut(
    .x(exp_x),
    .weight(exp_weight)
);

//FSM
always @(posedge clk) begin
    if(!rst_n)
    begin
        state <=IDLE;

        q_cnt <= 2'd0;
        token_cnt <= 3'd0;
        dim_cnt <= 2'd0;  
        out_valid <= 1'b0;
        done <= 1'b0;  

        score_acc <= 18'sd0;
    end

    else 
    begin
        done <= 1'b0;
        out_valid <= 1'b0;
        case(state)
            IDLE:
            begin
                if (start)
                begin
                    state <= LOAD_Q;
                end
            end

            LOAD_Q:
            begin
                if(q_valid)
                begin
                    q_buf[q_cnt] <= q_in;

                    if(q_cnt == 2'd3)
                    begin
                        q_cnt <=2'd0;
                        token_cnt <=3'b0;
                        dim_cnt <=2'd0;

                        state <= LOAD_KV;
                    end
                    else 
                    begin
                        q_cnt <= q_cnt + 1;
                    end
                end
            end

            LOAD_KV:
            begin
                if (kv_valid)
                begin
                    k_buf[token_cnt][dim_cnt] <= k_in;
                    v_buf[token_cnt][dim_cnt] <= v_in;

                    if (dim_cnt == 2'd3)
                    begin
                        dim_cnt <= 2'd0;

                        if (token_cnt == 3'd7)
                        begin
                            token_cnt <= 3'd0;
                            state <= DOT;
                        end

                        else
                        begin
                            token_cnt <= token_cnt +1'b1;
                        end
                    end

                    else
                    begin
                        dim_cnt <= dim_cnt +1'b1;
                    end
                end
            end

            DOT:
            begin
                if (dim_cnt == 2'd3)
                begin
                    score_buf[token_cnt] <= score_acc + q_buf[dim_cnt] * k_buf[token_cnt][dim_cnt];
                    score_acc <= 18'sd0;
                    dim_cnt <= 2'd0;
                    if (token_cnt == 3'd7)
                    begin
                        token_cnt <= 3'd0;
                        max_cnt <= 3'd0;
                        exp_phase <= 1'b0;
                        max_score <= score_buf[0];
                        dim_cnt<= 3'd0;
                        state <= EXP;
                    end
                    else
                    begin
                        token_cnt <= token_cnt +1'b1;
                    end
                end
                else
                begin
                    score_acc <= score_acc + q_buf[dim_cnt] * k_buf[token_cnt][dim_cnt];
                    dim_cnt <= dim_cnt +1'b1;
                end
            end

            EXP:
            begin
                if(!exp_phase)
                begin
                    if (max_cnt == 7)
                    begin
                        if(max_score < score_buf[max_cnt])
                        begin
                            max_score <= score_buf[max_cnt];
                            exp_x <= score_buf[0] - score_buf[max_cnt];
                        end
                        else
                        begin
                            exp_x <= score_buf[0] - max_score;
                        end
                        max_cnt <=0;
                        exp_phase <= 1'b1;
                        exp_cnt <= 3'b0;
                        judge_L <= 1;
                    end
                    else
                    begin
                        if(max_score < score_buf[max_cnt])
                        begin
                            max_score <= score_buf[max_cnt];
                        end
                         max_cnt <= max_cnt + 1'b1;
                    end
                end
                else
                begin
                    weight_buf[exp_cnt] <= exp_weight;
                    if(exp_cnt == 3'd7)
                    begin
                        exp_cnt <= 3'd0;
                        L <= 8'b0;
                        update_cnt <= 3'b0;
                        state <= UPDATE;
                    end
                    else
                    begin
                        exp_cnt <= exp_cnt + 1'b1;

                        exp_x <= score_buf[exp_cnt + 1'b1] - max_score;
                    end
                end
                
            end

            UPDATE:
            begin
                if(judge_L)
                begin
                    if(update_cnt == 3'd7)
                    begin
                        L <= L + weight_buf[update_cnt];
                        acc_acc <= 16'sd0;
                        acc_cnt <= 3'd0;                     
                        judge_L <= 1'b0;
                    end
                    else
                   begin
                       L <= L + weight_buf[update_cnt];
                       update_cnt <= update_cnt + 1'b1;
                   end
                end

                else
                begin
                    if(acc_cnt == 3'd7)
                    begin
                        acc_buf[dim_cnt] <= acc_acc + $signed({1'b0, weight_buf[acc_cnt]})  * v_buf[acc_cnt][dim_cnt];
                        acc_acc <= 16'sd0;
                        acc_cnt <=0;
                        if(dim_cnt == 2'd3)
                        begin
                            dim_cnt <= 2'b0;
                            norm_cnt <= 2'b0;
                            state <= NORM;
                        end
                        else
                        begin
                            dim_cnt <= dim_cnt +1'b1;
                        end
                    end
                    else
                    begin
                        acc_acc <= acc_acc + $signed({1'b0, weight_buf[acc_cnt]})  * v_buf[acc_cnt][dim_cnt];
                        acc_cnt <= acc_cnt +1'b1;
                    end
                end

            end


            NORM:
            begin
                out_valid <= 1'b1;
                if (acc_buf[norm_cnt] > 0)
                begin
                    out_data <= (acc_buf[norm_cnt]  + $signed({8'b0,L})/2)/ $signed({8'b0,L});
                end
                else
                begin
                out_data <= (acc_buf[norm_cnt]  - $signed({8'b0,L})/2)/ $signed({8'b0,L});
                end
                if(norm_cnt == 2'd3)
                begin
                    norm_cnt <=2'b0;
                    state <= OUTPUT;
                end
                else
                begin
                    norm_cnt <= norm_cnt +1'b1;
                end
            end

            OUTPUT:
            begin
                done <= 1'b1;
                state <= IDLE;
            end

            default:
            begin
                
            end


        endcase
    end
end


endmodule
