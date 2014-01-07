# Clocking #

Chosing clock speeds in microcontrollers tends to be a tradeoff
between speed of computation and power consumption.
@@
The faster a processor runs, the more power it uses, and the more
heat it generates. 
@@
On a desktop this is often a non-issue, there is usually amply 
available power, and it becomes sensible to run as fast as your
application needs, and your cooling hardware supports. 

On a microcontroller power becomes a lot more important, often
devices will be running off a bettery, and choosing a clock speed
means choosing how long the device will last before needing to be
recharged. 
@@
We won't be delving very deeply into the power and speed tradeoffs
that come from various settings of the CPU clock, but it is good
to keep the tradeoff in mind when you're developing devices where
power consumption is important. 

Additionally all of the peripherals on the LPC use clocks 
which are derived from the CPU clock, and those clocks often need
to be very precisely set, which means that you need to be able
to choose and set your CPU clock precisely as well. 

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

## Clock Dividers ##

@smallfigure("Clock Divider Block Diagram",assets/Clock-Divider-Diagram.eps,0.95,Clk-Div-Dia)

_Clock Dividers_ are an integral part of any complex clocking system.
@@
They allow you to turn a single precisely timed clock signal into another
running an integer multiple slower. 

As shown in Figure @ref(Clk-Div-Dia), internally they have two registers, 
a counter register, and a factor register. 
@@
The counter register simply counts all the edges in the input signal. 
@@
And the factor register stores the amount by which the input signal is slowed
down, and is usually user modifiable. 

During operation, there is an edge detector, which will trigger two events
whenever it sees a rising or falling edge on the input signal. 

  1. It will test if the value in the factor register is equal to the value
     of the counter register. 
  2. It will increment the counter register. 

Then, if the equality test was successful it will perform two more actions. 

  3. Reset the counter register to 0.
  4. Toggle the state of the output signal, switching low to high and vice
     versa.

If the number in the factor register is $N$, then the period of the input signal
will be multiplied by $N + 1$ and the frequency will be divided
by the same amount, as shown in Figure @ref(Clk-Div-Timing).
@@
So, if $F_{in}$ and $F_{out}$ are, respectively, the input and output frequencies
then $\frac{F_{in}}{N + 1} = F_{out}$

@table("Clock Divider Timing Example",assets/Divider-Timing.tikz,Clk-Div-Timing)

## Phase Locked Loops ##

@figure("PLL0 Block Diagram",assets/PLL-Block-Diagram.eps,PLL0-Blk-Dia)

PLLs are clock multipliers, where a clock divider will divide the frequency of
an incoming signal, a PLL will multiply it. 
@@
A PLL is a complex self correcting feedback loop, but in order to use it all
one needs to know is that $F_{in} \times 2 \times (M+1) = F_{out}$ where $M$
is the value in the M-Divider's factor register.[^PLL0-Extra-Div]

[^PLL0-Extra-Div]:The equation
accounts for the extra scaling divider that is in the LPC's PLL0. A standard 
PLL doesn't have this extra divider, with the CCO being connected directly to
the M-Divider, and therefore has the equation $F_{in} \times (M+1) = F_{out}$.

To see how the PLL works, one must first understand that it is a feedback loop,
it starts with an approximation of the final output signal and refines it till
it's an exact multiple of the input signal.

Within the PLL is a _Current Controlled Oscillator (CCO)_ that will generate the
final output signal, it starts oscillating at some frequency that's close, but
not quite what we want. 
@@
The output of the CCO is divided by both the _Scaling Divider_ and the 
_M-Divider_ to get an approximation for the incoming signal. 

If $F_{approx}$ is the frequency of the approximated signal, we know that
$F_{approx} = \frac{F_{out}}{2 \times (M + 1)}$, because the output signal
is divided twice before it becomes the approximation. 
@@
If we're lucky enough that $F_{approx} = F_{in}$ we can substitute and solve
to show that $F_{out} = 2 \times (M + 1) \times F_{in}$, meaning that we've
successfully multiplied the frequency of our input signal. 

But if $F_{approx} \ne F_{in}$ then how does the PLL make $F_{approx} = F_{in}$? 

@table("PLL Error Correction",assets/PLL-Correction.tikz,PLL-Err-Tim)

This is done by the _Phase/Frequency Comparator_ which can figure out if the
approximation is running at a higher or lower frequency than the input, or
if the approximation and the input have a different phase. 
@@
The difference between the approximation and the input constitute an error
term.
@@
Figure @ref(PLL-Err-Tim), shows the ways the error term can be combined with
the current state of CCO to create a refined approximation. 

