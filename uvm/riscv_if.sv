interface riscv_if (input logic clk)
      
    logic        rst_n,

    logic        debug_valid,       
    logic [31:0] debug_pc,          
    logic [4:0]  debug_rd,
    logic        debug_we,          
    logic [31:0] debug_out,         
    logic        debug_mem_we,      
    logic [31:0] debug_mem_addr,
    logic [31:0] debug_mem_wdata,

    logic        debug_stall,
    logic        debug_redirect,
    logic [1:0]  debug_fwd_a,
    logic [1:0]  debug_fwd_b

    clocking driver_cb @(posedge clk);
       default input #1step output #2ns;
       input ;
       output rst_n;

    endclocking

endinterface