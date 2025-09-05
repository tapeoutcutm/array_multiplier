import cocotb
from cocotb.triggers import RisingEdge, Timer


async def reset_dut(dut, cycles=5):
    """Reset helper."""
    dut.rst_n.value = 0
    await Timer(1, units="ns")
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


def safe_int(signal):
    """Convert cocotb signal to int safely (avoid X/Z)."""
    try:
        return int(signal.value)
    except ValueError:
        return 0


@cocotb.test()
async def test_mac_spst_basic(dut):
    """Test MAC with SPST adder in TinyTapeout wrapper."""

    # Init
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1
    dut.clk.value = 0

    # Clock generator
    async def clk_gen():
        while True:
            dut.clk.value = 0
            await Timer(5, units="ns")
            dut.clk.value = 1
            await Timer(5, units="ns")

    cocotb.start_soon(clk_gen())

    # Reset
    await reset_dut(dut)

    # --- Test 1: Multiply 3 * 4 ---
    dut.ui_in.value = 3
    dut.uio_in.value = 4
    await RisingEdge(dut.clk)   # capture inputs
    await RisingEdge(dut.clk)   # update accumulator
    acc1 = (safe_int(dut.uio_out) << 8) | safe_int(dut.uo_out)
    assert acc1 == 12, f"Expected 12, got {acc1}"

    # --- Test 2: Add 2 * 5 ---
    dut.ui_in.value = 2
    dut.uio_in.value = 5
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    acc2 = (safe_int(dut.uio_out) << 8) | safe_int(dut.uo_out)
    assert acc2 == 12 + 10, f"Expected 22, got {acc2}"

    # --- Test 3: Add 10 * 10 ---
    dut.ui_in.value = 10
    dut.uio_in.value = 10
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    acc3 = (safe_int(dut.uio_out) << 8) | safe_int(dut.uo_out)
    assert acc3 == 22 + 100, f"Expected 122, got {acc3}"

    # --- Test 4: Disable accumulation and load external high byte ---
    dut.ena.value = 0
    dut.uio_in.value = 0x55
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    acc4 = (safe_int(dut.uio_out) << 8) | safe_int(dut.uo_out)
    assert (acc4 >> 8) == 0x55, f"Expected high byte 0x55, got {hex(acc4 >> 8)}"

    # --- Test 5: Re-enable accumulation with 1*1 ---
    dut.ena.value = 1
    dut.ui_in.value = 1
    dut.uio_in.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    acc5 = (safe_int(dut.uio_out) << 8) | safe_int(dut.uo_out)
    assert acc5 == (0x55 << 8) + 1, f"Expected 0x5501, got {hex(acc5)}"
