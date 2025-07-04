`timescale 1ns / 1ps

`include "defs.sv"

module top(
    input clk,
    input rst
);

    wire pipeline_en; // enable the whole pipeline flowing, disabled when stall (e.g. cache miss)
    // signals in stages
    // 1. IF 
    // branch prediction and fetch instruction from icache
    wire    [31:0]      if_pc;
    wire                bpu_id_invlid;

    // 2. ID
    // decode and fetch data from regfile, and calculate immext
    reg     [31:0]      id_pc;
    wire    [31:0]      id_inst;
    wire                id_icache_valid;

    wire    [2:0]       id_pc_ctrl;
    wire    [2:0]       id_imm_type;
    wire    [3:0]       id_mem_ctrl;

    wire    [3:0]       id_alu_ctrl;
    wire    [1:0]       id_alu_a_sel;
    wire                id_alu_b_sel;
    wire                id_reg_w_en;
    wire    [1:0]       id_rd_sel;
    wire    [4:0]       id_rs1;
    wire    [4:0]       id_rs2;
    wire    [4:0]       id_rd;

    wire                id_csr_we;
    wire    [2:0]       id_func3;
    wire    [11:0]      id_csr_addr;
    wire                id_target_en;
    wire                id_target_jump;
    wire                bpu_id_invalid;

    wire    [31:0]      id_reg1;
    wire    [31:0]      id_reg2;
    wire    [31:0]      id_imm;
    wire    [31:0]      id_target;

    // 3. EX
    reg     [31:0]      ex_pc;
    reg     [31:0]      ex_inst;
    reg                 ex_icache_valid;

    reg     [2:0]       ex_pc_ctrl;
    reg     [2:0]       ex_imm_type;
    reg     [3:0]       ex_mem_ctrl;

    reg     [3:0]       ex_alu_ctrl;
    reg     [1:0]       ex_alu_a_sel;
    reg                 ex_alu_b_sel;
    reg                 ex_reg_w_en;
    reg     [1:0]       ex_rd_sel;
    reg     [4:0]       ex_rs1;
    reg     [4:0]       ex_rs2;
    reg     [4:0]       ex_rd;

    reg                 ex_csr_we;
    reg     [2:0]       ex_func3;
    reg     [11:0]      ex_csr_addr;
    reg                 ex_target_en;
    reg                 ex_target_jump;

    reg     [31:0]      ex_reg1_id; // the reg data get from id stage, which may be replaced by wb_wdata
    wire    [31:0]      ex_reg1;
    reg     [31:0]      ex_reg2_id;
    wire    [31:0]      ex_reg2;
    reg     [31:0]      ex_imm;

    wire                ex_bypass_reg1;
    wire                ex_bypass_reg2;

    reg     [31:0]      ex_alu_a; // wire
    reg     [31:0]      ex_alu_b; // wire
    wire    [31:0]      ex_alu_o;

    wire                ex_dcache_ren;
    wire    [2:0]       ex_dcache_rwidth;
    wire                ex_dcache_rsign;

    wire                ex_dcache_wen;
    wire    [2:0]       ex_dcache_wwidth;

    wire    [31:0]      ex_csr;
    wire    [31:0]      ex_mepc;
    wire    [31:0]      ex_mtvec;

    wire    [31:0]      ex_dnpc;
    wire                ex_is_br;
    wire                ex_is_br_taken;

    // 4. WB
    reg     [31:0]      wb_pc;
    reg     [1:0]       wb_rd_sel;

    wire    [31:0]      wb_dcache_rdata;
    wire                wb_dcache_valid;

    reg     [31:0]      wb_alu_o;
    reg     [4:0]       wb_rd;
    reg                 wb_reg_w_en;
    reg     [31:0]      wb_csr;
    reg     [31:0]      wb_wdata; // wire
    

    // pipe line register state update
    assign pipeline_en = id_icache_valid && wb_dcache_valid;
    always @(posedge clk) begin
        if(pipeline_en) begin
            id_pc               <= if_pc;
 
            ex_pc               <= id_pc;
            ex_inst             <= id_inst;
            ex_icache_valid     <= id_icache_valid;
 
            ex_pc_ctrl          <= id_pc_ctrl;
            ex_imm_type         <= id_imm_type;
            ex_mem_ctrl         <= bpu_id_invalid?`MEM_NONE:id_mem_ctrl;
 
            ex_alu_ctrl         <= id_alu_ctrl;
            ex_alu_a_sel        <= id_alu_a_sel;
            ex_alu_b_sel        <= id_alu_b_sel;
            ex_reg_w_en         <= bpu_id_invalid?1'b0:id_reg_w_en;
            ex_rd_sel           <= id_rd_sel;
            ex_rs1              <= id_rs1;
            ex_rs2              <= id_rs2;
            ex_rd               <= id_rd;
 
            ex_csr_we           <= bpu_id_invalid?1'b0:id_csr_we;
            ex_func3            <= id_func3;
            ex_csr_addr         <= id_csr_addr;
            ex_target_en        <= id_target_en;
            ex_target_jump      <= id_target_jump;
 
            ex_reg1_id          <= id_reg1;
            ex_reg2_id          <= id_reg2;
            ex_imm              <= id_imm; 

            wb_pc               <= ex_pc;
            wb_rd_sel           <= ex_rd_sel;
            wb_alu_o            <= ex_alu_o;
            wb_rd               <= ex_rd;
            wb_reg_w_en         <= ex_reg_w_en;
            wb_csr              <= ex_csr;
        end
    end
    
    // IF stage
    pred u_pred(
        .clk            	(clk             ),
        .rst            	(rst             ),
        .pipeline_en    	(pipeline_en     ),
        .ex_pc          	(ex_pc           ),
        .ex_dnpc        	(ex_dnpc         ),
        .is_ex_br       	(ex_is_br        ),
        .is_br_taken    	(ex_is_br_taken  ),
        .id_target      	(id_target       ),
        .id_target_en   	(id_target_en    ),
        .id_target_jump 	(id_target_jump  ),
        .id_pc          	(id_pc           ),
        .pc_out         	(if_pc           ),
        .id_invalid     	(bpu_id_invalid  )
    );

    icache u_icache(
        .clk            	(clk             ),
        .rst            	(rst             ),
        .pipeline_en 	    (pipeline_en     ),
        .pc             	(if_pc           ),
        .inst           	(id_inst         ),
        .valid          	(id_icache_valid )
    );

    // ID stage
    decoder u_decoder(
        .inst_i           	(id_inst         ),
        .pc_ctrl         	(id_pc_ctrl       ),
        .imm_type       	(id_imm_type     ),
        .mem_ctrl       	(id_mem_ctrl     ),
        .alu_ctrl       	(id_alu_ctrl     ),
        .alu_a_sel      	(id_alu_a_sel    ),
        .alu_b_sel      	(id_alu_b_sel    ),
        .reg_w_en    	    (id_reg_w_en     ),
        .reg_rd_sel     	(id_rd_sel       ),
        .rs1            	(id_rs1          ),
        .rs2            	(id_rs2          ),
        .rd             	(id_rd           ),
        .csr_we         	(id_csr_we       ),
        .func3          	(id_func3        ),
        .csr_addr       	(id_csr_addr     ),
        .target_en      	(id_target_en    ),
        .target_jump 	    (id_target_jump  )
    );
    
    reg_file u_reg_file(
        .clk            	(clk             ),
        .rst            	(rst             ),
        .pipeline_en    	(pipeline_en     ),
        .rs1            	(id_rs1          ),
        .rs2            	(id_rs2          ),
        .rd             	(wb_rd           ),
        .wdata          	(wb_wdata        ),
        .wen            	(wb_reg_w_en     ),
        .reg1           	(id_reg1         ),
        .reg2           	(id_reg2         )
    );
    
    immext u_immext(
        .inst           	(id_inst[31:7]   ),
        .imm_type       	(id_imm_type     ),
        .ext            	(id_imm          )
    );

    assign id_target = id_pc + id_imm;

    // EX stage
    dcache_decoder u_dcache_decoder(
        .decode_Mctl 	    (ex_mem_ctrl     ),
        .ren         	    (ex_dcache_ren   ),
        .rwidth      	    (ex_dcache_rwidth),
        .rsign       	    (ex_dcache_rsign ),
        .wen         	    (ex_dcache_wen   ),
        .wwidth      	    (ex_dcache_wwidth)
    );

    alu u_alu(
        .op  	            (ex_alu_ctrl     ),
        .a_i 	            (ex_alu_a        ),
        .b_i 	            (ex_alu_b        ),
        .out 	            (ex_alu_o        )
    );
    
    csr_file u_csr_file(
        .clk            	(clk             ),
        .rst            	(rst             ),
        .pipeline_en    	(pipeline_en     ),
        .csr_we         	(ex_csr_we       ),
        .func3          	(ex_func3        ),
        .rs1            	(ex_rs1          ),
        .reg1           	(ex_reg1         ),
        .pc             	(ex_pc           ),
        .csr_addr       	(ex_csr_addr     ),
        .csr            	(ex_csr          ),
        .mepc_out       	(ex_mepc         ),
        .mtvec_out      	(ex_mtvec        )
    );
    
    pc_sys u_pc_sys(
        .pc          	    (ex_pc           ),
        .pc_ctrl      	    (ex_pc_ctrl      ),
        .alu_o       	    (|ex_alu_o       ),
        .reg1        	    (ex_reg1         ),
        .offset      	    (ex_imm          ),
        .epc         	    (ex_mepc         ),
        .mtvec       	    (ex_mtvec        ),
        .dnpc        	    (ex_dnpc         ),
        .is_br       	    (ex_is_br        ),
        .is_br_taken 	    (ex_is_br_taken  )
    );
    
    dcache u_dcache(
        .clk         	    (clk             ),
        .rst         	    (rst             ),
        .pipeline_en 	    (pipeline_en     ),
        .ren         	    (ex_dcache_ren   ),
        .addr        	    (ex_alu_o        ),
        .rwidth      	    (ex_dcache_rwidth),
        .rsign       	    (ex_dcache_rsign ),
        .rdata       	    (wb_dcache_rdata ),
        .wen         	    (ex_dcache_wen   ),
        .wwidth      	    (ex_dcache_wwidth),
        .wdata       	    (ex_reg2         ),
        .valid       	    (wb_dcache_valid )
    );

    forwarding u_forwarding(
        .ex_rs1      	    (ex_rs1          ),
        .ex_rs2      	    (ex_rs2          ),
        .wb_rd       	    (wb_rd           ),
        .wb_reg_wen  	    (wb_reg_w_en      ),
        .bypass_reg1 	    (ex_bypass_reg1  ),
        .bypass_reg2 	    (ex_bypass_reg2  )
    );
    
    assign ex_reg1 = ex_bypass_reg1?wb_wdata:ex_reg1_id;
    assign ex_reg2 = ex_bypass_reg2?wb_wdata:ex_reg2_id;

    always @ (*) begin
        case(ex_alu_a_sel)
            `ALU_a_reg1: ex_alu_a = ex_reg1;
            `ALU_a_0: ex_alu_a = 0;
            `ALU_a_pc: ex_alu_a = ex_pc;
            default: ex_alu_a = 0;
        endcase
    end

    always @ (*) begin
        case(ex_alu_b_sel)
            `ALU_b_reg2: ex_alu_b = ex_reg2;
            `ALU_b_imm: ex_alu_b = ex_imm;
            default: ex_alu_b = 0;
        endcase
    end

    // WB
    always @ (*) begin
        case(wb_rd_sel)
            `RD_ALU: wb_wdata = wb_alu_o;
            `RD_MEM: wb_wdata = wb_dcache_rdata;
            `RD_SNPC: wb_wdata = wb_pc+4;
            `RD_CSR: wb_wdata = wb_csr;
            default: wb_wdata = 0;
        endcase
    end

endmodule
