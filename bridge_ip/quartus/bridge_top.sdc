# bridge_top.sdc
# Minimal constraints — register-to-register timing only
# Target: Cyclone V 5CSEMA5F31C6 at 100 MHz

# Clock definition
create_clock -name HCLK -period 10.000 [get_ports HCLK]

# Clock uncertainty
derive_clock_uncertainty

# Cut async reset from timing analysis
set_false_path -from [get_ports HRESETn]

# Cut all I/O paths — we only care about internal register-to-register timing
set_false_path -from [get_ports *] -to [get_registers *]
set_false_path -from [get_registers *] -to [get_ports *]