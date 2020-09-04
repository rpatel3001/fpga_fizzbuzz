export COCOTB_REDUCED_LOG_FMT = 1

TOPLEVEL_LANG ?= verilog
SIM ?= verilator
TEST ?= TOP

EXTRA_ARGS += -Wno-WIDTH --timescale 1us/1us

ifdef WAVE
  EXTRA_ARGS += --trace --trace-threads 1
endif

ifeq ($(TEST), TOP)
  VERILOG_SOURCES = uart_tx.sv uart_rx.sv uart_top.sv
  MODULE = test_top
  TOPLEVEL = uart_top
endif

ifeq ($(TEST), RX)
  VERILOG_SOURCES = uart_rx.sv
  MODULE = test_rx
  TOPLEVEL = uart_rx
endif

ifeq ($(TEST), TX)
  VERILOG_SOURCES = uart_tx.sv
  MODULE = test_tx
  TOPLEVEL = uart_tx
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
