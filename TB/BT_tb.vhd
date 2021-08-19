
ENTITY bt_tb IS
   -- Declarations

END bt_tb ;


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

LIBRARY work;

ARCHITECTURE struct OF bt_tb IS

   -- Internal signal declarations
   signal BTCTL : std_logic_vector (7 downto 0);
   signal BTCNT : std_logic_vector (31 downto 0) := X"00000000";
   signal BTIFG : std_logic;

   signal BTIP   : std_logic_vector (2 downto 0) := "000";
   signal BTSSEL : std_logic_vector (1 downto 0) := "00";
   signal BTHOLD : std_logic                     := '1';

   signal clk, reset : std_logic := '0';

   -- Component Declarations
   component BasicTimer is
      port (
         MCLK  : in  std_logic;
         reset : in  std_logic;
         BTCTL : in  std_logic_vector (7 downto 0);  -- Basic Timer Control Register
         BTCNT : in  std_logic_vector (31 downto 0); -- Basic Timer Counter (init)
         BTIFG : out std_logic                       -- Basic Timer Flag
      );
   end component BasicTimer;

BEGIN

   BTCTL <= "00" & BTHOLD & BTSSEL & BTIP;


   -- Instance port mappings.
   U_0 : BasicTimer
      PORT MAP (
         MCLK  => clk,
         reset => reset,
         BTCTL => BTCTL,
         BTCNT => BTCNT,
         BTIFG => BTIFG
      );

   tb : process
   begin
      reset <= '1';
      wait for 175 ns;
      reset <= '0';
      wait until rising_edge(clk);
      BTCNT <= X"00000005";
      BTIP <= "001";
      BTSSEL <= "01";
      wait until rising_edge(clk);
      BTHOLD <= '0';
      wait until rising_edge(BTIFG);
      wait until rising_edge(BTIFG);
      wait until rising_edge(clk);
      BTHOLD <= '1';      
      wait;
   end process;

   clk <= not clk after 50 ns;


END struct;