This continual process of error checking and correction means the PLL becomes
locked to the input signal, and outputs a precisely frequency multiplied version
thereof. 

## Calculating Clock Speed ##

@smallfigure("Cpu Clock Generation Diagram",assets/Clock-Settings.eps,0.95,CPU-Clk-Gen)

Calculating the current clock speed is a matter of following each of the
intermediate steps between the three core oscillators, and the final `cclk` signal
that actually clocks the LPC's CPU. 

`sysclk` 

  : This can be connected to any of the core oscillators on the LPC, so its
    frequency can be 12MHz if connected to `osc_clk`, 4MHz if connected to 
    `irc_osc` or 32.7 KHz if connected to `irc_osc`. 

`pll0clk`

  : This is the output of PLL0, and its frequency must be between 275 MHz and
    550MHz.

If you let,  

  \[ N = \text{The value in the PLL0 N-Divider's factor register} \]
  \[ M = \text{The value in the PLL0 internal clock divider's factor register} \]

then 

  \[ F_{\mathtt{pll0clk}} = \frac{2 \times (M +1) \times F_{\mathtt{sysclk}}}{N +1} \]

`pllclk`

  : This is the output of the CPU PLL Selector and can be set to either
    `sysclk` or `pll0clk`, 

`cclk`

  : This is your final system clock, and is `pllclk` divided by the CPU 
    Clock Divider, this can be at most 120 MHz.

If you let

  \[ D = \text{The value in the CPU Clock Divider's Factor Register} \]

then
 
  \[ F_{\mathtt{cclk}} = \frac{F_{\mathtt{pllclk}}}{D+1} \] 

## Working Backwards ##

If we want to change our LPC's clock speed, we must answer the following
questions: 

  - Which oscillator should be connected to `sysclk`?
  - Should we use the PLL, and if so what should the N-Divider, and 
    M-Divider be set to? 
  - What should the CPU Clock Divider be set to? 

We also must keep in mind the following restrictions:

  - The CPU factor register on supports values between 0 and 255. 
  - The N-Divider's factor register only supports values between 1 and 32
  - The M-Divider's factor register only supports values between 6 and 512
     and a number of extra values seen on page 38 in the manual. 
  - If we're using PLL0 it must output a signal between 275MHz and 550MHz.
  - The final clock speed cannot be more than 120MHz. 

In order to figure out all of the above we should work backwards from our 
target `cclk` frequency, $F_{\mathtt{cclk}}$.

First, we should check if we can forgo the PLL entirely. 
@@
For every oscillator check if $F_{\mathtt{cclk}} \leq F_{oscillator}$.
@@
If it is, check if $\frac{F_{oscillator}}{F_{\mathtt{cclk}}}$ is
an integer less than 256.
@@
If that too is true, then we can do the following:

  1) Set `sysclk` to connect to that oscillator.
  2) Bypass PLL0, connecting `sysclk` directly to `pllclk`.
  3) And set the CPU Clock Divider to 
     $\frac{F_{oscillator}}{F_{\mathtt{cclk}}} - 1$.

If we couldn't forgo the PLL, then we need to figure out the PLL settings we'll
use. 
@@
If we're using PLL0, we know $F_{\mathtt{pllclk}}$ is less than 275MHz, and 550MHz,
and that for some integer $D$ between 0 and 255:

  \[F_{\mathtt{pllclk}} = (D+1) \times F_{\mathtt{cclk}}\] 

The PLL consumes less power when it runs at a lower frequency, so we should choose
the smallest D that will fit within the bounds. 

Now we know we've got to set the CPU Clock Divider to $D$, but we still have to 
figure out which oscillator to use, and what to set the N and M dividers to. 

We want this to be true:

  \[ F_{\mathtt{pllclk}}=\frac{2 \times(M+1)\times F_{\mathtt{sysclk}}}{N +1}\]

We can solve and substitute to get: 

  \[\frac{N+1}{M+1}\approx\frac{2 \times F_{oscillator}}{F_{\mathtt{pllclk}}} \]

So for each oscillator we can find the best approximation for the right hand side
possible using a valid $N$ and $M$.
@@
Namely with $N$ between 1 and 32, and $M$ between 6 and 512 (or another value 
given on page 38 of the manual).
@@
We can then choose which combination of oscillator, $N$ and $M$ will give us the
least error.

Namely if we let

  \[ R = \frac{2 \times F_{oscillator}}{F_{\mathtt{pllclk}}} \]
  \[ \delta = \text{ The error for any combination of oscillator, }N\text{ and }M\text{.} \]

then 

  \[ \delta = \left(\frac{\frac{N+1}{M+1} - R}{R}\right)^2 \]

Once we have the settings that'll minimize the timing error, we can do the 
following: 

  1) Set `sysclk` to the proper oscillator.
  2) Set the N-Divider and M-Divider to $N$ and $M$, respectively.
  3) Connect PLL0 to `pllclk`.
  4) And set the CPU Clock Divider to $D$.

