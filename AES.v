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

    reg [127:0] rm_P [0:10];
    reg [127:0] rm_K [0:10];
    reg [127:0] rm_C [0:10];
    reg [127:0] rm_SK [0:10];
    wire [127:0] _rm_C [0:10];
    wire [127:0] _rm_SK [0:10];

    reg enable = 0;
    reg raise_valid = 0;
    reg wait_one_cycle;

    // 1 means valid; 0 means invalid.
    reg rm_valid [0:10];
    wire _rm_valid [0:10];

    genvar i;
    integer j;
    integer k;

    generate
        for (i = 0; i < 11; i = i + 1) begin
            One_Round one_round(
                .round(i),
                .P(rm_P[i]),
                .K(rm_K[i]),
                .enable(enable),
                .C(_rm_C[i]),
                .SK(_rm_SK[i]),
                .valid(_rm_valid[i])
            );
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (raise_valid) begin
            valid <= 1;
            raise_valid <= 0;
        end else begin
            valid <= 0;
        end

        if (rst) begin
            C <= 0;
            valid <= 0;

            for (j = 0; j < 11; j = j + 1) begin
                rm_P[j] <= 0;
                rm_K[j] <= 0;
                rm_C[j] <= 0;
                rm_SK[j] <= 0;
                rm_valid[j] <= 0;
            end

            enable <= 0;

            wait_one_cycle <= 1;
        end else begin
            if (wait_one_cycle) begin
                enable <= 1;
                wait_one_cycle <= 0;
            end else begin
                rm_P[0] <= P;
                rm_K[0] <= K;

                for (j = 0; j < 11; j = j + 1) begin
                    if (_rm_valid[j]) begin
                        if (j != 10) begin
                            rm_P[j + 1] <= _rm_C[j];
                            rm_K[j + 1] <= _rm_SK[j];
                        end else begin
                            C <= rm_C[j];
                            raise_valid <= 1;
                        end
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        for (k = 0; k < 11; k = k + 1) begin
            if (_rm_valid[k]) begin
                rm_C[k] <= _rm_C[k];
                rm_SK[k] <= _rm_SK[k];
                rm_valid[k] <= _rm_valid[k];
            end else begin
                rm_valid[k] <= 0;
            end
        end
    end

endmodule


