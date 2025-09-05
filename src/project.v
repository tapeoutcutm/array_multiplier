/*
 * MAC with SPST adder (TinyTapeout compliant)
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// ============================================================
// Top-level TinyTapeout wrapper
// ============================================================
module tt_um_mac_spst_tiny (
    input  wire [7:0] ui_in,    // Dedicated inputs: operand A
    output wire [7:0] uo_out,   // Dedicated outputs: accumulator low byte
    input  wire [7:0] uio_in,   // IOs: input path (operand B / ext high byte in)
    output wire [7:0] uio_out,  // IOs: output path (accumulator high byte)
    output wire [7:0] uio_oe,   // IOs: enable path (1=drive output)
    input  wire       ena,      // always 1 when powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset, active low
);

    // Internal signals
    wire [7:0] out_low;
    wire [7:0] out_high;
    wire       out_high_oe;

    // Operand mapping
    wire [7:0] operand_a = ui_in;
    wire [7:0] operand_b = uio_in;

    // Instantiate the MAC core
    mac_spst_tiny dut (
        .clk(clk),
        .rst_n(rst_n),
        .acc_en(ena),
        .in_a(operand_a),
        .in_b(operand_b),
        .out_low(out_low),
        .out_high(out_high),
        .out_high_oe(out_high_oe)
    );

    // Outputs
    assign uo_out  = out_low;                  // low byte
    assign uio_out = out_high;                 // high byte
    assign uio_oe  = {8{out_high_oe}};         // enable mask

endmodule


// ============================================================
// Core MAC with SPST Adder (no inout)
// ============================================================
module mac_spst_tiny (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        acc_en,
    input  wire [7:0]  in_a,
    input  wire [7:0]  in_b,
    output wire [7:0]  out_low,
    output wire [7:0]  out_high,
    output wire        out_high_oe
);
    reg [15:0] acc;
    wire [15:0] mult_out;
    wire [15:0] sum;

    // Multiplier
    array_mult8x8 u_mult (
        .a(in_a),
        .b(in_b),
        .y(mult_out)
    );

    // SPST Adder
    spst_adder16 u_adder (
        .a(acc),
        .b(mult_out),
        .sum(sum)
    );

    // Accumulator update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 16'd0;
        end else if (acc_en) begin
            acc <= sum;
        end
    end

    // Outputs
    assign out_low    = acc[7:0];
    assign out_high   = acc[15:8];
    assign out_high_oe = 1'b1;   // always drive high byte

endmodule


// ============================================================
// 8x8 Array Multiplier
// ============================================================
module array_mult8x8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [15:0] y
);
    assign y = a * b;
endmodule


// ============================================================
// 16-bit SPST Adder
// ============================================================
module spst_adder16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [15:0] sum
);
    assign sum = a + b; // Replace with SPST optimized logic if needed
endmodule
