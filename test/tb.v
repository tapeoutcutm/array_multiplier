`timescale 1ns / 1ps
// -----------------------------------------------------------------
// tb_mac_spst_tiny.v
// Testbench for mac_spst_tiny module - Tiny Tapeout style
// -----------------------------------------------------------------
module tb_mac_spst_tiny;
    reg clk = 0;
    reg rst_n = 0;
    reg acc_en = 0;
    reg load_ext_high = 0;
    reg io_drive_tb = 1;     // controls whether DUT drives io_high
    reg [7:0] a = 0, b = 0;

    reg ext_drive = 0;
    reg [7:0] ext_val = 8'h00;

    // Bidirectional bus for upper byte
    wire [7:0] io_bus;

    // TB drives io_bus if ext_drive=1, else high-Z
    assign io_bus = ext_drive ? ext_val : 8'bz;

    wire [7:0] out_low;

    mac_spst_tiny dut (
        .clk(clk),
        .rst_n(rst_n),
        .acc_en(acc_en),
        .in_a(a),
        .in_b(b),
        .out_low(out_low),
        .io_high(io_bus),
        .io_drive(io_drive_tb),
        .load_ext_high(load_ext_high)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_mac_spst_tiny.vcd");
        $dumpvars(0, tb_mac_spst_tiny);

        // Reset
        rst_n = 0;
        #20;
        rst_n = 1;

        // Test 1: accumulate several multiplications, DUT drives io_high
        io_drive_tb = 1;
        acc_en = 1;
        a = 8'd3;    b = 8'd4;    #10;  // acc = 12
        a = 8'd2;    b = 8'd5;    #10;  // acc += 10 -> 22
        a = 8'd100;  b = 8'd2;    #10;  // acc += 200 -> 222
        acc_en = 0;

        // Display acc values
        $display("After accumulation: out_low=0x%h io_high(module drives)=0x%h", out_low, io_bus);
        #10;

        // Test 2: module releases io_high, external drives 0xAA
        io_drive_tb = 0;       // release module drive (tri-state)
        ext_val = 8'hAA;       // external value for upper byte
        ext_drive = 1;         // start driving external value
        load_ext_high = 1;     // latch external value on next clock
        #10;
        load_ext_high = 0;
        ext_drive = 0;         // stop driving, tri-state

        // Let module drive again to verify latched value
        io_drive_tb = 1;
        #10;
        $display("After external load: out_low=0x%h io_high=%0h (expected 0xAA)", out_low, io_bus);

        #20;
        $finish;
    end
endmodule
