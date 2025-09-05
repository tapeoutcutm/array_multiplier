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
        if (!rst_n) begin
            acc <= 16'd0;
        end else if (acc_en) begin
            acc <= sum;
        end
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
    assign sum = a + b; // Replace with SPST optimized logic if needed
endmodule
