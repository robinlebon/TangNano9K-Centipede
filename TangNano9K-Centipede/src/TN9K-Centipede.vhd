---------------------------------------------------------------------------------
--                          Centipede - Tang Nano 9k
--                              Code from Brad
--
--                         Modified for Tang Nano 9k 
--                            by pinballwiz.org 
--                               02/09/2025
---------------------------------------------------------------------------------
-- Keyboard inputs :
--   5 : Add coin
--   1 : Start 1 player
--   RIGHT arrow : Move Right
--   LEFT arrow  : Move Left
--   UP arrow : Move Up
--   DOWN arrow  : Move Down
--   LCtrl : Fire
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------
entity centipede_tn9k is
port(
	Clock_27    : in std_logic;
    I_RESET     : in std_logic;
	O_VIDEO_R	: out std_logic_vector(2 downto 0); 
	O_VIDEO_G	: out std_logic_vector(2 downto 0);
	O_VIDEO_B	: out std_logic_vector(1 downto 0);
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;
	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
    ps2_clk     : in std_logic;
	ps2_dat     : inout std_logic;
 	led         : out std_logic_vector(5 downto 0) 
 );
end centipede_tn9k;
------------------------------------------------------------------------------
architecture struct of centipede_tn9k is

 signal clock_100 : std_logic;
 signal clock_36  : std_logic;
 signal clock_18  : std_logic;
 signal clock_12  : std_logic;
 signal clock_9   : std_logic;
 signal clock_6   : std_logic;
 --
 signal video_rgb   : std_logic_vector(8 downto 0);
 signal rgb_i       : std_logic_vector(7 downto 0);
 --
 signal h_sync     : std_logic;
 signal v_sync	   : std_logic;
 signal h_blank    : std_logic;
 signal v_blank	   : std_logic;

 signal hsync_x2   : std_logic;
 signal vsync_x2   : std_logic;
 --
 signal audio      : std_logic_vector(3 downto 0);
 signal audio_pwm  : std_logic;
 --
 signal reset      : std_logic;
 --
 signal kbd_intr        : std_logic;
 signal kbd_scancode    : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU   : std_logic_vector(8 downto 0);
 --
 constant CLOCK_FREQ    : integer := 27E6;
 signal counter_clk     : std_logic_vector(25 downto 0);
 signal clock_4hz       : std_logic;
 signal AD              : std_logic_vector(15 downto 0);
 -- 
 signal slot      	    : std_logic_vector(2 downto 0) := (others => '0');
 signal ledr      	    : std_logic_vector(4 downto 1) := (others => '0');
---------------------------------------------------------------------------
component centipede 
    port(
  clk_100mhz    : in std_logic;
  clk_12mhz     : in std_logic;
  reset         : in std_logic;
  playerinput_i : in std_logic_vector (9 downto 0);
  trakball_i    : in std_logic_vector (7 downto 0);
  joystick_i    : in std_logic_vector (7 downto 0);
  sw1_i         : in std_logic_vector (7 downto 0);
  sw2_i         : in std_logic_vector (7 downto 0);
  led_o         : out std_logic_vector (4 downto 1);
  rgb_o         : out std_logic_vector (8 downto 0);
  hsync_o       : out std_logic;
  vsync_o       : out std_logic;
  hblank_o      : out std_logic;
  vblank_o      : out std_logic;
  audio_o       : out std_logic_vector (3 downto 0);
  AD            : out std_logic_vector (15 downto 0)
    );
end component; 
---------------------------------------------------------------------------
component Gowin_rPLL
    port (
        clkout: out std_logic;
        clkin: in std_logic
    );
end component;
---------------------------------------------------------------------------
component Gowin_rPLL2
    port (
        clkout: out std_logic;
        clkin: in std_logic
    );
end component;
---------------------------------------------------------------------------
begin

    reset <= not I_RESET;
---------------------------------------------------------------------------
-- Clocks
Clock1: Gowin_rPLL
    port map (
        clkout => clock_100,
        clkin => Clock_27
    );
