"""Top level module test."""

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

    return chr(int("".join(outchar), 2))


async def tx_char(dut, inchar):
    """Transmit a character on 1 bit UART bus."""
    inval = bin(ord(inchar) * 2 + 512)[2:]
    for j in reversed(range(len(inval))):
        for k in range(CLKS_PER_BIT):
            await FallingEdge(dut.clk)
        dut.rx_phy <= int(inval[j])


async def uart_transact(dut, inchar, expchar):
    """Send then receive a character over UART."""
    cocotb.log.info("Sending %s" % (inchar))
    await tx_char(dut, inchar)
    outchar = await rx_char(dut)
    cocotb.log.info("Expected %s, received %s" % (expchar, outchar))
    assert expchar == outchar, "Expected %s, got %s" % (bin(ord(expchar)), bin(ord(outchar)))


async def heartbeat(dut):
    """Print variables on a timer to debug."""
    cocotb.log.info("heartbeat started")
    while 1:
        await Timer(10, units="us")
        cocotb.log.info("tx busy: %d, rx_busy: %d" % (dut.tx_busy, dut.rx_busy))


@cocotb.test()
async def test_top_simple(dut):
    """Test UART loopback."""
    NUM_TESTS = 1

    # cocotb.fork(heartbeat(dut))
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())
    dut.rx_phy <= 1
    await FallingEdge(dut.clk)

    for i in range(NUM_TESTS):
        dut.rst <= 1
        await FallingEdge(dut.clk)
        dut.rst <= 0
        await FallingEdge(dut.clk)
        await uart_transact(dut, "n", "0")
        await uart_transact(dut, "n", "1")
        await uart_transact(dut, "n", "2")
        await uart_transact(dut, "n", "3")
        await uart_transact(dut, "r", "0")
        await uart_transact(dut, "n", "1")
        await uart_transact(dut, "n", "2")
        await uart_transact(dut, "n", "3")
        await uart_transact(dut, "n", "4")
        await uart_transact(dut, "n", "5")
        await uart_transact(dut, "n", "6")
        await uart_transact(dut, "n", "7")
        await uart_transact(dut, "n", "8")
        await uart_transact(dut, "n", "0")
        await uart_transact(dut, "n", "1")
        await uart_transact(dut, "n", "2")
        await uart_transact(dut, "n", "3")
