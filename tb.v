// Copyright (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2007-10-30 18:17:38 +0100 (Tue, 30 Oct 2007) $
// $Revision: 68821 $

module tb;

//Internal signals declarations:
reg Clk;
reg Rst;
reg Key;
reg Car;
reg RadioSensor;
reg FailureDetect;
wire GreenA;
wire YellowA;
wire RedA;
wire FlashingYellowA;
wire GreenB;
wire YellowB;
wire RedB;
wire FlashingYellowB;
wire RedCrossing;
wire GreenCrossing;
wire FlashingGreenCrossing;


// Unit Under Test port map
    TrafficControl UUT (.* );

integer my_file;
initial my_file = $fopen("lights.txt");
initial    $fmonitor(my_file, $realtime, , "ps %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h ", Clk, Rst, Key, Car, RadioSensor, FailureDetect, GreenA, YellowA, RedA, FlashingYellowA, GreenB, YellowB, RedB, FlashingYellowB, RedCrossing, GreenCrossing, FlashingGreenCrossing);

`ifdef _VERBOSE
`define DISPLAY(msg, _time, unit)           $info(msg, _time, unit);
`else
`define DISPLAY(msg, _time, unit)
`endif

// CLOCK
initial Clk = 0;
always begin: Clock_Stimulus
    Clk = #50000    ~Clk;
end


initial
begin : STIMUL // beginning of stimulus process
    #0;
    Rst = 1'b1;
    Key = 1'b0;
    Car = 1'b0;
    RadioSensor = 1'b0;
    FailureDetect = 1'b0;
    #70000;
    Rst = 1'b0;
    #290000;
    Car = 1'b1;
    `DISPLAY("Car appeared on road B        ", $time, " ns")
        #480000;
    Car = 1'b0;
    `DISPLAY("No car on road B              ", $time, " ns")
    #570000;
    Car = 1'b1;
    `DISPLAY("Car appeared on road B        ", $time, " ns")
        #1680000;
    Car = 1'b0;
    `DISPLAY("No car on road B              ", $time, " ns")
    #990000;
    RadioSensor = 1'b1;
    `DISPLAY("Ambulance on road B            ", $time, " ns")
        #450000;
    RadioSensor = 1'b0;
        #480000;
    Key = 1'b1;
    `DISPLAY("Pedestrians pushed key        ", $time, " ns")
        #1710000;
    Key = 1'b0;
        #330000;
    Car = 1'b1;
    `DISPLAY("Car appeared on road B        ", $time, " ns")
        #150000;
    Car = 1'b0;
    `DISPLAY("No car on road B              ", $time, " ns")
        #330000;
    Car = 1'b1;
    `DISPLAY("Car appeared on road B        ", $time, " ns")
        #210000;
    RadioSensor = 1'b1;
    `DISPLAY("Ambulance on road B            ", $time, " ns")
        #390000;
`ifdef _NO_BUG
    Rst = 1'b0;
`else
    Rst = 1'b1;
`endif
    Car = 1'b0;
    `DISPLAY("No car on road B              ", $time, " ns")
        #30000;
    Rst = 1'b0;
        #1180000;
    RadioSensor = 1'b0;
        #1290000;
    FailureDetect = 1'b1;
    `DISPLAY("Lights failure occurred       ", $time, " ns")
        #660000;
    FailureDetect = 1'b0;
    `DISPLAY("Lights failure fixed          ", $time, " ns")
        #630000;
    Car = 1'b1;
    `DISPLAY("Car appeared on road B        ", $time, " ns")
        #930000;
    Car = 1'b0;
    `DISPLAY("No car on road B              ", $time, " ns")
        #150000;
    FailureDetect = 1'b1;
    `DISPLAY("Lights failure occurred       ", $time, " ns")
        #370000;
    FailureDetect = 1'b0;
    `DISPLAY("Lights failure fixed          ", $time, " ns")
        #470000;
    Car = 1'b1;
    `DISPLAY("Car appeared on road B        ", $time, " ns")
    #480000;
    Car = 1'b0;
    `DISPLAY("No car on road B              ", $time, " ns")
    #460000;
    RadioSensor = 1'b1;
    `DISPLAY("Ambulance on road B            ", $time, " ns")
    #2000000;
    $finish;
end // end of stimulus process


endmodule
