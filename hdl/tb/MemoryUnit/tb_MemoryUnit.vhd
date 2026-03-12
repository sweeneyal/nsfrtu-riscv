library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library nsfrtu_riscv;
    use nsfrtu_riscv.CommonUtility.all;
    use nsfrtu_riscv.InstructionUtility.all;
    use nsfrtu_riscv.DatapathUtility.all;

entity tb_MemoryUnit is
    generic (runner_cfg : string);
end entity tb_MemoryUnit;

architecture rtl of tb_MemoryUnit is
    constant cAddressWidth_b    : positive := 32;
    constant cDataWidth_b       : positive := 32;
    constant cCachelineSize_B   : positive := 16;

    constant cGenerateCache     : boolean  := true;
    constant cCacheType         : string   := "Direct";
    constant cCacheSize_entries : positive := 1024;
    constant cCache_NumSets     : positive := 1;
    
    constant cNumCacheMasks     : positive := 1;
    constant cCacheMasks        : std_logic_matrix_t
        (0 to cNumCacheMasks - 1)(cAddressWidth_b - 1 downto 0) := (0 => x"0000FFFF")

    signal clk_i    : std_logic;
    signal resetn_i : std_logic;

    signal decoded_i : decoded_instr_t;
    signal valid_i   : std_logic;
    signal addr_i    : std_logic_vector(cAddressWidth_b - 1 downto 0);
    signal data_i    : std_logic_vector(cDataWidth_b - 1 downto 0);
    signal res_o     : std_logic_vector(cDataWidth_b - 1 downto 0);
    signal valid_o   : std_logic;

    signal cache_hit_o  : std_logic;
    signal cache_miss_o : std_logic;

    signal data_awaddr_o  : std_logic_vector(cAddressWidth_b - 1 downto 0);
    signal data_awprot_o  : std_logic_vector(2 downto 0);
    signal data_awvalid_o : std_logic;
    signal data_awready_i : std_logic;

    signal data_wdata_o  : std_logic_vector(8 * cCachelineSize_B - 1 downto 0);
    signal data_wstrb_o  : std_logic_vector(cCachelineSize_B - 1 downto 0);
    signal data_wvalid_o : std_logic;
    signal data_wready_i : std_logic;

    signal data_bresp_i  : std_logic_vector(1 downto 0);
    signal data_bvalid_i : std_logic;
    signal data_bready_o : std_logic;

    signal data_araddr_o  : std_logic_vector(cAddressWidth_b - 1 downto 0);
    signal data_arprot_o  : std_logic_vector(2 downto 0);
    signal data_arvalid_o : std_logic;
    signal data_arready_i : std_logic;

    signal data_rdata_i  : std_logic_vector(8 * cCachelineSize_B - 1 downto 0);
    signal data_rresp_i  : std_logic_vector(1 downto 0);
    signal data_rvalid_i : std_logic;
    signal data_rready_o : std_logic
begin

    eDut : entity nsfrtu_riscv.MemoryUnit
    generic map (
        cAddressWidth_b    => cAddressWidth_b,
        cDataWidth_b       => cDataWidth_b,
        cCachelineSize_B   => cCachelineSize_B,

        cGenerateCache     => cGenerateCache,
        cCacheType         => cCacheType,
        cCacheSize_entries => cCacheSize_entries,
        cCache_NumSets     => cCache_NumSets,
        
        cNumCacheMasks     => cNumCacheMasks,
        cCacheMasks        => cCacheMasks
    ) port map (
        i_clk    => clk_i,
        i_resetn => resetn_i,

        i_decoded => decoded_i,
        i_valid   => valid_i,
        i_addr    => addr_i,
        i_data    => data_i,
        o_res     => res_o,
        o_valid   => valid_o,

        o_cache_hit => cache_hit_o,
        o_cache_miss => cache_miss_o,

        o_data_awaddr => data_awaddr_o,
        o_data_awprot => data_awprot_o,
        o_data_awvalid => data_awvalid_o,
        i_data_awready => data_awready_i,

        o_data_wdata  => data_wdata_o,
        o_data_wstrb => data_wstrb_o,
        o_data_wvalid => data_wvalid_o,
        i_data_wready => data_wready_i,

        i_data_bresp => data_bresp_i,
        i_data_bvalid => data_bvalid_i,
        o_data_bready => data_bready_o,

        o_data_araddr => data_araddr_o,
        o_data_arprot => data_arprot_o,
        o_data_arvalid => data_arvalid_o,
        i_data_arready => data_arready_i,

        i_data_rdata  => data_rdata_i,
        i_data_rresp => data_rresp_i,
        i_data_rvalid => data_rvalid_i,
        o_data_rready => data_rready_o
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_basic") then
                check(false);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture rtl;