"""Top level module test."""

import asyncio
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer, ClockCycles, First


CLKS_PER_BIT = 2
CLK_HZ = 100_000
CLK_NS = 1e9 / CLK_HZ


@cocotb.coroutine
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


async def uart_transact(dut, inchar, expstr):
    """Send then receive a character over UART."""
    cocotb.log.info("Sending %s" % (inchar))
    await tx_char(dut, inchar)

    outstr = ""
    for i in range(len(expstr)):
        rx_task = rx_char(dut)
        timeout_task = Timer(CLK_NS * CLKS_PER_BIT * 8 * 2, 'ns')
        fut = await First(rx_task, timeout_task)
        assert fut is not timeout_task, "rx_char() timed out"
        outstr += fut
    cocotb.log.info("Expected %s, received %s" % (expstr, outstr))
    assert expstr == outstr, "Expected %s, received %s" % (expstr, outstr)


async def heartbeat(dut):
    """Print variables on a timer to debug."""
    cocotb.log.info("heartbeat started")
    while 1:
        await Timer(CLK_NS, units="ns")
        cocotb.log.info("tx busy: %d, rx_busy: %d" % (dut.tx_busy, dut.rx_busy))


@cocotb.test()
async def test_top_simple(dut):
    """Test UART based BCD counter."""
    NUM_TESTS = 1

    # cocotb.fork(heartbeat(dut))
    clock = Clock(dut.clk, CLK_NS, units="ns")
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
        for j in range(1, 18):
            await uart_transact(dut, "n", str(j))
        for j in range(0, 18):
            await uart_transact(dut, "n", str(j))
        for j in range(0, 18):
            await uart_transact(dut, "n", str(j))
