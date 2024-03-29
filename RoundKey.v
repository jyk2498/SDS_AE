// Top_Roundkey_and_Memory
// This module makes roundkeys when signal 'en' is input.
// It takes almost 36 clk to make pre-to-ten roundkey.
// When the round number value and read enable value are input, the corresponding round key 
// and the valid signal confirming whether the value is valid are output simultaneously.  
// Note : If you use the roundkey value, set the en signal to 0.
//
module Top_RoundKey_and_Memory(
    input clk,
    input areset,
    input en,
    input wire [31:0] init_word_1,
    input wire [31:0] init_word_2,
    input wire [31:0] init_word_3,
    input wire [31:0] init_word_4,
    input [3:0] read_round_number,
    input read_en,
    output wire [31:0] Round_key_w_1,
    output wire [31:0] Round_key_w_2,
    output wire [31:0] Round_key_w_3,
    output wire [31:0] Round_key_w_4,
    output wire vaild    
);
wire [3:0] r_round_num;
wire o_done;
wire [31:0] w_save_word_1,w_save_word_2,w_save_word_3,w_save_word_4;
Top_Roundkey u0(clk,areset,en,init_word_1,init_word_2,init_word_3,init_word_4,o_done,r_round_num,w_save_word_1,w_save_word_2,w_save_word_3,w_save_word_4);
key_momery u1(clk,areset,r_round_num,w_save_word_1,w_save_word_2,w_save_word_3,w_save_word_4,o_done,read_round_number,read_en,Round_key_w_1,Round_key_w_2,Round_key_w_3,Round_key_w_4,vaild);
endmodule

// Top_Roundkey
module Top_Roundkey(
    input clk,
    input areset,
    input en,
    input wire [31:0] init_word_1,
    input wire [31:0] init_word_2,
    input wire [31:0] init_word_3,
    input wire [31:0] init_word_4,
    output wire o_done,
    output reg [3:0] r_round_num,
    output wire [31:0] w_save_word_1,
    output wire [31:0] w_save_word_2,
    output wire [31:0] w_save_word_3,
    output wire [31:0] w_save_word_4
);
wire [31:0] i_word_1,i_word_2,i_word_3,i_word_4;
reg [31:0] o_save_word_1,o_save_word_2,o_save_word_3,o_save_word_4;
wire add_done;
reg Round_en;
reg [3:0] round_num;
wire [31:0] save_word_1,save_word_2,save_word_3,save_word_4;
Mux u0 (init_word_1,init_word_2,init_word_3,init_word_4,o_save_word_1,o_save_word_2,o_save_word_3,o_save_word_4,round_num,i_word_1,i_word_2,i_word_3,i_word_4);
Roundkey u1(clk,areset,Round_en,i_word_1,i_word_2,i_word_3,i_word_4,round_num,add_done,save_word_1,save_word_2,save_word_3,save_word_4);

