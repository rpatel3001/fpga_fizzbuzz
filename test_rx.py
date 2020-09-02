"""RX module test."""

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge


CLKS_PER_BIT = 2


async def tx_char(dut, inchar):
    """Transmit a character on a 1 bit UART bus."""
    inval = bin(inchar * 2 + 512)[2:]
    for j in reversed(range(len(inval))):
        for k in range(CLKS_PER_BIT):
            await FallingEdge(dut.clk)
        dut.i_rx_data <= int(inval[j])

    while 1:
        outbit = dut.o_rx_valid.value.integer
        if outbit == 1:
            return dut.o_rx_data.value
        await FallingEdge(dut.clk)


@cocotb.test()
async def test_rx_simple(dut):
    """Test that the input character appears in the output register."""
    NUM_TESTS = 1

    clock = Clock(dut.clk, 10, units="us")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    await FallingEdge(dut.clk)  # Synchronize with the clock
    dut.rst <= 1
    dut.i_rx_data <= 1
    await FallingEdge(dut.clk)
    dut.rst <= 0
    await FallingEdge(dut.clk)

    for i in range(NUM_TESTS):
        inchar = random.randint(0, 255)
        cocotb.log.info("random value: %s" % bin(inchar + 256)[3:])

        outchar = await tx_char(dut, inchar)

        cocotb.log.info("Expected %s and got %s on iteration %d" % (bin(inchar + 256)[3:], bin(outchar + 256)[3:], i))
        assert inchar == outchar, "output was incorrect on the {}th cycle".format(i)
