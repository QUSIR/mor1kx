
`include "mor1kx-defines.v"

module mor1kx_cpu(/*AUTOARG*/
   // Outputs
   ibus_adr_o, ibus_req_o, dbus_adr_o, dbus_dat_o, dbus_req_o,
   dbus_bsel_o, dbus_we_o, du_dat_o, du_ack_o, du_stall_o,
   spr_bus_addr_o, spr_bus_we_o, spr_bus_stb_o, spr_bus_dat_o,
   spr_sr_o,
   // Inputs
   clk, rst, ibus_err_i, ibus_ack_i, ibus_dat_i, dbus_err_i,
   dbus_ack_i, dbus_dat_i, irq_i, du_addr_i, du_stb_i, du_dat_i,
   du_we_i, du_stall_i, spr_bus_dat_dc_i, spr_bus_ack_dc_i,
   spr_bus_dat_dmmu_i, spr_bus_ack_dmmu_i, spr_bus_dat_immu_i,
   spr_bus_ack_immu_i, spr_bus_dat_mac_i, spr_bus_ack_mac_i,
   spr_bus_dat_pmu_i, spr_bus_ack_pmu_i, spr_bus_dat_pcu_i,
   spr_bus_ack_pcu_i, spr_bus_dat_fpu_i, spr_bus_ack_fpu_i
   );

   
   input clk, rst;

   parameter OPTION_OPERAND_WIDTH = 32;

   parameter OPTION_CPU = "FOURSTAGE";
   
   parameter FEATURE_DATACACHE = "NONE";
   parameter OPTION_DCACHE_BLOCK_WIDTH = 5;
   parameter OPTION_DCACHE_SET_WIDTH = 9;
   parameter OPTION_DCACHE_WAYS = 2;
   parameter FEATURE_DMMU = "NONE";
   parameter FEATURE_INSTRUCTIONCACHE = "NONE";
   parameter OPTION_ICACHE_BLOCK_WIDTH = 5;
   parameter OPTION_ICACHE_SET_WIDTH = 9;
   parameter OPTION_ICACHE_WAYS = 2;
   parameter OPTION_ICACHE_LIMIT_WIDTH = 32;
   parameter FEATURE_IMMU = "NONE";
   parameter FEATURE_PIC = "ENABLED";
   parameter FEATURE_TIMER = "ENABLED";
   parameter FEATURE_DEBUGUNIT = "NONE";
   parameter FEATURE_PERFCOUNTERS = "NONE";
   parameter FEATURE_MAC = "NONE";

   parameter FEATURE_SYSCALL = "ENABLED";
   parameter FEATURE_TRAP = "ENABLED";
   parameter FEATURE_RANGE = "ENABLED";

   parameter OPTION_PIC_TRIGGER = "EDGE";

   parameter OPTION_RF_ADDR_WIDTH = 5;
   parameter OPTION_RF_WORDS = 32;

   parameter OPTION_RESET_PC = {{(OPTION_OPERAND_WIDTH-13){1'b0}},
				`OR1K_RESET_VECTOR,8'd0};

   parameter FEATURE_MULTIPLIER = "THREESTAGE";
   parameter FEATURE_DIVIDER = "NONE";

   parameter FEATURE_ADDC = "NONE";
   parameter FEATURE_SRA = "ENABLED";
   parameter FEATURE_ROR = "NONE";
   parameter FEATURE_EXT = "NONE";
   parameter FEATURE_CMOV = "NONE";
   parameter FEATURE_FFL1 = "NONE";
   
   parameter FEATURE_CUST1 = "NONE";
   parameter FEATURE_CUST2 = "NONE";
   parameter FEATURE_CUST3 = "NONE";
   parameter FEATURE_CUST4 = "NONE";
   parameter FEATURE_CUST5 = "NONE";
   parameter FEATURE_CUST6 = "NONE";
   parameter FEATURE_CUST7 = "NONE";
   parameter FEATURE_CUST8 = "NONE";
   
   parameter OPTION_SHIFTER = "ENABLED";
   
   // Instruction bus
   input ibus_err_i;
   input ibus_ack_i;
   input [`OR1K_INSN_WIDTH-1:0] ibus_dat_i;
   output [OPTION_OPERAND_WIDTH-1:0] ibus_adr_o;
   output 			     ibus_req_o;

   // Data bus
   input 			     dbus_err_i;
   input 			     dbus_ack_i;
   input [OPTION_OPERAND_WIDTH-1:0]  dbus_dat_i;
   output [OPTION_OPERAND_WIDTH-1:0] dbus_adr_o;
   output [OPTION_OPERAND_WIDTH-1:0] dbus_dat_o;
   output 			     dbus_req_o;
   output [3:0] 		     dbus_bsel_o;
   output 			     dbus_we_o;
   
   // Interrupts
   input [31:0] 		     irq_i;
   
   // Debug interface
   input [15:0] 		     du_addr_i;
   input 			     du_stb_i;
   input [OPTION_OPERAND_WIDTH-1:0]  du_dat_i;
   input 			     du_we_i;
   output [OPTION_OPERAND_WIDTH-1:0] du_dat_o;
   output 			     du_ack_o;
   // Stall control from debug interface
   input 			     du_stall_i;
   output 			     du_stall_o;

   // SPR accesses to external units (cache, mmu, etc.)
   output [15:0] 		     spr_bus_addr_o;
   output 			     spr_bus_we_o;
   output 			     spr_bus_stb_o;
   output [OPTION_OPERAND_WIDTH-1:0] spr_bus_dat_o;
   input [OPTION_OPERAND_WIDTH-1:0]  spr_bus_dat_dc_i;
   input 			     spr_bus_ack_dc_i;   
//SJK   input [OPTION_OPERAND_WIDTH-1:0]  spr_bus_dat_ic_i;
//SJK   input 			     spr_bus_ack_ic_i;   
   input [OPTION_OPERAND_WIDTH-1:0]  spr_bus_dat_dmmu_i;
   input 			     spr_bus_ack_dmmu_i;   
   input [OPTION_OPERAND_WIDTH-1:0]  spr_bus_dat_immu_i;
   input 			     spr_bus_ack_immu_i;   
   input [OPTION_OPERAND_WIDTH-1:0]  spr_bus_dat_mac_i;
   input 			     spr_bus_ack_mac_i;   
   input [OPTION_OPERAND_WIDTH-1:0]  spr_bus_dat_pmu_i;
   input 			     spr_bus_ack_pmu_i;   
   input [OPTION_OPERAND_WIDTH-1:0]  spr_bus_dat_pcu_i;
   input 			     spr_bus_ack_pcu_i;   
   input [OPTION_OPERAND_WIDTH-1:0]  spr_bus_dat_fpu_i;
   input 			     spr_bus_ack_fpu_i;   
   output [15:0] 		     spr_sr_o;

   generate
      if (OPTION_CPU=="FOURSTAGE") begin : cpu_gen
	 mor1kx_cpu_fourstage
	   #(
	     .OPTION_OPERAND_WIDTH(OPTION_OPERAND_WIDTH),
	     .FEATURE_DATACACHE(FEATURE_DATACACHE),
	     .OPTION_DCACHE_BLOCK_WIDTH(OPTION_DCACHE_BLOCK_WIDTH),
	     .OPTION_DCACHE_SET_WIDTH(OPTION_DCACHE_SET_WIDTH),
	     .OPTION_DCACHE_WAYS(OPTION_DCACHE_WAYS),
	     .FEATURE_DMMU(FEATURE_DMMU),
	     .FEATURE_INSTRUCTIONCACHE(FEATURE_INSTRUCTIONCACHE),
	     .OPTION_ICACHE_BLOCK_WIDTH(OPTION_ICACHE_BLOCK_WIDTH),
	     .OPTION_ICACHE_SET_WIDTH(OPTION_ICACHE_SET_WIDTH),
	     .OPTION_ICACHE_WAYS(OPTION_ICACHE_WAYS),
	     .OPTION_ICACHE_LIMIT_WIDTH(OPTION_ICACHE_LIMIT_WIDTH),
	     .FEATURE_IMMU(FEATURE_IMMU),
	     .FEATURE_PIC(FEATURE_PIC),
	     .FEATURE_TIMER(FEATURE_TIMER),
	     .FEATURE_DEBUGUNIT(FEATURE_DEBUGUNIT),
	     .FEATURE_PERFCOUNTERS(FEATURE_PERFCOUNTERS),
	     .FEATURE_MAC(FEATURE_MAC),
	     .FEATURE_SYSCALL(FEATURE_SYSCALL),
	     .FEATURE_TRAP(FEATURE_TRAP),
	     .FEATURE_RANGE(FEATURE_RANGE),
	     .OPTION_PIC_TRIGGER(OPTION_PIC_TRIGGER),
	     .OPTION_RF_ADDR_WIDTH(OPTION_RF_ADDR_WIDTH),
	     .OPTION_RF_WORDS(OPTION_RF_WORDS),
	     .OPTION_RESET_PC(OPTION_RESET_PC),
	     .FEATURE_MULTIPLIER(FEATURE_MULTIPLIER),
	     .FEATURE_DIVIDER(FEATURE_DIVIDER),
	     .FEATURE_ADDC(FEATURE_ADDC),
	     .FEATURE_SRA(FEATURE_SRA),
	     .FEATURE_ROR(FEATURE_ROR),
	     .FEATURE_EXT(FEATURE_EXT),
	     .FEATURE_CMOV(FEATURE_CMOV),
	     .FEATURE_FFL1(FEATURE_FFL1),
	     .FEATURE_CUST1(FEATURE_CUST1),
	     .FEATURE_CUST2(FEATURE_CUST2),
	     .FEATURE_CUST3(FEATURE_CUST3),
	     .FEATURE_CUST4(FEATURE_CUST4),
	     .FEATURE_CUST5(FEATURE_CUST5),
	     .FEATURE_CUST6(FEATURE_CUST6),
	     .FEATURE_CUST7(FEATURE_CUST7),
	     .FEATURE_CUST8(FEATURE_CUST8),
	     .OPTION_SHIFTER(OPTION_SHIFTER)
	     )
	   mor1kx_cpu
	   (/*AUTOINST*/
	    // Outputs
	    .ibus_adr_o			(ibus_adr_o[OPTION_OPERAND_WIDTH-1:0]),
	    .ibus_req_o			(ibus_req_o),
	    .dbus_adr_o			(dbus_adr_o[OPTION_OPERAND_WIDTH-1:0]),
	    .dbus_dat_o			(dbus_dat_o[OPTION_OPERAND_WIDTH-1:0]),
	    .dbus_req_o			(dbus_req_o),
	    .dbus_bsel_o		(dbus_bsel_o[3:0]),
	    .dbus_we_o			(dbus_we_o),
	    .du_dat_o			(du_dat_o[OPTION_OPERAND_WIDTH-1:0]),
	    .du_ack_o			(du_ack_o),
	    .du_stall_o			(du_stall_o),
	    .spr_bus_addr_o		(spr_bus_addr_o[15:0]),
	    .spr_bus_we_o		(spr_bus_we_o),
	    .spr_bus_stb_o		(spr_bus_stb_o),
	    .spr_bus_dat_o		(spr_bus_dat_o[OPTION_OPERAND_WIDTH-1:0]),
	    .spr_sr_o			(spr_sr_o[15:0]),
	    // Inputs
	    .clk			(clk),
	    .rst			(rst),
	    .ibus_err_i			(ibus_err_i),
	    .ibus_ack_i			(ibus_ack_i),
	    .ibus_dat_i			(ibus_dat_i[`OR1K_INSN_WIDTH-1:0]),
	    .dbus_err_i			(dbus_err_i),
	    .dbus_ack_i			(dbus_ack_i),
	    .dbus_dat_i			(dbus_dat_i[OPTION_OPERAND_WIDTH-1:0]),
	    .irq_i			(irq_i[31:0]),
	    .du_addr_i			(du_addr_i[15:0]),
	    .du_stb_i			(du_stb_i),
	    .du_dat_i			(du_dat_i[OPTION_OPERAND_WIDTH-1:0]),
	    .du_we_i			(du_we_i),
	    .du_stall_i			(du_stall_i),
	    .spr_bus_dat_dc_i		(spr_bus_dat_dc_i[OPTION_OPERAND_WIDTH-1:0]),
	    .spr_bus_ack_dc_i		(spr_bus_ack_dc_i),
	    .spr_bus_dat_dmmu_i		(spr_bus_dat_dmmu_i[OPTION_OPERAND_WIDTH-1:0]),
	    .spr_bus_ack_dmmu_i		(spr_bus_ack_dmmu_i),
	    .spr_bus_dat_immu_i		(spr_bus_dat_immu_i[OPTION_OPERAND_WIDTH-1:0]),
	    .spr_bus_ack_immu_i		(spr_bus_ack_immu_i),
	    .spr_bus_dat_mac_i		(spr_bus_dat_mac_i[OPTION_OPERAND_WIDTH-1:0]),
	    .spr_bus_ack_mac_i		(spr_bus_ack_mac_i),
	    .spr_bus_dat_pmu_i		(spr_bus_dat_pmu_i[OPTION_OPERAND_WIDTH-1:0]),
	    .spr_bus_ack_pmu_i		(spr_bus_ack_pmu_i),
	    .spr_bus_dat_pcu_i		(spr_bus_dat_pcu_i[OPTION_OPERAND_WIDTH-1:0]),
	    .spr_bus_ack_pcu_i		(spr_bus_ack_pcu_i),
	    .spr_bus_dat_fpu_i		(spr_bus_dat_fpu_i[OPTION_OPERAND_WIDTH-1:0]),
	    .spr_bus_ack_fpu_i		(spr_bus_ack_fpu_i));

	 // synthesis translate_off
