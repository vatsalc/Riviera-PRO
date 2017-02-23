// Copyright (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2007-10-30 17:40:56 +0100 (Tue, 30 Oct 2007) $
// $Revision: 68819 $

module Counter #(
            parameter N=4,         // counter length
            parameter EN_Q0=0,    // enable condition, 0 - EN, 1 - EN & (q>0)
            parameter DIR=1         // counting direction
        )
        (
            input Clk,
            input Rst,
            input Load,
            input Enable,
            input [N:0] DataIn,
            output [N:0] QOut
        );

reg [N:0] q;


// ---- Implementation ---------------------------------------------------------------------

always @(negedge Clk , posedge Rst , posedge Load)
begin : Counter_body
    if (Rst)
        q = 0;
    else if (Load)
        q = DataIn;
    else if ( Enable && (!EN_Q0 || (EN_Q0 && (q>0))))
    begin : Counting_block
        if (DIR)
            q++;
        else
            q--;
    end : Counting_block
end : Counter_body

assign QOut = q;

endmodule
