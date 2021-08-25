-- Ifetch module (provides the PC and instruction 
--memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY Ifetch IS
	PORT(
		Instruction   : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		PC_plus_4_out : OUT STD_LOGIC_VECTOR( 10 DOWNTO 0 );
		Add_result    : IN  STD_LOGIC_VECTOR( 8 DOWNTO 0 );
		Branch        : IN  STD_LOGIC;
		Jump          : IN  STD_LOGIC;
		JumpReg       : IN  STD_LOGIC;
		Zero          : IN  STD_LOGIC;
		PC_out        : OUT STD_LOGIC_VECTOR( 10 DOWNTO 0 );
		read_data_1   : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		clock, reset  : IN  STD_LOGIC;
		INTR		  : IN 	STD_LOGIC;
		INTA		  : buffer 	STD_LOGIC;
		ISR_address	  : IN	STD_LOGIC_VECTOR( 8 DOWNTO 0)		-- 8 BITS
	);
END Ifetch;

ARCHITECTURE behavior OF Ifetch IS
	SIGNAL PC, PC_plus_4, Mem_Addr      	: STD_LOGIC_VECTOR( 10 DOWNTO 0 );
	SIGNAL next_PC	: STD_LOGIC_VECTOR( 8 DOWNTO 0 );
	SIGNAL Instruct   			: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL INTR_OLD		: STD_LOGIC;
BEGIN

	--------------------------------------------------------------------------------
	--ROM for Instruction Memory
	inst_memory : altsyncram

		GENERIC MAP (
			operation_mode         => "ROM",
			width_a                => 32,
			widthad_a              => 11,
			lpm_type               => "altsyncram",
			outdata_reg_a          => "UNREGISTERED",
			init_file              => "C:\final_lab_cpu\developement\stuff from moodle\app_test\program.hex",
			intended_device_family => "Cyclone"
		)
		PORT MAP (
			clock0    => clock,
			address_a => Mem_Addr,
			q_a       => Instruct );
	----------------------------------------------------------------------------
	
	-- Instruction select - if interrupt is '1' then opcode=31, else the fetched one
	Instruction <= 	X"FC000000" WHEN 	INTR = '1'
								ELSE	Instruct;
	
	
	
	-- Instructions always start on word address - not byte
	PC(1 DOWNTO 0) <= "00";

	-- copy output signals - allows read inside module
	PC_out        <= PC;
	PC_plus_4_out <= PC_plus_4;

	-- send address to inst. memory address register
	Mem_Addr <= Next_PC & "00";

	-- Adder to increment PC by 4        
	PC_plus_4( 9 DOWNTO 2 ) <= PC( 9 DOWNTO 2 ) + 1;
	PC_plus_4( 1 DOWNTO 0 ) <= "00";

	-- Mux to select Branch Address or PC + 4        
	Next_PC <=
		'0' & X"00"                     WHEN Reset = '1' ELSE
		-- ISR_address				  WHEN (INTR = '1'  and INTA = '0') or (INTR_OLD = '1')	 ELSE 		-- Choose the address of the ISR WHEN INTR='1'
		ISR_address				  WHEN INTR_OLD = '1'	 ELSE 		-- Choose the address of the ISR WHEN INTR='1'
		PC(10 DOWNTO 2)			  WHEN (INTR = '1') ELSE						--KEEP PC WHEN FIRST ENCOUNTERING INTERRUPT
		Add_result                WHEN ((Branch = '1') AND (Zero = '1') AND (Instruct(31 DOWNTO 26) = "000100")) ELSE	--beq
		Add_result                WHEN ((Branch = '1') AND (Zero = '0') AND (Instruct(31 DOWNTO 26) = "000101")) ELSE	--bne
		Add_result                WHEN ((Jump = '1') AND (Instruct(31 DOWNTO 26) = "000010")) ELSE						--j
		Add_result                WHEN ((Jump = '1') AND (Instruct(31 DOWNTO 26) = "000011")) ELSE						--jal
		read_data_1( 10 DOWNTO 2 ) WHEN ((JumpReg = '1') AND (Instruct(5 DOWNTO 0) = "001000") AND (Instruct(31 DOWNTO 26) = "000000" )) ELSE	--jr
		PC_plus_4( 10 DOWNTO 2 );

	
	-- Acknowledge to the InterruptController
	process( clock, reset )
		begin
			if reset = '1' then
				INTA <= '1';
			elsif falling_edge(clock) then
				IF INTR = '1' THEN
					INTA <= '0';
				ELSIF Instruct = x"03600008" THEN
					INTA <= '1';
				END IF;
			end if;
	end process;
	
	PROCESS ( clock, reset )
	BEGIN
		IF reset = '1' THEN
			PC( 10 DOWNTO 2) <= "000000000" ;
		elsif rising_edge(clock) then
			PC( 10 DOWNTO 2 ) <= Next_PC;
		END IF;
	END PROCESS;
	
	PROCESS (clock, reset)
	begin
		IF reset = '1' THEN
			INTR_OLD <= '0';
		elsif falling_edge(clock) then
			INTR_OLD <= INTR;
		END IF;
	end process;
	
	
END behavior;


