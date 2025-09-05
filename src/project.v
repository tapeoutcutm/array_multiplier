`timescale 1ns / 1ps
// -----------------------------------------------------------------
// array_mult8x8.v
// 8x8 combinational array multiplier (Braun/regular array)
// -----------------------------------------------------------------
module array_mult8x8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [15:0] p
);
    wire [15:0] pp [7:0];
    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin : PP
            assign pp[i] = (b[i] ? ( {8'b0, a} << i ) : 16'b0);
        end
    endgenerate
    wire [15:0] sum0, sum1, sum2, sum3;
    assign sum0 = pp[0] + pp[1];
    assign sum1 = pp[2] + pp[3];
    assign sum2 = pp[4] + pp[5];
    assign sum3 = pp[6] + pp[7];
    wire [15:0] sum01 = sum0 + sum1;
    wire [15:0] sum23 = sum2 + sum3;
    assign p = sum01 + sum23;
endmodule

// -----------------------------------------------------------------
// spst_adder16.v
// 16-bit adder implementing SPST: split lower and upper 8 bits
// -----------------------------------------------------------------
module spst_adder16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [15:0] sum,
    output wire        carry_out
);
    // Lower part (LSP)
    wire [8:0] lsp_sum_ext;
    assign lsp_sum_ext = {1'b0, a[7:0]} + {1'b0, b[7:0]};
    wire [7:0] lsp_sum = lsp_sum_ext[7:0];
    wire       carry_lsp = lsp_sum_ext[8];
    // Detection logic
    wire a_msp_nonzero = |a[15:8];
    wire b_msp_nonzero = |b[15:8];
    wire compute_msp = a_msp_nonzero | b_msp_nonzero | carry_lsp;
    // MSP result
    wire [8:0] msp_sum_ext;
    assign msp_sum_ext = {1'b0, a[15:8]} + {1'b0, b[15:8]} + carry_lsp;
    wire [7:0] msp_sum_computed = msp_sum_ext[7:0];
    wire       carry_msp = msp_sum_ext[8];
    // Bypass
    wire [7:0] msp_sum_bypassed = a[15:8];
    assign sum[7:0]  = lsp_sum;
    assign sum[15:8] = (compute_msp) ? msp_sum_computed : msp_sum_bypassed;
    assign carry_out = compute_msp ? carry_msp : 1'b0;
endmodule

// -----------------------------------------------------------------
// mac_spst_tiny.v
// Top module, Tiny Tapeout 8-bit IO limit, correct inout usage
// -----------------------------------------------------------------
module mac_spst_tiny (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        acc_en,        // enable accumulation (normal operation)
    input  wire [7:0]  in_a,
    input  wire [7:0]  in_b,
    output wire [7:0]  out_low,       // lower byte of accumulator (always driven)
    inout  wire [7:0]  io_high,       // upper byte of accumulator (bidirectional pad)
    input  wire        io_drive,      // 1 = module drives io_high; 0 = tri-state
    input  wire        load_ext_high  // when 1 (and acc_en==0) capture external io_high into acc[15:8]
);
    // Internal accumulator
    reg  [15:0] acc_reg;
    wire [15:0] product;
    wire [15:0] sum_next;
    wire        carry_out_unused;

    // Multiplier and adder
    array_mult8x8 u_mult (
        .a(in_a),
        .b(in_b),
        .p(product)
    );
    spst_adder16  u_spst (
        .a(acc_reg),
        .b(product),
        .sum(sum_next),
        .carry_out(carry_out_unused)
    );

    // Output: lower byte always
    assign out_low = acc_reg[7:0];

    // Correct tristate for inout pad
    assign io_high = io_drive ? acc_reg[15:8] : 8'bz;

    // Safely sample external value (when io_drive==0)
    wire [7:0] io_high_in;
    assign io_high_in = io_high;

    // Accumulator update rules
    always @(posedge clk) begin
        if (!rst_n) begin
            acc_reg <= 16'b0;
        end else if (acc_en) begin
            acc_reg <= sum_next;
        end else if (load_ext_high) begin
            acc_reg[15:8] <= io_high_in;
        end else begin
            acc_reg <= acc_reg;
        end
    end
endmodule
