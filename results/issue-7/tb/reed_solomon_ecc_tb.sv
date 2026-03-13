// Reed-Solomon ECC Testbench
// Covers the reed_solomon_ecc wrapper (results/issue-7/rtl/reed_solomon_ecc.v)
// with DATA_WIDTH = 8, 16, and 32 instantiated in parallel.
//
// RTL fixes applied in this workspace (results/issue-7/rtl/ only):
//   1. All sub-modules: codeword_in[7:0][N] chained indexing not supported by
//      Icarus Verilog; replaced with direct bit select codeword_in[N].
//   2. reed_solomon_ecc_w4.v: missing assign mul_0_1[0] added to match the
//      GF(2^8) generator polynomial used in all other width variants.
//
// Compile and run (from repository root):
//   iverilog -g2012 -o results/issue-7/build/reed_solomon_ecc_tb.out \
//       results/issue-7/tb/reed_solomon_ecc_tb.sv \
//       results/issue-7/rtl/reed_solomon_ecc.v \
//       results/issue-7/rtl/reed_solomon_ecc_w4.v \
//       results/issue-7/rtl/reed_solomon_ecc_w8.v \
//       results/issue-7/rtl/reed_solomon_ecc_w16.v \
//       results/issue-7/rtl/reed_solomon_ecc_w32.v \
//       results/issue-7/rtl/reed_solomon_ecc_w64.v \
//       results/issue-7/rtl/reed_solomon_ecc_w128.v
//   vvp results/issue-7/build/reed_solomon_ecc_tb.out

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
    //   Wrapper exposes 160-bit bus; only codeword_out[39:0] is meaningful.
    // ----------------------------------------------------------------
    reg        enc_en8, dec_en8;
    reg  [7:0] din8;
    reg [159:0] cw_in8;
    wire [159:0] cw_out8;
    wire  [7:0] dout8;
    wire        err_det8, err_cor8, vld8;

    reed_solomon_ecc #(.DATA_WIDTH(8)) dut8 (
        .clk(clk),          .rst_n(rst_n),
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
    //   Wrapper codeword_out[47:0] meaningful; upper 112 bits are 0.
    // ----------------------------------------------------------------
    reg        enc_en16, dec_en16;
    reg [15:0] din16;
    reg [159:0] cw_in16;
    wire [159:0] cw_out16;
    wire [15:0] dout16;
    wire        err_det16, err_cor16, vld16;

    reed_solomon_ecc #(.DATA_WIDTH(16)) dut16 (
        .clk(clk),           .rst_n(rst_n),
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
    //   Wrapper codeword_out[63:0] meaningful; upper 96 bits are 0.
    // ----------------------------------------------------------------
    reg        enc_en32, dec_en32;
    reg [31:0] din32;
    reg [159:0] cw_in32;
    wire [159:0] cw_out32;
    wire [31:0] dout32;
    wire        err_det32, err_cor32, vld32;

    reed_solomon_ecc #(.DATA_WIDTH(32)) dut32 (
        .clk(clk),           .rst_n(rst_n),
        .encode_en(enc_en32), .decode_en(dec_en32),
        .data_in(din32),      .codeword_in(cw_in32),
        .codeword_out(cw_out32),
        .data_out(dout32),
        .error_detected(err_det32),
        .error_corrected(err_cor32),
        .valid_out(vld32)
    );

    // ----------------------------------------------------------------
    // Failure counter and VCD dump
    // ----------------------------------------------------------------
    integer fail_count;

    initial begin
        $dumpfile("results/issue-7/build/reed_solomon_ecc_tb.vcd");
        $dumpvars(0, reed_solomon_ecc_tb);
    end

    // ----------------------------------------------------------------
    // Helper: check a condition; print and count failures.
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

        $display("=== Reed-Solomon ECC Testbench START ===");

        // ============================================================
        // S0 – RESET CHECK
        //   Hold active-low reset for 4 clock cycles.
        //   All registered outputs must remain zero.
        // ============================================================
        $display("--- S0: Reset check ---");
        repeat(4) @(posedge clk);
        @(negedge clk);
        chk(vld8     === 1'b0,   "S0 vld8=0");
        chk(err_det8 === 1'b0,   "S0 err=0");
        chk((|cw_out8) === 1'b0, "S0 cw_out8=0");
        chk(vld16    === 1'b0,   "S0 vld16=0");
        chk(vld32    === 1'b0,   "S0 vld32=0");

        // Deassert reset at negedge; one idle posedge before first op.
        rst_n = 1;
        @(posedge clk);

        // ============================================================
        // S1 – DUT8: ENCODE + DECODE ROUND-TRIP (nominal data 0xAB)
        //   Assert encode_en for exactly one cycle; RTL has 1-cycle
        //   latency, so valid_out and codeword_out are stable at the
        //   negedge that immediately follows the capturing posedge.
        // ============================================================
        $display("--- S1: DUT8 encode 0xAB, decode round-trip ---");
        @(negedge clk);  enc_en8 = 1; din8 = 8'hAB;  // drive at negedge
        @(posedge clk);                                // P1: captures encode_en=1
        @(negedge clk);                                // N1: outputs registered & stable
        chk(vld8 === 1'b1,           "S1 vld after enc");
        chk(cw_out8[7:0] === 8'hAB,  "S1 data byte preserved");
        saved_cw8 = cw_out8[39:0];
        enc_en8 = 0;     // deassert at N1 – safe, before next posedge
        $display("    codeword[39:0] = 0x%010X", saved_cw8);

        // valid_out must deassert on the very next cycle (no new op).
        @(posedge clk);  // P2: enc_en=0 → valid_out=0 registered
        @(negedge clk);  // N2
        chk(vld8 === 1'b0, "S1 vld deasserts");

        // Feed the clean encoded codeword back for decode.
        @(negedge clk);  dec_en8 = 1; cw_in8 = {120'b0, saved_cw8};
        @(posedge clk);  // P3: captures decode_en=1
        @(negedge clk);  // N3
        chk(vld8     === 1'b1,  "S1 vld after dec");
        chk(dout8    === 8'hAB, "S1 decoded data=AB");
        chk(err_det8 === 1'b0,  "S1 no error on clean cw");
        dec_en8 = 0;

        // ============================================================
        // S2 – DUT8: ALL-ZERO DATA → ALL-ZERO CODEWORD
        //   GF multiplication by zero is zero, so encoding 0x00
        //   must produce a 40-bit all-zero codeword.
        // ============================================================
        $display("--- S2: DUT8 encode 0x00 (all-zero) ---");
        @(negedge clk);  enc_en8 = 1; din8 = 8'h00;
        @(posedge clk);
        @(negedge clk);
        chk(vld8 === 1'b1,                      "S2 vld");
        chk(cw_out8[39:0] === 40'h0,            "S2 zero-cw");
        enc_en8 = 0;

        // Decode the all-zero codeword: all syndromes must be zero.
        @(negedge clk);  dec_en8 = 1; cw_in8 = 160'h0;
        @(posedge clk);
        @(negedge clk);
        chk(err_det8 === 1'b0, "S2 no error on zero cw");
        chk(dout8    === 8'h00,"S2 decoded data=00");
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
        chk(err_det8 === 1'b1, "S4 error det: parity corrupt");
        $display("    error_detected=%b (expected 1)", err_det8);
        dec_en8 = 0;

        // ============================================================
        // S5 – DUT8: ERROR DETECTION – CORRUPT DATA BYTE
        //   Flip the LSB of the data byte (cw[0]).
        // ============================================================
        $display("--- S5: DUT8 error detect – corrupt data byte ---");
        @(negedge clk);
        dec_en8 = 1;
        cw_in8  = {120'b0, saved_cw8 ^ 40'h00_0000_0001};
        @(posedge clk);
        @(negedge clk);
        chk(err_det8 === 1'b1, "S5 error det: data corrupt");
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
        @(posedge clk);              // P1: captures 0x11
        @(negedge clk); din8 = 8'h22;
        @(posedge clk);              // P2: captures 0x22
        @(negedge clk); din8 = 8'h33;
        @(posedge clk);              // P3: captures 0x33
        @(negedge clk);              // N3: outputs reflect 0x33
        chk(vld8         === 1'b1,  "S7 vld after 3rd enc");
        chk(cw_out8[7:0] === 8'h33, "S7 last data byte=33");
        enc_en8 = 0;

        // ============================================================
        // S8 – DUT8: SIMULTANEOUS encode_en + decode_en
        //   Both flags raised together.  The RTL processes both in the
        //   same clock cycle; valid_out must be asserted.
        // ============================================================
        $display("--- S8: DUT8 simultaneous encode+decode ---");
        @(negedge clk);
        enc_en8 = 1; dec_en8 = 1;
        din8   = 8'hAA;
        cw_in8 = 160'h0;   // All-zero codeword → no syndrome error
        @(posedge clk);
        @(negedge clk);
        chk(vld8     === 1'b1,  "S8 vld after sim enc+dec");
        chk(err_det8 === 1'b0,  "S8 no error on zero cw (dec)");
        enc_en8 = 0; dec_en8 = 0;

        // ============================================================
        // S9 – DUT8: ASYNC RESET MID-OPERATION
        //   Assert rst_n=0 while an encode is in progress; the async
        //   reset clears outputs immediately (verified with #1 delay).
        //   After release, outputs remain zero for one idle cycle.
        // ============================================================
        $display("--- S9: DUT8 async reset mid-operation ---");
        @(negedge clk);
        enc_en8 = 1; din8 = 8'hDE;
        rst_n   = 0;  // Assert reset asynchronously (negedge of rst_n)
        #1;           // Small propagation delay to let async clear settle
        chk((|cw_out8) === 1'b0, "S9 cw_out=0 during reset");
        chk(vld8        === 1'b0, "S9 vld=0 during reset");
        @(posedge clk); // posedge while reset active
        @(negedge clk);
        enc_en8 = 0;
        chk(vld8 === 1'b0, "S9 vld=0 after clk with reset");

        rst_n = 1;
        @(posedge clk);  // recovery cycle
        @(negedge clk);
        chk(vld8 === 1'b0, "S9 vld=0 after reset release (idle)");

        // ============================================================
        // S10 – DUT16: ENCODE + DECODE ROUND-TRIP (0xBEEF)
        //   48-bit codeword; data at [15:0], 4 parity bytes at [47:16].
        // ============================================================
        $display("--- S10: DUT16 encode 0xBEEF round-trip ---");
        @(negedge clk);  enc_en16 = 1; din16 = 16'hBEEF;
        @(posedge clk);
        @(negedge clk);
        chk(vld16          === 1'b1,     "S10 vld16 after enc");
        chk(cw_out16[15:0] === 16'hBEEF, "S10 data bytes preserved");
        saved_cw16 = cw_out16[47:0];
        enc_en16 = 0;
        $display("    DUT16 codeword[47:0] = 0x%012X", saved_cw16);

        @(negedge clk);  dec_en16 = 1; cw_in16 = {112'b0, saved_cw16};
        @(posedge clk);
        @(negedge clk);
        chk(dout16    === 16'hBEEF, "S10 decoded data=BEEF");
        chk(err_det16 === 1'b0,     "S10 no error on clean cw16");
        dec_en16 = 0;

        // S10b – DUT16: error detection on corrupted codeword
        //   Flip parity byte 0 (bits [23:16] of the 48-bit codeword).
        @(negedge clk);
        dec_en16 = 1;
        cw_in16 = {112'b0, saved_cw16 ^ 48'h00_00_FF_00_00_00};
        @(posedge clk);
        @(negedge clk);
        chk(err_det16 === 1'b1, "S10b DUT16 error detected");
        dec_en16 = 0;

        // ============================================================
        // S11 – DUT32: ENCODE + DECODE ROUND-TRIP (0xDEADBEEF)
        //   64-bit codeword; data at [31:0], 4 parity bytes at [63:32].
        // ============================================================
        $display("--- S11: DUT32 encode 0xDEADBEEF round-trip ---");
        @(negedge clk);  enc_en32 = 1; din32 = 32'hDEADBEEF;
        @(posedge clk);
        @(negedge clk);
        chk(vld32          === 1'b1,         "S11 vld32 after enc");
        chk(cw_out32[31:0] === 32'hDEADBEEF, "S11 data bytes preserved");
        saved_cw32 = cw_out32[63:0];
        enc_en32 = 0;
        $display("    DUT32 codeword[63:0] = 0x%016X", saved_cw32);

        @(negedge clk);  dec_en32 = 1; cw_in32 = {96'b0, saved_cw32};
        @(posedge clk);
        @(negedge clk);
        chk(dout32    === 32'hDEADBEEF, "S11 decoded data=DEADBEEF");
        chk(err_det32 === 1'b0,         "S11 no error on clean cw32");
        dec_en32 = 0;

        // S11b – DUT32: error detection on a corrupted codeword.
        //   Flip bit 0 of data byte 2 (codeword[16]).
        @(negedge clk);
        dec_en32 = 1;
        cw_in32  = {96'b0, saved_cw32 ^ 64'h0000_0000_0001_0000};
        @(posedge clk);
        @(negedge clk);
        chk(err_det32 === 1'b1, "S11b DUT32 error detected");
        dec_en32 = 0;

        // ============================================================
        // S12 – DUT32: ALL-ZERO DATA
        // ============================================================
        $display("--- S12: DUT32 encode 0x00000000 (all-zero) ---");
        @(negedge clk);  enc_en32 = 1; din32 = 32'h0;
        @(posedge clk);
        @(negedge clk);
        chk(cw_out32[63:0] === 64'h0, "S12 zero-data -> zero cw32");
        enc_en32 = 0;

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
