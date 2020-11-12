library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

package Convolution_pkg IS
--    TYPE integer_vector is ARRAY(integer RANGE <>) OF integer;
    TYPE array_2D is ARRAY(integer RANGE <>) OF std_logic_vector;
    TYPE array_3D is ARRAY(integer RANGE <>) OF array_2D;
end package;
package body Convolution_pkg IS
  --impure function rand_int(min_val, max_val : integer) return integer is
  --  variable seed1, seed2 : integer := 999;
  --  variable r : real;
  --begin
  --  uniform(seed1, seed2, r);
  --  return integer(round(r * real(max_val - min_val + 1) + real(min_val) - 0.5));
  --end function;
end package body;

-------------------------------------------------
--  ████████╗██████╗          ██████╗███████╗  --
--  ╚══██╔══╝██╔══██╗        ██╔════╝██╔════╝  --
--     ██║   ██████╔╝        ██║     █████╗    --
--     ██║   ██╔══██╗        ██║     ██╔══╝    --
--     ██║   ██████╔╝███████╗╚██████╗███████╗  --
--     ╚═╝   ╚═════╝ ╚══════╝ ╚═════╝╚══════╝  --
-------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;

use work.Convolution_pkg.all;

entity conv_eng_tb is
  generic (full_CE           : natural  := 0;  -- generates a 2D convolution engine that performs 1 entire convolution per cycle
           pixel_CE          : natural  := 1;  -- generates a 2D convolution engine that calculates 1 pixel per cycle
    	   i_width           : natural  := 32;  -- Image width
           i_height          : natural  := 32;  -- Image height 
           k_width           : natural  := 3;  -- kernel width
           k_height          : natural  := 3;  -- kernel height
           USE_CONV_NETLIST  : natural  := 1);
end conv_eng_tb;

architecture CE_TB of conv_eng_tb is

  constant pad_sz_w      : integer := (k_width-1)/2;
  constant pad_sz_h      : integer := (k_height-1)/2;
  constant i_width_real  : integer := i_width + 2*pad_sz_w;
  constant i_height_real : integer := i_height + 2*pad_sz_h;

  signal clock, reset_n : std_logic;
  signal krnl_data      : integer;
  signal img_data       : integer;
  signal krnl_addr      : integer_vector(0 to 1);
  signal img_addr       : integer_vector(0 to 1);
  signal krnl_buf_wr    : std_logic;
  signal img_buf_wr     : std_logic;

  signal conv_done        : std_logic;
  signal img_out_addr     : integer_vector (0 to 1);
  signal img_out_rd_Data  : integer;
  signal img_rd_data      : integer_vector (0 to (k_width*k_height)-1);
  signal new_img          : integer_vector (0 to (i_width*i_height)-1);

  signal img_loaded       : std_logic;
  signal krnl_loaded      : std_logic;
  signal img_x_count      : integer;
  signal img_y_count      : integer;
  signal krnl_x_count     : integer;
  signal krnl_y_count     : integer;

  component convolution 
    generic (full_CE       : natural;
    	     pixel_CE      : natural;
             i_width       : natural;
			 i_height      : natural;
    		 i_width_real  : natural;
             i_height_real : natural;
             k_width       : natural;
             k_height      : natural
             );
    port (clock, reset_n   : in std_logic;
          krnl_data        : in integer;
          img_data         : in integer;
          krnl_addr        : in integer_vector(0 to 1);
          img_addr         : in integer_vector(0 to 1);
          img_buf_wr       : in std_logic;
          krnl_buf_wr      : in std_logic;
          img_loaded       : in std_logic;
          krnl_loaded      : in std_logic;
          conv_done        : out std_logic;
          img_out_addr     : in  integer_vector(0 to 1);
          img_rd_data      : out integer_vector(0 to (k_width*k_height)-1);
          img_out_rd_Data  : out integer
          -- Output Read Signals
          --new_img_read_req : in  std_logic;
          --new_img_addr     : in  integer;
          --data_o           : out integer
          );

  end component;

 component convolution_net_wrap
    generic (full_CE       : natural;
    	     pixel_CE      : natural;
             i_width       : natural;
			 i_height      : natural;
    		 i_width_real  : natural;
             i_height_real : natural;
             k_width       : natural;
             k_height      : natural
             );
    port (clock, reset_n   : in std_logic;
          krnl_data        : in integer;
          img_data         : in integer;
          krnl_addr        : in integer_vector(0 to 1);
          img_addr         : in integer_vector(0 to 1);
          img_buf_wr       : in std_logic;
          krnl_buf_wr      : in std_logic;
          img_loaded       : in std_logic;
          krnl_loaded      : in std_logic;
          conv_done        : out std_logic;
          img_out_addr     : in  integer_vector(0 to 1);
          img_rd_data      : out integer_vector(0 to (k_width*k_height)-1);
          img_out_rd_data  : out integer
          );
  end component;

  signal period : Time := 10 ns;

  type krnl_memory is array (0 to k_width-1, 0 to k_height-1) of integer;
  type img_memory  is array (0 to i_width_real-1, 0 to i_height_real-1)  of integer;

  impure function rand_int(min_val, max_val : integer) return integer is
    variable seed1, seed2 : integer := 999;
    variable r : real;
  begin
    uniform(seed1, seed2, r);
    return integer(
      round(r * real(max_val - min_val + 1) + real(min_val) - 0.5));
  end function;

  --constant rand : integer := rand_int(0, 9);

  signal krnl: krnl_memory := (0 to k_width-1 => (0 to k_height-1 => 0));
  signal img: img_memory   := (0 to i_width_real-1 => (0 to i_height_real-1 => 0));

