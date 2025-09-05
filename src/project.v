/*
 * MAC with SPST adder
 * TinyTapeout wrapper
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_mac_spst_tiny (
    input  wire [7:0] ui_in,    // Dedicated inputs: operand A
    output wire [7:0] uo_out,   // Dedicated outputs: accumulator low byte
    input  wire [7:0] uio_in,   // IOs: input path (operand B / external high byte)
    output wire [7:0] uio_out,  // IOs: output path (accumulator high byte)
    output wire [7:0] uio_oe,   // IOs: enable path (1=drive high byte)
    input  wire       ena,      // always 1 when powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset, active low
);

    // Internal signals
    wire [7:0] out_low;
    reg        io_drive_reg;
    reg        load_ext_high_reg;

    // Operand mapping
    wire [7:0] operand_a = ui_in;
    wire [7:0] operand_b = uio_in;

    // Control: 
    // - accumulate when ena=1
    // - drive high byte when ena=1
    // - allow external load when ena=0
    wire acc_en = ena;

    always @(*) begin
        io_drive_reg      = ena;
        load_ext_high_reg = ~ena;
    end

    // Instantiate the DUT
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
    assign uo_out  = out_low;              // dedicated outputs = low byte
    assign uio_out = uio_in;               // high byte bus
    assign uio_oe  = {8{io_drive_reg}};    // enable only when DUT drives

endmodule
