// Reed-Solomon ECC sub-module: 8-bit data width
// RS(5,1) over GF(2^8): N=5 bytes, K=1 data byte, T=2 correctable errors
// Primitive polynomial: 0x11D, first-consecutive-root (FCR)=0
//
// Codeword layout (40 bits, little-endian byte):
//   [7:0]  – data byte 0
//   [15:8] – parity byte 0
//   [23:16]– parity byte 1
//   [31:24]– parity byte 2
//   [39:32]– parity byte 3
//
// Encode: combinational GF(2^8) polynomial division; result registered on clock edge.
// Decode: 4 syndromes S0–S3 computed combinationally; error_corrected is a placeholder (=0).
// Latency: 1 clock cycle from enable assertion to valid_out pulse.

module reed_solomon_ecc_w8 (
    input  wire clk,
    input  wire rst_n,        // Active-low asynchronous reset
    input  wire encode_en,    // Assert to encode data_in; output valid next cycle
    input  wire decode_en,    // Assert to decode codeword_in; output valid next cycle
    input  wire [7:0]  data_in,       // 8-bit data word (one GF symbol)
    input  wire [39:0] codeword_in,   // Received codeword for syndrome check / decode
    output reg  [39:0] codeword_out,  // Encoded codeword (data at LSB, parity at MSB)
    output reg  [7:0]  data_out,      // Extracted data from codeword_in[7:0]
    output reg  error_detected,       // Non-zero syndrome: at least one symbol is in error
    output reg  error_corrected,      // Placeholder — correction not yet implemented (always 0)
    output reg  valid_out             // Single-cycle pulse indicating output is valid
);
    wire [7:0] msg_bytes [0:0];
    assign msg_bytes[0] = data_in[7:0];  // Full byte — no zero extension needed

    // --- Encoder: GF(2^8) polynomial remainder (combinational) ---
    wire [7:0] feedback_0 = 8'b0 ^ msg_bytes[0];
    assign mul_0_0[0] = feedback_0[2] ^ feedback_0[6] ^ feedback_0[7];
    assign mul_0_0[1] = feedback_0[3] ^ feedback_0[7];
    assign mul_0_0[2] = feedback_0[2] ^ feedback_0[4] ^ feedback_0[6] ^ feedback_0[7];
    assign mul_0_0[3] = feedback_0[2] ^ feedback_0[3] ^ feedback_0[5] ^ feedback_0[6];
    assign mul_0_0[4] = feedback_0[2] ^ feedback_0[3] ^ feedback_0[4];
    assign mul_0_0[5] = feedback_0[3] ^ feedback_0[4] ^ feedback_0[5];
    assign mul_0_0[6] = feedback_0[0] ^ feedback_0[4] ^ feedback_0[5] ^ feedback_0[6];
    assign mul_0_0[7] = feedback_0[1] ^ feedback_0[5] ^ feedback_0[6] ^ feedback_0[7];
    wire [7:0] mul_0_0; // Wire declared after its assign statements (valid forward-reference in Verilog)
    assign mul_0_1[0] = feedback_0[2] ^ feedback_0[3] ^ feedback_0[4] ^ feedback_0[5] ^ feedback_0[6];
    assign mul_0_1[1] = feedback_0[3] ^ feedback_0[4] ^ feedback_0[5] ^ feedback_0[6] ^ feedback_0[7];
    assign mul_0_1[2] = feedback_0[2] ^ feedback_0[3] ^ feedback_0[7];
    assign mul_0_1[3] = feedback_0[0] ^ feedback_0[2] ^ feedback_0[5] ^ feedback_0[6];
    assign mul_0_1[4] = feedback_0[0] ^ feedback_0[1] ^ feedback_0[2] ^ feedback_0[4] ^ feedback_0[5] ^ feedback_0[7];
    assign mul_0_1[5] = feedback_0[0] ^ feedback_0[1] ^ feedback_0[2] ^ feedback_0[3] ^ feedback_0[5] ^ feedback_0[6];
    assign mul_0_1[6] = feedback_0[0] ^ feedback_0[1] ^ feedback_0[2] ^ feedback_0[3] ^ feedback_0[4] ^ feedback_0[6] ^ feedback_0[7];
    assign mul_0_1[7] = feedback_0[1] ^ feedback_0[2] ^ feedback_0[3] ^ feedback_0[4] ^ feedback_0[5] ^ feedback_0[7];
    wire [7:0] mul_0_1;
    assign mul_0_2[0] = feedback_0[3] ^ feedback_0[4] ^ feedback_0[6];
    assign mul_0_2[1] = feedback_0[0] ^ feedback_0[4] ^ feedback_0[5] ^ feedback_0[7];
    assign mul_0_2[2] = feedback_0[0] ^ feedback_0[1] ^ feedback_0[3] ^ feedback_0[4] ^ feedback_0[5];
    assign mul_0_2[3] = feedback_0[1] ^ feedback_0[2] ^ feedback_0[3] ^ feedback_0[5];
    assign mul_0_2[4] = feedback_0[0] ^ feedback_0[2];
    assign mul_0_2[5] = feedback_0[0] ^ feedback_0[1] ^ feedback_0[3];
    assign mul_0_2[6] = feedback_0[1] ^ feedback_0[2] ^ feedback_0[4];
    assign mul_0_2[7] = feedback_0[2] ^ feedback_0[3] ^ feedback_0[5];
    wire [7:0] mul_0_2;
    assign mul_0_3[0] = feedback_0[0] ^ feedback_0[5] ^ feedback_0[6] ^ feedback_0[7];
    assign mul_0_3[1] = feedback_0[0] ^ feedback_0[1] ^ feedback_0[6] ^ feedback_0[7];
    assign mul_0_3[2] = feedback_0[0] ^ feedback_0[1] ^ feedback_0[2] ^ feedback_0[5] ^ feedback_0[6];
    assign mul_0_3[3] = feedback_0[0] ^ feedback_0[1] ^ feedback_0[2] ^ feedback_0[3] ^ feedback_0[5];
    assign mul_0_3[4] = feedback_0[1] ^ feedback_0[2] ^ feedback_0[3] ^ feedback_0[4] ^ feedback_0[5] ^ feedback_0[7];
    assign mul_0_3[5] = feedback_0[2] ^ feedback_0[3] ^ feedback_0[4] ^ feedback_0[5] ^ feedback_0[6];
    assign mul_0_3[6] = feedback_0[3] ^ feedback_0[4] ^ feedback_0[5] ^ feedback_0[6] ^ feedback_0[7];
    assign mul_0_3[7] = feedback_0[4] ^ feedback_0[5] ^ feedback_0[6] ^ feedback_0[7];
    wire [7:0] mul_0_3;
    // --- Parity bytes ---
    wire [7:0] parity_byte_0 = (8'b0 ^ mul_0_3);
    wire [7:0] parity_byte_1 = (8'b0 ^ mul_0_2);
    wire [7:0] parity_byte_2 = (8'b0 ^ mul_0_1);
    wire [7:0] parity_byte_3 = mul_0_0;
    // Assemble encoded codeword: data at LSB, parity bytes above it.
    wire [39:0] encoded_result;
    assign encoded_result[7:0]   = msg_bytes[0];
    assign encoded_result[15:8]  = parity_byte_0;
    assign encoded_result[23:16] = parity_byte_1;
    assign encoded_result[31:24] = parity_byte_2;
    assign encoded_result[39:32] = parity_byte_3;
    // --- Syndrome Generator (combinational, 4 syndromes S0–S3) ---
    wire has_error;
    assign syn_mul_0_1[0] = codeword_in[7:0][0];
    assign syn_mul_0_1[1] = codeword_in[7:0][1];
    assign syn_mul_0_1[2] = codeword_in[7:0][2];
    assign syn_mul_0_1[3] = codeword_in[7:0][3];
    assign syn_mul_0_1[4] = codeword_in[7:0][4];
    assign syn_mul_0_1[5] = codeword_in[7:0][5];
    assign syn_mul_0_1[6] = codeword_in[7:0][6];
    assign syn_mul_0_1[7] = codeword_in[7:0][7];
    wire [7:0] syn_mul_0_1;
    wire [7:0] syn_sum_0_1 = syn_mul_0_1 ^ codeword_in[15:8];
    assign syn_mul_0_2[0] = syn_sum_0_1[0];
    assign syn_mul_0_2[1] = syn_sum_0_1[1];
    assign syn_mul_0_2[2] = syn_sum_0_1[2];
    assign syn_mul_0_2[3] = syn_sum_0_1[3];
    assign syn_mul_0_2[4] = syn_sum_0_1[4];
    assign syn_mul_0_2[5] = syn_sum_0_1[5];
    assign syn_mul_0_2[6] = syn_sum_0_1[6];
    assign syn_mul_0_2[7] = syn_sum_0_1[7];
    wire [7:0] syn_mul_0_2;
    wire [7:0] syn_sum_0_2 = syn_mul_0_2 ^ codeword_in[23:16];
    assign syn_mul_0_3[0] = syn_sum_0_2[0];
    assign syn_mul_0_3[1] = syn_sum_0_2[1];
    assign syn_mul_0_3[2] = syn_sum_0_2[2];
    assign syn_mul_0_3[3] = syn_sum_0_2[3];
    assign syn_mul_0_3[4] = syn_sum_0_2[4];
    assign syn_mul_0_3[5] = syn_sum_0_2[5];
    assign syn_mul_0_3[6] = syn_sum_0_2[6];
    assign syn_mul_0_3[7] = syn_sum_0_2[7];
    wire [7:0] syn_mul_0_3;
    wire [7:0] syn_sum_0_3 = syn_mul_0_3 ^ codeword_in[31:24];
    assign syn_mul_0_4[0] = syn_sum_0_3[0];
    assign syn_mul_0_4[1] = syn_sum_0_3[1];
    assign syn_mul_0_4[2] = syn_sum_0_3[2];
    assign syn_mul_0_4[3] = syn_sum_0_3[3];
    assign syn_mul_0_4[4] = syn_sum_0_3[4];
    assign syn_mul_0_4[5] = syn_sum_0_3[5];
    assign syn_mul_0_4[6] = syn_sum_0_3[6];
    assign syn_mul_0_4[7] = syn_sum_0_3[7];
    wire [7:0] syn_mul_0_4;
    wire [7:0] syn_sum_0_4 = syn_mul_0_4 ^ codeword_in[39:32];
    assign syn_mul_1_1[0] = codeword_in[7:0][7];
    assign syn_mul_1_1[1] = codeword_in[7:0][0];
    assign syn_mul_1_1[2] = codeword_in[7:0][1] ^ codeword_in[7:0][7];
    assign syn_mul_1_1[3] = codeword_in[7:0][2] ^ codeword_in[7:0][7];
    assign syn_mul_1_1[4] = codeword_in[7:0][3] ^ codeword_in[7:0][7];
    assign syn_mul_1_1[5] = codeword_in[7:0][4];
    assign syn_mul_1_1[6] = codeword_in[7:0][5];
    assign syn_mul_1_1[7] = codeword_in[7:0][6];
    wire [7:0] syn_mul_1_1;
    wire [7:0] syn_sum_1_1 = syn_mul_1_1 ^ codeword_in[15:8];
    assign syn_mul_1_2[0] = syn_sum_1_1[7];
    assign syn_mul_1_2[1] = syn_sum_1_1[0];
    assign syn_mul_1_2[2] = syn_sum_1_1[1] ^ syn_sum_1_1[7];
    assign syn_mul_1_2[3] = syn_sum_1_1[2] ^ syn_sum_1_1[7];
    assign syn_mul_1_2[4] = syn_sum_1_1[3] ^ syn_sum_1_1[7];
    assign syn_mul_1_2[5] = syn_sum_1_1[4];
    assign syn_mul_1_2[6] = syn_sum_1_1[5];
    assign syn_mul_1_2[7] = syn_sum_1_1[6];
    wire [7:0] syn_mul_1_2;
    wire [7:0] syn_sum_1_2 = syn_mul_1_2 ^ codeword_in[23:16];
    assign syn_mul_1_3[0] = syn_sum_1_2[7];
    assign syn_mul_1_3[1] = syn_sum_1_2[0];
    assign syn_mul_1_3[2] = syn_sum_1_2[1] ^ syn_sum_1_2[7];
    assign syn_mul_1_3[3] = syn_sum_1_2[2] ^ syn_sum_1_2[7];
    assign syn_mul_1_3[4] = syn_sum_1_2[3] ^ syn_sum_1_2[7];
    assign syn_mul_1_3[5] = syn_sum_1_2[4];
    assign syn_mul_1_3[6] = syn_sum_1_2[5];
    assign syn_mul_1_3[7] = syn_sum_1_2[6];
    wire [7:0] syn_mul_1_3;
    wire [7:0] syn_sum_1_3 = syn_mul_1_3 ^ codeword_in[31:24];
    assign syn_mul_1_4[0] = syn_sum_1_3[7];
    assign syn_mul_1_4[1] = syn_sum_1_3[0];
    assign syn_mul_1_4[2] = syn_sum_1_3[1] ^ syn_sum_1_3[7];
    assign syn_mul_1_4[3] = syn_sum_1_3[2] ^ syn_sum_1_3[7];
    assign syn_mul_1_4[4] = syn_sum_1_3[3] ^ syn_sum_1_3[7];
    assign syn_mul_1_4[5] = syn_sum_1_3[4];
    assign syn_mul_1_4[6] = syn_sum_1_3[5];
    assign syn_mul_1_4[7] = syn_sum_1_3[6];
    wire [7:0] syn_mul_1_4;
    wire [7:0] syn_sum_1_4 = syn_mul_1_4 ^ codeword_in[39:32];
    assign syn_mul_2_1[0] = codeword_in[7:0][6];
    assign syn_mul_2_1[1] = codeword_in[7:0][7];
    assign syn_mul_2_1[2] = codeword_in[7:0][0] ^ codeword_in[7:0][6];
    assign syn_mul_2_1[3] = codeword_in[7:0][1] ^ codeword_in[7:0][6] ^ codeword_in[7:0][7];
    assign syn_mul_2_1[4] = codeword_in[7:0][2] ^ codeword_in[7:0][6] ^ codeword_in[7:0][7];
    assign syn_mul_2_1[5] = codeword_in[7:0][3] ^ codeword_in[7:0][7];
    assign syn_mul_2_1[6] = codeword_in[7:0][4];
    assign syn_mul_2_1[7] = codeword_in[7:0][5];
    wire [7:0] syn_mul_2_1;
    wire [7:0] syn_sum_2_1 = syn_mul_2_1 ^ codeword_in[15:8];
    assign syn_mul_2_2[0] = syn_sum_2_1[6];
    assign syn_mul_2_2[1] = syn_sum_2_1[7];
    assign syn_mul_2_2[2] = syn_sum_2_1[0] ^ syn_sum_2_1[6];
    assign syn_mul_2_2[3] = syn_sum_2_1[1] ^ syn_sum_2_1[6] ^ syn_sum_2_1[7];
    assign syn_mul_2_2[4] = syn_sum_2_1[2] ^ syn_sum_2_1[6] ^ syn_sum_2_1[7];
    assign syn_mul_2_2[5] = syn_sum_2_1[3] ^ syn_sum_2_1[7];
    assign syn_mul_2_2[6] = syn_sum_2_1[4];
    assign syn_mul_2_2[7] = syn_sum_2_1[5];
    wire [7:0] syn_mul_2_2;
    wire [7:0] syn_sum_2_2 = syn_mul_2_2 ^ codeword_in[23:16];
    assign syn_mul_2_3[0] = syn_sum_2_2[6];
    assign syn_mul_2_3[1] = syn_sum_2_2[7];
    assign syn_mul_2_3[2] = syn_sum_2_2[0] ^ syn_sum_2_2[6];
    assign syn_mul_2_3[3] = syn_sum_2_2[1] ^ syn_sum_2_2[6] ^ syn_sum_2_2[7];
    assign syn_mul_2_3[4] = syn_sum_2_2[2] ^ syn_sum_2_2[6] ^ syn_sum_2_2[7];
    assign syn_mul_2_3[5] = syn_sum_2_2[3] ^ syn_sum_2_2[7];
    assign syn_mul_2_3[6] = syn_sum_2_2[4];
    assign syn_mul_2_3[7] = syn_sum_2_2[5];
    wire [7:0] syn_mul_2_3;
    wire [7:0] syn_sum_2_3 = syn_mul_2_3 ^ codeword_in[31:24];
    assign syn_mul_2_4[0] = syn_sum_2_3[6];
    assign syn_mul_2_4[1] = syn_sum_2_3[7];
    assign syn_mul_2_4[2] = syn_sum_2_3[0] ^ syn_sum_2_3[6];
    assign syn_mul_2_4[3] = syn_sum_2_3[1] ^ syn_sum_2_3[6] ^ syn_sum_2_3[7];
    assign syn_mul_2_4[4] = syn_sum_2_3[2] ^ syn_sum_2_3[6] ^ syn_sum_2_3[7];
    assign syn_mul_2_4[5] = syn_sum_2_3[3] ^ syn_sum_2_3[7];
    assign syn_mul_2_4[6] = syn_sum_2_3[4];
    assign syn_mul_2_4[7] = syn_sum_2_3[5];
    wire [7:0] syn_mul_2_4;
    wire [7:0] syn_sum_2_4 = syn_mul_2_4 ^ codeword_in[39:32];
    assign syn_mul_3_1[0] = codeword_in[7:0][5];
    assign syn_mul_3_1[1] = codeword_in[7:0][6];
    assign syn_mul_3_1[2] = codeword_in[7:0][5] ^ codeword_in[7:0][7];
    assign syn_mul_3_1[3] = codeword_in[7:0][0] ^ codeword_in[7:0][5] ^ codeword_in[7:0][6];
    assign syn_mul_3_1[4] = codeword_in[7:0][1] ^ codeword_in[7:0][5] ^ codeword_in[7:0][6] ^ codeword_in[7:0][7];
    assign syn_mul_3_1[5] = codeword_in[7:0][2] ^ codeword_in[7:0][6] ^ codeword_in[7:0][7];
    assign syn_mul_3_1[6] = codeword_in[7:0][3] ^ codeword_in[7:0][7];
    assign syn_mul_3_1[7] = codeword_in[7:0][4];
    wire [7:0] syn_mul_3_1;
    wire [7:0] syn_sum_3_1 = syn_mul_3_1 ^ codeword_in[15:8];
    assign syn_mul_3_2[0] = syn_sum_3_1[5];
    assign syn_mul_3_2[1] = syn_sum_3_1[6];
    assign syn_mul_3_2[2] = syn_sum_3_1[5] ^ syn_sum_3_1[7];
    assign syn_mul_3_2[3] = syn_sum_3_1[0] ^ syn_sum_3_1[5] ^ syn_sum_3_1[6];
    assign syn_mul_3_2[4] = syn_sum_3_1[1] ^ syn_sum_3_1[5] ^ syn_sum_3_1[6] ^ syn_sum_3_1[7];
    assign syn_mul_3_2[5] = syn_sum_3_1[2] ^ syn_sum_3_1[6] ^ syn_sum_3_1[7];
    assign syn_mul_3_2[6] = syn_sum_3_1[3] ^ syn_sum_3_1[7];
    assign syn_mul_3_2[7] = syn_sum_3_1[4];
    wire [7:0] syn_mul_3_2;
    wire [7:0] syn_sum_3_2 = syn_mul_3_2 ^ codeword_in[23:16];
    assign syn_mul_3_3[0] = syn_sum_3_2[5];
    assign syn_mul_3_3[1] = syn_sum_3_2[6];
    assign syn_mul_3_3[2] = syn_sum_3_2[5] ^ syn_sum_3_2[7];
    assign syn_mul_3_3[3] = syn_sum_3_2[0] ^ syn_sum_3_2[5] ^ syn_sum_3_2[6];
    assign syn_mul_3_3[4] = syn_sum_3_2[1] ^ syn_sum_3_2[5] ^ syn_sum_3_2[6] ^ syn_sum_3_2[7];
    assign syn_mul_3_3[5] = syn_sum_3_2[2] ^ syn_sum_3_2[6] ^ syn_sum_3_2[7];
    assign syn_mul_3_3[6] = syn_sum_3_2[3] ^ syn_sum_3_2[7];
    assign syn_mul_3_3[7] = syn_sum_3_2[4];
    wire [7:0] syn_mul_3_3;
    wire [7:0] syn_sum_3_3 = syn_mul_3_3 ^ codeword_in[31:24];
    assign syn_mul_3_4[0] = syn_sum_3_3[5];
    assign syn_mul_3_4[1] = syn_sum_3_3[6];
    assign syn_mul_3_4[2] = syn_sum_3_3[5] ^ syn_sum_3_3[7];
    assign syn_mul_3_4[3] = syn_sum_3_3[0] ^ syn_sum_3_3[5] ^ syn_sum_3_3[6];
    assign syn_mul_3_4[4] = syn_sum_3_3[1] ^ syn_sum_3_3[5] ^ syn_sum_3_3[6] ^ syn_sum_3_3[7];
    assign syn_mul_3_4[5] = syn_sum_3_3[2] ^ syn_sum_3_3[6] ^ syn_sum_3_3[7];
    assign syn_mul_3_4[6] = syn_sum_3_3[3] ^ syn_sum_3_3[7];
    assign syn_mul_3_4[7] = syn_sum_3_3[4];
    wire [7:0] syn_mul_3_4;
    wire [7:0] syn_sum_3_4 = syn_mul_3_4 ^ codeword_in[39:32];
    assign has_error = (|syn_sum_0_4) | (|syn_sum_1_4) | (|syn_sum_2_4) | (|syn_sum_3_4);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            codeword_out <= 0;
            data_out <= 0;
            error_detected <= 0;
            error_corrected <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= 0;
            
            if (encode_en) begin
                codeword_out <= encoded_result;
                valid_out <= 1'b1;
            end
            
            if (decode_en) begin
                // Extract data (Systematic at LSB)
                data_out <= codeword_in[7:0];
                error_detected <= has_error;
                error_corrected <= 1'b0; // Corrected placeholder
                valid_out <= 1'b1;
            end
        end
    end
endmodule