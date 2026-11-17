`timescale 1ns/1ps

module tb_control_unit;
    import alu_pkg::*;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic       reg_write, mem_read, mem_write, branch, jump, jalr;
    logic [1:0] ALUsrc_1;
    logic       ALUsrc_2;
    alu_op_t    ALUop;
    logic [1:0] result_src;
    logic       uses_rs1, uses_rs2;

    int errors = 0;

    control_unit dut (
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .branch(branch), .jump(jump), .jalr(jalr),
        .ALUsrc_1(ALUsrc_1), .ALUsrc_2(ALUsrc_2), .ALU_op(ALUop),
        .result_src(result_src), .uses_rs1(uses_rs1), .uses_rs2(uses_rs2)
    );

    // Compare one signal and report it by name if it is wrong
    `define CMP(sig, exp) \
        if (sig !== exp) begin \
            $display("  FAIL %-12s: %s = %0h, expected %0h", name, `"sig`", sig, exp); \
            bad = 1; \
        end

    // One row of the truth table.
    // Argument order:  rw  mr  mw  br  jmp jalr  srcA srcB  alu_op  res  rs1 rs2
    task automatic check(
        input string      name,
        input [6:0]       op, input [2:0] f3, input [6:0] f7,
        input             e_rw, e_mr, e_mw, e_br, e_jmp, e_jalr,
        input [1:0]       e_srcA, input e_srcB,
        input alu_op_t    e_aluop,
        input [1:0]       e_res,
        input             e_rs1, e_rs2
    );
        bit bad = 0;
        opcode = op; funct3 = f3; funct7 = f7;
        #1;
        `CMP(reg_write,  e_rw)
        `CMP(mem_read,   e_mr)
        `CMP(mem_write,  e_mw)
        `CMP(branch,     e_br)
        `CMP(jump,       e_jmp)
        `CMP(jalr,       e_jalr)
        `CMP(ALUsrc_1,  e_srcA)
        `CMP(ALUsrc_2,  e_srcB)
        `CMP(ALUop,     e_aluop)
        `CMP(result_src, e_res)
        `CMP(uses_rs1,   e_rs1)
        `CMP(uses_rs2,   e_rs2)
        if (bad) errors++;
        else     $display("pass %s", name);
    endtask

    // opcodes
    localparam [6:0] OP     = 7'b0110011, OPIMM = 7'b0010011, LOAD  = 7'b0000011,
                     STORE  = 7'b0100011, BRANCH= 7'b1100011, JAL   = 7'b1101111,
                     JALR   = 7'b1100111, LUI   = 7'b0110111, AUIPC = 7'b0010111;
    localparam [6:0] F7_0 = 7'b0000000, F7_ALT = 7'b0100000;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_control_unit);

        //     name         opcode   funct3  funct7 rw mr mw br jmp jalr srcA srcB aluop  res   rs1 rs2
        // ---------------- R-type ----------------
        check("add",          OP,    3'b000, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_ADD,  2'b00, 1, 1);
        check("sub",          OP,    3'b000, F7_ALT, 1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_SUB,  2'b00, 1, 1);
        check("sll",          OP,    3'b001, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_SLL,  2'b00, 1, 1);
        check("slt",          OP,    3'b010, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_SLT,  2'b00, 1, 1);
        check("sltu",         OP,    3'b011, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_SLTU, 2'b00, 1, 1);
        check("xor",          OP,    3'b100, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_XOR,  2'b00, 1, 1);
        check("srl",          OP,    3'b101, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_SRL,  2'b00, 1, 1);
        check("sra",          OP,    3'b101, F7_ALT, 1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_SRA,  2'b00, 1, 1);
        check("or",           OP,    3'b110, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_OR,   2'b00, 1, 1);
        check("and",          OP,    3'b111, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 0, ALU_AND,  2'b00, 1, 1);

        // ---------------- I-type ALU ----------------
        check("addi",         OPIMM, 3'b000, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_ADD,  2'b00, 1, 0);
        // negative immediate sets instr[30]; addi must STILL be an add, never a sub
        check("addi neg imm", OPIMM, 3'b000, F7_ALT, 1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_ADD,  2'b00, 1, 0);
        check("slti",         OPIMM, 3'b010, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_SLT,  2'b00, 1, 0);
        check("sltiu",        OPIMM, 3'b011, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_SLTU, 2'b00, 1, 0);
        check("xori",         OPIMM, 3'b100, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_XOR,  2'b00, 1, 0);
        check("ori",          OPIMM, 3'b110, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_OR,   2'b00, 1, 0);
        check("andi",         OPIMM, 3'b111, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_AND,  2'b00, 1, 0);
        check("slli",         OPIMM, 3'b001, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_SLL,  2'b00, 1, 0);
        check("srli",         OPIMM, 3'b101, F7_0,   1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_SRL,  2'b00, 1, 0);
        check("srai",         OPIMM, 3'b101, F7_ALT, 1, 0, 0, 0, 0, 0, 2'b00, 1, ALU_SRA,  2'b00, 1, 0);

        // ---------------- memory ----------------
        check("lw",           LOAD,  3'b010, F7_0,   1, 1, 0, 0, 0, 0, 2'b00, 1, ALU_ADD,  2'b01, 1, 0);
        check("sw",           STORE, 3'b010, F7_0,   0, 0, 1, 0, 0, 0, 2'b00, 1, ALU_ADD,  2'b00, 1, 1);

        // ---------------- branches (all six use the same control) ----------------
        check("beq",          BRANCH,3'b000, F7_0,   0, 0, 0, 1, 0, 0, 2'b01, 1, ALU_ADD,  2'b00, 1, 1);
        check("bne",          BRANCH,3'b001, F7_0,   0, 0, 0, 1, 0, 0, 2'b01, 1, ALU_ADD,  2'b00, 1, 1);
        check("blt",          BRANCH,3'b100, F7_0,   0, 0, 0, 1, 0, 0, 2'b01, 1, ALU_ADD,  2'b00, 1, 1);
        check("bge",          BRANCH,3'b101, F7_0,   0, 0, 0, 1, 0, 0, 2'b01, 1, ALU_ADD,  2'b00, 1, 1);
        check("bltu",         BRANCH,3'b110, F7_0,   0, 0, 0, 1, 0, 0, 2'b01, 1, ALU_ADD,  2'b00, 1, 1);
        check("bgeu",         BRANCH,3'b111, F7_0,   0, 0, 0, 1, 0, 0, 2'b01, 1, ALU_ADD,  2'b00, 1, 1);

        // ---------------- jumps and upper-immediates ----------------
        check("jal",          JAL,   3'b000, F7_0,   1, 0, 0, 0, 1, 0, 2'b01, 1, ALU_ADD,  2'b10, 0, 0);
        check("jalr",         JALR,  3'b000, F7_0,   1, 0, 0, 0, 1, 1, 2'b00, 1, ALU_ADD,  2'b10, 1, 0);
        check("lui",          LUI,   3'b000, F7_0,   1, 0, 0, 0, 0, 0, 2'b10, 1, ALU_ADD,  2'b00, 0, 0);
        check("auipc",        AUIPC, 3'b000, F7_0,   1, 0, 0, 0, 0, 0, 2'b01, 1, ALU_ADD,  2'b00, 0, 0);

        // ---------------- anything else must act as a NOP ----------------
        check("all-zero instr", 7'b0000000, 3'b000, F7_0, 0, 0, 0, 0, 0, 0, 2'b00, 0, ALU_ADD, 2'b00, 0, 0);
        check("fence",        7'b0001111, 3'b000, F7_0, 0, 0, 0, 0, 0, 0, 2'b00, 0, ALU_ADD, 2'b00, 0, 0);
        check("ecall",        7'b1110011, 3'b000, F7_0, 0, 0, 0, 0, 0, 0, 2'b00, 0, ALU_ADD, 2'b00, 0, 0);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule