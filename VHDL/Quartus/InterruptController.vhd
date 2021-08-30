library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------------------------------------------
entity InterruptController is
	port (
		-- Reset
		RST_irq : in  std_logic;
		reset   : out std_logic;

		-- Interrupt Request (Hardware)
		RX_irq   : in std_logic; -- RX interrupt request
		TX_irq   : in std_logic; -- TX interrupt request
		BT_irq   : in std_logic; -- Basic Timer interrupt request
		KEY1_irq : in std_logic; -- KEY1 interrupt request
		KEY2_irq : in std_logic; -- KEY2 interrupt request
		KEY3_irq : in std_logic; -- KEY3 interrupt request

		-- Interrupt Registers
		GIE       : in  std_logic;                     -- Global Interrupt Enable (SW) -> $k0(0)
		IE        : in  std_logic_vector (5 downto 0); -- Interrupt Enable Register (SW)
		IFG_in    : in  std_logic_vector (5 downto 0); -- Interrupt Flag Register (SW)
		IFG_out   : out std_logic_vector (7 downto 0); -- Interrupt Flag Register (SW)
		IFG_write : in  std_logic;                     -- Data in IFG ready to be used
		TYPEx     : out std_logic_vector (8 downto 0); -- Type Register

		-- CPU
		INTA : in  std_logic; -- '0': ACK (Interrupt Acknolwdge)
		INTR : out std_logic; -- Interrupt request

		-- Clear Flag 
		clr_BT : in boolean;
		clr_RX : in boolean;
		clr_TX : in boolean
	-- clr_KEY1, clr_KEY2, clr_KEY3 : in boolean
	);
end entity InterruptController;

--------------------------------------------------------------------------------
architecture logic of InterruptController is
	signal GIEx     : std_logic;                     -- Global Interrup Enable (HW)
	signal IFGx     : std_logic_vector (5 downto 0); -- Global Interrup Enable (HW)
	signal TYPE_reg : std_logic_vector (7 downto 0);

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

	-- Added for clearing BT
	signal clr_BT_irq : std_logic;
	signal BTIFG_clr  : std_logic;

begin
	reset <= RST_irq;

	GIEx    <= GIE and INTA;
	IFG_out <= "00" & IFGx;
	IFGx    <= KEY3IFG & KEY2IFG & KEY1IFG & BTIFG & TXIFG & RXIFG;

	TYPEx    <= '0' & TYPE_reg;
	TYPE_reg <=
		X"08" when RXIFG = '1' else
		X"0C" when TXIFG = '1' else
		X"10" when BTIFG = '1' else
		X"14" when KEY1IFG = '1' else
		X"18" when KEY2IFG = '1' else
		X"1C" when KEY3IFG = '1' else
		X"ff";

	FLAG <= '0' when IFGx = "00000" else '1';
	INTR <= FLAG and GIEx;

	clr_BT_irq <= '1'       when IFG_write = '1' or clr_BT else '0';
	BTIFG_clr  <= IFG_in(2) when IFG_write = '1' else '0';

	----------------------------------------------------------------------------
	-- Interrupt Enable
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
	process (RX_irq, clr_RX)
	begin
		if clr_RX then
			RXIFG <= '0';
		elsif rising_edge(RX_irq) then
			RXIFG <= RXIE;
		end if;
	end process;

	process (TX_irq, clr_TX)
	begin
		if clr_TX then
			TXIFG <= '0';
		elsif rising_edge(TX_irq) then
			TXIFG <= TXIE;
		end if;
	end process;

	process (BT_irq, clr_BT_irq, BTIFG_clr)
	begin
		if clr_BT_irq = '1' then
			BTIFG <= BTIFG_clr;
		elsif rising_edge(BT_irq) then
			BTIFG <= BTIE;
		end if;
	end process;

	process (KEY1_irq, IFG_write, IFG_in(3))
	begin
		if IFG_write = '1' then
			KEY1IFG <= IFG_in(3);
		elsif rising_edge(KEY1_irq) then
			KEY1IFG <= KEY1IE;
		end if;
	end process;

	process (KEY2_irq, IFG_write, IFG_in(4))
	begin
		if IFG_write = '1' then
			KEY2IFG <= IFG_in(4);
		elsif rising_edge(KEY2_irq) then
			KEY2IFG <= KEY2IE;
		end if;
	end process;

	process (KEY3_irq, IFG_write, IFG_in(5))
	begin
		if IFG_write = '1' then
			KEY3IFG <= IFG_in(5);
		elsif rising_edge(KEY3_irq) then
			KEY3IFG <= KEY3IE;
		end if;
	end process;


end architecture logic;