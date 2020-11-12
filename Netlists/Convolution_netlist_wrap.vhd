library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;

entity convolution_net_wrap is
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
end entity;

Architecture CE_net_wrap of convolution_net_wrap is

 type array_2D is array(integer range <>) of std_logic_vector;

 signal img_rd_data_internal : array_2D(0 to (k_width*k_height)-1)(0 to 31);
 signal img_out_rd_data_internal : std_logic_vector(31 downto 0);

 component convolution_netlist
  port (
    clock             : in  STD_LOGIC;
    reset_n           : in  STD_LOGIC;
    krnl_data         : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    img_data          : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    \krnl_addr[0]\    : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    \krnl_addr[1]\    : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_addr[0]\     : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_addr[1]\     : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    krnl_buf_wr       : in  STD_LOGIC;
    img_buf_wr        : in  STD_LOGIC;
    img_loaded        : in  STD_LOGIC;
    krnl_loaded       : in  STD_LOGIC;
    conv_done         : out STD_LOGIC;
    \img_out_addr[0]\ : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_out_addr[1]\ : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_rd_data[0]\  : out STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_rd_data[1]\  : out STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_rd_data[2]\  : out STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_rd_data[3]\  : out STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_rd_data[4]\  : out STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_rd_data[5]\  : out STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_rd_data[6]\  : out STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_rd_data[7]\  : out STD_LOGIC_VECTOR ( 31 downto 0 );
    \img_rd_data[8]\  : out STD_LOGIC_VECTOR ( 31 downto 0 );
    img_out_rd_data   : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  end component;

begin

  process(all)
  begin
    for i in 0 to (k_width*k_height)-1 loop
      img_rd_data(i) <= to_integer(unsigned(img_rd_data_internal(i)));
    end loop;
  end process;

  img_out_rd_data <= to_integer(unsigned(img_out_rd_data_internal));

  CE : convolution_netlist
    port map(
    clock              => clock,
    reset_n            => reset_n,
    krnl_data          => std_logic_vector(to_unsigned(krnl_data,32)), 
    img_data           => std_logic_vector(to_unsigned(img_data,32)), 
    \krnl_addr[0]\     => std_logic_vector(to_unsigned(krnl_addr(0),32)), 
    \krnl_addr[1]\     => std_logic_vector(to_unsigned(krnl_addr(1),32)), 
    \img_addr[0]\      => std_logic_vector(to_unsigned(img_addr(0),32)), 
    \img_addr[1]\      => std_logic_vector(to_unsigned(img_addr(1),32)), 
    krnl_buf_wr        => krnl_buf_wr,
    img_buf_wr         => img_buf_wr, 
    img_loaded         => img_loaded,
    krnl_loaded        => krnl_loaded,
    conv_done          => conv_done,
    \img_out_addr[0]\  => std_logic_vector(to_unsigned(img_out_addr(0),32)),
    \img_out_addr[1]\  => std_logic_vector(to_unsigned(img_out_addr(1),32)),
    \img_rd_data[0]\   => img_rd_data_internal(0),
    \img_rd_data[1]\   => img_rd_data_internal(1),
    \img_rd_data[2]\   => img_rd_data_internal(2),
    \img_rd_data[3]\   => img_rd_data_internal(3),
    \img_rd_data[4]\   => img_rd_data_internal(4),
    \img_rd_data[5]\   => img_rd_data_internal(5),
    \img_rd_data[6]\   => img_rd_data_internal(6),
    \img_rd_data[7]\   => img_rd_data_internal(7),
    \img_rd_data[8]\   => img_rd_data_internal(8),
    img_out_rd_data    => img_out_rd_data_internal
    );


end architecture;