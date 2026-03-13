
// Reed-Solomon ECC Wrapper
// Supports DATA_WIDTH: 4, 8, 16, 32, 64, 128 bits
// Galois field: GF(2^8), primitive polynomial 0x11D
// Correction capability: T=2 symbols (4 parity bytes)
//
// All codeword ports are fixed at 160 bits (the maximum codeword width for
// DATA_WIDTH=128).  The wrapper slices the lower N bits for each sub-module
// and zero-pads sub-module outputs back to 160 bits.
//
// Codeword layout (little-endian byte packing):
//   [DATA_BYTES*8-1 : 0]        – data bytes (systematic, LSB = byte 0)
//   [CW_BITS-1 : DATA_BYTES*8]  – 4 RS parity bytes
//
// Sub-module codeword widths:
//   DATA_WIDTH=4/8  -> 5 bytes  -> 40 bits  (DATA_BYTES=1, CW=40)
//   DATA_WIDTH=16   -> 6 bytes  -> 48 bits  (DATA_BYTES=2, CW=48)
//   DATA_WIDTH=32   -> 8 bytes  -> 64 bits  (DATA_BYTES=4, CW=64)
//   DATA_WIDTH=64   -> 12 bytes -> 96 bits  (DATA_BYTES=8, CW=96)
//   DATA_WIDTH=128  -> 20 bytes -> 160 bits (DATA_BYTES=16, CW=160)

module reed_solomon_ecc #(
    parameter DATA_WIDTH = 8   // Supported: 4, 8, 16, 32, 64, 128
) (
    input  wire                    clk,
    input  wire                    rst_n,         // Active-low asynchronous reset
    input  wire                    encode_en,     // Pulse to start encode; data_in consumed next cycle
    input  wire                    decode_en,     // Pulse to start decode; codeword_in consumed next cycle
    input  wire [DATA_WIDTH-1:0]   data_in,       // Raw data word (encode) or received word (decode)
    // 160-bit bus: only the lower N bits are meaningful; upper bits ignored on input.
    input  wire [159:0]            codeword_in,
    // 160-bit bus: lower N bits contain the encoded/decoded codeword; upper bits are 0.
    output wire [159:0]            codeword_out,
    output wire [DATA_WIDTH-1:0]   data_out,      // Corrected data after decode
    output wire                    error_detected, // Syndromes were non-zero
    output wire                    error_corrected,// Errors corrected (currently a placeholder — always 0)
    output wire                    valid_out       // Single-cycle pulse: outputs are valid
);

    // Combinational generate block: selects the appropriate width-specific sub-module.
    // Unused upper bits of codeword_out are driven to 0 by the sub-module assignments below.
    generate
        if (DATA_WIDTH == 4) begin : w4
            wire [39:0] cw_out_w4;
            reed_solomon_ecc_w4 u_rs (
                .clk(clk), .rst_n(rst_n),
                .encode_en(encode_en), .decode_en(decode_en),
                .data_in(data_in),
                .codeword_in(codeword_in[39:0]),
                .codeword_out(cw_out_w4),
                .data_out(data_out),
                .error_detected(error_detected),
                .error_corrected(error_corrected),
                .valid_out(valid_out)
            );
            assign codeword_out = {120'b0, cw_out_w4};
        end else if (DATA_WIDTH == 8) begin : w8
            wire [39:0] cw_out_w8;
            reed_solomon_ecc_w8 u_rs (
                .clk(clk), .rst_n(rst_n),
                .encode_en(encode_en), .decode_en(decode_en),
                .data_in(data_in),
                .codeword_in(codeword_in[39:0]),
                .codeword_out(cw_out_w8),
                .data_out(data_out),
                .error_detected(error_detected),
                .error_corrected(error_corrected),
                .valid_out(valid_out)
            );
             assign codeword_out = {120'b0, cw_out_w8};
        end else if (DATA_WIDTH == 16) begin : w16
            wire [47:0] cw_out_w16;
            reed_solomon_ecc_w16 u_rs (
                .clk(clk), .rst_n(rst_n),
                .encode_en(encode_en), .decode_en(decode_en),
                .data_in(data_in),
                .codeword_in(codeword_in[47:0]),
                .codeword_out(cw_out_w16),
                .data_out(data_out),
                .error_detected(error_detected),
                .error_corrected(error_corrected),
                .valid_out(valid_out)
            );
             assign codeword_out = {112'b0, cw_out_w16};
        end else if (DATA_WIDTH == 32) begin : w32
            wire [63:0] cw_out_w32;
            reed_solomon_ecc_w32 u_rs (
                .clk(clk), .rst_n(rst_n),
                .encode_en(encode_en), .decode_en(decode_en),
                .data_in(data_in),
                .codeword_in(codeword_in[63:0]),
                .codeword_out(cw_out_w32),
                .data_out(data_out),
                .error_detected(error_detected),
                .error_corrected(error_corrected),
                .valid_out(valid_out)
            );
             assign codeword_out = {96'b0, cw_out_w32};
        end else if (DATA_WIDTH == 64) begin : w64
            wire [95:0] cw_out_w64;
            reed_solomon_ecc_w64 u_rs (
                .clk(clk), .rst_n(rst_n),
                .encode_en(encode_en), .decode_en(decode_en),
                .data_in(data_in),
                .codeword_in(codeword_in[95:0]),
                .codeword_out(cw_out_w64),
                .data_out(data_out),
                .error_detected(error_detected),
                .error_corrected(error_corrected),
                .valid_out(valid_out)
            );
             assign codeword_out = {64'b0, cw_out_w64};
        end else if (DATA_WIDTH == 128) begin : w128
            wire [159:0] cw_out_w128;
            reed_solomon_ecc_w128 u_rs (
                .clk(clk), .rst_n(rst_n),
                .encode_en(encode_en), .decode_en(decode_en),
                .data_in(data_in),
                .codeword_in(codeword_in[159:0]),
                .codeword_out(cw_out_w128),
                .data_out(data_out),
                .error_detected(error_detected),
                .error_corrected(error_corrected),
                .valid_out(valid_out)
            );
             assign codeword_out = cw_out_w128;
             
        end else begin : fallback
            assign codeword_out = 0;
            assign data_out = 0;
            assign error_detected = 0;
            assign error_corrected = 0;
            assign valid_out = 0;
        end
    endgenerate

endmodule