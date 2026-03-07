library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library nsfrtu_riscv;
    use nsfrtu_riscv.DebugUtility.all;
    use nsfrtu_riscv.CommonUtility.all;

entity HartCtrl is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        o_status : out hart_status_t
    );
end entity HartCtrl;