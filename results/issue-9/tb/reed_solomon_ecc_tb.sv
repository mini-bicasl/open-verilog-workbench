// Reed-Solomon ECC Testbench  –  issue-9
// DUT: reed_solomon_ecc wrapper (results/issue-9/rtl/reed_solomon_ecc.v)
// Tested DATA_WIDTH configurations: 8, 16, 32, 64
//
// Covered scenarios
//   S0  – Reset: all outputs held at 0 while rst_n=0
//   S1  – DUT8  encode 0xAB + decode round-trip (nominal)
//   S2  – DUT8  encode 0x00 (all-zero), decode all-zero codeword
//   S3  – DUT8  encode 0xFF round-trip
//   S4  – DUT8  error detection: corrupt parity byte
//   S5  – DUT8  error detection: corrupt data byte
//   S6  – DUT8  error_corrected is always 0 (RTL placeholder)
//   S7  – DUT8  back-to-back encodes (3 consecutive cycles)
//   S8  – DUT8  simultaneous encode_en + decode_en in same cycle
//   S9  – DUT8  async reset mid-operation
//   S10 – DUT16 encode 0xBEEF + decode round-trip
//   S10b– DUT16 error detection on corrupted codeword
//   S11 – DUT32 encode 0xDEADBEEF + decode round-trip
//   S11b– DUT32 error detection
//   S12 – DUT32 all-zero data
//   S13 – DUT64 encode 0xCAFEBABEDEAD1234 + decode round-trip
//   S13b– DUT64 error detection: corrupt data byte 0
//
// Compile (from repository root):
//   iverilog -g2012 -o results/issue-9/build/reed_solomon_ecc_tb.out \
//       results/issue-9/tb/reed_solomon_ecc_tb.sv \
//       results/issue-9/rtl/reed_solomon_ecc.v \
//       results/issue-9/rtl/reed_solomon_ecc_w4.v \
//       results/issue-9/rtl/reed_solomon_ecc_w8.v \
//       results/issue-9/rtl/reed_solomon_ecc_w16.v \
//       results/issue-9/rtl/reed_solomon_ecc_w32.v \
//       results/issue-9/rtl/reed_solomon_ecc_w64.v \
//       results/issue-9/rtl/reed_solomon_ecc_w128.v
// Run:
//   vvp results/issue-9/build/reed_solomon_ecc_tb.out

