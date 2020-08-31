export COCOTB_REDUCED_LOG_FMT = 1

TOPLEVEL_LANG ?= verilog
SIM ?= verilator
TEST ?= TOP

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