## Making The Changes ##

Now that we know how to choose the various clocking settings we'll use, we
need to learn how to apply them.
@@
This involves making **absolutely sure** that you perform certain operations
in a certain order, checking and double checking the state of the system, 
and operations that serve only to prove to the LPC you're paying attention. 

Clocking can be a dangerous subsystem to play around in, if we input badly
chosen settings, we could render our microcontrollers useless.
@@
This is why the LPC's clocking subsystem requires people to jump through hoops
to change anything.

### Registers ###

Before we dive into the algorithm to change the settings, we should step through
the various registers we'll be using and look at their functions. 

`LPC_SC->CLKSRCSEL`

  : The Clock Source selection register, this is what will connect a particular
    oscillator to `sysclk`. Look at page 34 of the manual for more details on
    how to operate it.

`LPC_SC->CCLKCFG`

  : The CPU Clock Divider's factor register, this controls the divider placed
    right before `CCLK`. See manual page 54.

`LPC_SC->PLL0STAT`

  : The PLL0 Status register, this read-only register makes the currently
    applied PLL0 settings visible to you. It has the connection status of PLL0
    the N-Divider and M-Divider factor registers, and a status bit which tells
    you if the PLL is synced yet with its input signal. See manual page 39. 

`LPC_SC->PLL0CON`

  : The PLL0 Control register, this register controls whether PLL0 is on, and
    lets you choose between connecting `pllclk` directly to `sysclk` or to PLL0
    See manual page 37.

`LPC_SC->PLL0CFG`

  : The PLL0 Configuration register, this is where you set the factor registers
    for the N-Divider and M-Divider. See manual page 37.

`LPC_SC->PLL0FEED`

  : The PLL0 Feed register, you write afeed sequence to this register
    in quick succession in order to validate changes you've made to the 
    other PLL0 registers, and actually apply them to the PLL. See manual page 40. 

### Feed Sequence ###

The PLL registers together form an update-commit system, where every change of
PLL settings requires a feed sequence in order to actually be applied.
@@
This exists so that random memory accesses won't change the settings on this
device, and if you want to break your LPC you've got to actually work to do it. 

A feed sequence consists of writing `0xAA` and  `0x55` to `PLL0FEED` one after
the other, with no other memory operations on any of the other system control 
registers in between. 

~~~~~{.C}
    void PLL0_feed_sequence(){
        LPC_SC->PLLOFEED = 0xAA;
        LPC_SC->PLLOFEED = 0x55;
    }
~~~~~

### Update Algorithm ###

When you have chosen your settings, there's a well specified algorithm
^[See page 46 in the manual] which explains what changes you have to make
and in what order. 
@@
It is very important that you don't combine steps, and make sure that you
get no interrupts during this process. 

  1) Check if PLL0 is already connected, if it is disable it with one feed
     sequence.^[See the appendix for all the macros used herein]

~~~~~{.C}
    if(GETBIT(LPC_SC->PLL0STAT,25)){ // If PLL0 is connected
        BITOFF(LPC_SC->PLL0CON,1);     // Write disconnect flag
        PLL0_feed_sequence();           // Commit changes
    }
~~~~~

  2) Disable PLL0 with a feed sequence.

~~~~~{.C}
    BITOFF(LPC_SC->PLL0CON,0);     // Write disable flag
    PLL0_feed_sequence();           // Commit changes
~~~~~

  3) If you do not plan to use the PLL, set the CPU clock divider to
     your final value, otherwise set it to 1. 

~~~~~{.C}
    // Change CPU Divider
    LPC_SC->CCLKSEL = <CPU Clock Divider Value>; 
~~~~~

  4) Write to the Clock Source Selection Control register to change the
     clock source if needed.

~~~~~{.C}
    // Change sysclk source
    LPC_SC->CLKSRCSEL = <Clock Identifier Bits>;
