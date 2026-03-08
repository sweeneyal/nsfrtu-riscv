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
                report "Running ADD";
                instr_i.operation <= ADD;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in 0 to 255 loop
                        opB_i <= to_slvu(jj, 32);
                        wait for 100 ps;
                        check(res_o = to_slvu(ii + jj, 32));
                    end loop;
                end loop;

                report "Running SUB";
                instr_i.operation <= SUBTRACT;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in 0 to 255 loop
                        opB_i <= to_slvu(jj, 32);
                        wait for 100 ps;
                        check(res_o = to_slv(ii - jj, 32));
                    end loop;
                end loop;

                report "Running SHIFT_LL";
                instr_i.operation <= SHIFT_LL;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in 0 to 31 loop
                        opB_i <= to_slvu(jj, 32);
                        wait for 100 ps;
                        check(res_o = std_logic_vector(shift_left(unsigned(opA_i), jj)));
                    end loop;
                end loop;

                report "Running SHIFT_RA";
                instr_i.operation <= SHIFT_RA;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in 0 to 31 loop
                        opB_i <= to_slvu(jj, 32);
                        wait for 100 ps;
                        check(res_o = std_logic_vector(shift_right(signed(opA_i), jj)));
                    end loop;
                end loop;

                report "Running SHIFT_RL";
                instr_i.operation <= SHIFT_RL;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in 0 to 31 loop
                        opB_i <= to_slvu(jj, 32);
                        wait for 100 ps;
                        check(res_o = std_logic_vector(shift_right(unsigned(opA_i), jj)));
                    end loop;
                end loop;

                report "Running SLT";
                instr_i.operation <= SLT;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in -255 to 255 loop
                        opB_i <= to_slv(jj, 32);
                        wait for 100 ps;
                        check(res_o(0) = bool2bit(ii < jj));
                    end loop;
                end loop;

                report "Running SLTU";
                instr_i.operation <= SLTU;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in 0 to 255 loop
                        opB_i <= to_slv(jj, 32);
                        wait for 100 ps;
                        check(res_o(0) = bool2bit(ii < jj));
                    end loop;
                end loop;

                report "Running BITWISE_OR";
                instr_i.operation <= BITWISE_OR;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in 0 to 255 loop
                        opB_i <= to_slv(jj, 32);
                        wait for 100 ps;
                        check(res_o = (opA_i or opB_i));
                    end loop;
                end loop;

                report "Running BITWISE_XOR";
                instr_i.operation <= BITWISE_XOR;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in 0 to 255 loop
                        opB_i <= to_slv(jj, 32);
                        wait for 100 ps;
                        check(res_o = (opA_i xor opB_i));
                    end loop;
                end loop;

                report "Running BITWISE_AND";
                instr_i.operation <= BITWISE_AND;
                for ii in 0 to 255 loop
                    opA_i <= to_slvu(ii, 32);
                    for jj in 0 to 255 loop
                        opB_i <= to_slv(jj, 32);
                        wait for 100 ps;
                        check(res_o = (opA_i and opB_i));
                    end loop;
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture rtl;