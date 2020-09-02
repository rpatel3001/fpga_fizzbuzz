"""Top level module test."""

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer


CLKS_PER_BIT = 2


async def rx_char(dut):
    """Receive a character on a 1 bit UART bus."""
    while 1:
        outbit = dut.tx_phy.value.integer
        if outbit == 0:
            break
        await FallingEdge(dut.clk)
    for j in range(int(CLKS_PER_BIT * 1.5)):
        await FallingEdge(dut.clk)

    outchar = []
    for j in range(8):
        outchar.insert(0, dut.tx_phy.value.binstr)
        for k in range(CLKS_PER_BIT):
            await FallingEdge(dut.clk)

    while 1:
        outbit = dut.tx_busy.value.integer
        if outbit == 0:
            break
        await FallingEdge(dut.clk)

    return int("".join(outchar), 2)


async def tx_char(dut, inchar):
    """Transmit a character on 1 bit UART bus."""
    inval = bin(inchar * 2 + 512)[2:]
    for j in reversed(range(len(inval))):
        for k in range(CLKS_PER_BIT):
            await FallingEdge(dut.clk)
        dut.rx_phy <= int(inval[j])


async def heartbeat(dut):
    """Print variable on a timer to debug."""
    cocotb.log.info("heartbeat started")
    while 1:
        await Timer(10, units="us")
        cocotb.log.info("tx busy: %d, rx_busy: %d" % (dut.tx_busy, dut.rx_busy))


@cocotb.test()
async def test_top_simple(dut):
    """Test UART loopback."""
    NUM_TESTS = 1

    # cocotb.fork(heartbeat(dut))
    clock = Clock(dut.clk, 10, units="us")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    await FallingEdge(dut.clk)  # Synchronize with the clock
    dut.rst <= 1
    dut.rx_phy <= 1
    await FallingEdge(dut.clk)
    dut.rst <= 0

    for i in range(NUM_TESTS):
        inval = random.randint(0, 255)
        cocotb.log.info("random value: %s" % bin(inval + 256)[3:])

        cocotb.fork(tx_char(dut, inval))

        outval = await rx_char(dut)

        cocotb.log.info("Expected %s and got %s on iteration %d" % (bin(inval + 256)[3:], bin(outval + 256)[3:], i))
        assert inval == outval, "output was incorrect on the {}th cycle".format(i)
