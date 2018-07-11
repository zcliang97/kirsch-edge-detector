library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Declare 8 directions -- 
package directions is 
  subtype dir is std_logic_vector(2 downto 0);
	constant East		        :dir := "000";
	constant SouthEast      :dir := "101";
	constant South     	    :dir := "011";
	constant SouthWest   	  :dir := "111";
	constant West   	      :dir := "001";
	constant NorthWest   	  :dir := "100";
	constant North   	      :dir := "010";
	constant NorthEast   	  :dir := "110" ;	
end directions;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Declare states -- 
package all_states is 
  subtype states is std_logic_vector(2 downto 0);
  constant ReplaceRow     :states := "000";
	constant Set1           :states := "001";
  constant Set2      	    :states := "010";
  constant Set3           :states := "011";
	constant Set4     	    :states := "100";
end all_states;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util.all;
use work.all_states.all;
use work.directions.all;
use work.kirsch_synth_pkg.all;

entity kirsch is
  port(
    clk        : in  std_logic;                      
    reset      : in  std_logic;                      
    i_valid    : in  std_logic;                 
    i_pixel    : in  std_logic_vector(7 downto 0);
    o_valid    : out std_logic;                 
    o_edge     : out std_logic;	                     
    o_dir      : out direction_ty;
    o_mode     : out mode_ty;
    o_row      : out std_logic_vector(7 downto 0);
    o_col      : out std_logic_vector(7 downto 0);
   
    debug_switch	: in	std_logic_vector(15 downto 0);	 
    debug_num_0 	: out	std_logic_vector(3 downto 0);
    debug_num_1		: out	std_logic_vector(3 downto 0);
    debug_num_2		: out	std_logic_vector(3 downto 0);
    debug_num_3		: out	std_logic_vector(3 downto 0);
    debug_num_4		: out std_logic_vector(3 downto 0);
    debug_num_5		: out std_logic_vector(3 downto 0)
  );
end entity kirsch;

architecture main of kirsch is
  --Signals
  signal col_pos, row_pos : std_logic_vector(7 downto 0);
  signal a, b, c, d, e, f, g, h, i : std_logic_vector(7 downto 0);
  signal valid: std_logic_vector(7 downto 0);		
  signal pros: std_logic_vector(7 downto 0);
  signal state: states;

  signal all_rows : unsigned(3 downto 0);
  signal count : unsigned(7 downto 0);
  signal index : unsigned(7 downto 0);

  signal one_hot :  std_logic_vector(2 downto 0);
  signal o_m0_data : std_logic_vector(7 downto 0);
  signal o_m1_data : std_logic_vector(7 downto 0);
  signal o_m2_data : std_logic_vector(7 downto 0);
  
--Signals STAGE 1
  signal reg0, reg1 : unsigned(8 downto 0);

--Signals STAGE 2
  -- TODO: reg2 ???
  signal reg2 : unsigned(8 downto 0);
  signal reg3 : unsigned(8 downto 0);
  signal reg4 : unsigned(9 downto 0);

--Signals STAGE 3
  signal reg5 : unsigned(9 downto 0);
  
--Signals STAGE 4
  signal reg6 : unsigned(12 downto 0);

begin  
  m0 : entity work.mem(main) port map (
    clock => clk,
    wren => i_valid and one_hot(0),
    address => index,
    data => std_logic_vector(i_pixel),
    q => o_m0_data
  );
  m1 : entity work.mem(main) port map (
    clock => clk,
    wren => i_valid and one_hot(1),
    address => index,
    data => std_logic_vector(i_pixel),
    q => o_m1_data
  );
  m2 : entity work.mem(main) port map (
    clock => clk,
    wren => i_valid and one_hot(2),
    address => index,
    data => std_logic_vector(i_pixel),
    q => o_m2_data
  );
  
  readData: process begin
    wait until rising_edge(clk);
    if i_valid then
      if index = to_unsigned(255, 8) then
        index <= to_unsigned(0, 8);
        all_rows <= all_rows + 1;
        --TODO:
        case(one_hot) is
          when "001" =>
            one_hot <= "010";
          when "010" =>
            one_hot <= "100";
          when "100" =>
            one_hot <= "001";
          when others =>
            one_hot <= one_hot;
        end case;
      else
        index <= index + 1;
      end if;
    end if;
  end process;

  updateMatrix: process begin
    wait until rising_edge(clk);
    if (i_valid = '1') then
      a <= b;
      h <= i;
      g <= f;
      b <= c;
      i <= d;
      f <= e;
      -- Maybe move this out of the process
      c <= std_logic_vector(o_m0_data) when one_hot(2) else std_logic_vector(o_m1_data) when one_hot(0) else std_logic_vector(o_m2_data);
      d <= std_logic_vector(o_m0_data) when one_hot(1) else std_logic_vector(o_m1_data) when one_hot(2) else std_logic_vector(o_m2_data);
      e <= i_pixel;
    end if;
  end process;

  stage1: process begin
    wait until rising_edge(clk);
    if (all_rows >= 2 and index >= 2) then      --might have to adjust indices
      case(state) is
        when Set1 =>
          reg0 <= resize(unsigned(h), 9) + resize(unsigned(a), 9);
          reg1 <= resize(unsigned(b), 9);
          if g > b then
            reg1 <= resize(unsigned(g), 9);
          end if;
          state <= Set2;
        when Set2 =>
          reg0 <= resize(unsigned(b), 9) + resize(unsigned(c), 9);
          reg1 <= resize(unsigned(a), 9);
          if d > a then
            reg1 <= resize(unsigned(d), 9);
          end if;
          state <= Set3;
        when Set3 =>
          reg0 <= resize(unsigned(d), 9) + resize(unsigned(e), 9);
          reg1 <= resize(unsigned(c), 9);
          if f > c then
            reg1 <= resize(unsigned(f), 9);
          end if;
          state <= Set4;
        when Set4 =>
          reg0 <= resize(unsigned(f), 9) + resize(unsigned(g), 9);
          reg1 <= resize(unsigned(e), 9);
          if h > e then
            reg1 <= resize(unsigned(h), 9);
          end if;
          state <= Set1;
        when others =>
          reg0 <= reg0;
          reg1 <= reg1;
      end case;
    end if;
  end process;

  stage2: process begin
    wait until rising_edge(clk);
    reg4 <= resize(reg0, 10) + resize(reg1, 10);
    case(state) is
      when Set1 =>
        reg3 <= (reg0 sll 1) + ("0" + reg0);
      when others =>
        reg3 <= reg3 + (reg0 sll 1) + ("0" + reg0);
    end case;
  end process;

  stage3: process begin
    wait until rising_edge(clk);
    case(state) is
      when Set1 =>
        reg5 <= to_unsigned(0, 10);
      when others =>
        if reg5 < reg4 then
          reg5 <= reg4;
        else
          reg5 <= reg5;
        end if;
      end case;
  end process;

  stage4: process begin
    wait until rising_edge(clk);
    case (state) is 
      when Set3 =>
        -- reg7 <= reg3;
        o_valid <= '1';
        if (reg3 - (reg5 sll 3)) > to_unsigned(384, 13) then
          --reg6 <= '1';
          o_edge <= '1';
        else
          o_edge <= '0';
        end if;
      when others =>
        o_valid <= '0';
        o_edge <= '0';
    end case;
  end process;

  output_reset: process(clk) begin
    if o_valid then
      o_valid <= '0';
    else
      o_valid <= o_valid;
    end if;
    -- TODO: reset after finishing one image
  end process;

end architecture;
