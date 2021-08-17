LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

entity hex_to_7_segment is
	port(
		hex    : in  std_logic_vector(3 downto 0);
		output : out std_logic_vector (6 downto 0));
end hex_to_7_segment;

architecture rtl of hex_to_7_segment is
begin
	----------------------------------------------------------------------------
	converter : process(hex)
	begin
		case hex is
			when x"0"   => output <= "1000000"; -- "0"     
			when x"1"   => output <= "1111001"; -- "1" 
			when x"2"   => output <= "0100100"; -- "2" 
			when x"3"   => output <= "0110000"; -- "3" 
			when x"4"   => output <= "0011001"; -- "4" 
			when x"5"   => output <= "0010010"; -- "5" 
			when x"6"   => output <= "0000010"; -- "6" 
			when x"7"   => output <= "1111000"; -- "7" 
			when x"8"   => output <= "0000000"; -- "8"     
			when x"9"   => output <= "0010000"; -- "9" 
			when x"A"   => output <= "0100000"; -- a
			when x"B"   => output <= "0000011"; -- b
			when x"C"   => output <= "1000110"; -- C
			when x"D"   => output <= "0100001"; -- d
			when x"E"   => output <= "0000110"; -- E
			when x"F"   => output <= "0001110"; -- F
			when others => output <= "1111111"; -- OFF (default)
		end case;
	end process;

end rtl;