`timescale 1ns/1ps
`default_nettype none

module tb;

    // DUT I/O
    reg  [7:0] ui_in;     // operand A
    wire [7:0] uo_out;    // low byte output
    reg  [7:0] uio_in;    // operand B / external input
    wire [7:0] uio_out;   // high byte output
    wire [7:0] uio_oe;    // output enable
    reg        ena;       // enable (like chip select)
    reg        clk;       // clock
    reg        rst_n;     // reset

    // Instantiate DUT
    tt_um_mac_spst_tiny dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock (10 ns period)

    // Stimulus
    initial begin
        // Init
        ui_in   = 8'd0;
        uio_in  = 8'd0;
        ena     = 1'b1;
        rst_n   = 1'b0;

        // Reset pulse
        #20;
        rst_n = 1'b1;

        // Test 1: multiply 3 * 4
        @(posedge clk);
        ui_in  = 8'd3;     // A = 3
        uio_in = 8'd4;     // B = 4

        @(posedge clk);
        $display("MAC after 1 cycle: Acc=%h%h", uio_out, uo_out);

        // Test 2: accumulate with 2 * 5
        @(posedge clk);
        ui_in  = 8'd2;     // A = 2
        uio_in = 8'd5;     // B = 5

        @(posedge clk);
        $display("MAC after 2 cycles: Acc=%h%h", uio_out, uo_out);

        // Test 3: accumulate with 10 * 10
        @(posedge clk);
        ui_in  = 8'd10;    
        uio_in = 8'd10;

        @(posedge clk);
        $display("MAC after 3 cycles: Acc=%h%h", uio_out, uo_out);

        // Disable accumulation (ena=0), load external high byte = 0x55
        @(posedge clk);
        ena    = 1'b0;
        uio_in = 8'h55;

        @(posedge clk);
        $display("External high byte loaded: Acc=%h%h", uio_out, uo_out);

        // Re-enable accumulation
        @(posedge clk);
        ena    = 1'b1;
        ui_in  = 8'd1;
        uio_in = 8'd1;

        @(posedge clk);
        $display("Final Accumulate: Acc=%h%h", uio_out, uo_out);

        #20;
        $finish;
    end

endmodule