--  constant krnl: krl_memory := (
--            (1, 2, 1),
--            (2, 1, 2),
--            (1, 2, 1));
--
--  constant img: img_memory := (
--            (2, 2, 1, 1, 1),
--            (1, 1, 1, 1, 1),
--            (2, 2, 1, 1, 1),
--      	  (1, 1, 1, 1, 1),
--            (3, 3, 1, 1, 1));

begin

  clock_gen : process
  begin
    clock <= '0';
    wait for period/2;
    clock <= '1';
    wait for period/2;
  end process;

  reset_n <= '0' after 0 ns, '1' after 30 ns;

  process (clock, reset_n)
  begin
    if reset_n = '0' then
      krnl_buf_wr  <= '0';
      img_buf_wr   <= '0';
      img_loaded   <= '0';
      krnl_loaded  <= '0';
      img_x_count  <= 0;
      img_y_count  <= 0;
      krnl_x_count <= 0;
      krnl_y_count <= 0;
      for x in pad_sz_w to pad_sz_w+i_width-1 loop
        for y in pad_sz_h to pad_sz_h+i_height-1 loop
          img(x,y) <= x*y*rand_int(0,9);  -- initialize the matricies with psuedo randomness
        end loop;
      end loop;
      for x in 0 to k_width-1 loop
        for y in 0 to k_height-1 loop
          krnl(x,y) <= (x+y+1)*rand_int(0,9);  -- initialize the matricies with psuedo randomness
        end loop;
      end loop;
    elsif(clock' event and clock='1')then
      if (img_x_count = i_height_real-1 and img_y_count = i_width_real-1) then
        img_loaded <= '1';
      else
        if img_x_count = i_width_real - 1 then
          img_x_count <= 0;
          img_y_count <= img_y_count + 1;
        else
          img_x_count <= img_x_count + 1;
        end if;
      	img_buf_wr <= '1';
      end if;
	  img_addr <= (img_y_count,img_x_count);
	  img_data <= img(img_y_count,img_x_count);
      if (krnl_x_count = k_height-1 and krnl_y_count = k_width-1) then
        krnl_loaded <= '1';
      else
        if krnl_x_count = k_width - 1 then
          krnl_x_count <= 0;
          krnl_y_count <= krnl_y_count + 1;
        else
          krnl_x_count <= krnl_x_count + 1;
        end if;
      	krnl_buf_wr <= '1';
      end if;
	  krnl_addr <= (krnl_y_count,krnl_x_count);
	  krnl_data <= krnl(krnl_y_count,krnl_x_count);
    end if;
  end process;

  CONV_ENG_RTL : if USE_CONV_NETLIST = 0 generate
  CE : convolution
    generic map(
    	   full_CE       => full_CE,
           pixel_CE      => pixel_CE,
    	   i_width       => i_width,
		   i_height      => i_height,
    	   i_width_real  => i_width_real,
           i_height_real => i_height_real,
           k_width       => k_width,
           k_height      => k_height)
    port map(
    	clock            => clock,
    	reset_n          => reset_n,
        krnl_data        => krnl_data, 
    	img_data         => img_data, 
    	krnl_addr        => krnl_addr, 
    	img_addr         => img_addr, 
    	krnl_buf_wr      => krnl_buf_wr, 
    	img_buf_wr       => img_buf_wr, 
        img_loaded       => img_loaded,
        krnl_loaded      => krnl_loaded,
        conv_done        => conv_done,
        img_out_addr     => img_out_addr,
        img_rd_data      => img_rd_data,
        img_out_rd_Data  => img_out_rd_Data
    );
  end generate CONV_ENG_RTL;

  CONV_ENG_NETLIST : if USE_CONV_NETLIST = 1 generate
  CE : convolution_net_wrap
    generic map(
    	 full_CE       => full_CE,
         pixel_CE      => pixel_CE,
    	 i_width       => i_width,
		 i_height      => i_height,
    	 i_width_real  => i_width_real,
         i_height_real => i_height_real,
         k_width       => k_width,
         k_height      => k_height)
    port map(
    	clock            => clock,
    	reset_n          => reset_n,
        krnl_data        => krnl_data, 
    	img_data         => img_data, 
    	krnl_addr        => krnl_addr, 
    	img_addr         => img_addr, 
    	krnl_buf_wr      => krnl_buf_wr, 
    	img_buf_wr       => img_buf_wr, 
        img_loaded       => img_loaded,
        krnl_loaded      => krnl_loaded,
        conv_done        => conv_done,
        img_out_addr     => img_out_addr,
        img_rd_data      => img_rd_data,
        img_out_rd_Data  => img_out_rd_Data
    );
  end generate CONV_ENG_NETLIST;
   

end CE_TB;

---------------------------------------------------------------------------------------------------
--   ██████╗ ██████╗ ███╗   ██╗██╗   ██╗       ███████╗███╗   ██╗ ██████╗ ██╗███╗   ██╗███████╗  --
--  ██╔════╝██╔═══██╗████╗  ██║██║   ██║       ██╔════╝████╗  ██║██╔════╝ ██║████╗  ██║██╔════╝  --
--  ██║     ██║   ██║██╔██╗ ██║██║   ██║       █████╗  ██╔██╗ ██║██║  ███╗██║██╔██╗ ██║█████╗    --
--  ██║     ██║   ██║██║╚██╗██║╚██╗ ██╔╝       ██╔══╝  ██║╚██╗██║██║   ██║██║██║╚██╗██║██╔══╝    --
--  ╚██████╗╚██████╔╝██║ ╚████║ ╚████╔╝███████╗███████╗██║ ╚████║╚██████╔╝██║██║ ╚████║███████╗  --
--   ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝ ╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝  --
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.Convolution_pkg.all;


entity convolution is
    generic (full_CE       : natural  := 1;  -- generates a 2D convolution engine that performs 1 entire convolution per cycle
    	     pixel_CE      : natural  := 0;  -- generates a 2D convolution engine that calculates 1 pixel per cycle
    	     i_width       : natural  := 4;  -- Image width
             i_height      : natural  := 4;  -- Image height 
    		 i_width_real  : natural  := 6; -- Actual image width with zeropadded confines (padding size changes based on kernel dimensions)
             i_height_real : natural  := 6; -- Actual image width with zeropadded confines (padding size changes based on kernel dimensions)
             k_width       : natural  := 3;  -- kernel width
             k_height      : natural  := 3   -- kernel height
             );
    port (clock, reset_n   : in  std_logic;
    	  krnl_data        : in  integer;
    	  img_data         : in  integer;
          krnl_addr        : in  integer_vector(0 to 1);
          img_addr         : in  integer_vector(0 to 1);
    	  krnl_buf_wr      : in  std_logic;
    	  img_buf_wr       : in  std_logic;
          img_loaded       : in  std_logic;
          krnl_loaded      : in  std_logic;
          conv_done        : out std_logic;
          img_out_addr     : in  integer_vector(0 to 1);
          img_rd_data      : out integer_vector(0 to (k_width*k_height)-1);
          img_out_rd_Data  : out integer
          -----------------------------------------
          -- Output Read Signals
          --new_img_read_req : in  std_logic;
          --new_img_addr     : in  integer;
          --data_o           : out integer
          );
end convolution;

architecture conv_eng of convolution is

type krnl_memory is array (0 to k_width-1, 0 to k_height-1) of integer;
type img_memory  is array (0 to i_width_real-1, 0 to i_height_real-1)  of integer;
type integer_map is array (integer range <>) of integer_vector;

signal krnl : krnl_memory;
signal img : img_memory; -- used by the full CE
signal img_bram : integer_map(0 to (k_width*k_height)-1)(0 to (i_width_real*i_height_real)-1);  -- used for the pixel CE to generate brams
signal new_img  : integer_vector (0 to (i_width*i_height) -1);
--signal img_rd_data : integer_vector(0 to (k_width*k_height)-1);
signal img_addr_internal : array_2D(0 to 1)(0 to 7);
signal img_out_addr_internal : array_2D(0 to 1)(0 to 7);


signal img_ld_lat  : std_logic;
signal krnl_ld_lat : std_logic;
signal img_rd_ready  : std_logic;
signal krnl_rd_ready : std_logic;

signal img_x_count     : integer;
signal img_y_count     : integer;
signal img_x_count_lat : integer;
signal img_y_count_lat : integer;
signal img_x_count_wr  : integer; 
signal img_y_count_wr  : integer; 


signal img_rd_data_wire : integer_vector(0 to (k_width*k_height)-1);


signal pixel_result : integer;

attribute dont_touch : string;
attribute dont_touch of new_img : signal is "true";

attribute ram_style : string;
attribute ram_style of img_bram : signal is "block";
attribute ram_style of new_img : signal is "block";


BEGIN   

  process(clock, reset_n)
  begin
    if reset_n = '0' then
      img_ld_lat      <= '0';
      krnl_ld_lat     <= '0';
      img_rd_ready    <= '0';
      krnl_rd_ready   <= '0';
      img_x_count_lat <= 0;
      img_y_count_lat <= 0;
      img_x_count_wr  <= 0; 
      img_y_count_wr  <= 0; 
    elsif (clock' event and clock = '1') then
      img_ld_lat      <= img_loaded;
      krnl_ld_lat     <= krnl_loaded;
      img_rd_ready    <= img_ld_lat;
      krnl_rd_ready   <= krnl_ld_lat;
      img_x_count_lat <= img_x_count;
      img_y_count_lat <= img_y_count;
      img_x_count_wr  <= img_x_count_lat;
      img_y_count_wr  <= img_y_count_lat;
    end if;
  end process;

  process(clock)
    begin
    if(clock' event and clock='1')then
      if krnl_buf_wr = '1' then
        krnl(krnl_addr(1),krnl_addr(0)) <= krnl_data;
      end if;
    end if;
    --if new_img_read_req = '1' and conv_done = '1' then
    --  data_o <= new_img(new_img_addr);
    --end if;
  end process;

-------------------------------------------------------------
--  ███████╗██╗   ██╗██╗     ██╗          ██████╗███████╗  --
--  ██╔════╝██║   ██║██║     ██║         ██╔════╝██╔════╝  --
--  █████╗  ██║   ██║██║     ██║         ██║     █████╗    --
--  ██╔══╝  ██║   ██║██║     ██║         ██║     ██╔══╝    --
--  ██║     ╚██████╔╝███████╗███████╗    ╚██████╗███████╗  --
--  ╚═╝      ╚═════╝ ╚══════╝╚══════╝     ╚═════╝╚══════╝  --
-------------------------------------------------------------


  full_CE_gen : if full_CE = 1 generate
  process (clock)
    variable sum :integer 	:= 0;
    variable n_i_width_real:integer  := i_width_real -(k_width-1);
    variable n_i_hight_real:integer  := i_height_real-(k_height-1);
    begin
    if(clock' event and clock='1')then
      if img_ld_lat = '1' and krnl_ld_lat = '1' then
        for y in 0 to (n_i_hight_real-1) loop
	      for x in 0 to (n_i_width_real-1) loop
	        sum :=0;
	        for k_r in 0 to (k_height-1) loop
		      for k_c in 0 to (k_width-1) loop
		        sum := sum + img((y+k_r),(x+k_c)) * krnl(k_r,k_c); 	
		      end loop;
	        end loop;
	        new_img(y*(n_i_width_real)+x) <= sum;
	      end loop;
        end loop;
      end if;
    end if;
  end process;

  img_out_addr_internal(0) <= std_logic_vector(to_unsigned(img_out_addr(0),8));
  img_out_addr_internal(1) <= std_logic_vector(to_unsigned(img_out_addr(1),8));

   process (clock)
    begin
    if(clock' event and clock='1')then
      img_out_rd_Data <= new_img(to_integer(unsigned(img_out_addr_internal(0)))*i_width_real+to_integer(unsigned(img_out_addr_internal(1))));
    end if;
  end process;

  process(clock)
    begin
    if(clock' event and clock='1')then
      if img_buf_wr = '1' then
        img(img_addr(1),img_addr(0)) <= img_data;
      end if;
    end if;
  end process;

  end generate full_CE_gen;


---------------------------------------------------------------
--  ██████╗ ██╗██╗  ██╗███████╗██╗          ██████╗███████╗  --
--  ██╔══██╗██║╚██╗██╔╝██╔════╝██║         ██╔════╝██╔════╝  --
--  ██████╔╝██║ ╚███╔╝ █████╗  ██║         ██║     █████╗    --
--  ██╔═══╝ ██║ ██╔██╗ ██╔══╝  ██║         ██║     ██╔══╝    --
--  ██║     ██║██╔╝ ██╗███████╗███████╗    ╚██████╗███████╗  --
--  ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝     ╚═════╝╚══════╝  --
---------------------------------------------------------------

  pixel_CE_gen : if pixel_CE = 1 generate

  process (clock, reset_n)
    variable sum             : integer  := 0;
    variable n_i_width_real  : integer  := i_width_real -(k_width-1);
    variable n_i_height_real : integer  := i_height_real-(k_height-1);
    begin
    if reset_n = '0' then
      conv_done   <= '0';
      img_x_count <= 0;
      img_y_count <= 0;
    elsif(clock' event and clock='1')then
      if img_ld_lat = '1' and krnl_ld_lat = '1' then
        if (img_x_count = i_height - 1 and img_y_count = i_width - 1) then
          conv_done <= '1';
        else
          if img_x_count = i_width - 1 then
            img_x_count <= 0;
            img_y_count <= img_y_count + 1;
          else
            img_x_count <= img_x_count + 1;
          end if;
        end if;
      end if;
      if img_rd_ready = '1' and krnl_rd_ready = '1' then
		sum :=0;
		for k_r in 0 to (k_height-1) loop
		  for k_c in 0 to (k_width-1) loop
		    --sum := sum + img((img_y_count+k_r),(img_x_count+k_c)) * krnl(k_r,k_c);
		    sum := sum + img_rd_data(k_r*k_width+k_c) * krnl(k_r,k_c); 	
		  end loop;
		end loop;
		pixel_result <= sum;
		--new_img(img_y_count_lat*(i_width)+img_x_count_lat) <= sum;
      end if;
    end if;
  end process;

  img_addr_internal(0) <= std_logic_vector(to_unsigned(img_addr(0),8));
  img_addr_internal(1) <= std_logic_vector(to_unsigned(img_addr(1),8));

  img_out_addr_internal(0) <= std_logic_vector(to_unsigned(img_out_addr(0),8));
  img_out_addr_internal(1) <= std_logic_vector(to_unsigned(img_out_addr(1),8));

   process (clock)
    begin
    if(clock' event and clock='1')then
      if img_rd_ready = '1' then
		new_img(img_y_count_wr*(i_width)+img_x_count_wr) <= pixel_result;
      end if;
      img_out_rd_Data <= new_img(to_integer(unsigned(img_out_addr_internal(0)))*i_width_real+to_integer(unsigned(img_out_addr_internal(1))));
    end if;
  end process;

  bank_r :for k_r in 0 to 2 generate
  bank_c :for k_c in 0 to 2 generate
    source_img : process(clock)
    begin
      if(clock'event and clock='1')then
        if img_buf_wr = '1' then
          --img(img_addr(1),img_addr(0)) <= img_data;
          img_bram(k_r*k_width+k_c)((to_integer(unsigned(img_addr_internal(0)))*i_width_real)+to_integer(unsigned(img_addr_internal(1)))) <= img_data; -- here we make the 2D address (y,x) to index a 1D array by doing this (y*x_width + x) 
        end if;
  	    img_rd_data(k_r*k_width+k_c) <= img_bram(k_r*k_width+k_c)(((img_y_count+k_r)*i_width_real)+(img_x_count+k_c));
      end if;
    end process;
  end generate;
  end generate;

  end generate;

end conv_eng;