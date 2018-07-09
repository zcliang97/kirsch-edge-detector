
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util.all;
use work.kirsch_synth_pkg.all;

--Declare 8 directions -- 
package directions is 
  subtype dir is std_logic_vector(2 downto 0);
	constant East		        :dir :=  "000";
	constant SouthEast      :dir := "101";
	constant South     	    :dir := "011";
	constant SouthWest   	  :dir := "111";
	constant West   	      :dir := "001";
	constant NorthWest   	  :dir := "100";
	constant North   	      :dir := "010";
	constant NorthEast   	  :dir := "110" ;	
end directions;

--Declare states -- 
package states is 
  subtype state is std_logic_vector(2 downto 0);
	constant Set1           :state := "001";
  constant Set2      	    :state := "010";
  constant Set3           :state := "011";
	constant Set4     	    :state := "100";
end states;

entity kirsch is
  port(
    clk        : in  std_logic;                      
    reset      : in  std_logic;                      
    i_valid    : in  std_logic;                 
    i_pixel    : in  unsigned(7 downto 0);
    o_valid    : out std_logic;                 
    o_edge     : out std_logic;	                     
    o_dir      : out direction_ty;
    o_mode     : out mode_ty;
    o_row      : out unsigned(7 downto 0);
    o_col      : out unsigned(7 downto 0);
   
    debug_switch	: in	std_logic_vector(15 downto 0);	 
    debug_num_0 	: out	std_logic_vector(3 downto 0);
    debug_num_1		: out	std_logic_vector(3 downto 0);
    debug_num_2		: out	std_logic_vector(3 downto 0);
    debug_num_3		: out	std_logic_vector(3 downto 0);
    debug_num_4		: out 	std_logic_vector(3 downto 0);
    debug_num_5		: out 	std_logic_vector(3 downto 0)
  );
end entity kirsch;

architecture main of kirsch is

begin  
      
  --Signals
    signal col_pos, row_pos : std_logic_vector(7 downto 0);
    signal a, b, c, d, e, f, g, h, i, j : std_logic_vector(7 downto 0);
    signal valid: std_logic_vector(7 downto 0);		
    signal pros: std_logic_vector(7 downto 0);
    signal state: std_logic_vector(1 downto 0);

  --Signals STAGE 1
    signal reg0, reg1 : std_logic_vector(7 downto 0);
  

  --Signals STAGE 2
    signal reg2, reg3, reg4 : std_logic_vector(7 downto 0);

    stage1: process begin
      wait until rising_edge(clk);
      reg4 <= reg0 + reg1;
      case(state) is
        when Set1 =>
          reg0 <= h+a;
          reg1 <= b;
          if g > b then
            reg1 <= g;
          end if;
        when Set2 =>
          reg0 <= b+c;
          reg1 <= b;
          if d > a then
            reg1 <= d;
          end if;
        when Set3 =>
          reg0 <= d+e;
          reg1 <= c;
          if f > c then
            reg1 <= f;
          end if;
        when Set4 =>
          reg0 <= f+g;
          reg1 <= e;
          if h > e then
            reg1 <= h;
          end if;
        when others =>
          reg0 <= reg0;
          reg1 <= reg1;
      end case;
    end process;

    stage2: process begin
      wait until rising_edge(clk);
      reg4 <= reg0 + reg1;
      case(state) is
        when Set1 =>
          reg3 <= (reg0 sll 1) + reg0;
        when others =>
          reg3 <= reg3 + (reg0 sll 1) + reg0;
      end case;
    end process;


end architecture;
