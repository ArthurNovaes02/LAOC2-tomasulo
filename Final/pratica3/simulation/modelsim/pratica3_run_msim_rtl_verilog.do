transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/Positivo/Desktop/faculdade/LAOC2/QUARTUS/pratica3 {C:/Users/Positivo/Desktop/faculdade/LAOC2/QUARTUS/pratica3/pratica3.v}

