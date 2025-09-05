`timescale 1ns / 1ps

module tb_mac_spst_tiny;
    reg clk = 0;
    reg rst_n = 0;
    reg acc_en = 0;
    reg load_ext_high = 0;
    reg io_drive_tb = 1; // controls if DUT drives io_high
    reg [7:0] a = 0, b = 0;

    reg ext_drive = 0;
    reg [7:0] ext_val = 8'h00;

    // Bidirectional bus for upper accumulator byte
    wire [7:0] io_bus;

    // Testbench drives io_bus when ext_drive==1; else high-Z
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

    // 10ns clock generator
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_mac_spst_tiny.vcd");
        $dumpvars(0, tb_mac_spst_tiny);

        // Reset
        rst_n = 0; #20;
        rst_n = 1;

        // Test 1: accumulate a few products, module drives high byte
        io_drive_tb = 1; // module drives io_high
        acc_en = 1;
        a = 8'd3;    b = 8'd4;   #10; // acc += 12
        a = 8'd2;    b = 8'd5;   #10; // acc += 10 -> 22
        a = 8'd100;  b = 8'd2;   #10; // acc += 200 -> 222
        acc_en = 0;

        // Read acc externally: module should drive io_bus with high byte
        $display("After accumulation: out_low=0x%h io_high(module drives)=0x%h", out_low, io_bus);
        #10;

        // Test 2: external logic loads a new high byte
        io_drive_tb = 0;    // release pad
        ext_val = 8'hAA;    // external value for high byte
        ext_drive = 1;      // start driving bus
        load_ext_high = 1;  // load on next clk
        #10;
        load_ext_high = 0;
        ext_drive = 0;      // stop driving (optional)

        // Let module drive again, read high byte
        io_drive_tb = 1;    // module drives bus
        #10;
        $display("After external load: out_low=0x%h io_high=%0h (expected high byte=0xAA)", out_low, io_bus);

        #20;
        $finish;
    end
endmodule
