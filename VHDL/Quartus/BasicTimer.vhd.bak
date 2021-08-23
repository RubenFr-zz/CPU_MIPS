library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------------------------------------------
entity BasicTimer is
	port (
		MCLK, reset : in  std_logic;
		BTCTL       : in  std_logic_vector (7 downto 0);  -- Basic Timer Control Register
		BTCNT       : in  std_logic_vector (31 downto 0); -- Basic Timer Counter (init)
		BTIFG       : out std_logic                       -- Basic Timer Flag
	);
end entity BasicTimer;

--------------------------------------------------------------------------------
architecture logic of BasicTimer is
	signal counter, next_counter : std_logic_vector (31 downto 0) := (others => '0');
	signal divider               : std_logic_vector (2 downto 0)  := (others => '0');

	signal BTIP   : std_logic_vector (2 downto 0);
	signal BTSSEL : std_logic_vector (1 downto 0);
	signal BTHOLD : std_logic;

	signal CLK   : std_logic;
	signal MCLK2 : std_logic;
	signal MCLK4 : std_logic;
	signal MCLK8 : std_logic;

	signal FLAG : std_logic;
begin

	BTIP   <= BTCTL (2 downto 0);
	BTSSEL <= BTCTL (4 downto 3);
	BTHOLD <= BTCTL(5);

	BTIFG <= FLAG;
	FLAG  <=
		counter(0)  when BTIP = "000" else
		counter(3)  when BTIP = "001" else
		counter(7)  when BTIP = "010" else
		counter(11) when BTIP = "011" else
		counter(15) when BTIP = "100" else
		counter(19) when BTIP = "101" else
		counter(23) when BTIP = "110" else
		counter(25) when BTIP = "111" else 'Z';

	MCLK2 <= divider(0);
	MCLK4 <= divider(1);
	MCLK8 <= divider(2);

	CLK <=
		MCLK  when BTSSEL = "00" else
		MCLK2 when BTSSEL = "01" else
		MCLK4 when BTSSEL = "10" else
		MCLK8 when BTSSEL = "11" else 'Z';

	next_counter <=
		BTCNT   when FLAG = '1' else
		counter when BTHOLD = '1' else
		counter + '1';

	----------------------------------------------------------------------------
	process (MCLK, reset)
	begin
		if reset = '1' then
			divider <= (others => '0');
		elsif rising_edge(MCLK) then
			divider <= divider + '1';
		end if;
	end process;

	----------------------------------------------------------------------------
	process (CLK, reset, BTCNT)
	begin
		if reset = '1' or BTCNT'event then
			counter <= BTCNT;
		elsif rising_edge(CLK) then
			counter <= next_counter;
		end if;
	end process;

end architecture logic;