~~~~~

  5) If you are not using the PLL, you are done, otherwise continue.

  6) Write values to the N-Divider and M-Divider and use a feed sequence
     to enable them. The dividers can only be updated when PLL0 is disabled.

~~~~~{.C}
    // Write divider values
    SETBITS(LPC_SC->PLL0CFG,0,14,<M-Divider Value>);
    SETBITS(LPC_SC->PLL0CFG,23,16,<N-Divider Value>);
    PLL0_feed_sequence(); // Commit Changes
~~~~~

  7) Enable PLL0 with one feed sequence.

~~~~~{.C}
    BITON(LPC_SC->PLL0CON,0); // Set Enable Flag
    PLL0_feed_sequence(); // Commit Changes
~~~~~

  8) Set the CPU Clock Divider to its final value. It is critical to do
     this before connecting PLL0.
     
~~~~~{.C}
    LPC_SC->CCLKSEL = <CPU Clock Divider Value>; // Change Clock Divider
~~~~~

  9) Wait for PLL0 to achieve lock.

Let

  \[ F_{pllref} = \frac{F_{\mathtt{sysclk}}}{N+1} \]
  
If $100 \mathrm{kHz} \leq F_{pllref} \leq 20 \mathrm{MHz}$ wait for the PLL
to lock. 

~~~~~{.C}
    while(! GETBIT(LPC_SC->PLL0STAT,26)); // Spin on Lock Flag
~~~~~

  
If $F_{pllref} < 100\mathrm{kHz}$ wait for $200 / F_{pllref}$ seconds. 
  
~~~~~{.C}
    int i,count = <Number of cycles with current clock speed>;
    while(i++ < count); // Wait sensible amount of time
~~~~~
  
If $20\mathrm{MHz} < F_{pllref}$ wait for $200\mathrm{\mu s}$. 

~~~~~{.C}
    int i,count = <Number of cycles with current clock speed>;
    while(i++ < count); // Wait sensible amount of time
~~~~~

  10) Connect PLL0 with a feed sequence.

~~~~~{.C}
    BITON(LPC_SC->PLL0CON,1); //Set PLL0 Connect Flag
    PLL0_feed_sequence(); // Commit Changes
~~~~~

## Peripheral Clocks ##

Many peripherals are timed using the _Peripheral Clock Dividers_. 
@@
There are four clocks `pclk1`,`pclk2`,`pclk4` and `pclk8`, which
are clocks derived from `cclk`, and are 1,2,4,and 8 times as slow 
as `cclk`. 
@@
Namely, they are implemented with clock dividers with fixed factor
registers of 0,1,3 and 7.

You can see how to connect them to various paripherals on pages 
56 and 57 of the manual.

## Project : Precision Timing ##

Many aspects of your LPC require very precise clocking. 
@@
Things like the USB subsystem, the _Analog to Digital Converter (ADC)_
and _Direct Memory Access (DMA)_ all perform operations that are timed
using your internal CPU clock. 
@@
The accuracy of those features, and more depends on how accurate your
clock speed is.

We are going to experiment with changing the clock speed to generate
output signals at various frequencies. 

### Steps ###

  1) Write a script, in any laguage you want, that will calculate
     clock settings for you. It should, given a target clock speed, 
     give you everything needed to write the clock setup code.

~~~~~{.bash}
    $ ./clk-calc --target=120MHz

    Base Oscillator : ...
    Use PLL : ...
        N-Divider : ...
        M-Divider : ...
    CPU Clock Divider : ... 

    Target Freq: ...
    Output Freq: ...
    Error: ... 
    
    $ ./clk-calc --target=200MHz

    Cannot Compute: Target Clock Too High
~~~~~

  2) Write a program that repeatedly toggles a GPIO pin, so that you 
     get a square wave. 

  3) Use `make lst` and the [ARM Cortex M3 Manual](http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0432c/CHDCICDF.html) to find the number of
     clock cycles between every toggle. 

  4) Change the frequency of your output square wave without changing 
     the loop at all, use only different clocking settings. 
 
### Questions ###

As you progress through the exercise, answer the followign questions:

  1) What is the lowest CPU clock speed you can achieve with this setup?
  
  2) How many clock cycles does your loop take between GPIO toggles?
 

  3) What are the options needed to get the maximum speed, 120MHz? 

  4) What is the frequency of your output signal when the CPU clock 
     is 200Hz? 120MHz? 

  5) What clock frequency do you need to get an output signal at 1kHz? 



