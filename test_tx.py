"""TX module test."""

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge


CLKS_PER_BIT = 2


async def rx_char(dut):
    """Receive a character on a 1 bit UART bus."""
    while 1:
        outbit = dut.o_tx_data.value.integer
        if outbit == 0:
            break
        await FallingEdge(dut.clk)
    for j in range(int(CLKS_PER_BIT * 1.5)):
        await FallingEdge(dut.clk)

    outchar = []
    for j in range(8):
        outchar.insert(0, dut.o_tx_data.value.binstr)
        for k in range(CLKS_PER_BIT):
            await FallingEdge(dut.clk)

    while 1:
        outbit = dut.o_tx_busy.value.integer
        if outbit == 0:
            break
        await FallingEdge(dut.clk)

    return int("".join(outchar), 2)


@cocotb.test()
async def test_tx_simple(dut):
    """Test that the input character appears on the output bus."""
    NUM_TESTS = 1

    clock = Clock(dut.clk, 10, units="us")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    await FallingEdge(dut.clk)  # Synchronize with the clock
    dut.rst <= 1
    await FallingEdge(dut.clk)
    dut.rst <= 0
    await FallingEdge(dut.clk)

    for i in range(NUM_TESTS):
        inval = random.randint(0, 255)
        cocotb.log.info("random value: %s" % bin(inval + 256)[3:])

        dut.i_tx_data <= inval  # Assign the random value val to the input port d
        dut.i_tx_valid <= 1
        await FallingEdge(dut.clk)
        dut.i_tx_data <= 0
        dut.i_tx_valid <= 0

        outval = await rx_char(dut)
        assert dut.o_tx_data.value, "TX line did not return to idle high on the %dth cycle" % i

        cocotb.log.info("Expected %s and got %s on iteration %d" % (bin(inval + 256)[3:], bin(outval + 256)[3:], i))
        assert inval == outval, "output was incorrect on the {}th cycle".format(i)
