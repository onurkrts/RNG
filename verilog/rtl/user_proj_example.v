// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

	wire [31:0]x;
	wire [31:0]y;
	wire [31:0]z;


    // WB MI A
    assign wbs_dat_o = 31'h0;
    assign wbs_ack_o = 1'b0;

    // IO
    assign io_out = x;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign la_data_out = {{32{1'b0}}, z, y, x};
	
    // Assuming LA probes [97:96] are for controlling the count clk & reset  
    assign clk = (~la_oenb[96]) ? la_data_in[96]: wb_clk_i;
    assign rst = (~la_oenb[97]) ? la_data_in[97]: wb_rst_i;

    rng_chaos rng_chaos(
        .clk(clk),
        .rst(rst),
		.x(x),
		.y(y),
		.z(z)
    );

endmodule

/*------------------------------------------------------------------------\
| Piecewise Digital Chaos Generator                                       |
| Verilog HDL                                                             |
|                                                                         |
| M. Affan Zidan, A. G. Radwan and K. N. Salama                           |
| Sensors Lab - KAUST                                                     |
| mohammed.zidan@kaust.edu.sa                                             |
|                                                                         |
| Created: Sept 7, 2010                                                   |
| Last Modified: Mar 22, 2012                                             |
\------------------------------------------------------------------------*/

/*------------------------------------------------------------------------\
| Copyright (c) 2011, M. Affan Zidan, A. G. Radwan and K. N. Salama       |
| King Abdullah University of Science and Technology                      |
| All rights reserved.                                                    |
|                                                                         |
| Redistribution and use in source and binary forms, with or without      |
| modification, are permitted provided that the following conditions are  |
| met:                                                                    |
|     * Redistributions of source code must retain the above copyright    |
|       notice, this list of conditions and the following disclaimer.     |
|     * Redistributions in binary form must reproduce the above copyright |
|       notice, this list of conditions and the following disclaimer in   |
|       the documentation and/or other materials provided with the        |
|       distribution                                                      |
|     * Neither the name of the King Abdullah University of Science and   |
|       Technology (KAUST) nor the names of its contributors may be used  |
|       to endorse or promote products derived from this software without |
|       specific prior written permission.                                |
|                                                                         |
| THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS     |
| "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT           |
| NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   |
| FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE          |
| COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECtime,            |
| INDIRECtime, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES   |
| (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR      |
| SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      |
| HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACtime,  |
| STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)  ARISING  |
| IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE      |
| POSSIBILITY OF SUCH DAMAGE.                                             |
\------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------
---------------------------------------------------------------------------
Feel free to use/modify these codes as you see fit. Any publications 
(codes, papers, technical reports,..) in which our codes (in their original
or a modified format) have been used should  should cite the following 
references.

References:
------------

[1]	M. A. Zidan, A. G. Radwan, and K. N. Salama, â€œRandom Number Generation
	Based on Digital Differential Chaos, â€?IEEE International Midwest 
	Symposium on Circuits and Systems (MWSCAS), Seoul, South Korea, 2011
 	
[2]	M. A. Zidan, A. G. Radwan, and K. N. Salama, â€œThe Effect of Numerical 
	Techniques on Differential Equation Based Chaotic Generators,â€?IEEE 
	International Conference on Microelectronics (ICM), Tunisia, 2011

---------------------------------------------------------------------------

System Equations:
-----------------
x_dot = y
y_dot = z
z_dot = -z-y * B(y) - x

B(y) = a, if    y >= 1
       0, else

Constants:
----------
a = 4

Initial conditions:
-------------------
x(0) = 0
y(0) = 1
z(0) = 0 
---------------------------------------------------------------------------
-------------------------------------------------------------------------*/


///////////////////////////////////////////////////////////////////////////
// Main Module ////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

module rng_chaos (
input	 			clk, 
input 				rst, 
output reg [31:0]	x, 
output reg [31:0]	y, 
output reg [31:0]	z);

// Parameters
localparam WIDTH = 32;     // <-------------- Bus Width        
localparam INT_WIDTH = 10; // <-------------- Int Width
localparam STEP_SHIFT = 6; // <-- 1/h = 2 ^ -STEP_SHIFT


///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

// Please don't change bellow here

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

localparam FRAC_WIDTH = WIDTH - INT_WIDTH;
localparam INITIAL = { {INT_WIDTH-1{1'b0}}, 1'b1, {FRAC_WIDTH{1'b0}} };

// wires
wire [WIDTH-1:0] xn;
wire [WIDTH-1:0] yn;
wire [WIDTH-1:0] zn;

// intermediate
wire en;
wire [WIDTH-1:0] by;
wire [WIDTH-1:0] zd;

// -------- ///////////////////////////////////////////////////////////////

assign en = (~y[WIDTH-1])  &  (|y[WIDTH-2:FRAC_WIDTH]);

assign by = ({WIDTH{en}})  &  ({y[WIDTH-3:0],2'b0});

assign zd = z+x+by;

// 
assign xn = x + {{STEP_SHIFT{ y[WIDTH-1]}},  y[WIDTH-1:STEP_SHIFT]};
assign yn = y + {{STEP_SHIFT{ z[WIDTH-1]}},  z[WIDTH-1:STEP_SHIFT]};
assign zn = z - {{STEP_SHIFT{zd[WIDTH-1]}}, zd[WIDTH-1:STEP_SHIFT]};

///////////////////////////////////////////////////////////////////////////
// FSM ////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
always @(posedge clk) begin
	if(!rst) begin
		x <= 32'h0;
		y <= INITIAL;
		z <= 32'h0;
	end else begin
		x <= xn;
		y <= yn;
		z <= zn;
	end	
end

endmodule
`default_nettype wire