// internal counter for round_num
always @(posedge clk or negedge areset) begin
    if(!areset) begin
        round_num <= 0;
        Round_en <= 0;
    end else if(!en) begin
        round_num <= 0;
        Round_en <= 0;
    end else if(!add_done) begin
        Round_en <= 1;
    end else if(round_num <= 4'b1010) begin
        round_num <= round_num +1;
        Round_en <= 1;
    end else begin
        Round_en <= 0; 
    end
end

always @(posedge clk or negedge areset) begin
    if(!areset) begin
        r_round_num <= 0;
    end else if(add_done) begin
    r_round_num <= round_num;
    end
end

reg r_done;
always@(posedge clk or negedge areset) begin
    if(!areset) begin
        o_save_word_1 <= 0;
        o_save_word_2 <= 0;
        o_save_word_3 <= 0;
        o_save_word_4 <= 0;
        r_done <= 0;
    end else if(add_done) begin
        o_save_word_1 <= save_word_1;
        o_save_word_2 <= save_word_2;
        o_save_word_3 <= save_word_3;
        o_save_word_4 <= save_word_4;
        r_done <= 1;
    end else begin
        r_done <= 0;
    end
end

reg c_r_done;
always@(posedge clk or negedge areset) begin
    if(!areset) begin
        c_r_done <= 0;
    end else if(r_done) begin
        c_r_done <= 1;
    end else begin
        c_r_done <= 0;
    end
end

assign o_done = en && (r_done == 1 && c_r_done == 0);
assign w_save_word_1 = o_save_word_1;
assign w_save_word_2 = o_save_word_2;
assign w_save_word_3 = o_save_word_3;
assign w_save_word_4 = o_save_word_4;


endmodule

//Roundkey
module Roundkey(
    input clk,
    input areset,
    input en,
    input [31:0] i_word_1,
    input [31:0] i_word_2,
    input [31:0] i_word_3,
    input [31:0] i_word_4,
    input [3:0] round_num,
    output o_done,
    output  [31:0] o_word_1,
    output  [31:0] o_word_2,
    output  [31:0] o_word_3,
    output  [31:0] o_word_4
);
parameter IDLE = 2'b00;
parameter ADD = 2'b01;

reg [1:0] c_state;
reg [1:0] n_state;

wire ADD_done;

always @(posedge clk or negedge areset) begin
    if(!areset) begin
        c_state <= IDLE;
    end else begin
        c_state <= n_state;
    end
end

always @(*) begin
    //n_state = IDLE;
    case(c_state)
    IDLE : if(en == 1'b1) begin
            n_state = ADD;
            end else begin
            n_state = IDLE;
            end
    ADD : if(ADD_done == 1) begin
                n_state = IDLE; 
          end else begin
                n_state = ADD;
          end
        
    default : n_state = IDLE;
    endcase
end

//output
reg ADD_en;
wire [31:0] Shift_word_4;
wire [31:0] s_box_word_4;
always @(*) begin
    case(c_state)
    IDLE :  begin
            ADD_en = 0;
        end
    ADD : begin
            ADD_en = 1;
        end
    default : begin ADD_en = 0; end
    endcase
end

wire [31:0] save_word_1,save_word_2,save_word_3,save_word_4;
wire [31:0] G_word;
Shift u0 (i_word_4,Shift_word_4);
aes_sbox u2(Shift_word_4,s_box_word_4);
Make_G u3(round_num,s_box_word_4,G_word);
ADD u4(clk,areset,ADD_en,round_num,i_word_1,i_word_2,i_word_3,i_word_4,G_word,ADD_done,save_word_1,save_word_2,save_word_3,save_word_4);
assign o_word_1 = save_word_1;
assign o_word_2 = save_word_2;
assign o_word_3 = save_word_3;
assign o_word_4 = save_word_4;
assign o_done = ADD_done;
endmodule

//Shift ( Combination )
module Shift(
    input [31:0] i_word_4,
    output reg [31:0] Shift_word_4
);

always @(*) begin
        Shift_word_4 = {i_word_4[15:8],i_word_4[23:16],i_word_4[31:24],i_word_4[7:0]};
end
endmodule


//Mux
module Mux(
    input [31:0] init_word_1,
    input [31:0] init_word_2,
    input [31:0] init_word_3,
    input [31:0] init_word_4,
    input [31:0] save_word_1,
    input [31:0] save_word_2,
    input [31:0] save_word_3,
    input [31:0] save_word_4,
    input [3:0] round_num,
    output reg [31:0] i_word_1,
    output reg [31:0] i_word_2,
    output reg [31:0] i_word_3,
    output reg [31:0] i_word_4
);
always @(*) begin
    if(round_num == 4'b0000) begin
            i_word_1 = init_word_1;
            i_word_2 = init_word_2;
            i_word_3 = init_word_3;
            i_word_4 = init_word_4;
    end else begin
            i_word_1 = save_word_1;
            i_word_2 = save_word_2;
            i_word_3 = save_word_3;
            i_word_4 = save_word_4;
    end
end
endmodule

//Make_G
module Make_G(
    input [3:0] round_num,
    input [31:0] s_box_word_4,
    output reg [31:0] G_word
);

reg [31:0] RC;
always@(*) begin
    case(round_num)
    4'b0000 : RC = 8'h00;
    4'b0001 : RC = 8'h01;
    4'b0010 : RC = 8'h02;
    4'b0011 : RC = 8'h04;
    4'b0100 : RC = 8'h08;
    4'b0101 : RC = 8'h10;
    4'b0110 : RC = 8'h20;
    4'b0111 : RC = 8'h40;
    4'b1000 : RC = 8'h80;
    4'b1001 : RC = 8'h1B;
    4'b1010 : RC = 8'h36;
    default : RC = 8'h00;
    endcase
end


always @(*) begin
        G_word = {s_box_word_4[7:0]^RC,s_box_word_4[15:8],s_box_word_4[23:16],s_box_word_4[31:24]}; 
end


endmodule

//ADD
module ADD(
    input clk,
    input areset,
    input en,
    input [3:0] round_num,
    input [31:0] i_word_1,
    input [31:0] i_word_2,
    input [31:0] i_word_3,
    input [31:0] i_word_4,
    input [31:0] G_word,
    output wire o_done,
    output reg [31:0] save_word_1,
    output reg [31:0] save_word_2,
    output reg [31:0] save_word_3,
    output reg [31:0] save_word_4
);

reg r_done;
always@(posedge clk or negedge areset) begin
    if(!areset) begin
        save_word_1 <= 32'b0;
        save_word_2 <= 32'b0;
        save_word_3 <= 32'b0;
        save_word_4 <= 32'b0;
        r_done <= 0;
    end else if(!en) begin
        save_word_1 <= 32'b0;
        save_word_2 <= 32'b0;
        save_word_3 <= 32'b0;
        save_word_4 <= 32'b0;
        r_done <= 0;
    end else if(round_num > 4'b1010) begin
        r_done <= 0;    
    end else if(round_num == 4'b0000) begin
        save_word_1 <= i_word_1;
        save_word_2 <= i_word_2;
        save_word_3 <= i_word_3;
        save_word_4 <= i_word_4;
        r_done <= 1;
    end else begin
        save_word_1 <= i_word_1 ^ G_word;
        save_word_2 <= i_word_1 ^ G_word ^ i_word_2;
        save_word_3 <= i_word_1 ^ G_word ^ i_word_2 ^ i_word_3;
        save_word_4 <= i_word_1 ^ G_word ^ i_word_2 ^ i_word_3 ^ i_word_4;
        r_done <= 1;
    end
end

reg c_r_done;
always @(posedge clk or negedge areset) begin
    if(!areset) begin
        c_r_done <= 0;
    end else if(r_done==1)begin
        c_r_done <= 1;
    end else
        c_r_done <= 0;
end

assign o_done = en && (r_done == 1 && c_r_done == 0);

endmodule


//key_momery
module key_momery(
    input clk,
    input areset,
    input [3:0] r_round_num,
    input [31:0] w_save_word_1,
    input [31:0] w_save_word_2,
    input [31:0] w_save_word_3,
    input [31:0] w_save_word_4,
    input o_done,
    input [3:0] read_round_num,
    input read_en,
    output reg [31:0] Round_key_w_1,
    output reg [31:0] Round_key_w_2,
    output reg [31:0] Round_key_w_3,
    output reg [31:0] Round_key_w_4,
    output wire vaild
);

reg [31:0] key_memory [0:43];
reg vaild_0,vaild_1,vaild_2,vaild_3,vaild_4,vaild_5,vaild_6,vaild_7,vaild_8,vaild_9,vaild_10;
always@(posedge clk or negedge areset) begin
    if(!areset) begin
        key_memory[0] <= 32'b0;
        key_memory[1] <= 32'b0;
        key_memory[2] <= 32'b0;
        key_memory[3] <= 32'b0;
        key_memory[4] <= 32'b0;
        key_memory[5] <= 32'b0;
        key_memory[6] <= 32'b0;
        key_memory[7] <= 32'b0;
        key_memory[8] <= 32'b0;
        key_memory[9] <= 32'b0;
        key_memory[10] <= 32'b0;
        key_memory[11] <= 32'b0;
        key_memory[12] <= 32'b0;
        key_memory[13] <= 32'b0;
        key_memory[14] <= 32'b0;
        key_memory[15] <= 32'b0;
        key_memory[16] <= 32'b0;
        key_memory[17] <= 32'b0;
        key_memory[18] <= 32'b0;
        key_memory[19] <= 32'b0;
        key_memory[20] <= 32'b0;
        key_memory[21] <= 32'b0;
        key_memory[22] <= 32'b0;
        key_memory[23] <= 32'b0;
        key_memory[24] <= 32'b0;
        key_memory[25] <= 32'b0;
        key_memory[26] <= 32'b0;
        key_memory[27] <= 32'b0;
        key_memory[28] <= 32'b0;
        key_memory[29] <= 32'b0;
        key_memory[30] <= 32'b0;
        key_memory[31] <= 32'b0;
        key_memory[32] <= 32'b0;
        key_memory[33] <= 32'b0;
        key_memory[34] <= 32'b0;
        key_memory[35] <= 32'b0;
        key_memory[36] <= 32'b0;
        key_memory[37] <= 32'b0;
        key_memory[38] <= 32'b0;
        key_memory[39] <= 32'b0;
        key_memory[40] <= 32'b0;
        key_memory[41] <= 32'b0;
        key_memory[42] <= 32'b0;
        key_memory[43] <= 32'b0;
        vaild_0 <= 0;
        vaild_1 <= 0;
        vaild_2 <= 0;
        vaild_3 <= 0;
        vaild_4 <= 0;
        vaild_5 <= 0;
        vaild_6 <= 0;
        vaild_7 <= 0;
        vaild_8 <= 0;
        vaild_9 <= 0;
        vaild_10 <= 0;
    end else if(o_done) begin
        if(r_round_num == 4'b0000) begin
            key_memory[0] <= w_save_word_1;
            key_memory[1] <= w_save_word_2;
            key_memory[2] <= w_save_word_3;
            key_memory[3] <= w_save_word_4;
            vaild_0 <= 1;
        end else if(r_round_num == 4'b0001) begin
            key_memory[4] <= w_save_word_1;
            key_memory[5] <= w_save_word_2;
            key_memory[6] <= w_save_word_3;
            key_memory[7] <= w_save_word_4;
            vaild_1 <= 1;
        end else if(r_round_num == 4'b0010) begin
            key_memory[8] <= w_save_word_1;
            key_memory[9] <= w_save_word_2;
            key_memory[10] <= w_save_word_3;
            key_memory[11] <= w_save_word_4;
            vaild_2 <= 1;
        end else if(r_round_num == 4'b0011) begin
            key_memory[12] <= w_save_word_1;
            key_memory[13] <= w_save_word_2;
            key_memory[14] <= w_save_word_3;
            key_memory[15] <= w_save_word_4;
            vaild_3 <= 1;
        end else if(r_round_num == 4'b0100) begin
            key_memory[16] <= w_save_word_1;
            key_memory[17] <= w_save_word_2;
            key_memory[18] <= w_save_word_3;
            key_memory[19] <= w_save_word_4;
            vaild_4 <= 1;
        end else if(r_round_num == 4'b0101) begin
            key_memory[20] <= w_save_word_1;
            key_memory[21] <= w_save_word_2;
            key_memory[22] <= w_save_word_3;
            key_memory[23] <= w_save_word_4;
            vaild_5 <= 1;
        end else if(r_round_num == 4'b0110) begin
            key_memory[24] <= w_save_word_1;
            key_memory[25] <= w_save_word_2;
            key_memory[26] <= w_save_word_3;
            key_memory[27] <= w_save_word_4;
            vaild_6 <= 1;
        end else if(r_round_num == 4'b0111) begin
            key_memory[28] <= w_save_word_1;
            key_memory[29] <= w_save_word_2;
            key_memory[30] <= w_save_word_3;
            key_memory[31] <= w_save_word_4;
            vaild_7 <= 1;
        end else if(r_round_num == 4'b1000) begin
            key_memory[32] <= w_save_word_1;
            key_memory[33] <= w_save_word_2;
            key_memory[34] <= w_save_word_3;
            key_memory[35] <= w_save_word_4;
            vaild_8 <= 1;
        end else if(r_round_num == 4'b1001) begin
            key_memory[36] <= w_save_word_1;
            key_memory[37] <= w_save_word_2;
            key_memory[38] <= w_save_word_3;
            key_memory[39] <= w_save_word_4;
            vaild_9 <= 1;
        end else if(r_round_num == 4'b1010) begin
            key_memory[40] <= w_save_word_1;
            key_memory[41] <= w_save_word_2;
            key_memory[42] <= w_save_word_3;
            key_memory[43] <= w_save_word_4;
            vaild_10 <= 1;
        end
    end
end
reg r_vaild;
always @ (posedge clk or negedge areset) begin
    if(!areset) begin
        Round_key_w_1 <= 0;
        Round_key_w_2 <= 0;
        Round_key_w_3 <= 0;
        Round_key_w_4 <= 0;
        r_vaild <= 0;
    end else if(!read_en) begin
        Round_key_w_1 <= 0;
        Round_key_w_2 <= 0;
        Round_key_w_3 <= 0;
        Round_key_w_4 <= 0;
        r_vaild <= 0;
    end else if(read_round_num == 4'b0000) begin
        if(vaild_0 == 1) begin
            Round_key_w_1 <= key_memory[0];
            Round_key_w_2 <= key_memory[1];
            Round_key_w_3 <= key_memory[2];
            Round_key_w_4 <= key_memory[3];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b0001) begin
        if(vaild_1 == 1) begin
            Round_key_w_1 <= key_memory[4];
            Round_key_w_2 <= key_memory[5];
            Round_key_w_3 <= key_memory[6];
            Round_key_w_4 <= key_memory[7];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b0010) begin
        if(vaild_2 == 1) begin
            Round_key_w_1 <= key_memory[8];
            Round_key_w_2 <= key_memory[9];
            Round_key_w_3 <= key_memory[10];
            Round_key_w_4 <= key_memory[11];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b0011) begin
        if(vaild_3 == 1) begin
            Round_key_w_1 <= key_memory[12];
            Round_key_w_2 <= key_memory[13];
            Round_key_w_3 <= key_memory[14];
            Round_key_w_4 <= key_memory[15];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b0100) begin
        if(vaild_4 == 1) begin
            Round_key_w_1 <= key_memory[16];
            Round_key_w_2 <= key_memory[17];
            Round_key_w_3 <= key_memory[18];
            Round_key_w_4 <= key_memory[19];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b0101) begin
        if(vaild_5 == 1) begin
            Round_key_w_1 <= key_memory[20];
            Round_key_w_2 <= key_memory[21];
            Round_key_w_3 <= key_memory[22];
            Round_key_w_4 <= key_memory[23];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b0110) begin
        if(vaild_6 == 1) begin
            Round_key_w_1 <= key_memory[24];
            Round_key_w_2 <= key_memory[25];
            Round_key_w_3 <= key_memory[26];
            Round_key_w_4 <= key_memory[27];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b0111) begin
        if(vaild_7 == 1) begin
            Round_key_w_1 <= key_memory[28];
            Round_key_w_2 <= key_memory[29];
            Round_key_w_3 <= key_memory[30];
            Round_key_w_4 <= key_memory[31];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b1000) begin
        if(vaild_8 == 1) begin
            Round_key_w_1 <= key_memory[32];
            Round_key_w_2 <= key_memory[33];
            Round_key_w_3 <= key_memory[34];
            Round_key_w_4 <= key_memory[35];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b1001) begin
        if(vaild_9 == 1) begin
            Round_key_w_1 <= key_memory[36];
            Round_key_w_2 <= key_memory[37];
            Round_key_w_3 <= key_memory[38];
            Round_key_w_4 <= key_memory[39];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end else if(read_round_num == 4'b1010) begin
        if(vaild_10 == 1) begin
            Round_key_w_1 <= key_memory[40];
            Round_key_w_2 <= key_memory[41];
            Round_key_w_3 <= key_memory[42];
            Round_key_w_4 <= key_memory[43];
            r_vaild <= 1;
        end else begin
            r_vaild <= 0;
        end
    end
end

reg c_r_vaild;
always @(posedge clk or posedge areset) begin
    if(!areset) begin
        c_r_vaild <= 0;
    end else if(!r_vaild) begin
        c_r_vaild <= 0;
    end else begin
        c_r_vaild <= 1;
    end
end
assign vaild = read_en && (r_vaild == 1 && c_r_vaild == 0);
endmodule
//S_box
module aes_sbox(
    input wire [31 : 0] sboxw, // input must be word, 1 column of state matrix
    output wire [31 : 0] new_sboxw 
);

  // SBOX 
  wire [7 : 0] sbox [0 : 255]; // array elements is 8 bits, array size is 255

  assign new_sboxw[31 : 24] = sbox[sboxw[31 : 24]];
  assign new_sboxw[23 : 16] = sbox[sboxw[23 : 16]];
  assign new_sboxw[15 : 08] = sbox[sboxw[15 : 08]];
  assign new_sboxw[07 : 00] = sbox[sboxw[07 : 00]];

  // SBOX content
  assign sbox[8'h00] = 8'h63;
  assign sbox[8'h01] = 8'h7c;
  assign sbox[8'h02] = 8'h77;
  assign sbox[8'h03] = 8'h7b;
  assign sbox[8'h04] = 8'hf2;
  assign sbox[8'h05] = 8'h6b;
  assign sbox[8'h06] = 8'h6f;
  assign sbox[8'h07] = 8'hc5;
  assign sbox[8'h08] = 8'h30;
  assign sbox[8'h09] = 8'h01;
  assign sbox[8'h0a] = 8'h67;
  assign sbox[8'h0b] = 8'h2b;
  assign sbox[8'h0c] = 8'hfe;
  assign sbox[8'h0d] = 8'hd7;
  assign sbox[8'h0e] = 8'hab;
  assign sbox[8'h0f] = 8'h76;
  assign sbox[8'h10] = 8'hca;
  assign sbox[8'h11] = 8'h82;
  assign sbox[8'h12] = 8'hc9;
  assign sbox[8'h13] = 8'h7d;
  assign sbox[8'h14] = 8'hfa;
  assign sbox[8'h15] = 8'h59;
  assign sbox[8'h16] = 8'h47;
  assign sbox[8'h17] = 8'hf0;
  assign sbox[8'h18] = 8'had;
  assign sbox[8'h19] = 8'hd4;
  assign sbox[8'h1a] = 8'ha2;
  assign sbox[8'h1b] = 8'haf;
  assign sbox[8'h1c] = 8'h9c;
  assign sbox[8'h1d] = 8'ha4;
  assign sbox[8'h1e] = 8'h72;
  assign sbox[8'h1f] = 8'hc0;
  assign sbox[8'h20] = 8'hb7;
  assign sbox[8'h21] = 8'hfd;
  assign sbox[8'h22] = 8'h93;
  assign sbox[8'h23] = 8'h26;
  assign sbox[8'h24] = 8'h36;
  assign sbox[8'h25] = 8'h3f;
  assign sbox[8'h26] = 8'hf7;
  assign sbox[8'h27] = 8'hcc;
  assign sbox[8'h28] = 8'h34;
  assign sbox[8'h29] = 8'ha5;
  assign sbox[8'h2a] = 8'he5;
  assign sbox[8'h2b] = 8'hf1;
  assign sbox[8'h2c] = 8'h71;
  assign sbox[8'h2d] = 8'hd8;
  assign sbox[8'h2e] = 8'h31;
  assign sbox[8'h2f] = 8'h15;
  assign sbox[8'h30] = 8'h04;
  assign sbox[8'h31] = 8'hc7;
  assign sbox[8'h32] = 8'h23;
  assign sbox[8'h33] = 8'hc3;
  assign sbox[8'h34] = 8'h18;
  assign sbox[8'h35] = 8'h96;
  assign sbox[8'h36] = 8'h05;
  assign sbox[8'h37] = 8'h9a;
  assign sbox[8'h38] = 8'h07;
  assign sbox[8'h39] = 8'h12;
  assign sbox[8'h3a] = 8'h80;
  assign sbox[8'h3b] = 8'he2;
  assign sbox[8'h3c] = 8'heb;
  assign sbox[8'h3d] = 8'h27;
  assign sbox[8'h3e] = 8'hb2;
  assign sbox[8'h3f] = 8'h75;
  assign sbox[8'h40] = 8'h09;
  assign sbox[8'h41] = 8'h83;
  assign sbox[8'h42] = 8'h2c;
  assign sbox[8'h43] = 8'h1a;
  assign sbox[8'h44] = 8'h1b;
  assign sbox[8'h45] = 8'h6e;
  assign sbox[8'h46] = 8'h5a;
  assign sbox[8'h47] = 8'ha0;
  assign sbox[8'h48] = 8'h52;
  assign sbox[8'h49] = 8'h3b;
  assign sbox[8'h4a] = 8'hd6;
  assign sbox[8'h4b] = 8'hb3;
  assign sbox[8'h4c] = 8'h29;
  assign sbox[8'h4d] = 8'he3;
  assign sbox[8'h4e] = 8'h2f;
  assign sbox[8'h4f] = 8'h84;
  assign sbox[8'h50] = 8'h53;
  assign sbox[8'h51] = 8'hd1;
  assign sbox[8'h52] = 8'h00;
  assign sbox[8'h53] = 8'hed;
  assign sbox[8'h54] = 8'h20;
  assign sbox[8'h55] = 8'hfc;
  assign sbox[8'h56] = 8'hb1;
  assign sbox[8'h57] = 8'h5b;
  assign sbox[8'h58] = 8'h6a;
  assign sbox[8'h59] = 8'hcb;
  assign sbox[8'h5a] = 8'hbe;
  assign sbox[8'h5b] = 8'h39;
  assign sbox[8'h5c] = 8'h4a;
  assign sbox[8'h5d] = 8'h4c;
  assign sbox[8'h5e] = 8'h58;
  assign sbox[8'h5f] = 8'hcf;
  assign sbox[8'h60] = 8'hd0;
  assign sbox[8'h61] = 8'hef;
  assign sbox[8'h62] = 8'haa;
  assign sbox[8'h63] = 8'hfb;
  assign sbox[8'h64] = 8'h43;
  assign sbox[8'h65] = 8'h4d;
  assign sbox[8'h66] = 8'h33;
  assign sbox[8'h67] = 8'h85;
  assign sbox[8'h68] = 8'h45;
  assign sbox[8'h69] = 8'hf9;
  assign sbox[8'h6a] = 8'h02;
  assign sbox[8'h6b] = 8'h7f;
  assign sbox[8'h6c] = 8'h50;
  assign sbox[8'h6d] = 8'h3c;
  assign sbox[8'h6e] = 8'h9f;
  assign sbox[8'h6f] = 8'ha8;
  assign sbox[8'h70] = 8'h51;
  assign sbox[8'h71] = 8'ha3;
  assign sbox[8'h72] = 8'h40;
  assign sbox[8'h73] = 8'h8f;
  assign sbox[8'h74] = 8'h92;
  assign sbox[8'h75] = 8'h9d;
  assign sbox[8'h76] = 8'h38;
  assign sbox[8'h77] = 8'hf5;
  assign sbox[8'h78] = 8'hbc;
  assign sbox[8'h79] = 8'hb6;
  assign sbox[8'h7a] = 8'hda;
  assign sbox[8'h7b] = 8'h21;
  assign sbox[8'h7c] = 8'h10;
  assign sbox[8'h7d] = 8'hff;
  assign sbox[8'h7e] = 8'hf3;
  assign sbox[8'h7f] = 8'hd2;
  assign sbox[8'h80] = 8'hcd;
  assign sbox[8'h81] = 8'h0c;
  assign sbox[8'h82] = 8'h13;
  assign sbox[8'h83] = 8'hec;
  assign sbox[8'h84] = 8'h5f;
  assign sbox[8'h85] = 8'h97;
  assign sbox[8'h86] = 8'h44;
  assign sbox[8'h87] = 8'h17;
  assign sbox[8'h88] = 8'hc4;
  assign sbox[8'h89] = 8'ha7;
  assign sbox[8'h8a] = 8'h7e;
  assign sbox[8'h8b] = 8'h3d;
  assign sbox[8'h8c] = 8'h64;
  assign sbox[8'h8d] = 8'h5d;
  assign sbox[8'h8e] = 8'h19;
  assign sbox[8'h8f] = 8'h73;
  assign sbox[8'h90] = 8'h60;
  assign sbox[8'h91] = 8'h81;
  assign sbox[8'h92] = 8'h4f;
  assign sbox[8'h93] = 8'hdc;
  assign sbox[8'h94] = 8'h22;
  assign sbox[8'h95] = 8'h2a;
  assign sbox[8'h96] = 8'h90;
  assign sbox[8'h97] = 8'h88;
  assign sbox[8'h98] = 8'h46;
  assign sbox[8'h99] = 8'hee;
  assign sbox[8'h9a] = 8'hb8;
  assign sbox[8'h9b] = 8'h14;
  assign sbox[8'h9c] = 8'hde;
  assign sbox[8'h9d] = 8'h5e;
  assign sbox[8'h9e] = 8'h0b;
  assign sbox[8'h9f] = 8'hdb;
  assign sbox[8'ha0] = 8'he0;
  assign sbox[8'ha1] = 8'h32;
  assign sbox[8'ha2] = 8'h3a;
  assign sbox[8'ha3] = 8'h0a;
  assign sbox[8'ha4] = 8'h49;
  assign sbox[8'ha5] = 8'h06;
  assign sbox[8'ha6] = 8'h24;
  assign sbox[8'ha7] = 8'h5c;
  assign sbox[8'ha8] = 8'hc2;
  assign sbox[8'ha9] = 8'hd3;
  assign sbox[8'haa] = 8'hac;
  assign sbox[8'hab] = 8'h62;
  assign sbox[8'hac] = 8'h91;
  assign sbox[8'had] = 8'h95;
  assign sbox[8'hae] = 8'he4;
  assign sbox[8'haf] = 8'h79;
  assign sbox[8'hb0] = 8'he7;
  assign sbox[8'hb1] = 8'hc8;
  assign sbox[8'hb2] = 8'h37;
  assign sbox[8'hb3] = 8'h6d;
  assign sbox[8'hb4] = 8'h8d;
  assign sbox[8'hb5] = 8'hd5;
  assign sbox[8'hb6] = 8'h4e;
  assign sbox[8'hb7] = 8'ha9;
  assign sbox[8'hb8] = 8'h6c;
  assign sbox[8'hb9] = 8'h56;
  assign sbox[8'hba] = 8'hf4;
  assign sbox[8'hbb] = 8'hea;
  assign sbox[8'hbc] = 8'h65;
  assign sbox[8'hbd] = 8'h7a;
  assign sbox[8'hbe] = 8'hae;
  assign sbox[8'hbf] = 8'h08;
  assign sbox[8'hc0] = 8'hba;
  assign sbox[8'hc1] = 8'h78;
  assign sbox[8'hc2] = 8'h25;
  assign sbox[8'hc3] = 8'h2e;
  assign sbox[8'hc4] = 8'h1c;
  assign sbox[8'hc5] = 8'ha6;
  assign sbox[8'hc6] = 8'hb4;
  assign sbox[8'hc7] = 8'hc6;
  assign sbox[8'hc8] = 8'he8;
  assign sbox[8'hc9] = 8'hdd;
  assign sbox[8'hca] = 8'h74;
  assign sbox[8'hcb] = 8'h1f;
  assign sbox[8'hcc] = 8'h4b;
  assign sbox[8'hcd] = 8'hbd;
  assign sbox[8'hce] = 8'h8b;
  assign sbox[8'hcf] = 8'h8a;
  assign sbox[8'hd0] = 8'h70;
  assign sbox[8'hd1] = 8'h3e;
  assign sbox[8'hd2] = 8'hb5;
  assign sbox[8'hd3] = 8'h66;
  assign sbox[8'hd4] = 8'h48;
  assign sbox[8'hd5] = 8'h03;
  assign sbox[8'hd6] = 8'hf6;
  assign sbox[8'hd7] = 8'h0e;
  assign sbox[8'hd8] = 8'h61;
  assign sbox[8'hd9] = 8'h35;
  assign sbox[8'hda] = 8'h57;
  assign sbox[8'hdb] = 8'hb9;
  assign sbox[8'hdc] = 8'h86;
  assign sbox[8'hdd] = 8'hc1;
  assign sbox[8'hde] = 8'h1d;
  assign sbox[8'hdf] = 8'h9e;
  assign sbox[8'he0] = 8'he1;
  assign sbox[8'he1] = 8'hf8;
  assign sbox[8'he2] = 8'h98;
  assign sbox[8'he3] = 8'h11;
  assign sbox[8'he4] = 8'h69;
  assign sbox[8'he5] = 8'hd9;
  assign sbox[8'he6] = 8'h8e;
  assign sbox[8'he7] = 8'h94;
  assign sbox[8'he8] = 8'h9b;
  assign sbox[8'he9] = 8'h1e;
  assign sbox[8'hea] = 8'h87;
  assign sbox[8'heb] = 8'he9;
  assign sbox[8'hec] = 8'hce;
  assign sbox[8'hed] = 8'h55;
  assign sbox[8'hee] = 8'h28;
  assign sbox[8'hef] = 8'hdf;
  assign sbox[8'hf0] = 8'h8c;
  assign sbox[8'hf1] = 8'ha1;
  assign sbox[8'hf2] = 8'h89;
  assign sbox[8'hf3] = 8'h0d;
  assign sbox[8'hf4] = 8'hbf;
  assign sbox[8'hf5] = 8'he6;
  assign sbox[8'hf6] = 8'h42;
  assign sbox[8'hf7] = 8'h68;
  assign sbox[8'hf8] = 8'h41;
  assign sbox[8'hf9] = 8'h99;
  assign sbox[8'hfa] = 8'h2d;
  assign sbox[8'hfb] = 8'h0f;
  assign sbox[8'hfc] = 8'hb0;
  assign sbox[8'hfd] = 8'h54;
  assign sbox[8'hfe] = 8'hbb;
  assign sbox[8'hff] = 8'h16;

endmodule