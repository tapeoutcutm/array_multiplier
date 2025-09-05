`timescale 1ns / 1ps
// -----------------------------------------------------------------
// mac_spst_tiny.v
// 8-bit Multiply-Accumulate with SPST adder, tri-state IO
// Tiny Tapeout style module with 8-bit IO limit
// -----------------------------------------------------------------
module mac_spst_tiny (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        acc_en,        // enable accumulation (normal operation)
    input  wire [7:0]  in_a,          // multiplier input a
    input  wire [7:0]  in_b,          // multiplier input b
    output wire [7:0]  out_low,       // lower byte of accumulator (always driven)
    inout  wire [7:0]  io_high,       // upper byte of accumulator (bidirectional pad)
    input  wire        io_drive,      // 1 = module drives io_high; 0 = tri-state (hi-z)
    input  wire        load_ext_high // when 1 (and acc_en==0) capture external io_high into acc[15:8]
);

    // Internal accumulator register
    reg  [15:0] acc_reg;

    wire [15:0] product;
    wire [15:0] sum_next;
    wire        carry_out_unused;

    // 8x8 multiplier instance
    array_mult8x8 u_mult (
        .a(in_a),
        .b(in_b),
        .p(product)
    );

    // 16-bit SPST adder instance
    spst_adder16 u_spst (
        .a(acc_reg),
        .b(product),
        .sum(sum_next),
        .carry_out(carry_out_unused)
    );

    // Drive lower byte output
    assign out_low = acc_reg[7:0];

    // Tri-state upper byte output
    assign io_high = io_drive ? acc_reg[15:8] : 8'bz;

    // Sample external pad when io_drive is low
    wire [7:0] io_high_in;
    assign io_high_in = io_high;

    // Accumulator update on clock
    always @(posedge clk) begin
        if (!rst_n) begin
            acc_reg <= 16'b0;
        end else if (acc_en) begin
            acc_reg <= sum_next;
        end else if (load_ext_high) begin
            acc_reg[15:8] <= io_high_in;
            // lower byte unchanged
        end else begin
            acc_reg <= acc_reg;
        end
    end

endmodule
