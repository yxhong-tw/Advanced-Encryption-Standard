//
// Designer: P76124215
//

module AES(
    input clk,
    input rst,
    input [127:0] P,
    input [127:0] K,
    output reg [127:0] C,
    output reg valid
);

    reg [127:0] Ps [0:99]
    reg [6:0] P_read_index;
    reg [6:0] P_process_index;
    reg [127:0] Ks [0:99]
    reg [6:0] K_read_index;
    reg [6:0] K_process_index;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            C <= 0;
            valid <= 0;
            P_read_index <= 0;
            P_process_index <= 0;
            K_read_index <= 0;
            K_process_index <= 0;
        end
        else begin
            if (P_read_index < 100) begin
                Ps[P_read_index] <= P;
                Ks[K_read_index] <= K;
                P_read_index <= P_read_index + 1;
                K_read_index <= K_read_index + 1;
            end
        end
    end

endmodule


module One_Round(
    input clk,
    input rst,
    input [127:0] P,
    input [127:0] K,
    input [3:0] round,
    output reg [127:0] C,
    output reg valid
);

    localparam [2:0] IDLE = 0;
    localparam [2:0] READ = 1;
    localparam [2:0] SUB_BYTES = 2;
    localparam [2:0] SHIFT_ROWS = 3;
    localparam [2:0] MIX_COLUMNS = 4;
    localparam [2:0] KEY_EXPANSION = 5;
    localparam [2:0] ADD_ROUND_KEY = 6;
    localparam [2:0] DONE = 7;

    reg [2:0] state = IDLE;
    reg [2:0] next_state = IDLE;

    reg [127:0] _P;
    reg [127:0] _K;

    reg [7:0] substitution_table [0:255];

    reg [1:0] column_counter;

    reg [31:0] rcon_table [0:9];

    reg is_rotated_word;
    reg is_substituted_word;
    reg is_done_xor;

    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = (x << 1) ^ (8'h1b & {8{x[7]}});
        end
    endfunction

    function [7:0] multiply;
        input [7:0] x;
        input [1:0] mode;
        begin
            case (mode)
                0: multiply = x;
                1: multiply = xtime(x);
                2: multiply = x ^ xtime(x);
                default: multiply = 0;
            endcase
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            C <= 0;
            valid <= 0;

            _P <= 0;
            _K <= 0;

            substitution_table[8'h00] <= 8'h63;
            substitution_table[8'h01] <= 8'h7c;
            substitution_table[8'h02] <= 8'h77;
            substitution_table[8'h03] <= 8'h7b;
            substitution_table[8'h04] <= 8'hf2;
            substitution_table[8'h05] <= 8'h6b;
            substitution_table[8'h06] <= 8'h6f;
            substitution_table[8'h07] <= 8'hc5;
            substitution_table[8'h08] <= 8'h30;
            substitution_table[8'h09] <= 8'h01;
            substitution_table[8'h0a] <= 8'h67;
            substitution_table[8'h0b] <= 8'h2b;
            substitution_table[8'h0c] <= 8'hfe;
            substitution_table[8'h0d] <= 8'hd7;
            substitution_table[8'h0e] <= 8'hab;
            substitution_table[8'h0f] <= 8'h76;
            substitution_table[8'h10] <= 8'hca;
            substitution_table[8'h11] <= 8'h82;
            substitution_table[8'h12] <= 8'hc9;
            substitution_table[8'h13] <= 8'h7d;
            substitution_table[8'h14] <= 8'hfa;
            substitution_table[8'h15] <= 8'h59;
            substitution_table[8'h16] <= 8'h47;
            substitution_table[8'h17] <= 8'hf0;
            substitution_table[8'h18] <= 8'had;
            substitution_table[8'h19] <= 8'hd4;
            substitution_table[8'h1a] <= 8'ha2;
            substitution_table[8'h1b] <= 8'haf;
            substitution_table[8'h1c] <= 8'h9c;
            substitution_table[8'h1d] <= 8'ha4;
            substitution_table[8'h1e] <= 8'h72;
            substitution_table[8'h1f] <= 8'hc0;
            substitution_table[8'h20] <= 8'hb7;
            substitution_table[8'h21] <= 8'hfd;
            substitution_table[8'h22] <= 8'h93;
            substitution_table[8'h23] <= 8'h26;
            substitution_table[8'h24] <= 8'h36;
            substitution_table[8'h25] <= 8'h3f;
            substitution_table[8'h26] <= 8'hf7;
            substitution_table[8'h27] <= 8'hcc;
            substitution_table[8'h28] <= 8'h34;
            substitution_table[8'h29] <= 8'ha5;
            substitution_table[8'h2a] <= 8'he5;
            substitution_table[8'h2b] <= 8'hf1;
            substitution_table[8'h2c] <= 8'h71;
            substitution_table[8'h2d] <= 8'hd8;
            substitution_table[8'h2e] <= 8'h31;
            substitution_table[8'h2f] <= 8'h15;
            substitution_table[8'h30] <= 8'h04;
            substitution_table[8'h31] <= 8'hc7;
            substitution_table[8'h32] <= 8'h23;
            substitution_table[8'h33] <= 8'hc3;
            substitution_table[8'h34] <= 8'h18;
            substitution_table[8'h35] <= 8'h96;
            substitution_table[8'h36] <= 8'h05;
            substitution_table[8'h37] <= 8'h9a;
            substitution_table[8'h38] <= 8'h07;
            substitution_table[8'h39] <= 8'h12;
            substitution_table[8'h3a] <= 8'h80;
            substitution_table[8'h3b] <= 8'he2;
            substitution_table[8'h3c] <= 8'heb;
            substitution_table[8'h3d] <= 8'h27;
            substitution_table[8'h3e] <= 8'hb2;
            substitution_table[8'h3f] <= 8'h75;
            substitution_table[8'h40] <= 8'h09;
            substitution_table[8'h41] <= 8'h83;
            substitution_table[8'h42] <= 8'h2c;
            substitution_table[8'h43] <= 8'h1a;
            substitution_table[8'h44] <= 8'h1b;
            substitution_table[8'h45] <= 8'h6e;
            substitution_table[8'h46] <= 8'h5a;
            substitution_table[8'h47] <= 8'ha0;
            substitution_table[8'h48] <= 8'h52;
            substitution_table[8'h49] <= 8'h3b;
            substitution_table[8'h4a] <= 8'hd6;
            substitution_table[8'h4b] <= 8'hb3;
            substitution_table[8'h4c] <= 8'h29;
            substitution_table[8'h4d] <= 8'he3;
            substitution_table[8'h4e] <= 8'h2f;
            substitution_table[8'h4f] <= 8'h84;
            substitution_table[8'h50] <= 8'h53;
            substitution_table[8'h51] <= 8'hd1;
            substitution_table[8'h52] <= 8'h00;
            substitution_table[8'h53] <= 8'hed;
            substitution_table[8'h54] <= 8'h20;
            substitution_table[8'h55] <= 8'hfc;
            substitution_table[8'h56] <= 8'hb1;
            substitution_table[8'h57] <= 8'h5b;
            substitution_table[8'h58] <= 8'h6a;
            substitution_table[8'h59] <= 8'hcb;
            substitution_table[8'h5a] <= 8'hbe;
            substitution_table[8'h5b] <= 8'h39;
            substitution_table[8'h5c] <= 8'h4a;
            substitution_table[8'h5d] <= 8'h4c;
            substitution_table[8'h5e] <= 8'h58;
            substitution_table[8'h5f] <= 8'hcf;
            substitution_table[8'h60] <= 8'hd0;
            substitution_table[8'h61] <= 8'hef;
            substitution_table[8'h62] <= 8'haa;
            substitution_table[8'h63] <= 8'hfb;
            substitution_table[8'h64] <= 8'h43;
            substitution_table[8'h65] <= 8'h4d;
            substitution_table[8'h66] <= 8'h33;
            substitution_table[8'h67] <= 8'h85;
            substitution_table[8'h68] <= 8'h45;
            substitution_table[8'h69] <= 8'hf9;
            substitution_table[8'h6a] <= 8'h02;
            substitution_table[8'h6b] <= 8'h7f;
            substitution_table[8'h6c] <= 8'h50;
            substitution_table[8'h6d] <= 8'h3c;
            substitution_table[8'h6e] <= 8'h9f;
            substitution_table[8'h6f] <= 8'ha8;
            substitution_table[8'h70] <= 8'h51;
            substitution_table[8'h71] <= 8'ha3;
            substitution_table[8'h72] <= 8'h40;
            substitution_table[8'h73] <= 8'h8f;
            substitution_table[8'h74] <= 8'h92;
            substitution_table[8'h75] <= 8'h9d;
            substitution_table[8'h76] <= 8'h38;
            substitution_table[8'h77] <= 8'hf5;
            substitution_table[8'h78] <= 8'hbc;
            substitution_table[8'h79] <= 8'hb6;
            substitution_table[8'h7a] <= 8'hda;
            substitution_table[8'h7b] <= 8'h21;
            substitution_table[8'h7c] <= 8'h10;
            substitution_table[8'h7d] <= 8'hff;
            substitution_table[8'h7e] <= 8'hf3;
            substitution_table[8'h7f] <= 8'hd2;
            substitution_table[8'h80] <= 8'hcd;
            substitution_table[8'h81] <= 8'h0c;
            substitution_table[8'h82] <= 8'h13;
            substitution_table[8'h83] <= 8'hec;
            substitution_table[8'h84] <= 8'h5f;
            substitution_table[8'h85] <= 8'h97;
            substitution_table[8'h86] <= 8'h44;
            substitution_table[8'h87] <= 8'h17;
            substitution_table[8'h88] <= 8'hc4;
            substitution_table[8'h89] <= 8'ha7;
            substitution_table[8'h8a] <= 8'h7e;
            substitution_table[8'h8b] <= 8'h3d;
            substitution_table[8'h8c] <= 8'h64;
            substitution_table[8'h8d] <= 8'h5d;
            substitution_table[8'h8e] <= 8'h19;
            substitution_table[8'h8f] <= 8'h73;
            substitution_table[8'h90] <= 8'h60;
            substitution_table[8'h91] <= 8'h81;
            substitution_table[8'h92] <= 8'h4f;
            substitution_table[8'h93] <= 8'hdc;
            substitution_table[8'h94] <= 8'h22;
            substitution_table[8'h95] <= 8'h2a;
            substitution_table[8'h96] <= 8'h90;
            substitution_table[8'h97] <= 8'h88;
            substitution_table[8'h98] <= 8'h46;
            substitution_table[8'h99] <= 8'hee;
            substitution_table[8'h9a] <= 8'hb8;
            substitution_table[8'h9b] <= 8'h14;
            substitution_table[8'h9c] <= 8'hde;
            substitution_table[8'h9d] <= 8'h5e;
            substitution_table[8'h9e] <= 8'h0b;
            substitution_table[8'h9f] <= 8'hdb;
            substitution_table[8'ha0] <= 8'he0;
            substitution_table[8'ha1] <= 8'h32;
            substitution_table[8'ha2] <= 8'h3a;
            substitution_table[8'ha3] <= 8'h0a;
            substitution_table[8'ha4] <= 8'h49;
            substitution_table[8'ha5] <= 8'h06;
            substitution_table[8'ha6] <= 8'h24;
            substitution_table[8'ha7] <= 8'h5c;
            substitution_table[8'ha8] <= 8'hc2;
            substitution_table[8'ha9] <= 8'hd3;
            substitution_table[8'haa] <= 8'hac;
            substitution_table[8'hab] <= 8'h62;
            substitution_table[8'hac] <= 8'h91;
            substitution_table[8'had] <= 8'h95;
            substitution_table[8'hae] <= 8'he4;
            substitution_table[8'haf] <= 8'h79;
            substitution_table[8'hb0] <= 8'he7;
            substitution_table[8'hb1] <= 8'hc8;
            substitution_table[8'hb2] <= 8'h37;
            substitution_table[8'hb3] <= 8'h6d;
            substitution_table[8'hb4] <= 8'h8d;
            substitution_table[8'hb5] <= 8'hd5;
            substitution_table[8'hb6] <= 8'h4e;
            substitution_table[8'hb7] <= 8'ha9;
            substitution_table[8'hb8] <= 8'h6c;
            substitution_table[8'hb9] <= 8'h56;
            substitution_table[8'hba] <= 8'hf4;
            substitution_table[8'hbb] <= 8'hea;
            substitution_table[8'hbc] <= 8'h65;
            substitution_table[8'hbd] <= 8'h7a;
            substitution_table[8'hbe] <= 8'hae;
            substitution_table[8'hbf] <= 8'h08;
            substitution_table[8'hc0] <= 8'hba;
            substitution_table[8'hc1] <= 8'h78;
            substitution_table[8'hc2] <= 8'h25;
            substitution_table[8'hc3] <= 8'h2e;
            substitution_table[8'hc4] <= 8'h1c;
            substitution_table[8'hc5] <= 8'ha6;
            substitution_table[8'hc6] <= 8'hb4;
            substitution_table[8'hc7] <= 8'hc6;
            substitution_table[8'hc8] <= 8'he8;
            substitution_table[8'hc9] <= 8'hdd;
            substitution_table[8'hca] <= 8'h74;
            substitution_table[8'hcb] <= 8'h1f;
            substitution_table[8'hcc] <= 8'h4b;
            substitution_table[8'hcd] <= 8'hbd;
            substitution_table[8'hce] <= 8'h8b;
            substitution_table[8'hcf] <= 8'h8a;
            substitution_table[8'hd0] <= 8'h70;
            substitution_table[8'hd1] <= 8'h3e;
            substitution_table[8'hd2] <= 8'hb5;
            substitution_table[8'hd3] <= 8'h66;
            substitution_table[8'hd4] <= 8'h48;
            substitution_table[8'hd5] <= 8'h03;
            substitution_table[8'hd6] <= 8'hf6;
            substitution_table[8'hd7] <= 8'h0e;
            substitution_table[8'hd8] <= 8'h61;
            substitution_table[8'hd9] <= 8'h35;
            substitution_table[8'hda] <= 8'h57;
            substitution_table[8'hdb] <= 8'hb9;
            substitution_table[8'hdc] <= 8'h86;
            substitution_table[8'hdd] <= 8'hc1;
            substitution_table[8'hde] <= 8'h1d;
            substitution_table[8'hdf] <= 8'h9e;
            substitution_table[8'he0] <= 8'he1;
            substitution_table[8'he1] <= 8'hf8;
            substitution_table[8'he2] <= 8'h98;
            substitution_table[8'he3] <= 8'h11;
            substitution_table[8'he4] <= 8'h69;
            substitution_table[8'he5] <= 8'hd9;
            substitution_table[8'he6] <= 8'h8e;
            substitution_table[8'he7] <= 8'h94;
            substitution_table[8'he8] <= 8'h9b;
            substitution_table[8'he9] <= 8'h1e;
            substitution_table[8'hea] <= 8'h87;
            substitution_table[8'heb] <= 8'he9;
            substitution_table[8'hec] <= 8'hce;
            substitution_table[8'hed] <= 8'h55;
            substitution_table[8'hee] <= 8'h28;
            substitution_table[8'hef] <= 8'hdf;
            substitution_table[8'hf0] <= 8'h8c;
            substitution_table[8'hf1] <= 8'ha1;
            substitution_table[8'hf2] <= 8'h89;
            substitution_table[8'hf3] <= 8'h0d;
            substitution_table[8'hf4] <= 8'hbf;
            substitution_table[8'hf5] <= 8'he6;
            substitution_table[8'hf6] <= 8'h42;
            substitution_table[8'hf7] <= 8'h68;
            substitution_table[8'hf8] <= 8'h41;
            substitution_table[8'hf9] <= 8'h99;
            substitution_table[8'hfa] <= 8'h2d;
            substitution_table[8'hfb] <= 8'h0f;
            substitution_table[8'hfc] <= 8'hb0;
            substitution_table[8'hfd] <= 8'h54;
            substitution_table[8'hfe] <= 8'hbb;
            substitution_table[8'hff] <= 8'h16;

            column_counter = 0;

            rcon_table[0] <= 32'h01000000;
            rcon_table[1] <= 32'h02000000;
            rcon_table[2] <= 32'h04000000;
            rcon_table[3] <= 32'h08000000;
            rcon_table[4] <= 32'h10000000;
            rcon_table[5] <= 32'h20000000;
            rcon_table[6] <= 32'h40000000;
            rcon_table[7] <= 32'h80000000;
            rcon_table[8] <= 32'h1b000000;
            rcon_table[9] <= 32'h36000000;

            is_rotated_word <= 0;
            is_substituted_word <= 0;
            is_done_xor <= 0;
        end
        else begin
            state = next_state;

            case (state)
                IDLE: begin
                    C <= 0;
                    valid <= 0;

                    _P <= P;
                    _K <= K;

                    column_counter <= 0;

                    is_rotated_word <= 0;
                    is_substituted_word <= 0;
                    is_done_xor <= 0;
                end
                SUB_BYTES: begin
                    _P[7:0] <= substitution_table[_P[7:0]];
                    _P[15:8] <= substitution_table[_P[15:8]];
                    _P[23:16] <= substitution_table[_P[23:16]];
                    _P[31:24] <= substitution_table[_P[31:24]];
                    _P[39:32] <= substitution_table[_P[39:32]];
                    _P[47:40] <= substitution_table[_P[47:40]];
                    _P[55:48] <= substitution_table[_P[55:48]];
                    _P[63:56] <= substitution_table[_P[63:56]];
                    _P[71:64] <= substitution_table[_P[71:64]];
                    _P[79:72] <= substitution_table[_P[79:72]];
                    _P[87:80] <= substitution_table[_P[87:80]];
                    _P[95:88] <= substitution_table[_P[95:88]];
                    _P[103:96] <= substitution_table[_P[103:96]];
                    _P[111:104] <= substitution_table[_P[111:104]];
                    _P[119:112] <= substitution_table[_P[119:112]];
                    _P[127:120] <= substitution_table[_P[127:120]];
                end
                SHIFT_ROWS: begin
                    _P[15:8] <= _P[47:40];
                    _P[47:40] <= _P[79:72];
                    _P[79:72] <= _P[111:104];
                    _P[111:104] <= _P[15:8];
                    _P[23:16] <= _P[87:80];
                    _P[55:48] <= _P[119:112];
                    _P[87:80] <= _P[23:16];
                    _P[119:112] <= _P[55:48];
                    _P[31:24] <= _P[127:120];
                    _P[63:56] <= _P[31:24];
                    _P[95:88] <= _P[63:56];
                    _P[127:120] <= _P[95:88];
                end
                MIX_COLUMNS: begin
                    if (column_counter == 0) begin
                        _P[7:0] <= multiply(_P[7:0], 1) ^ multiply(_P[15:8], 2) ^ _P[23:16] ^ _P[31:24];
                        _P[15:8] <= _P[7:0] ^ multiply(_P[15:8], 1) ^ multiply(_P[23:16], 2) ^ _P[31:24];
                        _P[23:16] <= _P[7:0] ^ _P[15:8] ^ multiply(_P[23:16], 1) ^ multiply(_P[31:24], 2);
                        _P[31:24] <= multiply(_P[7:0], 2) ^ _P[15:8] ^ _P[23:16] ^ multiply(_P[31:24], 1);
                    end
                    else if (column_counter == 1) begin
                        _P[39:32] <= multiply(_P[39:32], 1) ^ multiply(_P[47:40], 2) ^ _P[55:48] ^ _P[63:56];
                        _P[47:40] <= _P[39:32] ^ multiply(_P[47:40], 1) ^ multiply(_P[55:48], 2) ^ _P[63:56];
                        _P[55:48] <= _P[39:32] ^ _P[47:40] ^ multiply(_P[55:48], 1) ^ multiply(_P[63:56], 2);
                        _P[63:56] <= multiply(_P[39:32], 2) ^ _P[47:40] ^ _P[55:48] ^ multiply(_P[63:56], 1);
                    end
                    else if (column_counter == 2) begin
                        _P[71:64] <= multiply(_P[71:64], 1) ^ multiply(_P[79:72], 2) ^ _P[87:80] ^ _P[95:88];
                        _P[79:72] <= _P[71:64] ^ multiply(_P[79:72], 1) ^ multiply(_P[87:80], 2) ^ _P[95:88];
                        _P[87:80] <= _P[71:64] ^ _P[79:72] ^ multiply(_P[87:80], 1) ^ multiply(_P[95:88], 2);
                        _P[95:88] <= multiply(_P[71:64], 2) ^ _P[79:72] ^ _P[87:80] ^ multiply(_P[95:88], 1);
                    end
                    // column_counter == 3
                    else begin
                        _P[103:96] <= multiply(_P[103:96], 1) ^ multiply(_P[111:104], 2) ^ _P[119:112] ^ _P[127:120];
                        _P[111:104] <= _P[103:96] ^ multiply(_P[111:104], 1) ^ multiply(_P[119:112], 2) ^ _P[127:120];
                        _P[119:112] <= _P[103:96] ^ _P[111:104] ^ multiply(_P[119:112], 1) ^ multiply(_P[127:120], 2);
                        _P[127:120] <= multiply(_P[103:96], 2) ^ _P[111:104] ^ _P[119:112] ^ multiply(_P[127:120], 1);
                    end

                    column_counter <= column_counter + 1;
                end
                KEY_EXPANSION: begin
                    if (!is_rotated_word) begin
                        _K[103:96] <= _K[111:104];
                        _K[111:104] <= _K[119:112];
                        _K[119:112] <= _K[127:120];
                        _K[127:120] <= _K[103:96];

                        is_rotated_word <= 1;
                    end
                    else if (!is_substituted_word) begin
                        _K[7:0] <= substitution_table[_K[7:0]];
                        _K[15:8] <= substitution_table[_K[15:8]];
                        _K[23:16] <= substitution_table[_K[23:16]];
                        _K[31:24] <= substitution_table[_K[31:24]];
                        _K[39:32] <= substitution_table[_K[39:32]];
                        _K[47:40] <= substitution_table[_K[47:40]];
                        _K[55:48] <= substitution_table[_K[55:48]];
                        _K[63:56] <= substitution_table[_K[63:56]];
                        _K[71:64] <= substitution_table[_K[71:64]];
                        _K[79:72] <= substitution_table[_K[79:72]];
                        _K[87:80] <= substitution_table[_K[87:80]];
                        _K[95:88] <= substitution_table[_K[95:88]];
                        _K[103:96] <= substitution_table[_K[103:96]];
                        _K[111:104] <= substitution_table[_K[111:104]];
                        _K[119:112] <= substitution_table[_K[119:112]];
                        _K[127:120] <= substitution_table[_K[127:120]];

                        is_substituted_word <= 1;
                    end
                    // Do the XOR operation
                    else begin
                        _K[31:0] = _K[31:0] ^ rcon_table[round];
                        _K[63:32] = _K[63:32] ^ _K[31:0];
                        _K[95:64] = _K[95:64] ^ _K[63:32];
                        _K[127:96] = _K[127:96] ^ _K[95:64];

                        is_done_xor <= 1;
                    end
                end
                ADD_ROUND_KEY: begin
                    C <= _P ^ _K;
                end
                DONE: begin
                    valid <= 1;
                end
            endcase
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (round == 0) begin
                    next_state <= ADD_ROUND_KEY;
                end
                else begin
                    next_state <= SUB_BYTES;
                end
            end
            SUB_BYTES: begin
                next_state <= SHIFT_ROWS;
            end
            SHIFT_ROWS: begin
                if (round == 9) begin
                    next_state <= KEY_EXPANSION;
                end
                else begin
                    next_state <= MIX_COLUMNS;
                end
            end
            MIX_COLUMNS: begin
                if (column_counter == 3) begin
                    next_state <= KEY_EXPANSION;
                end
                else begin
                    next_state <= MIX_COLUMNS;
                end
            end
            KEY_EXPANSION: begin
                if (is_done_xor) begin
                    next_state <= ADD_ROUND_KEY;
                end
                else begin
                    next_state <= KEY_EXPANSION;
                end
            end
            ADD_ROUND_KEY: begin
                next_state <= DONE;
            end
            DONE: begin
                next_state <= IDLE;
            end
        endcase
    end

endmodule
