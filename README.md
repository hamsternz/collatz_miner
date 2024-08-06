# collatz_miner
A single file FPGA project to 'mine' conter-examples for the Collatz Conjecture, for the Basys3.

Just a bit of fun really!

## The Colltaz conjecture
It's an unsolved/unproven maths problem. 

Take any number

* If it even then divide by two
* If it is odd then multiply by three and add one
* Repeat these two steps on the current result.
  
The conjecture is that if you repeat this over and over, ALL numbers will end up becoming one. 

Apparently it is known to about 2x10^20 that this is true, but it has not been proven for all numbers

## The miner
It's a VHDL file and XCF file that you can configure with the number of hex digits you are
willing to use, and the initial starting point for the search, and it will print progress
to the RS232 port. 

LED15 will blink to show it is alive, and LED0 will show if an overflow has occured in the math.

There are a three signals (finished, finished_value and finished_iterations) that can be used in 
simulation to verify that it is generating the correct sequence.
