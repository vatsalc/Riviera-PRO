# clear project library contents
adel -all

# compile project's source files
alog -sv2k5 ffd.v counter.v traffic_control.v tb.v  \
  -psl traffic_control_ver_vunit.psl

# initialize simulation
asim +access +r {$root}

# add signals to Waveform Viewer
wave /tb/UUT/*

# advance simulation
run -all

# uncomment following line to terminate simulation automatically from script
#endsim
