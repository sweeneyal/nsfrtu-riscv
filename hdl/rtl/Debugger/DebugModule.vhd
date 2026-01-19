library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library nsfrtu_riscv;
    use nsfrtu_riscv.DebugUtility.all;
    use nsfrtu_riscv.CommonUtility.all;

entity DebugModule is
    port (
        i_clk    : in std_logic;

        i_dmi_en    : in std_logic;
        i_dmi_op    : in dmi_op_t;
        i_dmi_addr  : in std_logic_vector(6 downto 0);
        i_dmi_wdata : in std_logic_vector(31 downto 0);
        o_dmi_rdata : out std_logic_vector(31 downto 0);
        o_dmi_valid : out std_logic;

        o_reg_addr  : out std_logic_vector(8 downto 0);
        o_reg_en    : out std_logic;
        o_reg_wen   : out std_logic;
        o_reg_wdata : out std_logic_vector(31 downto 0);
        i_reg_rdata : in std_logic_vector(31 downto 0)
    );
end entity DebugModule;

architecture rtl of DebugModule is
    signal dmcontrol : dmcontrol_t := dmcontrol_t'(
            haltreq         => '0',
            resumereq       => '0',
            hartreset       => '0',
            ackhavereset    => '0',
            ackunavail      => '0',
            hasel           => '0',
            hartsello       => (others => '0'),
            hartselhi       => (others => '0'),
            setkeepalive    => '0',
            clrkeepalive    => '0',
            setresethaltreq => '0',
            clrresethaltreq => '0',
            ndmreset        => '0',
            dmactive        => '0'
        );
    signal dmstatus : dmstatus_t := dmstatus_t'(
            ndmresetpending => '0',
            stickyunavail   => '0',
            impebreak       => '0',
            allhavereset    => '0',
            anyhavereset    => '0',
            allresumeack    => '0',
            anyresumeack    => '0',
            allnonexistent  => '0',
            anynonexistent  => '0',
            allunavail      => '0',
            anyunavail      => '0',
            allrunning      => '0',
            anyrunning      => '0',
            allhalted       => '0',
            anyhalted       => '0',
            authenticated   => '0',
            authbusy        => '0',
            hasresethaltreq => '0',
            confstrptrvalid => '0',
            version         => x"3"
        );

    signal hartinfo     : hartinfo_t := hartinfo_t'(
            nscratch   => (others => '0'),
            dataaccess => '0',
            datasize   => (others => '0'),
            dataaddr   => (others => '0')
        );
    signal haltsum1     : std_logic_vector(31 downto 0) := (others => '0');

    signal abstractcs   : abstractcs_t := abstractcs_t'(
            progbufsize => (others => '0'),
            busy        => '0',
            relaxedpriv => '0',
            cmderr      => (others => '0'),
            datacount   => (others => '0')
        );
    signal command      : command_t := command_t'(
            cmdtype => (others => '0'),
            control => (others => '0')
        );
    -- signal abstractauto : abstractauto_t := abstractauto_t'(
    --         autoexecprogbuf => (others => '0'),
    --         autoexecdata    => (others => '0')
    --     );

    signal confstrptr0  : std_logic_vector(31 downto 0) := (others => '0');
    signal progbuf0     : std_logic_vector(31 downto 0) := (others => '0');
    signal progbuf1     : std_logic_vector(31 downto 0) := (others => '0');
    signal authdata     : std_logic_vector(31 downto 0) := (others => '0');
    signal sbcs         : sbcs_t := sbcs_t'(
            sbversion       => (others => '0'),
            sbbusyerror     => '0',
            sbbusy          => '0',
            sbreadonaddr    => '0',
            sbaccess        => (others => '0'),
            sbautoincrement => '0',
            sbreadondata    => '0',
            sberror         => (others => '0'),
            sbasize         => (others => '0'),
            sbaccess128     => '0',
            sbaccess64      => '0',
            sbaccess32      => '0',
            sbaccess16      => '0',
            sbaccess8       => '0'
        );
    signal sbaddress0   : std_logic_vector(31 downto 0) := (others => '0');
    signal sbdata0      : std_logic_vector(31 downto 0) := (others => '0');

