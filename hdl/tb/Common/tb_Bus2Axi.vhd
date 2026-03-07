library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library nsfrtu_riscv;
    use nsfrtu_riscv.CommonUtility.all;
    use nsfrtu_riscv.InstructionUtility.all;
    use nsfrtu_riscv.DatapathUtility.all;

entity tb_Bus2Axi is
    generic (runner_cfg : string);
end entity tb_Bus2Axi;

architecture rtl of tb_Bus2Axi is
    signal instr_i : decoded_instr_t;
    signal opA_i   : std_logic_vector(31 downto 0);
    signal opB_i   : std_logic_vector(31 downto 0);
    signal res_o   : std_logic_vector(31 downto 0);
    signal eq_o    : std_logic;
begin

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