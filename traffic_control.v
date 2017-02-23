// Copyright (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2007-10-30 18:17:38 +0100 (Tue, 30 Oct 2007) $
// $Revision: 68821 $

//`timescale 1 ns  / 1 ps

`include "parameters.h"

module TrafficControl #(
                parameter NORMAL         = 6'b000001,
                parameter YELLOW         = 6'b000010,
                parameter RED1             = 6'b000100,
                parameter RED2             = 6'b001000,
                parameter YELLOW_RED         = 6'b010000,
                parameter FAILURE         = 6'b100000,

                parameter N = 3,    // counter's length (Count1)
                parameter M = 8        // counter's length (Count2)
            )
            (
                input Clk,
                input Rst,
                input Key,         // Key=1 a pedestrian pushed one of the keys
                input Car,         // Car=1 a car is on the road B
                input RadioSensor,    // RadioSensor=1 an ambulance is on the road B
                input FailureDetect,    // FailureDetect = 1 any lights element failure
                output GreenA,
                output YellowA,
                output RedA,
                output FlashingYellowA,
                output GreenB,
                output YellowB,
                output RedB,
                output FlashingYellowB,
                output RedCrossing,
                output GreenCrossing,
                output FlashingGreenCrossing
            );
// ---- Specification --------------------------------------------------------------

//psl  default clock = fell(Clk);

// if the radio sensor detects an appearing of the ambulance (posedge R)
// the lights change into green (GreenB) at that time
//psl    property as_e_p = never {{rose(RadioSensor)} & {GreenA} ; GreenB};
//psl    as_e : assert as_e_p;
// if the radio sensor detects an appearing of the ambulance (RadioSensor)
// the lights for the road A have always to change
// from green into red within min 4, max. 7 clk cycles
//psl    property as_f_p = always { rose(RadioSensor) } |-> {[*4:7];GreenB};
//psl    as_f : assert as_f_p;
// the green lights sequence for the road B (posedge GreenB) must start not earlier
// than T1 clk cycles after the beginning of the green light
// for the road A if there is no ambulance detected (~RadioSensor),
// if the ambulance is detected the rule shall not be checked
//psl    property as_h_p = always {rose(GreenA)}|->{[*0:5];!GreenB} sync_abort (RadioSensor);
//psl    as_h : assert as_h_p;

// ---- Implementation -------------------------------------------------------------

// FSM
reg [5:0] NextState, CurrentState;

//inputs into registers
wire rK;
wire rC;
wire rR;

wire Set;
wire RSet;

// Counter Count1 signals
reg Load;
reg Enable;
reg [N:0] DataIn;
wire [N:0] Count1_QOut;

// Counter Count2 signals
wire [M:0] Count2_QOut;
reg Load_T1;
wire Zero;

// output logic
assign GreenA = (CurrentState == NORMAL);
assign YellowA = (CurrentState == YELLOW | CurrentState == YELLOW_RED);
assign RedA = (CurrentState == RED1 | CurrentState == RED2 | CurrentState == YELLOW_RED);
assign FlashingYellowA = (CurrentState == FAILURE);

assign GreenB = (CurrentState == RED1 |CurrentState == RED2 | CurrentState == YELLOW_RED);
assign YellowB = (CurrentState == YELLOW | CurrentState == YELLOW_RED);
assign RedB = (CurrentState == NORMAL | CurrentState == YELLOW);
assign FlashingYellowB = (CurrentState == FAILURE);

assign RedCrossing = (CurrentState == NORMAL | CurrentState == YELLOW | CurrentState == YELLOW_RED);
assign GreenCrossing = (CurrentState == RED1);
assign FlashingGreenCrossing = (CurrentState == RED2);

`ifdef _VERBOSE
always @(GreenA , YellowA , RedA , FlashingYellowA)
begin
    if (GreenA)
        $info("Green for road A             ", $time, " ns");
    if (YellowA & !RedA)
        $info("Change to red for road A      ", $time, " ns");
    if (!YellowA & RedA)
        $info("Red for road A                ", $time, " ns");
    if (YellowA & RedA)
        $info("Change to green for road A    ", $time, " ns");
    if (FlashingYellowA)
        $info("Flashing yellow for road A    ", $time, " ns");
end

always @(GreenB , YellowB , RedB , FlashingYellowB)
begin
    if (GreenB)
        $info("Green for road B             ", $time, " ns");
    if (YellowB & !RedB)
        $info("Change to red for road B      ", $time, " ns");
    if (!YellowB & RedB)
        $info("Red for road B                ", $time, " ns");
    if (YellowB & RedB)
        $info("Change to green for road B    ", $time, " ns");
    if (FlashingYellowB)
        $info("Flashing yellow for road B    ", $time, " ns");
end


always @(RedCrossing , GreenCrossing , FlashingGreenCrossing)
begin
    if (RedCrossing)
        $info("Red for pedestrians           ", $time, " ns");
    if (GreenCrossing)
        $info("Green for pedestrians         ", $time, " ns");
    if (FlashingGreenCrossing)
        $info("Flashing green for pedestrians", $time, " ns");
