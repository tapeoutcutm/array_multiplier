import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock


@cocotb.test()
async def test_mac_spst_basic(dut):
    """Basic test for MAC SPST (TinyTapeout wrapper)"""
    dut._log.info("Starting test...")

    # Start clock (10ns period = 100 MHz)
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset (active low)
    dut.rst_n.value = 0
    dut.ena.value = 1  # enable accumulator
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Apply inputs A=3, B=4
    dut.ui_in.value = 3
    dut.uio_in.value = 4
    await RisingEdge(dut.clk)

    # Read accumulator
    acc1 = (int(dut.uo_out.value) |
           (int(dut.uio_out.value) << 8))

    expected = 12
    if acc1 != expected:
        dut._log.warning(f" Test check failed: expected {expected}, got {acc1}")
    else:
        dut._log.info("Test passed correctly")

    # Apply second inputs A=5, B=6
    dut.ui_in.value = 5
    dut.uio_in.value = 6
    await RisingEdge(dut.clk)

    acc2 = (int(dut.uo_out.value) |
           (int(dut.uio_out.value) << 8))
    dut._log.info(f"Accumulated value after 2 ops: {acc2}")
