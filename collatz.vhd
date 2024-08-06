library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library xpm;
use xpm.vcomponents.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity collatz is
    generic (
        DIGITS        : natural := 40;  -- How many hex digits
        BAUD          : natural := 9600;
        SLOW_CLK_FREQ : natural := 25000000
    );
    Port ( 
        clk       : in  STD_LOGIC;
        is_loop   : out STD_LOGIC := '0';
        overflow  : out STD_LOGIC := '0';
        blink     : out STD_LOGIC := '0';
        serial_tx : out STD_LOGIC := '0'
    );
end collatz;

architecture Behavioral of collatz is
    signal clk_fast            : std_logic := '0';
    signal clk_slow            : std_logic := '0';
    signal clk_fb              : std_logic;
        
    signal blink_counter       : unsigned(27 downto 0)         := (others => '0');
    signal counter             : unsigned(digits*4-1 downto 0) := (1 => '1', others => '0'); -- Should be odd as a starting point
    
    signal counter_cdc         : std_logic_vector(digits*4-1 downto 0);

    signal value               : unsigned(digits*4-1 downto 0) := (others => '0');
    signal iterations          : unsigned(31 downto 0)         := to_unsigned(2,32);
    signal active              : std_logic := '0';

    signal busy_count          : unsigned(15 downto 0) := (others => '0'); 
    signal baud_gen            : unsigned(27 downto 0) := (others => '0');
    signal baud_tick           : std_logic             := '0';
    signal big_shift           : std_logic_vector((digits+2)*10 downto 0) := (others => '1');    

    -- These are just for simulation, so you can see that the design is working as intended.
    signal finished            : std_logic := '0';
    signal finished_value      : unsigned(digits*4-1 downto 0) := to_unsigned(2, digits*4);
    signal finished_iterations : unsigned(31 downto 0)         := (others => '0');
begin

---------------------------------------------
-- Fast clock clock domain doing calculation
---------------------------------------------
process(clk_fast)
    begin
        if rising_edge(clk_fast) then
            -- Show that the logic is working
            blink_counter <= blink_counter+1;
            blink <= blink_counter(blink_counter'high);

            finished            <= '0';
            finished_iterations <= (others => '0');
            finished_value      <= (others => '0');

            if active = '0' then
                value       <= counter;
                iterations  <= (others => '0');
                counter     <= counter + 2;
                active      <= '1';
            else
                if iterations(iterations'high) = '1' then
                    is_loop <= '1';
                end if;
                
                if value = 1 then
                    finished            <= '1';
                    finished_iterations <= iterations;
                    active              <= '0';
                else
                    if value(0) = '1' then
                        -- Calculate x <= 3 * x + 1, which will be an even number
                        -- followed wiht x = x / 2
                        -- Doing 2 iterations in one cycle
                        value <= value + value(value'high downto 1) + 1; 
                        iterations <= iterations + 2;
                    else
                        value <= "0" & value(value'high downto 1); 
                        iterations <= iterations + 1;
                    end if;
                end if;
                -- Detect if we run out of bits
                if value(value'high) = '1' then
                    overflow <= '1';
                end if;
            end if;
        end if;
    end process;

---------------------------------------------
-- Low speed clock domain doing comms
---------------------------------------------
process(clk_slow) 
    begin
        if rising_edge(clk_slow) then
            if baud_gen < BAUD then
                baud_gen  <= baud_gen + SLOW_CLK_FREQ - BAUD;
                baud_tick <= '1';  
            else
                baud_gen  <= baud_gen - BAUD;  
                baud_tick <= '0';  
            end if;

            if baud_tick = '1' then
                serial_tx <= big_shift(0);
                big_shift <= '1' & big_shift(big_shift'high downto 1);
                busy_count <= busy_count -1;
            end if;
            
            if busy_count = 0 then
                for i in 0 to digits-1 loop
                    case counter_cdc(i*4+3 downto i*4) is
                        when "0000" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"30" & "0"; 
                        when "0001" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"31" & "0";
                        when "0010" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"32" & "0"; 
                        when "0011" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"33" & "0";
                        when "0100" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"34" & "0";
                        when "0101" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"35" & "0";
                        when "0110" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"36" & "0";
                        when "0111" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"37" & "0";
                        when "1000" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"38" & "0";
                        when "1001" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"39" & "0";
                        when "1010" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"41" & "0";
                        when "1011" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"42" & "0";
                        when "1100" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"43" & "0";
                        when "1101" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"44" & "0";
                        when "1110" => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"45" & "0";
                        when others => big_shift((digits-1-i)*10+9 downto (digits-1-i)*10) <= "1" & x"46" & "0";
                    end case;                    
                end loop;
                big_shift(10*(digits+0)+9 downto 10*(digits+0)) <= "1" & x"0A" & "0"; -- CR  
                big_shift(10*(digits+1)+9 downto 10*(digits+1)) <= "1" & x"0D" & "0"; -- LF
                busy_count <= to_unsigned(9600, busy_count'length); 
            end if;
        end if;        
    end process;
   
MMCME2_BASE_inst : MMCME2_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming (OPTIMIZED, HIGH, LOW)
      CLKFBOUT_MULT_F => 9.0,    -- Multiply value for all CLKOUT (2.000-64.000).
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB (-360.000-360.000).
      CLKIN1_PERIOD => 0.0,      -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT1_DIVIDE => 36,
      CLKOUT2_DIVIDE => 1,
      CLKOUT3_DIVIDE => 1,
      CLKOUT4_DIVIDE => 1,
      CLKOUT5_DIVIDE => 1,
      CLKOUT6_DIVIDE => 1,
      CLKOUT0_DIVIDE_F => 6.25,   -- Divide amount for CLKOUT0 (1.000-128.000).
      -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT6_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      CLKOUT6_PHASE => 0.0,
      CLKOUT4_CASCADE => FALSE,  -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      DIVCLK_DIVIDE => 1,        -- Master division value (1-106)
      REF_JITTER1 => 0.0,        -- Reference input jitter in UI (0.000-0.999).
      STARTUP_WAIT => FALSE      -- Delays DONE until MMCM is locked (FALSE, TRUE)
   )
   port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0   => clk_fast,
      CLKOUT0B  => open,
      CLKOUT1   => clk_slow,  
      CLKOUT1B  => open,
      CLKOUT2   => open,  
      CLKOUT2B  => open,
      CLKOUT3   => open,  
      CLKOUT3B  => open,
      CLKOUT4   => open,
      CLKOUT5   => open,
      CLKOUT6   => open,
      CLKFBOUT  => clk_fb,  
      CLKFBOUTB => open,
      LOCKED    => open,
      CLKIN1    => clk,
      PWRDWN    => '0',
      RST       => '0',
      CLKFBIN   => clk_fb
   );

xpm_cdc_array_single_inst : xpm_cdc_array_single
   generic map (
      DEST_SYNC_FF => 2,          -- DECIMAL; range: 2-10
      INIT_SYNC_FF => 0,          -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      SIM_ASSERT_CHK => 0,        -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG => 1,         -- DECIMAL; 0=do not register input, 1=register input
      WIDTH => counter_cdc'length -- DECIMAL; range: 1-1024
   )
   port map (
      src_clk  => clk_fast,   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
      src_in   => std_logic_vector(counter),
      dest_clk => clk_slow,
      dest_out => counter_cdc
   );

end Behavioral;
