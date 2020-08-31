export COCOTB_REDUCED_LOG_FMT = 1

TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES = uart_tx.sv uart_rx.sv uart_top.sv

ifdef WAVE
  EXTRA_ARGS += --trace --trace-threads 1
endif

MODULE = test_top
TOPLEVEL = uart_top

include $(shell cocotb-config --makefiles)/Makefile.sim
