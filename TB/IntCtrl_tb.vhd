
ENTITY IntCtrl_tb IS
   -- Declarations

END IntCtrl_tb ;


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

LIBRARY work;

ARCHITECTURE struct OF IntCtrl_tb IS

   -- Architecture declarations

   -- Internal signal declarations
   signal RX_irq   : std_logic := '0';
   signal TX_irq   : std_logic := '0';
   signal BT_irq   : std_logic := '0';
   signal KEY1_irq : std_logic := '0';
   signal KEY2_irq : std_logic := '0';
   signal KEY3_irq : std_logic := '0';

   signal GIE       : std_logic := '1';
   signal IE        : std_logic_vector (5 downto 0) := "111111";
   signal IFG       : std_logic_vector (5 downto 0) := "000000";
   signal IFG_write : std_logic := '0';
   signal TYPEx     : std_logic_vector (7 downto 0);

   signal INTA : std_logic := '1';
   signal INTR : std_logic;

   signal clk : std_logic := '0';


   -- Component Declarations
   component InterruptController is
      port (
         -- Interrupt Request (Hardware)
         RX_irq   : in std_logic; -- RX interrupt request (HW)
         TX_irq   : in std_logic; -- TX interrupt request (HW)
         BT_irq   : in std_logic; -- Basic Timer interrupt request (HW)
         KEY1_irq : in std_logic; -- KEY1 interrupt request (HW)
         KEY2_irq : in std_logic; -- KEY2 interrupt request (HW)
         KEY3_irq : in std_logic; -- KEY3 interrupt request (HW)

         -- Interrupt Registers
         GIE       : in  std_logic;                     -- Global Interrupt Enable (SW) -> $k0(0)
         IE        : in  std_logic_vector (5 downto 0); -- Interrupt Enable Register (SW)
         IFG       : in  std_logic_vector (5 downto 0); -- Interrupt Flag Register (SW)
         IFG_write : in  std_logic;                     -- Data in IFG ready to be used
         TYPEx     : out std_logic_vector (7 downto 0); -- Type Register

         -- CPU
         INTA : in  std_logic; -- '0': ACK (Interrupt Acknolwdge)
         INTR : out std_logic  -- Interrupt request (Global) 
      );
   end component InterruptController;

BEGIN

   -- Instance port mappings.
   U_0 : InterruptController
      PORT MAP (
         RX_irq    => RX_irq,
         TX_irq    => TX_irq,
         BT_irq    => BT_irq,
         KEY1_irq  => KEY1_irq,
         KEY2_irq  => KEY2_irq,
         KEY3_irq  => KEY3_irq,
         GIE       => GIE,
         IE        => IE,
         IFG       => IFG,
         IFG_write => IFG_write,
         TYPEx     => TYPEx,
         INTA      => INTA,
         INTR      => INTR
      );
   
   tb: process
   begin
      wait for 175 ns;
      KEY1_irq <= '1', '0' after 400 ns;
      wait until rising_edge(clk);
      INTA <= '0';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      IFG <= "110111";
      IFG_write <= '1';
      wait until rising_edge(clk);
      IFG_write <= '0';
      INTA <= '1';
      wait;
   end process;

   clk <= not clk after 50 ns;


END struct;
