// Copyright (c) Aldec, Inc.
// All rights reserved.
//
// Last modified: $Date: 2007-10-30 17:40:56 +0100 (Tue, 30 Oct 2007) $
// $Revision: 68819 $

module FFD     #(parameter N=1)
        (
            input Clk,
            input Rst,
            input Set,
            input [0:N-1] DIn,
            output [0:N-1] QOut
        );


// ---- Implementation ---------------------------------------------------------------------

reg [0:N-1] q;

always @(negedge Clk , posedge Rst , posedge Set)
begin : FlipFlopD_body
    if (Rst)
        q = 0;
    else if (Set)
    begin
        for(integer i = 0; i<=N-1; i++)
            q[i] = 1'b1;
        `ifdef _DEBUG
            if (N == 4)
                assert_strobe(q == 4'b1111);
        `endif
    end
    else
        q = DIn;
end : FlipFlopD_body

assign QOut = q;

endmodule