end
`endif // _VERBOSE


FFD FFD_K(.Clk(Clk), .Rst(1'b0), .Set(Key), .DIn(1'b0), .QOut(rK));
FFD FFD_C(.Clk, .Rst(1'b0), .Set(Car), .DIn(1'b0), .QOut(rC));
FFD FFD_R(.Clk, .Rst(1'b0), .Set(RadioSensor), .DIn(1'b0), .QOut(rR));


//FSM
// state change on the clock

always @(negedge Clk or posedge Rst)
if (Rst)
    CurrentState = NORMAL;
else
    CurrentState = NextState;

// state control and some temporal signals logic
always @(CurrentState or Rst or FailureDetect or rC or rK or rR or Zero or Count2_QOut)
if (Rst)
begin
    NextState = NORMAL;
    Load = 0;
    DataIn = 0;
    Load_T1 = 0;
end
else
begin
    case (NextState)
    NORMAL :
        begin : Green_for_RoadA
            if (FailureDetect)
                NextState = FAILURE;
            else if (rR)
                begin : Immediate_Transition_to_Yellow
                `ifdef _NO_BUG
                    NextState = YELLOW;
                `else
                    NextState = RED1; // causes assertion violation
                `endif
                    Load = 1'b1;
                    DataIn = `N1;
                    #10;
                    Load = 1'b0;
                end : Immediate_Transition_to_Yellow
            else if ((rK | rC) & (Count2_QOut > `T1) )
                begin : Conditional_Transition_to_Yellow
                `ifdef _NO_BUG
                    NextState = YELLOW;
                `else
                    NextState = RED1; // causes assertion violation
                `endif
                    Load = 1'b1;
                    DataIn = `N1;
                    #10;
                    Load = 1'b0;
                end : Conditional_Transition_to_Yellow
            else
                NextState = NORMAL;
        end    : Green_for_RoadA

    YELLOW :
        begin : Yellow_for_RoadA
            if (FailureDetect)
                NextState = FAILURE;
            else if (Zero)
                begin : Transition_into_RedA
                    NextState = RED1;
                    Load = 1'b1;
                    DataIn = `M1;
                    #10;
                    Load = 1'b0;
                end : Transition_into_RedA
            else
                NextState = YELLOW;
        end    : Yellow_for_RoadA

    RED1 :
        begin : Red_for_RoadA
            if (FailureDetect)
                NextState = FAILURE;
            else if (Zero)
                begin : Transition_into_RedA_FlashingGreenCrossing
                    NextState = RED2;
                    Load = 1'b1;
                    DataIn = `M2;
                    #10;
                    Load = 1'b0;
                end    :  Transition_into_RedA_FlashingGreenCrossing
            else
                NextState = RED1;
        end    : Red_for_RoadA

    RED2 :
        begin : Red_for_RoadA_FlashingGreen_for_Crossing
            if (FailureDetect)
                NextState = FAILURE;
            else if (Zero)
                begin : Transition_into_Red_Yellow_A
                    NextState = YELLOW_RED;
                    Load = 1'b1;
                    DataIn = `N3;
                    #10;
                    Load = 1'b0;
                end    : Transition_into_Red_Yellow_A
            else
                NextState = RED2;
        end    : Red_for_RoadA_FlashingGreen_for_Crossing


    YELLOW_RED :
        begin : Yellow_and_Red_for_Road_A
            if (FailureDetect)
                NextState = FAILURE;
            else if (Zero)
                begin : Transition_into_NormalState
                    NextState = NORMAL;
                       Load_T1 = 1'b1;
                    #10;
                    Load_T1 = 0;
                end      : Transition_into_NormalState
            else
                NextState = YELLOW_RED;
        end    : Yellow_and_Red_for_Road_A

    FAILURE :
        begin : Failere_Detected
            if (FailureDetect)
            `ifdef _NO_BUG
                  NextState = FAILURE;
            `else
                  NextState = YELLOW; // causes assertion violation
            `endif
            else
                NextState = NORMAL;
        end    : Failere_Detected
    endcase
end


// counter which counts lights periods


assign Set = (CurrentState == YELLOW) | (CurrentState == RED1)|(CurrentState == RED2)| (CurrentState == YELLOW_RED);
assign RSet = (CurrentState == YELLOW) | (CurrentState == RED1)|(CurrentState == RED2)| (CurrentState == YELLOW_RED);

always @(negedge Clk , posedge Rst , posedge Set , negedge RSet)
if (Rst | !RSet)
    Enable = 0;
else if (Set)
    Enable = 1'b1;

Counter #(.N(N), .EN_Q0(1'b1), .DIR(1'b0)) Count1 (
                                                    .*,
                                                    .QOut(Count1_QOut)
                                                );
assign Zero = (Count1_QOut==0);


// counter which counts the period t1 for green light of the road A

Counter #(.N(M), .EN_Q0(0), .DIR(1'b1))  Count2 (
                                                .Clk,
                                                .Rst(Load_T1),
                                                .Load(Rst),
                                                .DataIn(`T1),
                                                .Enable(CurrentState == NORMAL),
                                                .QOut(Count2_QOut)
                                                );

endmodule
