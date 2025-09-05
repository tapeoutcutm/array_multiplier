import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_mac_spst_basic(dut):
    """
    Test MAC with SPST adder in TinyTapeout wrapper.
    """
    # Setup clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset DUT
    dut.rst_n.value = 0
    dut.ena.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    dut.ena.value = 1
    await RisingEdge(dut.clk)

    # ---- Test 1: simple multiply-accumulate ----
    # Suppose ui_in[3:0] = a, ui_in[7:4] = b
    # Then MAC does acc += a*b, output at uo_out
    a = 3
    b = 4
    dut.ui_in.value = (b << 4) | a
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    acc1 = int(dut.uo_out.value)
    dut._log.info(f"MAC after 1 op: Acc={acc1}")
    assert acc1 == 12, f"Expected 12, got {acc1}"

    # ---- Test 2: accumulate again ----
    a = 2
    b = 5
    dut.ui_in.value = (b << 4) | a
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    acc2 = int(dut.uo_out.value)
    dut._log.info(f"MAC after 2 ops: Acc={acc2}")
    assert acc2 == 22, f"Expected 22, got {acc2}"

    # ---- Test 3: check reset clears accumulator ----
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    acc_reset = int(dut.uo_out.value)
    dut._log.info(f"MAC after reset: Acc={acc_reset}")
    assert acc_reset == 0, f"Expected reset to clear acc, got {acc_reset}"
