-- ******************************************************************************
-- 
--                   /------o
--             eccelerators
--          o------/
-- 
--  This file is an Eccelerators GmbH sample project.
-- 
--  MIT License:
--  Copyright (c) 2023 Eccelerators GmbH
-- 
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
-- 
--  The above copyright notice and this permission notice shall be included in all
--  copies or substantial portions of the Software.
-- 
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--  SOFTWARE.
-- ******************************************************************************
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
use work.BusJoinPackage.all;

entity BusJoinWishbone is
    generic(
        NUMBER_OF_BUSSES : positive;
        BUS_COUNT_WIDTH : positive; 
        ADDRESS_WIDTH : positive;
        DATA_WIDTH : positive
    );
	port (
		Clk : in std_logic;
		Rst : in std_logic;
		Cyc : in  std_logic_vector;
		Adr : in array_of_std_logic_vector;
		Sel : in array_of_std_logic_vector;
		We : in std_logic_vector;
		Stb : in std_logic_vector;
        DatIn : in array_of_std_logic_vector;
		DatOut : out array_of_std_logic_vector;
		Ack : out std_logic_vector;	
        JoinCyc : out std_logic;
		JoinAdr : out std_logic_vector;
		JoinSel : out std_logic_vector;
		JoinWe : out std_logic;
		JoinStb : out std_logic;
		JoinDatOut : out std_logic_vector;
		JoinDatIn: in std_logic_vector;
		JoinAck : in std_logic
	);
end entity;

architecture Behavioural of BusJoinWishbone is
    
    type State_T is (Idle, Cycle);
      
    function resolveCycleRequests (
        variable CycleRequests : std_logic_vector(NUMBER_OF_BUSSES-1 downto 0);
        variable MissedCountTable : array_of_unsigned(NUMBER_OF_BUSSES-1 downto 0)
    ) return integer is
        variable GreatestMissCount: integer := 0;
        variable SelectedRequest: integer := -1; 
    begin
        for i in 0 to NUMBER_OF_BUSSES-1 loop
            if CycleRequests(i) then
                if MissCountTable(i) > GreatestMissedCount then
                    GreatestMissCount := MissedCountTable(i);
                    SelectedRequest := i;
                end if;
            end if;
        end loop;
    end function;
    
    signal MissCountTable : array_of_unsigned(NUMBER_OF_BUSSES-1 downto 0) (BUS_COUNT_WIDTH-1 downto 0);
    signal SelectedBus : std_logic_vector(BUS_COUNT_WIDTH-1 downto 0); 

begin

    genDataOut : for i in 0 to BUS_COUNT_WIDTH-1 generate
        DatOut(i) <= JoinDatIn;
    end generate;
     
    Ack(to_integer(SelectedBus)) <= JoinAck;

    prcJoin : process ( Clk, Rst) is
        variable ri : integer := 0;
    begin
        if Rst then
        
            SelectedBus <= (others => '0');
            MissCountTable <= (others => (others => '0'));
            
        elsif rising_edge(Clk) then
            
            case State is
            
                when Idle =>
                    ri := resolveCycleRequests(Cyc, MissCountTable);
                    if ri >= 0 then       
                        SelectedBus <= to_unsigned(ri, BUS_COUNT_WIDTH);
                        JoinCyc <= '1';                   
                        JoinAdr <= Adr(ri);
                        JoinSel <= Sel(ri);
                        JoinWe <= DatIn(ri);
                        JoinStb <= We(ri);
                        JoinAdr <= Stb(ri);
                        JoinDatOut <= DatIn(ri);
                        MissCountTable(i) <= (others => '0');      
                        for i in 0 to NUMBER_OF_BUSSES-1 loop
                            if CycleRequests(i) and (i /= ri) then
                                MissCountTable(i) <= MissCountTable(i) + 1;
                            end if;
                        end loop;
                        State <= Cycle;
                    end if;

                when Cycle =>
                    if JoinAck then
                        JoinCyc <= '0';
                        State <= Cycle;
                    end if;
                
            end case;  
 
        end if;     
    end process;


	
end architecture;