module One_Round(
    input [3:0] round,
    input [127:0] P,
    input [127:0] K,
    input enable,
    output reg [127:0] C,
    output reg [127:0] SK,
    output reg valid
);
    reg [127:0] _P = 0;
    reg [127:0] _K = 0;
    reg [31:0] last_K = 0;

    reg [7:0] substitution_table [0:255];
    reg [31:0] rcon_table [0:9];

    initial begin
        substitution_table[8'h00] = 8'h63;
        substitution_table[8'h01] = 8'h7c;
        substitution_table[8'h02] = 8'h77;
        substitution_table[8'h03] = 8'h7b;
        substitution_table[8'h04] = 8'hf2;
        substitution_table[8'h05] = 8'h6b;
        substitution_table[8'h06] = 8'h6f;
        substitution_table[8'h07] = 8'hc5;
        substitution_table[8'h08] = 8'h30;
        substitution_table[8'h09] = 8'h01;
        substitution_table[8'h0a] = 8'h67;
        substitution_table[8'h0b] = 8'h2b;
        substitution_table[8'h0c] = 8'hfe;
        substitution_table[8'h0d] = 8'hd7;
        substitution_table[8'h0e] = 8'hab;
        substitution_table[8'h0f] = 8'h76;
        substitution_table[8'h10] = 8'hca;
        substitution_table[8'h11] = 8'h82;
        substitution_table[8'h12] = 8'hc9;
        substitution_table[8'h13] = 8'h7d;
        substitution_table[8'h14] = 8'hfa;
        substitution_table[8'h15] = 8'h59;
        substitution_table[8'h16] = 8'h47;
        substitution_table[8'h17] = 8'hf0;
        substitution_table[8'h18] = 8'had;
        substitution_table[8'h19] = 8'hd4;
        substitution_table[8'h1a] = 8'ha2;
        substitution_table[8'h1b] = 8'haf;
        substitution_table[8'h1c] = 8'h9c;
        substitution_table[8'h1d] = 8'ha4;
        substitution_table[8'h1e] = 8'h72;
        substitution_table[8'h1f] = 8'hc0;
        substitution_table[8'h20] = 8'hb7;
        substitution_table[8'h21] = 8'hfd;
        substitution_table[8'h22] = 8'h93;
        substitution_table[8'h23] = 8'h26;
        substitution_table[8'h24] = 8'h36;
        substitution_table[8'h25] = 8'h3f;
        substitution_table[8'h26] = 8'hf7;
        substitution_table[8'h27] = 8'hcc;
        substitution_table[8'h28] = 8'h34;
        substitution_table[8'h29] = 8'ha5;
        substitution_table[8'h2a] = 8'he5;
        substitution_table[8'h2b] = 8'hf1;
        substitution_table[8'h2c] = 8'h71;
        substitution_table[8'h2d] = 8'hd8;
        substitution_table[8'h2e] = 8'h31;
        substitution_table[8'h2f] = 8'h15;
        substitution_table[8'h30] = 8'h04;
        substitution_table[8'h31] = 8'hc7;
        substitution_table[8'h32] = 8'h23;
        substitution_table[8'h33] = 8'hc3;
        substitution_table[8'h34] = 8'h18;
        substitution_table[8'h35] = 8'h96;
        substitution_table[8'h36] = 8'h05;
        substitution_table[8'h37] = 8'h9a;
        substitution_table[8'h38] = 8'h07;
        substitution_table[8'h39] = 8'h12;
        substitution_table[8'h3a] = 8'h80;
        substitution_table[8'h3b] = 8'he2;
        substitution_table[8'h3c] = 8'heb;
        substitution_table[8'h3d] = 8'h27;
        substitution_table[8'h3e] = 8'hb2;
        substitution_table[8'h3f] = 8'h75;
        substitution_table[8'h40] = 8'h09;
        substitution_table[8'h41] = 8'h83;
        substitution_table[8'h42] = 8'h2c;
        substitution_table[8'h43] = 8'h1a;
        substitution_table[8'h44] = 8'h1b;
        substitution_table[8'h45] = 8'h6e;
        substitution_table[8'h46] = 8'h5a;
        substitution_table[8'h47] = 8'ha0;
        substitution_table[8'h48] = 8'h52;
        substitution_table[8'h49] = 8'h3b;
        substitution_table[8'h4a] = 8'hd6;
        substitution_table[8'h4b] = 8'hb3;
        substitution_table[8'h4c] = 8'h29;
        substitution_table[8'h4d] = 8'he3;
        substitution_table[8'h4e] = 8'h2f;
        substitution_table[8'h4f] = 8'h84;
        substitution_table[8'h50] = 8'h53;
        substitution_table[8'h51] = 8'hd1;
        substitution_table[8'h52] = 8'h00;
        substitution_table[8'h53] = 8'hed;
        substitution_table[8'h54] = 8'h20;
        substitution_table[8'h55] = 8'hfc;
        substitution_table[8'h56] = 8'hb1;
        substitution_table[8'h57] = 8'h5b;
        substitution_table[8'h58] = 8'h6a;
        substitution_table[8'h59] = 8'hcb;
        substitution_table[8'h5a] = 8'hbe;
        substitution_table[8'h5b] = 8'h39;
        substitution_table[8'h5c] = 8'h4a;
        substitution_table[8'h5d] = 8'h4c;
        substitution_table[8'h5e] = 8'h58;
        substitution_table[8'h5f] = 8'hcf;
        substitution_table[8'h60] = 8'hd0;
        substitution_table[8'h61] = 8'hef;
        substitution_table[8'h62] = 8'haa;
        substitution_table[8'h63] = 8'hfb;
        substitution_table[8'h64] = 8'h43;
        substitution_table[8'h65] = 8'h4d;
        substitution_table[8'h66] = 8'h33;
        substitution_table[8'h67] = 8'h85;
        substitution_table[8'h68] = 8'h45;
        substitution_table[8'h69] = 8'hf9;
        substitution_table[8'h6a] = 8'h02;
        substitution_table[8'h6b] = 8'h7f;
        substitution_table[8'h6c] = 8'h50;
        substitution_table[8'h6d] = 8'h3c;
        substitution_table[8'h6e] = 8'h9f;
        substitution_table[8'h6f] = 8'ha8;
        substitution_table[8'h70] = 8'h51;
        substitution_table[8'h71] = 8'ha3;
        substitution_table[8'h72] = 8'h40;
        substitution_table[8'h73] = 8'h8f;
        substitution_table[8'h74] = 8'h92;
        substitution_table[8'h75] = 8'h9d;
        substitution_table[8'h76] = 8'h38;
        substitution_table[8'h77] = 8'hf5;
        substitution_table[8'h78] = 8'hbc;
        substitution_table[8'h79] = 8'hb6;
        substitution_table[8'h7a] = 8'hda;
        substitution_table[8'h7b] = 8'h21;
        substitution_table[8'h7c] = 8'h10;
        substitution_table[8'h7d] = 8'hff;
        substitution_table[8'h7e] = 8'hf3;
        substitution_table[8'h7f] = 8'hd2;
        substitution_table[8'h80] = 8'hcd;
        substitution_table[8'h81] = 8'h0c;
        substitution_table[8'h82] = 8'h13;
        substitution_table[8'h83] = 8'hec;
        substitution_table[8'h84] = 8'h5f;
        substitution_table[8'h85] = 8'h97;
        substitution_table[8'h86] = 8'h44;
        substitution_table[8'h87] = 8'h17;
        substitution_table[8'h88] = 8'hc4;
        substitution_table[8'h89] = 8'ha7;
        substitution_table[8'h8a] = 8'h7e;
        substitution_table[8'h8b] = 8'h3d;
        substitution_table[8'h8c] = 8'h64;
        substitution_table[8'h8d] = 8'h5d;
        substitution_table[8'h8e] = 8'h19;
        substitution_table[8'h8f] = 8'h73;
        substitution_table[8'h90] = 8'h60;
        substitution_table[8'h91] = 8'h81;
        substitution_table[8'h92] = 8'h4f;
        substitution_table[8'h93] = 8'hdc;
        substitution_table[8'h94] = 8'h22;
        substitution_table[8'h95] = 8'h2a;
        substitution_table[8'h96] = 8'h90;
        substitution_table[8'h97] = 8'h88;
        substitution_table[8'h98] = 8'h46;
        substitution_table[8'h99] = 8'hee;
        substitution_table[8'h9a] = 8'hb8;
        substitution_table[8'h9b] = 8'h14;
        substitution_table[8'h9c] = 8'hde;
        substitution_table[8'h9d] = 8'h5e;
        substitution_table[8'h9e] = 8'h0b;
        substitution_table[8'h9f] = 8'hdb;
        substitution_table[8'ha0] = 8'he0;
        substitution_table[8'ha1] = 8'h32;
        substitution_table[8'ha2] = 8'h3a;
        substitution_table[8'ha3] = 8'h0a;
        substitution_table[8'ha4] = 8'h49;
        substitution_table[8'ha5] = 8'h06;
        substitution_table[8'ha6] = 8'h24;
        substitution_table[8'ha7] = 8'h5c;
        substitution_table[8'ha8] = 8'hc2;
        substitution_table[8'ha9] = 8'hd3;
        substitution_table[8'haa] = 8'hac;
        substitution_table[8'hab] = 8'h62;
        substitution_table[8'hac] = 8'h91;
        substitution_table[8'had] = 8'h95;
        substitution_table[8'hae] = 8'he4;
        substitution_table[8'haf] = 8'h79;
        substitution_table[8'hb0] = 8'he7;
        substitution_table[8'hb1] = 8'hc8;
        substitution_table[8'hb2] = 8'h37;
        substitution_table[8'hb3] = 8'h6d;
        substitution_table[8'hb4] = 8'h8d;
        substitution_table[8'hb5] = 8'hd5;
        substitution_table[8'hb6] = 8'h4e;
        substitution_table[8'hb7] = 8'ha9;
        substitution_table[8'hb8] = 8'h6c;
        substitution_table[8'hb9] = 8'h56;
        substitution_table[8'hba] = 8'hf4;
        substitution_table[8'hbb] = 8'hea;
        substitution_table[8'hbc] = 8'h65;
        substitution_table[8'hbd] = 8'h7a;
        substitution_table[8'hbe] = 8'hae;
        substitution_table[8'hbf] = 8'h08;
        substitution_table[8'hc0] = 8'hba;
        substitution_table[8'hc1] = 8'h78;
        substitution_table[8'hc2] = 8'h25;
        substitution_table[8'hc3] = 8'h2e;
        substitution_table[8'hc4] = 8'h1c;
        substitution_table[8'hc5] = 8'ha6;
        substitution_table[8'hc6] = 8'hb4;
        substitution_table[8'hc7] = 8'hc6;
        substitution_table[8'hc8] = 8'he8;
        substitution_table[8'hc9] = 8'hdd;
        substitution_table[8'hca] = 8'h74;
        substitution_table[8'hcb] = 8'h1f;
        substitution_table[8'hcc] = 8'h4b;
        substitution_table[8'hcd] = 8'hbd;
        substitution_table[8'hce] = 8'h8b;
        substitution_table[8'hcf] = 8'h8a;
        substitution_table[8'hd0] = 8'h70;
        substitution_table[8'hd1] = 8'h3e;
        substitution_table[8'hd2] = 8'hb5;
        substitution_table[8'hd3] = 8'h66;
        substitution_table[8'hd4] = 8'h48;
        substitution_table[8'hd5] = 8'h03;
        substitution_table[8'hd6] = 8'hf6;
        substitution_table[8'hd7] = 8'h0e;
        substitution_table[8'hd8] = 8'h61;
        substitution_table[8'hd9] = 8'h35;
        substitution_table[8'hda] = 8'h57;
        substitution_table[8'hdb] = 8'hb9;
        substitution_table[8'hdc] = 8'h86;
        substitution_table[8'hdd] = 8'hc1;
        substitution_table[8'hde] = 8'h1d;
        substitution_table[8'hdf] = 8'h9e;
        substitution_table[8'he0] = 8'he1;
        substitution_table[8'he1] = 8'hf8;
        substitution_table[8'he2] = 8'h98;
        substitution_table[8'he3] = 8'h11;
        substitution_table[8'he4] = 8'h69;
        substitution_table[8'he5] = 8'hd9;
        substitution_table[8'he6] = 8'h8e;
        substitution_table[8'he7] = 8'h94;
        substitution_table[8'he8] = 8'h9b;
        substitution_table[8'he9] = 8'h1e;
        substitution_table[8'hea] = 8'h87;
        substitution_table[8'heb] = 8'he9;
        substitution_table[8'hec] = 8'hce;
        substitution_table[8'hed] = 8'h55;
        substitution_table[8'hee] = 8'h28;
        substitution_table[8'hef] = 8'hdf;
        substitution_table[8'hf0] = 8'h8c;
        substitution_table[8'hf1] = 8'ha1;
        substitution_table[8'hf2] = 8'h89;
        substitution_table[8'hf3] = 8'h0d;
        substitution_table[8'hf4] = 8'hbf;
        substitution_table[8'hf5] = 8'he6;
        substitution_table[8'hf6] = 8'h42;
        substitution_table[8'hf7] = 8'h68;
        substitution_table[8'hf8] = 8'h41;
        substitution_table[8'hf9] = 8'h99;
        substitution_table[8'hfa] = 8'h2d;
        substitution_table[8'hfb] = 8'h0f;
        substitution_table[8'hfc] = 8'hb0;
        substitution_table[8'hfd] = 8'h54;
        substitution_table[8'hfe] = 8'hbb;
        substitution_table[8'hff] = 8'h16;

        rcon_table[0] = 32'h01000000;
        rcon_table[1] = 32'h02000000;
        rcon_table[2] = 32'h04000000;
        rcon_table[3] = 32'h08000000;
        rcon_table[4] = 32'h10000000;
        rcon_table[5] = 32'h20000000;
        rcon_table[6] = 32'h40000000;
        rcon_table[7] = 32'h80000000;
        rcon_table[8] = 32'h1b000000;
        rcon_table[9] = 32'h36000000;
    end

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
                2: multiply = xtime(x);
                3: multiply = x ^ xtime(x);
            endcase
        end
    endfunction

    function [127:0] sub_bytes;
        input [127:0] x;
        begin
            sub_bytes[7:0] = substitution_table[x[7:0]];
            sub_bytes[15:8] = substitution_table[x[15:8]];
            sub_bytes[23:16] = substitution_table[x[23:16]];
            sub_bytes[31:24] = substitution_table[x[31:24]];
            sub_bytes[39:32] = substitution_table[x[39:32]];
            sub_bytes[47:40] = substitution_table[x[47:40]];
            sub_bytes[55:48] = substitution_table[x[55:48]];
            sub_bytes[63:56] = substitution_table[x[63:56]];
            sub_bytes[71:64] = substitution_table[x[71:64]];
            sub_bytes[79:72] = substitution_table[x[79:72]];
            sub_bytes[87:80] = substitution_table[x[87:80]];
            sub_bytes[95:88] = substitution_table[x[95:88]];
            sub_bytes[103:96] = substitution_table[x[103:96]];
            sub_bytes[111:104] = substitution_table[x[111:104]];
            sub_bytes[119:112] = substitution_table[x[119:112]];
            sub_bytes[127:120] = substitution_table[x[127:120]];
        end
    endfunction

    function [127:0] shift_rows;
        input [127:0] x;
        begin
            shift_rows[127:120] = x[127:120];
            shift_rows[95:88] = x[95:88];
            shift_rows[63:56] = x[63:56];
            shift_rows[31:24] = x[31:24];
            shift_rows[119:112] = x[87:80];
            shift_rows[87:80] = x[55:48];
            shift_rows[55:48] = x[23:16];
            shift_rows[23:16] = x[119:112];
            shift_rows[111:104] = x[47:40];
            shift_rows[79:72] = x[15:8];
            shift_rows[47:40] = x[111:104];
            shift_rows[15:8] = x[79:72];
            shift_rows[103:96] = x[7:0];
            shift_rows[71:64] = x[103:96];
            shift_rows[39:32] = x[71:64];
            shift_rows[7:0] = x[39:32];
        end
    endfunction

    function [127:0] mix_columns;
        input [127:0] x;
        begin
            // Column 3
            mix_columns[31:24] = multiply(x[31:24], 2) ^ multiply(x[23:16], 3) ^ x[15:8] ^ x[7:0];
            mix_columns[23:16] = x[31:24] ^ multiply(x[23:16], 2) ^ multiply(x[15:8], 3) ^ x[7:0];
            mix_columns[15:8] = x[31:24] ^ x[23:16] ^ multiply(x[15:8], 2) ^ multiply(x[7:0], 3);
            mix_columns[7:0] = multiply(x[31:24], 3) ^ x[23:16] ^ x[15:8] ^ multiply(x[7:0], 2);

            // Column 2
            mix_columns[63:56] = multiply(x[63:56], 2) ^ multiply(x[55:48], 3) ^ x[47:40] ^ x[39:32];
            mix_columns[55:48] = x[63:56] ^ multiply(x[55:48], 2) ^ multiply(x[47:40], 3) ^ x[39:32];
            mix_columns[47:40] = x[63:56] ^ x[55:48] ^ multiply(x[47:40], 2) ^ multiply(x[39:32], 3);
            mix_columns[39:32] = multiply(x[63:56], 3) ^ x[55:48] ^ x[47:40] ^ multiply(x[39:32], 2);

            // Column 1
            mix_columns[95:88] = multiply(x[95:88], 2) ^ multiply(x[87:80], 3) ^ x[79:72] ^ x[71:64];
            mix_columns[87:80] = x[95:88] ^ multiply(x[87:80], 2) ^ multiply(x[79:72], 3) ^ x[71:64];
            mix_columns[79:72] = x[95:88] ^ x[87:80] ^ multiply(x[79:72], 2) ^ multiply(x[71:64], 3);
            mix_columns[71:64] = multiply(x[95:88], 3) ^ x[87:80] ^ x[79:72] ^ multiply(x[71:64], 2);

            // Column 0
            mix_columns[127:120] = multiply(x[127:120], 2) ^ multiply(x[119:112], 3) ^ x[111:104] ^ x[103:96];
            mix_columns[119:112] = x[127:120] ^ multiply(x[119:112], 2) ^ multiply(x[111:104], 3) ^ x[103:96];
            mix_columns[111:104] = x[127:120] ^ x[119:112] ^ multiply(x[111:104], 2) ^ multiply(x[103:96], 3);
            mix_columns[103:96] = multiply(x[127:120], 3) ^ x[119:112] ^ x[111:104] ^ multiply(x[103:96], 2);
        end
    endfunction

    function [127:0] key_expansion_rot;
        input [127:0] x;
        begin
            key_expansion_rot[7:0] = x[31:24];
            key_expansion_rot[15:8] = x[7:0];
            key_expansion_rot[23:16] = x[15:8];
            key_expansion_rot[31:24] = x[23:16];

            key_expansion_rot[39:32] = x[39:32];
            key_expansion_rot[47:40] = x[47:40];
            key_expansion_rot[55:48] = x[55:48];
            key_expansion_rot[63:56] = x[63:56];
            key_expansion_rot[71:64] = x[71:64];
            key_expansion_rot[79:72] = x[79:72];
            key_expansion_rot[87:80] = x[87:80];
            key_expansion_rot[95:88] = x[95:88];
            key_expansion_rot[103:96] = x[103:96];
            key_expansion_rot[111:104] = x[111:104];
            key_expansion_rot[119:112] = x[119:112];
            key_expansion_rot[127:120] = x[127:120];
        end
    endfunction

    function [127:0] key_expansion_sub;
        input [127:0] x;
        begin
            key_expansion_sub[7:0] = substitution_table[x[7:0]];
            key_expansion_sub[15:8] = substitution_table[x[15:8]];
            key_expansion_sub[23:16] = substitution_table[x[23:16]];
            key_expansion_sub[31:24] = substitution_table[x[31:24]];

            key_expansion_sub[39:32] = x[39:32];
            key_expansion_sub[47:40] = x[47:40];
            key_expansion_sub[55:48] = x[55:48];
            key_expansion_sub[63:56] = x[63:56];
            key_expansion_sub[71:64] = x[71:64];
            key_expansion_sub[79:72] = x[79:72];
            key_expansion_sub[87:80] = x[87:80];
            key_expansion_sub[95:88] = x[95:88];
            key_expansion_sub[103:96] = x[103:96];
            key_expansion_sub[111:104] = x[111:104];
            key_expansion_sub[119:112] = x[119:112];
            key_expansion_sub[127:120] = x[127:120];
        end
    endfunction

    function [127:0] key_expansion_xor;
        input [127:0] x;
        input [31:0] last_x;
        input [31:0] y;
        begin
            key_expansion_xor[127:96] = x[127:96] ^ (x[31:0] ^ y);
            key_expansion_xor[95:64] = x[95:64] ^ key_expansion_xor[127:96];
            key_expansion_xor[63:32] = x[63:32] ^ key_expansion_xor[95:64];
            key_expansion_xor[31:0] = last_K ^ key_expansion_xor[63:32];
        end
    endfunction

    function [127:0] add_round_key;
        input [127:0] x;
        input [127:0] y;
        begin
            add_round_key = x ^ y;
        end
    endfunction

    always @(P or K) begin
        if (enable) begin
            _P = P;
            _K = K;
            last_K = K[31:0];

            if (round != 0) begin
                _P = sub_bytes(_P);
                _P = shift_rows(_P);

                if (round != 10) begin
                    _P = mix_columns(_P);
                end

                _K = key_expansion_rot(_K);
                _K = key_expansion_sub(_K);
                _K = key_expansion_xor(_K, last_K, rcon_table[round - 1]);
            end

            C = add_round_key(_P, _K);
            SK = _K;
            valid = 1;
        end
    end

endmodule
