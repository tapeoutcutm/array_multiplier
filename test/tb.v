`timescale 1ns/1ps

module tb;

    reg clk, rst_n, ena;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;

    // Instantiate DUT
    tt_um_mac_spst_tiny dut (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .uo_out(uo_out),
        .uio_out(uio_out)
    );

    // Clock gen (10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    integer acc_val;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb);

        // Reset
        rst_n = 0;
        ena   = 1;
        ui_in = 0;
        uio_in = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;

        // --- Test 1: 3*4 = 12 ---
        ui_in  = 3;
        uio_in = 4;
        repeat (3) @(posedge clk);
        acc_val = {uio_out, uo_out};
        $display("MAC after 1 op: Acc=%0d", acc_val);

        // --- Test 2: + (2*5 = 10) → 22 ---
        ui_in  = 2;
        uio_in = 5;
        repeat (3) @(posedge clk);
        acc_val = {uio_out, uo_out};
        $display("MAC after 2 ops: Acc=%0d", acc_val);

        // --- Test 3: + (1*10 = 10) → 32 ---
        ui_in  = 1;
        uio_in = 10;
        repeat (3) @(posedge clk);
        acc_val = {uio_out, uo_out};
        $display("MAC after 3 ops: Acc=%0d", acc_val);

        $finish;
    end
endmodule
