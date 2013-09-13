# Clocking and Timers #

@inlinetodo(Write Clocking and timer intro)

## Clocking ##

@inlinetodo("Paragraph about clocking being a tradeoff between processing
power and power consumptions, and segue into LPC stuff")

Clocks in the LPC all derive from one of three oscillators. 

Main Oscillator

  : This is the usual clock source for the LPC and runs at 12MHz. 

Internal RC Oscillator

  : This is driven by an internal RC circuit at 4MHz, and is the
    clock the LPC uses when it's reset. Usually software will 
    later switch to the Main Oscillator. 

Real Time Clock (RTC) Oscillator

  : This is a 32.768 KHz Oscillator that powers the real time clock.
    Because of the precisely chosen frequency, the clock can increment
    a 32 bit counter on every tick, and overflow once a second. 

Each of these clocks can be used as a cpu clock, or with the help
of a _Phase Locked Loop (PLL)_ generate a much faster CPU clock, up to the
LPC's limit of 120MHz. 

Before we can get into how to set the LPC's clock, there are two components
you need to understand: Clock Dividers, and Phase Locked Loops. 

### Clock Dividers ###

@smallfigure("Clock Divider Block Diagram",assets/Clock-Divider-Diagram.eps,0.95)

_Clock Dividers_ are an integral part of any complex clocking system.
@@
They allow you to turn a single precisely timed clock signal into another
running an integer multiple slower. 

Internally they have two registers, a counter register, and a factor 
register. 
@@
The factor register stores the amount by which the input signal is slowed
down, and is usually user modifiable. 

During operation, there is an edge detector, which will trigger two events
whenever it sees a rising or falling edge on the input signal. 

  1. It will test if the value in the factor register is equal to the value
     of the counter register. 
  2. It will increment the counter register. 

Then, if the equality test was sucessful it will two more things. 

  3. Reset the counter register to 0.
  4. Toggle the state of the output signal, switching low to high and vice
     versa.

If the number in the factor register is $F$, then the period of the output signal
will be $F +1$ the period of the input signal, and the frequency will be divided
by the same amount. 

@table("Clock Divider Timing Example",assets/Divider-Timing.tikz)

### Phase Locked Loops ###

A PLL is a special circuit which can detect the phase 
of an incoming signal and output a signal with a different related
phase. 
@@
The PLLs inside our LPC are acting as clock multipliers, devices
which take the signal of the input frequency and output a signal that
is some multiple of that frequency. 

@figure("PLL Block Diagram",assets/PLL-Block-Diagram.eps)

@inlinetodo("Find way to say 'The PLL is given an input signal at frequency
F and a multiple M, and wants to generate a signal with a frequency FM.
This is how the PLL does that' without looking like an idiot")

@todo("This para needs restructuring to be more coherent")
Inside the PLL there is a _Current Controlled Oscillator (CCO)_  which
generates a signal at some frequency that's close to the target.
@@
Because of the error inherent in any such system, it cannot be a perfect
multiple of that input frequency. 
@@
So, the signal from the CCO is divided by the target multiple, to get a 
signal that approximates the input signal. 
@@
There is then a _Phase Frequency Detector (PFD)_ which looks at the two
incoming signals, the original input and the divided approximation, and 
determines the difference in their phases. 
@@
This difference is, in effect, an error term which can tell the CCO 
whether it's running ahead of the input, or behind.
@@
This error term is then used to modulate the CCO, making it run slower
if the approximation is ahead of the input, and faster if it's behind.
@todo("Find some way to make it clear that the PLL internal divider determines
how much the PLL \textit{multiplies} the input frequency")

@table("PLL Error Correction",assets/PLL-Correction.tikz)

The net effect is that the CCO becomes locked to the input signal, repeatedly
correcting itself so that it is running at the target speed. 

### Calculating Clock Speed ###

@smallfigure("Cpu Clock Generation Diagram",assets/Clock-Settings.eps,0.95)

Figuring out your current clock speed involves looking at your settings and 
calculating a number of intermediate clock stages.

`sysclk` 

  : This can be connected to any of the core oscillators on the LPC, so it
    can be 12MHz if connected to `osc_clk`, 4MHz if connected to `irc_osc`
    or 32.7 KHz if connected to `irc_osc`. 

`pll0clk`

  : This is the output frequency of PLL0, and must be between 275 MHz and
    550MHz.

If you let,  

  - $N = 1 + \text{the value in the PLL0 N-Divider's factor register}$
  - $M = 1 + \text{the value in the PLL0 internal clock divider's factor register}$
  - $F_{in} = \text{the value of }\mathtt{sysclk}$

then 

  - $\mathtt{pll0clk} = (2 \times M \times F_{in}) / N$.

The extra factor of $2$ comes from an extra internal divider in PLL0, which
makes sure the output frequency is within the valid range. 

`pllclk`

  : This is the output of the CPU PLL Selector and can be set to either
    `sysclk` or `pll0clk`

`cclk`

  : This is your final system clock, and is `pllclk` divided by the CPU 
    Clock Divider, this can be at most 120 MHz. 

### Working Backwards ###

Let's say we have a target clock speed we want to calculate, how do we do it? 

First, our target frequency `cclk` has to be less than or equal to a 120mHz.
@@
Working backwards, we can see that immediately before getting our target 
frequency, we divide it using the CPU clock divider. 
@@
The CPU Clock Divider's factor register can store an 8 bit value, meaning 
that we can multiply our current frequency by an integer between 1 and 256
to get the frequency before the clock divider, namely  `pllclk`.

If our target `cclk` is a factor of either 12Mhz, 4MHz or 32.7 KHz, we can 
bypass the entire PLL subsystem, and just use one of the original oscillators.
@@
So if there exists some number $D$ between 1 and 256 such that our target
$\mathtt{cclk} =\mathtt{sysclk} / D$, we can set the CPU Clock divider to 
that value, connect sysclk to the correct oscillator, and bypass PLL0.

If our target frequency isn't so convenient, we need to figure out 
what frequency PLL0 should output. 
@@
Here we should note that PLL0 must output a frequency between 275MHz and
550Mhz.
@@
So we need to find some $D$ such that 
$275\mathrm{MHz} \leq D \times \mathtt{cclk} \leq 550\mathrm{MHz}$.
@@
A lower $D$ is better, since the faster the PLL is actually running,
the more energy it'll consume. 
@@
Once you have a valid $D$, then you know that `pll0clk` has to equal
$D \times \mathtt{cclk}$.

Once we know what PLL0 is going to output we should figure out what
the internal dividers should be set to, and which oscillator we should
use. 
@@
Again, both the PLL N-Divider, and its internal M-Divider have 8 bit 
factor registers, 


### Making Changes ###

## Timers ##

### Basic Description ###

### Speed Settings ###

### Match Registers ###

### Capture Registers ### 

## Project : Something ##

