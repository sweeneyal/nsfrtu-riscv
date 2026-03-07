library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library nsfrtu_riscv;
    use nsfrtu_riscv.CommonUtility.all;
    use nsfrtu_riscv.InstructionUtility.all;
    use nsfrtu_riscv.DatapathUtility.all;

entity tb_IntegerAlu is
    generic (runner_cfg : string);
end entity tb_IntegerAlu;

architecture rtl of tb_IntegerAlu is
    signal instr_i : decoded_instr_t;
    signal opA_i   : std_logic_vector(31 downto 0);
    signal opB_i   : std_logic_vector(31 downto 0);
    signal res_o   : std_logic_vector(31 downto 0);
    signal eq_o    : std_logic;
begin
    
    eDut : entity nsfrtu_riscv.IntegerAlu
    port map (
        i_decoded => instr_i,
        i_opA     => opA_i,
        i_opB     => opB_i,

        o_res => res_o,
        o_eq  => eq_o
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