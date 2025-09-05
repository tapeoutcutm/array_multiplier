/*
 * Multiply-Accumulate with SPST Adder
 * TinyTapeout wrapper
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// ============================================================
// TinyTapeout wrapper
// ============================================================
module tt_um_mac_spst_tiny (
    input  wire [7:0] ui_in,    // Operand A
    output wire [7:0] uo_out,   // Accumulator low byte
    input  wire [7:0] uio_in,   // Operand B / external input
    output wire [7:0] uio_out,  // Accumulator high byte
    output wire [7:0] uio_oe,   // Output enable
    input  wire       ena,      // Chip enable
    input  wire       clk,      // Clock
    input  wire       rst_n     // Active-low reset
);

    // Internal signals
    wire [7:0] out_low;
    reg        io_drive_reg;
    reg        load_ext_high_reg;

    // Operand mapping
    wire [7:0] operand_a = ui_in;
    wire [7:0] operand_b = uio_in;

    // Accumulate only when ena=1
    wire acc_en = ena;

    always @(*) begin
        io_drive_reg      = ena;
        load_ext_high_reg = ~ena;
    end

    // Core MAC
    mac_spst_tiny dut (
        .clk(clk),
        .rst_n(rst_n),
        .acc_en(acc_en),
        .in_a(operand_a),
        .in_b(operand_b),
        .out_low(out_low),
        .io_high(uio_in),
        .io_drive(io_drive_reg),
        .load_ext_high(load_ext_high_reg)
    );

    // Outputs
    assign uo_out  = out_low;
    assign uio_out = uio_in;               // bus connection
    assign uio_oe  = {8{io_drive_reg}};

endmodule

// ============================================================
// Core MAC with SPST Adder
// ============================================================
module mac_spst_tiny (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        acc_en,
    input  wire [7:0]  in_a,
    input  wire [7:0]  in_b,
    output wire [7:0]  out_low,
    inout  wire [7:0]  io_high,
    input  wire        io_drive,
    input  wire        load_ext_high
);
    reg [15:0] acc;
    wire [15:0] mult_out;
    wire [15:0] sum;
    reg  [7:0]  ext_high;

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
        if (!rst_n)
            acc <= 16'd0;
        else if (acc_en)
            acc <= sum;
    end

    // External load of high byte when ena=0
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ext_high <= 8'd0;
        else if (load_ext_high)
            ext_high <= io_high;
    end

    // Outputs
    assign out_low = acc[7:0];
    assign io_high = io_drive ? acc[15:8] : 8'bz;

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
    assign sum = a + b; // simplified, can replace with SPST logic
endmodule
