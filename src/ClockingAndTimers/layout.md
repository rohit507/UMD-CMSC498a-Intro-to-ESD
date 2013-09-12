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

_Clock Dividers_ are an integral part of any complex clocking system,
they allow you to turn a single precisely timed clock signal into another
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

@missingfigure("Timing Diagram with multiple dividers running off the
                same clock")

### Phase Locked Loops ###

A PLL is a special circuit which can detect the phase 
of an incoming signal and output a signal with a different related
phase. 
@@
The PLLs inside our LPC are acting as clock multipliers, devices
which take the signal of the input frequency and output a signal that
is some multiple of that frequency. 

@missingfigure("Insert Fig 9 from manual page 36, or similar diagram")

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

@missingfigure("Table showing cases where the CCO approximation is ahead,
                behind and in sync with the input signal") 

The net effect is that the CCO becomes locked to the input signal, repeatedly
correcting itself so that it is running at the target speed. 

### Calculating Settings ###

@missingfigure("Insert CPU + PCLK subset of Fig 7 P.29 of the manual")

@smallfigure("Cpu Clock Generation Diagram",assets/Clock-Settings.eps,0.95)

Setting the LPC to your chosen clockspeed is about finding a path through
the 

### Making Changes ###

## Timers ##

### Basic Description ###

### Speed Settings ###

### Match Registers ###

### Capture Registers ### 

## Project : Something ##