--
Clock2: Gowin_rPLL2
    port map (
        clkout => Clock_36,
        clkin => Clock_27
    );
---------------------------------------------------------------------------
-- Clocks Divide

process (clock_36)
begin

 if rising_edge(clock_36) then
  clock_12      <= '0';
  clock_18  <= not clock_18;

  if slot = "101" then
   slot <= (others => '0');
  else
		slot <= std_logic_vector(unsigned(slot) + 1);
  end if;   
	
	if slot = "100" or slot = "001" then clock_6 <= not clock_6; end if;
	if slot = "100" or slot = "001" then clock_12  <= '1'; end if;	

 end if;
end process;
-------------------------------------------------------------------------
process (clock_18)
begin
 if rising_edge(clock_18) then
  clock_9  <= not clock_9;
 end if;
end process;
---------------------------------------------------------------------------
centipede_inst : centipede
  port map (
 clk_100mhz => clock_100,
 clk_12mhz  => clock_12,
 reset      => reset,
 playerinput_i => (not joy_BBBBFRLDU(7) & '1' & '1' & "111" & not joy_BBBBFRLDU(6) & not joy_BBBBFRLDU(5) & not joy_BBBBFRLDU(8) & not joy_BBBBFRLDU(4)), -- 9 downto 0
 trakball_i => "11111111",
 joystick_i => (not joy_BBBBFRLDU(3) & not joy_BBBBFRLDU(2) & not joy_BBBBFRLDU(1) & not joy_BBBBFRLDU(0) & not joy_BBBBFRLDU(3) & not joy_BBBBFRLDU(2) & not joy_BBBBFRLDU(1) & not joy_BBBBFRLDU(0)), -- 7 downto 0
 sw1_i      => "01010100", -- credit minimum, difficulty, bonus, bonus, lives, lives, language, language
 sw2_i      => "00000010", -- coin, 1 play, no bonus coins
 led_o      => ledr, -- 4 downto 1
 rgb_o      => video_rgb, -- 8 downto 0
 hsync_o    => h_sync,
 vsync_o   	=> v_sync,
 hblank_o   => h_blank,
 vblank_o  	=> v_blank,
 audio_o    => audio, -- 3 downto 0
 AD         => AD
);
-------------------------------------------------------------------------
-- vga output

    rgb_i <= video_rgb(7 downto 0) when h_blank = '0' and v_blank = '0' else "00000000";

	O_HSYNC     <= hsync_x2;
	O_VSYNC     <= vsync_x2;
-------------------------------------------------------------------------
dblscan : entity work.line_doubler
  port map (
	clock_12mhz => clock_12,
	video_i => rgb_i,
	hsync_i => h_sync,
	vsync_i => v_sync,
	vga_r_o => O_VIDEO_R,
	vga_g_o => O_VIDEO_G,
	vga_b_o(2 downto 1) => O_VIDEO_B,
	hsync_o =>(hsync_x2),
	vsync_o =>(vsync_x2),
	scanlines => '0'
  );
------------------------------------------------------------------------------
-- get scancode from keyboard

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_9,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);
-----------------------------------------------------------------------------
-- translate scancode to joystick

joystick : entity work.kbd_joystick
port map (
  clk         => clock_9,
  kbdint      => kbd_intr,
  kbdscancode => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU  => joy_BBBBFRLDU 
);
-----------------------------------------------------------------------------
  u_dac : entity work.dac
    generic map(
      msbi_g => 3
    )
    port  map(
      clk_i   => clock_12,
      res_n_i => I_RESET,
      dac_i   => audio,
      dac_o   => audio_pwm
    );

  O_AUDIO_L <= audio_pwm;
  O_AUDIO_R <= audio_pwm;
------------------------------------------------------------------------------
-- debug

process(reset, clock_27)
begin
  if reset = '1' then
    clock_4hz <= '0';
    counter_clk <= (others => '0');
  else
    if rising_edge(clock_27) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(5 downto 0) <= not AD(9 downto 4);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;
------------------------------------------------------------------------
end struct;