`timescale 1ns/1ps

module reed_solomon_ecc_tb;

    // ----------------------------------------------------------------
    // Clock and shared reset
    // ----------------------------------------------------------------
    reg clk;
    reg rst_n;

    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz (10 ns period)

    // ----------------------------------------------------------------
    // DUT #1 – DATA_WIDTH = 8
    //   RS(5,1): 1 data byte + 4 parity bytes = 40-bit codeword
    //   Wrapper exposes 160-bit bus; codeword_out[39:0] is meaningful.
    // ----------------------------------------------------------------
    reg        enc_en8, dec_en8;
    reg  [7:0] din8;
    reg [159:0] cw_in8;
    wire [159:0] cw_out8;
    wire  [7:0] dout8;
    wire        err_det8, err_cor8, vld8;

    reed_solomon_ecc #(.DATA_WIDTH(8)) dut8 (
        .clk(clk),           .rst_n(rst_n),
        .encode_en(enc_en8), .decode_en(dec_en8),
        .data_in(din8),      .codeword_in(cw_in8),
        .codeword_out(cw_out8),
        .data_out(dout8),
        .error_detected(err_det8),
        .error_corrected(err_cor8),
        .valid_out(vld8)
    );

    // ----------------------------------------------------------------
    // DUT #2 – DATA_WIDTH = 16
    //   RS(6,2): 2 data bytes + 4 parity bytes = 48-bit codeword
    //   Wrapper codeword_out[47:0] is meaningful; upper 112 bits are 0.
    // ----------------------------------------------------------------
    reg        enc_en16, dec_en16;
    reg [15:0] din16;
    reg [159:0] cw_in16;
    wire [159:0] cw_out16;
    wire [15:0] dout16;
    wire        err_det16, err_cor16, vld16;

    reed_solomon_ecc #(.DATA_WIDTH(16)) dut16 (
        .clk(clk),            .rst_n(rst_n),
        .encode_en(enc_en16), .decode_en(dec_en16),
        .data_in(din16),      .codeword_in(cw_in16),
        .codeword_out(cw_out16),
        .data_out(dout16),
        .error_detected(err_det16),
        .error_corrected(err_cor16),
        .valid_out(vld16)
    );

    // ----------------------------------------------------------------
    // DUT #3 – DATA_WIDTH = 32
    //   RS(8,4): 4 data bytes + 4 parity bytes = 64-bit codeword
    //   Wrapper codeword_out[63:0] is meaningful; upper 96 bits are 0.
    // ----------------------------------------------------------------
    reg        enc_en32, dec_en32;
    reg [31:0] din32;
    reg [159:0] cw_in32;
    wire [159:0] cw_out32;
    wire [31:0] dout32;
    wire        err_det32, err_cor32, vld32;

    reed_solomon_ecc #(.DATA_WIDTH(32)) dut32 (
        .clk(clk),            .rst_n(rst_n),
        .encode_en(enc_en32), .decode_en(dec_en32),
        .data_in(din32),      .codeword_in(cw_in32),
        .codeword_out(cw_out32),
        .data_out(dout32),
        .error_detected(err_det32),
        .error_corrected(err_cor32),
        .valid_out(vld32)
    );

    // ----------------------------------------------------------------
    // DUT #4 – DATA_WIDTH = 64
    //   RS(12,8): 8 data bytes + 4 parity bytes = 96-bit codeword
    //   Wrapper codeword_out[95:0] is meaningful; upper 64 bits are 0.
    // ----------------------------------------------------------------
    reg        enc_en64, dec_en64;
    reg [63:0] din64;
    reg [159:0] cw_in64;
    wire [159:0] cw_out64;
    wire [63:0] dout64;
    wire        err_det64, err_cor64, vld64;

    reed_solomon_ecc #(.DATA_WIDTH(64)) dut64 (
        .clk(clk),            .rst_n(rst_n),
        .encode_en(enc_en64), .decode_en(dec_en64),
        .data_in(din64),      .codeword_in(cw_in64),
        .codeword_out(cw_out64),
        .data_out(dout64),
        .error_detected(err_det64),
        .error_corrected(err_cor64),
        .valid_out(vld64)
    );

    // ----------------------------------------------------------------
    // Failure counter and VCD dump
    // ----------------------------------------------------------------
    integer fail_count;

    initial begin
        $dumpfile("results/issue-9/build/reed_solomon_ecc_tb.vcd");
        $dumpvars(0, reed_solomon_ecc_tb);
    end

    // ----------------------------------------------------------------
    // Helper task: check a condition; print and count failures.
    // ----------------------------------------------------------------
    task automatic chk;
        input        cond;
        input [127:0] tag;   // ASCII label (up to 16 chars)
    begin
        if (!cond) begin
            $display("  FAIL [%s]", tag);
            fail_count = fail_count + 1;
        end else begin
            $display("  pass [%s]", tag);
        end
    end
    endtask

    // ----------------------------------------------------------------
    // Temporary storage for codeword round-trip tests
    // ----------------------------------------------------------------
    reg [39:0]  saved_cw8;
    reg [47:0]  saved_cw16;
    reg [63:0]  saved_cw32;
    reg [95:0]  saved_cw64;

    // ================================================================
    // Main stimulus
    // All signal changes happen at @(negedge clk) to avoid race
    // conditions with the DUT's posedge-triggered always block.
    // Outputs are sampled at the negedge following the capturing
    // posedge (one half-period after registered outputs update).
    // ================================================================
    initial begin
        fail_count = 0;

        // Initialise all DUT inputs
        rst_n    = 0;
        enc_en8  = 0; dec_en8  = 0; din8  = 0; cw_in8  = 0;
        enc_en16 = 0; dec_en16 = 0; din16 = 0; cw_in16 = 0;
        enc_en32 = 0; dec_en32 = 0; din32 = 0; cw_in32 = 0;
        enc_en64 = 0; dec_en64 = 0; din64 = 0; cw_in64 = 0;

        $display("=== Reed-Solomon ECC Testbench START (issue-9) ===");

        // ============================================================
        // S0 – RESET CHECK
        //   Hold active-low reset for 4 clock cycles.
        //   All registered outputs must remain zero.
        // ============================================================
        $display("--- S0: Reset check ---");
        repeat(4) @(posedge clk);
        @(negedge clk);
        chk(vld8     === 1'b0,   "S0 vld8=0");
        chk(err_det8 === 1'b0,   "S0 err8=0");
        chk((|cw_out8) === 1'b0, "S0 cw_out8=0");
        chk(vld16    === 1'b0,   "S0 vld16=0");
        chk(vld32    === 1'b0,   "S0 vld32=0");
        chk(vld64    === 1'b0,   "S0 vld64=0");

        // Deassert reset; one idle posedge before first operation.
        rst_n = 1;
        @(posedge clk);

        // ============================================================
        // S1 – DUT8: ENCODE + DECODE ROUND-TRIP (nominal data 0xAB)
        //   Assert encode_en for exactly one cycle.  RTL has 1-cycle
        //   latency; outputs are stable at the negedge after capturing
        //   posedge.
        // ============================================================
        $display("--- S1: DUT8 encode 0xAB, decode round-trip ---");
        @(negedge clk);  enc_en8 = 1; din8 = 8'hAB;
        @(posedge clk);                 // P1: captures encode_en=1
        @(negedge clk);                 // N1: outputs stable
        chk(vld8 === 1'b1,           "S1 vld after enc");
        chk(cw_out8[7:0] === 8'hAB,  "S1 data byte preserved");
        saved_cw8 = cw_out8[39:0];
        enc_en8 = 0;
        $display("    codeword[39:0] = 0x%010X", saved_cw8);

        // valid_out must deassert on the next idle cycle.
        @(posedge clk);
        @(negedge clk);
        chk(vld8 === 1'b0, "S1 vld deasserts");

        // Feed the clean codeword back for decode.
        @(negedge clk);  dec_en8 = 1; cw_in8 = {120'b0, saved_cw8};
        @(posedge clk);
        @(negedge clk);
        chk(vld8     === 1'b1,  "S1 vld after dec");
        chk(dout8    === 8'hAB, "S1 decoded data=AB");
        chk(err_det8 === 1'b0,  "S1 no error on clean cw");
        dec_en8 = 0;

        // ============================================================
        // S2 – DUT8: ALL-ZERO DATA → ALL-ZERO CODEWORD
        //   GF multiply by zero is zero; all parity bytes must be 0.
        // ============================================================
        $display("--- S2: DUT8 encode 0x00 (all-zero) ---");
        @(negedge clk);  enc_en8 = 1; din8 = 8'h00;
        @(posedge clk);
        @(negedge clk);
        chk(vld8 === 1'b1,             "S2 vld");
        chk(cw_out8[39:0] === 40'h0,   "S2 zero-cw");
        enc_en8 = 0;

        // Decode the all-zero codeword: syndromes must all be zero.
        @(negedge clk);  dec_en8 = 1; cw_in8 = 160'h0;
        @(posedge clk);
        @(negedge clk);
        chk(err_det8 === 1'b0,  "S2 no error on zero cw");
        chk(dout8    === 8'h00, "S2 decoded data=00");
        dec_en8 = 0;

        // ============================================================
        // S3 – DUT8: ALL-ONES DATA ROUND-TRIP (0xFF)
        // ============================================================
        $display("--- S3: DUT8 encode 0xFF round-trip ---");
        @(negedge clk);  enc_en8 = 1; din8 = 8'hFF;
        @(posedge clk);
        @(negedge clk);
        chk(vld8 === 1'b1, "S3 vld after enc");
        saved_cw8 = cw_out8[39:0];
        enc_en8 = 0;
        $display("    codeword[39:0] = 0x%010X", saved_cw8);

        @(negedge clk);  dec_en8 = 1; cw_in8 = {120'b0, saved_cw8};
        @(posedge clk);
        @(negedge clk);
        chk(dout8    === 8'hFF, "S3 decoded data=FF");
        chk(err_det8 === 1'b0,  "S3 no error on clean 0xFF cw");
        dec_en8 = 0;

        // ============================================================
        // S4 – DUT8: ERROR DETECTION – CORRUPT PARITY BYTE
        //   Re-encode 0xAB; flip all bits of parity byte 0 (cw[15:8]).
        //   error_detected must be asserted.
        // ============================================================
        $display("--- S4: DUT8 error detect – corrupt parity byte ---");
        @(negedge clk);  enc_en8 = 1; din8 = 8'hAB;
        @(posedge clk);
        @(negedge clk);
        saved_cw8 = cw_out8[39:0];
        enc_en8 = 0;

        // XOR-flip parity byte 0 (bits [15:8] of the 40-bit codeword).
        @(negedge clk);
        dec_en8 = 1;
        cw_in8  = {120'b0, saved_cw8 ^ 40'h00_0000_FF00};
        @(posedge clk);
        @(negedge clk);
        chk(err_det8 === 1'b1, "S4 err: parity corrupt");
        $display("    error_detected=%b (expected 1)", err_det8);
        dec_en8 = 0;

        // ============================================================
        // S5 – DUT8: ERROR DETECTION – CORRUPT DATA BYTE
        //   Flip the LSB of the data byte (bit 0 of the codeword).
        // ============================================================
        $display("--- S5: DUT8 error detect – corrupt data byte ---");
        @(negedge clk);
        dec_en8 = 1;
        cw_in8  = {120'b0, saved_cw8 ^ 40'h00_0000_0001};
        @(posedge clk);
        @(negedge clk);
        chk(err_det8 === 1'b1, "S5 err: data corrupt");
        $display("    error_detected=%b (expected 1)", err_det8);
        dec_en8 = 0;

        // ============================================================
        // S6 – DUT8: error_corrected IS ALWAYS 0 (RTL placeholder)
        // ============================================================
        $display("--- S6: error_corrected always 0 ---");
        chk(err_cor8 === 1'b0, "S6 err_corrected=0");

        // ============================================================
        // S7 – DUT8: BACK-TO-BACK ENCODES (pipeline)
        //   Keep encode_en asserted for 3 consecutive cycles, updating
        //   data_in at each negedge.  After the 3rd posedge the output
        //   must reflect the last datum (0x33).
        // ============================================================
        $display("--- S7: DUT8 back-to-back encodes ---");
        @(negedge clk); enc_en8 = 1; din8 = 8'h11;
        @(posedge clk);               // P1: captures 0x11
        @(negedge clk); din8 = 8'h22;
        @(posedge clk);               // P2: captures 0x22
        @(negedge clk); din8 = 8'h33;
        @(posedge clk);               // P3: captures 0x33
        @(negedge clk);               // N3: outputs reflect 0x33
        chk(vld8         === 1'b1,  "S7 vld after 3rd enc");
        chk(cw_out8[7:0] === 8'h33, "S7 last data byte=33");
        enc_en8 = 0;

        // ============================================================
        // S8 – DUT8: SIMULTANEOUS encode_en + decode_en
        //   Both flags high together.  valid_out must be asserted.
        //   decode path: all-zero codeword → no syndrome error.
        // ============================================================
        $display("--- S8: DUT8 simultaneous encode+decode ---");
        @(negedge clk);
        enc_en8 = 1; dec_en8 = 1;
        din8   = 8'hAA;
        cw_in8 = 160'h0;   // All-zero codeword → syndromes all 0
        @(posedge clk);
        @(negedge clk);
        chk(vld8     === 1'b1, "S8 vld sim enc+dec");
        chk(err_det8 === 1'b0, "S8 no error (zero cw)");
        enc_en8 = 0; dec_en8 = 0;

        // ============================================================
        // S9 – DUT8: ASYNC RESET MID-OPERATION
        //   Assert rst_n=0 while an encode is in progress.  The async
        //   reset clears registered outputs immediately (#1 settle).
        //   After release, outputs remain 0 for one idle cycle.
        // ============================================================
        $display("--- S9: DUT8 async reset mid-operation ---");
        @(negedge clk);
        enc_en8 = 1; din8 = 8'hDE;
        rst_n   = 0;  // Assert reset asynchronously
        #1;           // Small propagation delay to let async clear settle
        chk((|cw_out8) === 1'b0, "S9 cw_out=0 during reset");
        chk(vld8        === 1'b0, "S9 vld=0 during reset");
        @(posedge clk);
        @(negedge clk);
        enc_en8 = 0;
        chk(vld8 === 1'b0, "S9 vld=0 clk w/ reset");

        rst_n = 1;
        @(posedge clk);  // recovery cycle
        @(negedge clk);
        chk(vld8 === 1'b0, "S9 vld=0 after release");

        // ============================================================
        // S10 – DUT16: ENCODE + DECODE ROUND-TRIP (0xBEEF)
        //   48-bit codeword; data at [15:0], parity bytes at [47:16].
        // ============================================================
        $display("--- S10: DUT16 encode 0xBEEF round-trip ---");
        @(negedge clk);  enc_en16 = 1; din16 = 16'hBEEF;
        @(posedge clk);
        @(negedge clk);
        chk(vld16          === 1'b1,      "S10 vld16 after enc");
        chk(cw_out16[15:0] === 16'hBEEF,  "S10 data bytes preserved");
        saved_cw16 = cw_out16[47:0];
        enc_en16 = 0;
        $display("    DUT16 codeword[47:0] = 0x%012X", saved_cw16);

        @(negedge clk);  dec_en16 = 1; cw_in16 = {112'b0, saved_cw16};
        @(posedge clk);
        @(negedge clk);
        chk(dout16    === 16'hBEEF, "S10 decoded data=BEEF");
        chk(err_det16 === 1'b0,     "S10 no error on clean cw16");
        dec_en16 = 0;

        // S10b – DUT16: error detection on corrupted parity byte 0
        //   Parity byte 0 sits at [23:16] of the 48-bit codeword.
        $display("--- S10b: DUT16 error detection ---");
        @(negedge clk);
        dec_en16 = 1;
        cw_in16  = {112'b0, saved_cw16 ^ 48'h00_00_FF_00_00_00};
        @(posedge clk);
        @(negedge clk);
        chk(err_det16 === 1'b1, "S10b DUT16 err detected");
        dec_en16 = 0;

        // ============================================================
        // S11 – DUT32: ENCODE + DECODE ROUND-TRIP (0xDEADBEEF)
        //   64-bit codeword; data at [31:0], parity bytes at [63:32].
        // ============================================================
        $display("--- S11: DUT32 encode 0xDEADBEEF round-trip ---");
        @(negedge clk);  enc_en32 = 1; din32 = 32'hDEADBEEF;
        @(posedge clk);
        @(negedge clk);
        chk(vld32          === 1'b1,          "S11 vld32 after enc");
        chk(cw_out32[31:0] === 32'hDEADBEEF,  "S11 data bytes preserved");
        saved_cw32 = cw_out32[63:0];
        enc_en32 = 0;
        $display("    DUT32 codeword[63:0] = 0x%016X", saved_cw32);

        @(negedge clk);  dec_en32 = 1; cw_in32 = {96'b0, saved_cw32};
        @(posedge clk);
        @(negedge clk);
        chk(dout32    === 32'hDEADBEEF, "S11 decoded=DEADBEEF");
        chk(err_det32 === 1'b0,         "S11 no error on clean cw32");
        dec_en32 = 0;

        // S11b – DUT32: flip bit 16 (LSB of data byte 2).
        $display("--- S11b: DUT32 error detection ---");
        @(negedge clk);
        dec_en32 = 1;
        cw_in32  = {96'b0, saved_cw32 ^ 64'h0000_0000_0001_0000};
        @(posedge clk);
        @(negedge clk);
        chk(err_det32 === 1'b1, "S11b DUT32 err detected");
        dec_en32 = 0;

        // ============================================================
        // S12 – DUT32: ALL-ZERO DATA
        // ============================================================
        $display("--- S12: DUT32 encode 0x00000000 (all-zero) ---");
        @(negedge clk);  enc_en32 = 1; din32 = 32'h0;
        @(posedge clk);
        @(negedge clk);
        chk(cw_out32[63:0] === 64'h0, "S12 zero-data->zero cw32");
        enc_en32 = 0;

        // ============================================================
        // S13 – DUT64: ENCODE + DECODE ROUND-TRIP
        //   96-bit codeword; data at [63:0], parity bytes at [95:64].
        // ============================================================
        $display("--- S13: DUT64 encode 0xCAFEBABEDEAD1234 round-trip ---");
        @(negedge clk);  enc_en64 = 1; din64 = 64'hCAFEBABEDEAD1234;
        @(posedge clk);
        @(negedge clk);
        chk(vld64          === 1'b1,               "S13 vld64 after enc");
        chk(cw_out64[63:0] === 64'hCAFEBABEDEAD1234, "S13 data preserved");
        saved_cw64 = cw_out64[95:0];
        enc_en64 = 0;
        $display("    DUT64 codeword[95:0] = 0x%024X", saved_cw64);

        @(negedge clk);  dec_en64 = 1; cw_in64 = {64'b0, saved_cw64};
        @(posedge clk);
        @(negedge clk);
        chk(dout64    === 64'hCAFEBABEDEAD1234, "S13 decoded ok");
        chk(err_det64 === 1'b0,                 "S13 no error clean cw64");
        dec_en64 = 0;

        // S13b – DUT64: corrupt data byte 0 (flip bit 0).
        $display("--- S13b: DUT64 error detection – corrupt data byte 0 ---");
        @(negedge clk);
        dec_en64 = 1;
        cw_in64  = {64'b0, saved_cw64 ^ 96'h0000_0000_0000_0000_0000_0001};
        @(posedge clk);
        @(negedge clk);
        chk(err_det64 === 1'b1, "S13b DUT64 err detected");
        $display("    error_detected=%b (expected 1)", err_det64);
        dec_en64 = 0;

        // ============================================================
        // Final summary
        // ============================================================
        $display("---");
        if (fail_count == 0)
            $display("=== PASS: All checks passed ===");
        else
            $display("=== FAIL: %0d check(s) failed ===", fail_count);

        $finish;
    end

endmodule
