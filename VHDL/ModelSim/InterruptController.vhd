library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------------------------
entity InterruptController is
	port (
		intS : in  std_logic_vector (5 downto 0);  -- int source 
		--CS_n : in  std_logic;                      -- Ctrl select
		INTA : in  std_logic;                      -- int ack (not)
		INTR : out std_logic;                      -- int request 
		Addr : out std_logic_vector (31 downto 0); -- Address bus 
		Data : out std_logic_vector (31 downto 0)  -- data bus
	);
end entity InterruptController;
--------------------------------------------------------------------------------
architecture logic of InterruptController is
	constant all_zeros : std_logic_vector(IFG'range) := (others => '0');

	signal IE     : std_logic_vector (7 downto 0); -- Interrupt Enable Register
	signal IFG    : std_logic_vector (7 downto 0); -- Interrupt Flag Register
	signal TYPE_r : std_logic_vector (7 downto 0); -- Interrupt Type Register
	signal GIE    : std_logic;                     -- Global Interrupt Enable

	signal irq     : std_logic_vector (5 downto 0);
	signal clr_irq : std_logic_vector (5 downto 0);
	signal intr_r  : std_logic;
begin
	GIE <= INTA;

	IE (7 downto 6)    <= "00";
	IFG (7 downto 6)   <= "00";
	Addr (7 downto 0)  <= TYPE_r;
	Addr (31 downto 8) <= (others => '0');

	INTR <= GIE and ('1' when IFG /= all_zeros else '0');

	----------------------------------------------------------------------------
	Gen : for i in 0 to 5 generate

		IFG(i) <= irq(i) and IE(i);

		process (intS(i), clr_irq(i))
		begin
			if clr_irq(i) = '1' then
				irq(i) <= '0';
			elsif rising_edge(intS(i)) then
				irq(i) <= '1';
			end if;
		end process;

	end generate Gen;
	----------------------------------------------------------------------------

	process (IFG (7 downto 0))
	begin
		if IFG(0) = '1' then
			TYPE_r <= X"08";
		elsif IFG(1) = '1' then
			TYPE_r <= X"0C";
		elsif IFG(2) = '1' then
			TYPE_r <= X"10";
		elsif IFG(3) = '1' then
			TYPE_r <= X"14";
		elsif IFG(4) = '1' then
			TYPE_r <= X"18";
		elsif IFG(5) = '1' then
			TYPE_r <= X"1C";
		else
			TYPE_r <= X"ZZ";
		end if;
	end process;
	----------------------------------------------------------------------------

	process( INTA )
	begin
		clr_irq <= (others <= '0');
		if falling_edge(INTA) then
			if IFG(0) = '1' then
				clr_irq(0) <= '1';
			elsif IFG(1) = '1' then
				clr_irq(1) <= '1';
			elsif IFG(2) = '1' then
				clr_irq(2) <= '1';
			elsif IFG(3) = '1' then
				clr_irq(3) <= '1';
			elsif IFG(4) = '1' then
				clr_irq(4) <= '1';
			elsif IFG(5) = '1' then
				clr_irq(5) <= '1';
			end if;
		end if;
	end process ;

end architecture logic;
