library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------------------------------------------
entity InterruptController is
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
		INTR : out std_logic  -- Interrupt request
	);
end entity InterruptController;

--------------------------------------------------------------------------------
architecture logic of InterruptController is
	signal GIEx : std_logic;                     -- Global Interrup Enable (HW)
	signal IFGx : std_logic_vector (7 downto 0); -- Interrupt Flag Register (HW)

	signal RXIE   : std_logic := '0'; -- RX interrupt enable
	signal TXIE   : std_logic := '0'; -- TX interrupt enable
	signal BTIE   : std_logic := '0'; -- Basic Timer interrupt enable
	signal KEY1IE : std_logic := '0'; -- KEY1 interrupt enable
	signal KEY2IE : std_logic := '0'; -- KEY2 interrupt enable
	signal KEY3IE : std_logic := '0'; -- KEY3 interrupt enable

	signal RXIFG   : std_logic := '0'; -- RX interrupt flag
	signal TXIFG   : std_logic := '0'; -- TX interrupt flag
	signal BTIFG   : std_logic := '0'; -- Basic Timer interrupt flag
	signal KEY1IFG : std_logic := '0'; -- KEY1 interrupt flag 
	signal KEY2IFG : std_logic := '0'; -- KEY2 interrupt flag
	signal KEY3IFG : std_logic := '0'; -- KEY3 interrupt flag

	signal FLAG : std_logic;

	constant all_zeros : std_logic_vector(IFGx'range) := (others => '0');
begin

	GIEx  <= GIE and INTA;
	IFGx  <= "00" & KEY3IFG & KEY2IFG & KEY1IFG & BTIFG & TXIFG & RXIFG;
	TYPEx <=
		X"08" when RXIFG = '1' else
		X"0C" when TXIFG = '1' else
		X"10" when BTIFG = '1' else
		X"14" when KEY1IFG = '1' else
		X"18" when KEY2IFG = '1' else
		X"1C" when KEY3IFG = '1' else
		(others => 'Z');

	FLAG <= '1' when IFGx /= all_zeros else '0';
	INTR <= FLAG and GIEx;

	----------------------------------------------------------------------------
	process (IE)
	begin
		RXIE   <= IE(0);
		TXIE   <= IE(1);
		BTIE   <= IE(2);
		KEY1IE <= IE(3);
		KEY2IE <= IE(4);
		KEY3IE <= IE(5);
	end process;

	----------------------------------------------------------------------------
	-- Interrupt Flag (Request)
	----------------------------------------------------------------------------
	process (RX_irq, IFG_write)
	begin
		if IFG_write = '1' then
			RXIFG <= RXIFG and IFG(0);
		elsif rising_edge(RX_irq) then
			RXIFG <= RXIE;
		end if;
	end process;

	process (TX_irq, IFG_write)
	begin
		if IFG_write = '1' then
			TXIFG <= TXIFG and IFG(1);
		elsif rising_edge(TX_irq) then
			TXIFG <= TXIE;
		end if;
	end process;

	process (BT_irq, IFG_write)
	begin
		if IFG_write = '1' then
			BTIFG <= BTIFG and IFG(2);
		elsif rising_edge(BT_irq) then
			BTIFG <= BTIE;
		end if;
	end process;

	process (KEY1_irq, IFG_write)
	begin
		if IFG_write = '1' then
			KEY1IFG <= KEY1IFG and IFG(3);
		elsif rising_edge(KEY1_irq) then
			KEY1IFG <= KEY1IE;
		end if;
	end process;

	process (KEY2_irq, IFG_write)
	begin
		if IFG_write = '1' then
			KEY2IFG <= KEY2IFG and IFG(4);
		elsif rising_edge(KEY2_irq) then
			KEY2IFG <= KEY2IE;
		end if;
	end process;

	process (KEY3_irq, IFG_write)
	begin
		if IFG_write = '1' then
			KEY3IFG <= KEY3IFG and IFG(5);
		elsif rising_edge(KEY3_irq) then
			KEY3IFG <= KEY3IE;
		end if;
	end process;


end architecture logic;