begin
    
    DmControlStateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (dmcontrol.dmactive = '0') then
                dmcontrol <= dmcontrol_t'(
                    haltreq         => '0',
                    resumereq       => '0',
                    hartreset       => '0',
                    ackhavereset    => '0',
                    ackunavail      => '0',
                    hasel           => '0',
                    hartsello       => (others => '0'),
                    hartselhi       => (others => '0'),
                    setkeepalive    => '0',
                    clrkeepalive    => '0',
                    setresethaltreq => '0',
                    clrresethaltreq => '0',
                    ndmreset        => '0',
                    dmactive        => '0'
                );
                if (i_dmi_en = '1' and ('0' & i_dmi_addr) = x"10") then
                    if (i_dmi_op = WRITE_OP) then
                        -- Update the dmactive bit. Possibly this can be a different register
                        -- that eventually updates this when the reset has been completed for all other
                        -- registers.
                        dmcontrol.dmactive <= i_dmi_wdata(0);
                    end if;
                end if;
            else
                if (i_dmi_en = '1' and ('0' & i_dmi_addr) = x"10") then
                    -- Writes are performed here, while reads are performed elsewhere
                    if (i_dmi_op = WRITE_OP) then
                        -- * writes to these bits are ignored if an abstract command is executing:
                        dmcontrol.haltreq         <= i_dmi_wdata(31); -- * 
                        dmcontrol.resumereq       <= i_dmi_wdata(30); -- *
                        dmcontrol.hartreset       <= i_dmi_wdata(29);
                        dmcontrol.ackhavereset    <= i_dmi_wdata(28); -- *
                        dmcontrol.ackunavail      <= i_dmi_wdata(27);
                        dmcontrol.hasel           <= '0'; -- we do not implement more than one hart.
                        dmcontrol.hartsello       <= (others => '0'); -- *; the only existing hart is hart0
                        dmcontrol.hartselhi       <= (others => '0'); -- *
                        -- this bit sets keepalive, unless clrkeepalive is simultaneously set.
                        dmcontrol.setkeepalive    <= i_dmi_wdata(5) and not i_dmi_wdata(4);
                        dmcontrol.clrkeepalive    <= i_dmi_wdata(4);
                        -- this bit sets resethaltreq, unless clrresethaltreq is simultaneously set.
                        dmcontrol.setresethaltreq <= i_dmi_wdata(3) and not i_dmi_wdata(2); -- *;
                        dmcontrol.clrresethaltreq <= i_dmi_wdata(2); -- *;
                        -- 
                        dmcontrol.ndmreset        <= i_dmi_wdata(1);
                        -- dmactive 
                        dmcontrol.dmactive        <= i_dmi_wdata(0);
                    end if;
                end if;
            end if;
        end if;
    end process DmControlStateMachine;

    DmStatusStateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (dmcontrol.dmactive = '0') then
                dmstatus.ndmresetpending <= '0';
                dmstatus.stickyunavail   <= '0';
                dmstatus.impebreak       <= '1';
                
                dmstatus.allhavereset <= '0';
                dmstatus.anyhavereset <= '0';
                
                dmstatus.allresumeack <= '0';
                dmstatus.anyresumeack <= '0';
                
                dmstatus.allnonexistent <= '0';
                dmstatus.anynonexistent <= '0';

                dmstatus.allunavail <= '0';
                dmstatus.anyunavail <= '0';

                dmstatus.allrunning <= '0';
                dmstatus.anyrunning <= '0';

                dmstatus.allhalted <= '0';
                dmstatus.anyhalted <= '0';

                dmstatus.authenticated <= '1';
                dmstatus.authbusy      <= '0';

                dmstatus.hasresethaltreq <= '0';
                dmstatus.confstrptrvalid <= '0';
                dmstatus.version         <= x"3";
            else
                dmstatus.ndmresetpending <= dmcontrol.ndmreset;
            end if;
        end if;
    end process DmStatusStateMachine;

    HartInfoStateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (dmcontrol.dmactive = '0') then
                hartinfo.nscratch <= (others => '0');
                hartinfo.dataaccess <= '0';
                hartinfo.datasize <= (others => '0');
                hartinfo.dataaddr <= (others => '0');
            else
                
            end if;
        end if;
    end process HartInfoStateMachine;
    
    AbstractCsStateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (dmcontrol.dmactive = '0') then
                abstractcs.progbufsize <= to_slv(2, 5);
                abstractcs.busy <= '0';
                abstractcs.relaxedpriv <= '0';
                abstractcs.cmderr <= (others => '0');
                abstractcs.datacount <= x"1";
            else
                
            end if;
        end if;
    end process AbstractCsStateMachine;

    AbstractCommandStateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (dmcontrol.dmactive = '0') then
                command.cmdtype <= (others => '0');
                command.control <= (others => '0');
            else
                
            end if;
        end if;
    end process AbstractCommandStateMachine;

    SystemBusAccessStateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (dmcontrol.dmactive = '0') then
                sbcs.sbversion       <= "001";
                sbcs.sbbusyerror     <= '0';
                sbcs.sbbusy          <= '0';
                sbcs.sbreadonaddr    <= '0';
                sbcs.sbaccess        <= to_slv(2, 3);
                sbcs.sbautoincrement <= '0';
                sbcs.sbreadondata    <= '0';
                sbcs.sberror         <= (others => '0');
                sbcs.sbasize         <= to_slv(32, 7);
                sbcs.sbaccess128     <= '0';
                sbcs.sbaccess64      <= '0';
                sbcs.sbaccess32      <= '1';
                sbcs.sbaccess16      <= '1';
                sbcs.sbaccess8       <= '1';

                sbaddress0 <= (others => '0');
                sbdata0    <= (others => '0');
            else

            end if;
        end if;
    end process SystemBusAccessStateMachine;

    ReadStateMachine: process(i_clk)
        variable dmi_addr : std_logic_vector(7 downto 0);
    begin
        if rising_edge(i_clk) then
            if (i_dmi_en = '1' and i_dmi_op = READ_OP) then
                dmi_addr := "0" & i_dmi_addr;
                case dmi_addr is
                    when x"10" =>
                        -- dmcontrol
                        o_dmi_rdata(31)  <= dmcontrol.haltreq;
                        o_dmi_rdata(30)  <= dmcontrol.resumereq;
                        o_dmi_rdata(29)  <= dmcontrol.hartreset;
                        o_dmi_rdata(28)  <= dmcontrol.ackhavereset;
                        o_dmi_rdata(27)  <= dmcontrol.ackunavail;
                        o_dmi_rdata(26)  <= dmcontrol.hasel;
                        o_dmi_rdata(25 downto 16)  <= dmcontrol.hartsello;
                        o_dmi_rdata(15 downto 6)  <= dmcontrol.hartselhi;
                        o_dmi_rdata(4)  <= dmcontrol.clrkeepalive;
                        o_dmi_rdata(5)  <= dmcontrol.setkeepalive;
                        o_dmi_rdata(3)  <= dmcontrol.setresethaltreq;
                        o_dmi_rdata(2)  <= dmcontrol.clrresethaltreq;
                        o_dmi_rdata(1)  <= dmcontrol.ndmreset;
                        o_dmi_rdata(0)  <= dmcontrol.dmactive;
                    when x"11" =>
                        -- dmstatus
                        o_dmi_rdata(31 downto 25) <= (others => '0');
                        o_dmi_rdata(24) <= dmstatus.ndmresetpending;
                        o_dmi_rdata(23) <= dmstatus.stickyunavail;
                        o_dmi_rdata(22) <= dmstatus.impebreak;
                        o_dmi_rdata(21 downto 20) <= (others => '0');
                        o_dmi_rdata(19) <= dmstatus.allhavereset;
                        o_dmi_rdata(18) <= dmstatus.anyhavereset;
                        o_dmi_rdata(17) <= dmstatus.allresumeack;
                        o_dmi_rdata(16) <= dmstatus.anyresumeack;
                        o_dmi_rdata(15) <= dmstatus.allnonexistent;
                        o_dmi_rdata(14) <= dmstatus.anynonexistent;
                        o_dmi_rdata(13) <= dmstatus.allunavail;
                        o_dmi_rdata(12) <= dmstatus.anyunavail;
                        o_dmi_rdata(11) <= dmstatus.allrunning;
                        o_dmi_rdata(10) <= dmstatus.anyrunning;
                        o_dmi_rdata(9) <= dmstatus.allhalted;
                        o_dmi_rdata(8) <= dmstatus.anyhalted;
                        o_dmi_rdata(7) <= dmstatus.authenticated;
                        o_dmi_rdata(6) <= dmstatus.authbusy;
                        o_dmi_rdata(5) <= dmstatus.hasresethaltreq;
                        o_dmi_rdata(4) <= dmstatus.confstrptrvalid;
                        o_dmi_rdata(3 downto 0) <= dmstatus.version;
                    when x"12" =>
                        -- hartinfo
                        o_dmi_rdata <= (others => '0');
                    when x"16" =>
                        -- abstractcs
                        o_dmi_rdata(31 downto 29) <= (others => '0');
                        o_dmi_rdata(28 downto 24) <= abstractcs.progbufsize;
                        o_dmi_rdata(23 downto 13) <= (others => '0');
                        o_dmi_rdata(12)           <= abstractcs.busy;
                        o_dmi_rdata(11)           <= abstractcs.relaxedpriv;
                        o_dmi_rdata(10 downto 8)  <= abstractcs.cmderr;
                        o_dmi_rdata(7 downto 4)   <= (others => '0');
                        o_dmi_rdata(3 downto 0)   <= abstractcs.datacount;
                    when x"17" =>
                        -- abstract command
                        o_dmi_rdata(31 downto 24) <= command.cmdtype;
                        o_dmi_rdata(23 downto 0)  <= command.control;
                    when x"18" =>
                        -- abstractauto
                        o_dmi_rdata <= (others => '0');
                    when x"19" =>
                        -- configuration structure pointer
                        o_dmi_rdata <= confstrptr0;
                    when x"20" =>
                        -- program buffer register 0
                        o_dmi_rdata <= progbuf0;
                    when x"21" =>
                        -- program buffer register 1
                        o_dmi_rdata <= progbuf1;
                    when x"30" =>
                        -- 32-bit serial port to/from the authentication module.
                        o_dmi_rdata <= authdata;
                    when x"38" =>
                        -- system bus control and status
                        o_dmi_rdata(31 downto 29) <= sbcs.sbversion;
                        o_dmi_rdata(28 downto 23) <= (others => '0');
                        o_dmi_rdata(22) <= sbcs.sbbusyerror;
                        o_dmi_rdata(21) <= sbcs.sbbusy;
                        o_dmi_rdata(20) <= sbcs.sbreadonaddr;
                        o_dmi_rdata(19 downto 17) <= sbcs.sbaccess;
                        o_dmi_rdata(16) <= sbcs.sbautoincrement;
                        o_dmi_rdata(15) <= sbcs.sbreadondata;
                        o_dmi_rdata(14 downto 12) <= sbcs.sberror;
                        o_dmi_rdata(11 downto 5) <= sbcs.sbasize;
                        o_dmi_rdata(4 downto 0) <= sbcs.sbaccess128 & sbcs.sbaccess64 
                            & sbcs.sbaccess32 & sbcs.sbaccess16 & sbcs.sbaccess8;
                    when x"39" =>
                        -- system bus address
                        o_dmi_rdata <= sbaddress0;
                    when x"3c" =>
                        -- system bus data
                        o_dmi_rdata <= sbdata0;
                    when others =>
                        -- all others are not yet implemented.
                        o_dmi_rdata <= (others => '0');
                
                end case;
            end if;
        end if;
    end process ReadStateMachine;
    
end architecture rtl;