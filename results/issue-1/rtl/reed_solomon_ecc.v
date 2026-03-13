
// Reed-Solomon ECC Wrapper - Instantiates Generated Real Hardware Modules
// Supports DATA_WIDTH 4, 8, 16, 32, 64, 128
// GF(2^8), T=2 (4 parity bytes)

module reed_solomon_ecc #(
    parameter DATA_WIDTH = 8
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    encode_en,
    input  wire                    decode_en,
    input  wire [DATA_WIDTH-1:0]   data_in,
    // Codeword Width = DATA_WIDTH (in bytes, rounded up) * 8 + 32 bits (4 bytes parity)
    // The testbench provides a fixed large width, we map correctly.
    // Generated modules expect specific widths.
    // w4 -> n=5 bytes. (1 data + 4 parity) -> 40 bits.
    // w8 -> n=5 bytes. (1 data + 4 parity) -> 40 bits.
    // w16 -> n=6 bytes. (2 data + 4 parity) -> 48 bits.
    // w32 -> n=8 bytes. (4 data + 4 parity) -> 64 bits.
    // w64 -> n=12 bytes. (8 data + 4 parity) -> 96 bits.
    // w128 -> n=20 bytes. (16 data + 4 parity) -> 160 bits.
    // The testbench defines `CODEWORD_WIDTH` based on simplified logic?
    // Let's check testbench assumption.
    // Current wrapper had: input [159:0] codeword_in. 
    // This covers the max case.
    input  wire [159:0]            codeword_in,
    output wire [159:0]            codeword_out,
    output wire [DATA_WIDTH-1:0]   data_out,
    output wire                    error_detected,
    output wire                    error_corrected,
    output wire                    valid_out
);

    // We need to map the 160-bit ports to the specific widths of the generated modules.
    // The generated modules output the exact width.
    // We pad outputs to 160.
    // We slice inputs.

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