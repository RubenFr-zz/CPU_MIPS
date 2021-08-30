LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
-----------------------------------
ENTITY Shifter IS
	GENERIC (
		n : INTEGER := 8;
		k : INTEGER := 3 -- k=log2(n)
	);
	PORT (
		shft_in     : IN  std_logic_vector (n-1 DOWNTO 0); -- Input to be shifted
		ShiftAmount : IN  std_logic_vector (k-1 DOWNTO 0); -- How much the input must be shifted (between 0 and 2^k-1)
		left_right  : IN  std_logic;                       -- 0: shift left, 1: shift right
		shft_out    : OUT std_logic_vector (n-1 DOWNTO 0);
		cout        : OUT std_logic -- Carry out
	);
END ENTITY Shifter;
-----------------------------------
ARCHITECTURE logic OF Shifter IS
	SUBTYPE vector IS std_logic_vector (n-1 DOWNTO 0);
	TYPE matrix IS ARRAY (k DOWNTO 0) OF vector;

	SIGNAL shift : matrix;                        -- holds intermediate results
	SIGNAL carry : std_logic_vector (k DOWNTO 0); -- holds intermediate carry

BEGIN
	shift(0) <= shft_in;  -- Initiate the process with the input
	carry(0) <= '0';      -- Initiate the carry with '0'
	shft_out <= shift(k); -- The output is the last value holded in shift(k)
	cout     <= carry(k); -- The carry out is the last value holded in carry(k)

	Gen : FOR i IN 0 TO k-1 GENERATE
		-- Barrel Shifter method: 
		-- If ShiftAmount(i) = 0 we don't need to shift -> shift(i+1) <= shift(i)
		-- If ShiftAmount(i) = 1 we shift by 2^i positions (the inserted bits are '0')
		-- Rather we shift to the left or righ depends on the left_right bit
		shift(i+1) <= shift(i)                                            WHEN ShiftAmount(i) = '0' ELSE
			shift(i)((n - 2**i - 1) DOWNTO 0) & ((2**i - 1) DOWNTO 0 => '0') WHEN left_right = '0' ELSE
			((2**i - 1) DOWNTO 0                                     => '0') & shift(i)(n - 1 DOWNTO 2**i);

		-- Barrel Shifter method: 
		-- If ShiftAmount(i) = 0 we don't need to shift -> carry(i+1) <= carry(i)
		-- If ShiftAmount(i) = 1 we shift by 2^i positions the carry is then the last bit that overflowed:
		--		shift(i)(n - 2**i) if we shift left
		--		shift(i)(2**i - 1) if we shift rigth
		carry(i+1) <= carry(i) WHEN ShiftAmount(i) = '0' ELSE
			shift(i)(n - 2**i)    WHEN left_right = '0' ELSE
			shift(i)(2**i - 1);
	END GENERATE Gen;

END ARCHITECTURE logic;