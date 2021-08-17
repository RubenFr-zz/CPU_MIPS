onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mips_tb/U_0/rst_in
add wave -noupdate /mips_tb/U_0/clk_24MHz
add wave -noupdate /mips_tb/U_0/Instruction
add wave -noupdate /mips_tb/U_0/PC
add wave -noupdate /mips_tb/U_0/Branch
add wave -noupdate /mips_tb/U_0/Jump
add wave -noupdate /mips_tb/U_0/LEDG
add wave -noupdate /mips_tb/U_0/LEDR
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 369
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {13125 ns}