`ifndef verilator
`endif
	 wire [`OR1K_INSN_WIDTH-1:0] monitor_decode_insn/* verilator public */;
	 wire 			     monitor_decode_advance/* verilator public */;
	 wire 			     monitor_execute_advance/* verilator public */;
	 wire 			     monitor_flag_set/* verilator public */;
	 wire 			     monitor_flag_clear/* verilator public */;
	 wire 			     monitor_flag_sr/* verilator public */;
	 wire 			     monitor_flag/* verilator public */;
	 wire [OPTION_OPERAND_WIDTH-1:0] monitor_spr_sr/* verilator public */;
	 wire [OPTION_OPERAND_WIDTH-1:0] monitor_execute_pc/* verilator public */;
	 wire [OPTION_OPERAND_WIDTH-1:0] monitor_rf_result_in/* verilator public */;
	 wire 				 monitor_clk/* verilator public */;
	 wire [OPTION_OPERAND_WIDTH-1:0] monitor_spr_epcr/* verilator public */;
	 wire [OPTION_OPERAND_WIDTH-1:0] monitor_spr_eear/* verilator public */;
	 wire [OPTION_OPERAND_WIDTH-1:0] monitor_spr_esr/* verilator public */;
	 

	 assign monitor_flag =  monitor_flag_set ? 1 :
			        monitor_flag_clear ? 0 : 
				monitor_flag_sr;
	 assign monitor_clk = clk;

	 assign monitor_decode_insn = cpu_gen.mor1kx_cpu.mor1kx_decode.decode_insn_i;
	 assign monitor_decode_advance = cpu_gen.mor1kx_cpu.padv_decode_o;
	 assign monitor_execute_advance = cpu_gen.mor1kx_cpu.padv_execute_o;
 	 assign monitor_flag_set = cpu_gen.mor1kx_cpu.mor1kx_execute_ctrl_fourstage.flag_set_i;
	 assign monitor_flag_clear = cpu_gen.mor1kx_cpu.mor1kx_execute_ctrl_fourstage.flag_clear_i;
	 assign monitor_flag_sr = cpu_gen.mor1kx_cpu.mor1kx_ctrl_fourstage.ctrl_flag_o;
	 assign monitor_spr_sr = {16'd0,cpu_gen.mor1kx_cpu.mor1kx_ctrl_fourstage.spr_sr[15:`OR1K_SPR_SR_F+1],cpu_gen.mor1kx_cpu.mor1kx_ctrl_fourstage.ctrl_flag_o,cpu_gen.mor1kx_cpu.mor1kx_ctrl_fourstage.spr_sr[`OR1K_SPR_SR_F-1:0]};
	 assign monitor_execute_pc = cpu_gen.mor1kx_cpu.pc_decode_to_execute;
	 assign monitor_rf_result_in = cpu_gen.mor1kx_cpu.mor1kx_rf_fourstage.result_i;
	 assign monitor_spr_esr = {16'd0,cpu_gen.mor1kx_cpu.mor1kx_ctrl_fourstage.spr_esr};
	 assign monitor_spr_epcr = cpu_gen.mor1kx_cpu.mor1kx_ctrl_fourstage.spr_epcr;
	 assign monitor_spr_eear = cpu_gen.mor1kx_cpu.mor1kx_ctrl_fourstage.spr_eear;

	 // synthesis translate_on

	 
      end // if (OPTION_CPU=="FOURSTAGE")
      else
	begin
	   initial begin
	      $display("Error: OPTION_CPU, %s, not valid", OPTION_CPU);
	      $finish();
	   end
	end
   endgenerate

endmodule // mor1kx_cpu
