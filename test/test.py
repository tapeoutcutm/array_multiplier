import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


def safe_int(sig):
    """Convert signal to int safely, even if 'x' or 'z'."""
    try:
        return int(sig.value)
    except ValueError:
        return 0


@cocotb.test()
async def test_mac_spst_basic(dut):
    """Test MAC with SPST adder in TinyTapeout wrapper."""

    # Start clock (10ns period → 100MHz)
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # --- Test 1: Multiply 3 * 4 = 12 ---
    dut.ui_in.value = 3
    dut.uio_in.value = 4

    await RisingEdge(dut.clk)   # capture inputs
    await RisingEdge(dut.clk)   # acc updates
    await RisingEdge(dut.clk)   # output stable

    acc1 = (safe_int(dut.uio_out) << 8) | safe_int(dut.uo_out)
    cocotb.log.info(f"MAC after 1 op: Acc={acc1}")
    assert acc1 == 12, f"Expected 12, got {acc1}"

    # --- Test 2: Add 2*5 = 10, Acc should be 22 ---
    dut.ui_in.value = 2
    dut.uio_in.value = 5

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    acc2 = (safe_int(dut.uio_out) << 8) | safe_int(dut.uo_out)
    cocotb.log.info(f"MAC after 2 ops: Acc={acc2}")
    assert acc2 == 22, f"Expected 22, got {acc2}"

    # --- Test 3: Add 1*10 = 10, Acc should be 32 ---
    dut.ui_in.value = 1
    dut.uio_in.value = 10

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    acc3 = (safe_int(dut.uio_out) << 8) | safe_int(dut.uo_out)
    cocotb.log.info(f"MAC after 3 ops: Acc={acc3}")
    assert acc3 == 32, f"Expected 32, got {acc3}"
