--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart-for-fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity UART_CLK_DIV_RX is
    Port (

        CLK : in std_logic; -- system clock
        RST : in std_logic; -- high active synchronous reset

        -- USER INTERFACE
        CLEAR    : in  std_logic; -- clock divider counter clear
        ENABLE   : in  std_logic; -- clock divider counter enable
        DIV_MARK : out std_logic; -- output divider mark (divided clock enable)

        -- Added
        BAUD_RATE : in std_logic -- baud rate value: 0 : 9600, 1: 115200   
    );
end entity;

architecture RTL of UART_CLK_DIV_RX is

    constant OS_CLK_DIV_VAL_9600   : integer := integer(real(12e6)/real(16*9600));                      --:= integer(real(12e6)/real(16*9600))
    constant OS_CLK_DIV_VAL_115200 : integer := integer(real(12e6)/real(16*115200));                    --:= integer(real(12e6)/real(16*115200))
    constant DIV_MAX_VAL_9600      : integer := integer(real(12e6)/real(OS_CLK_DIV_VAL_9600*9600));     --:= integer(real(12e6)/real(OS_CLK_DIV_VAL_9600*9600))
    constant DIV_MAX_VAL_115200    : integer := integer(real(12e6)/real(OS_CLK_DIV_VAL_115200*115200)); --:= integer(real(12e6)/real(OS_CLK_DIV_VAL_115200*115200))

    constant DIV_MARK_POS_9600  : integer := 3;
    constant CLK_DIV_WIDTH_9600 : integer := integer(ceil(log2(real(DIV_MAX_VAL_9600))));

    signal clk_div_cnt_9600      : unsigned(CLK_DIV_WIDTH_9600-1 downto 0);
    signal clk_div_cnt_mark_9600 : std_logic;

    constant DIV_MARK_POS_115200  : integer := 3;
    constant CLK_DIV_WIDTH_115200 : integer := integer(ceil(log2(real(DIV_MAX_VAL_115200))));

    signal clk_div_cnt_115200      : unsigned(CLK_DIV_WIDTH_115200-1 downto 0);
    signal clk_div_cnt_mark_115200 : std_logic;

    signal DIV_MARK_9600   : std_logic;
    signal DIV_MARK_115200 : std_logic;

begin

    clk_div_cnt_p_9600 : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (CLEAR = '1') then
                clk_div_cnt_9600 <= (others => '0');
            elsif (ENABLE = '1') then
                if (clk_div_cnt_9600 = DIV_MAX_VAL_9600-1) then
                    clk_div_cnt_9600 <= (others => '0');
                else
                    clk_div_cnt_9600 <= clk_div_cnt_9600 + 1;
                end if;
            end if;
        end if;
    end process;


    clk_div_cnt_mark_9600 <= '1' when (clk_div_cnt_9600 = DIV_MARK_POS_9600) else '0';


    clk_div_cnt_p_115200 : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (CLEAR = '1') then
                clk_div_cnt_115200 <= (others => '0');
            elsif (ENABLE = '1') then
                if (clk_div_cnt_115200 = DIV_MAX_VAL_115200-1) then
                    clk_div_cnt_115200 <= (others => '0');
                else
                    clk_div_cnt_115200 <= clk_div_cnt_115200 + 1;
                end if;
            end if;
        end if;
    end process;


    clk_div_cnt_mark_115200 <= '1' when (clk_div_cnt_115200 = DIV_MARK_POS_115200) else '0';

    div_mark_p_9600 : process (CLK)
    begin
        if (rising_edge(CLK)) then
            DIV_MARK_9600 <= ENABLE and clk_div_cnt_mark_9600;
        end if;
    end process;

    div_mark_p_115200 : process (CLK)
    begin
        if (rising_edge(CLK)) then
            DIV_MARK_115200 <= ENABLE and clk_div_cnt_mark_115200;
        end if;
    end process;

    --ADDED
    DIV_MARK <= DIV_MARK_9600 WHEN BAUD_RATE = '0' ELSE DIV_MARK_115200;

end architecture;
