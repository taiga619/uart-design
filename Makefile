IV = iverilog

sim : rtl/uart_tx.v tb/tb_uart_tx.v
	$(IV) -o sim.vvp rtl/uart_tx.v tb/tb_uart_tx.v
	vvp sim.vvp
clean :
	rm -rf sim.vvp sim.vcd
.PHONY : clean