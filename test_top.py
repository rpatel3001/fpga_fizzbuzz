import random
import logging
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

async def heartbeat(dut):
    cocotb.log.info("heartbeat started")
    while 1:
        await Timer(10, units="us")
        cocotb.log.info("tx busy: %d, rx_valid: %d, rx_busy: %d"%(dut.tx_busy, dut.rx_valid, dut.rx_busy))

@cocotb.test()
async def test_top_simple(dut):
    """ Test UART loopback. """
    NUM_TESTS = 1
    CLKS_PER_BIT = 2

    #cocotb.fork(heartbeat(dut))
    clock = Clock(dut.clk, 10, units="us")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    await FallingEdge(dut.clk)  # Synchronize with the clock
    dut.rst <= 1
    await FallingEdge(dut.clk)
    dut.rst <= 0

    for i in range(NUM_TESTS):
        inval = random.randint(0, 255)
        cocotb.log.info("random value: %s"%bin(inval+256)[3:])
        dut.tx_data <= inval  # Assign the random value val to the input port d
        dut.tx_valid <= 1
        await FallingEdge(dut.clk)
        dut.tx_data <= 0
        dut.tx_valid <= 0

        while 1:
            rxvalid = dut.rx_valid.value.integer
            if rxvalid:
                outval = dut.rx_data.value.integer
                break
            await FallingEdge(dut.clk)

        cocotb.log.info("Expected %s and got %s on iteration %d"%(bin(inval+256)[3:], bin(outval+256)[3:], i))
        assert inval == outval, "output was incorrect on the {}th cycle".format(i)
