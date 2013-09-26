# ADC #

@inlinetodo("Intro Paragraph")

The ADC is the analog counterpart to the GPIO's input mode. There are 8 ADC channels
each of which can read in a single value at a time. 

## Theory of Operation ##

@inlinetodo("Explain how the ADC works, what is meant by 'bits of precision' 
             and the mapping from D->A->D.")

## Basic Usage ##

@inlinetodo("Explain how to read a single value from the ADC, setting it up, 
             waiting for the done bit, setting the clock, etc." )

@inlinetodo("Explain how the ADC takes 65 clock cycles to pin down a value,
             how the various status registers interact.")

@inlinetodo("Explain the various settings in the control register, the 
             structure and mapping between the global data register and the
             various channel specific data registers, and the status register.
             the trim register can be ignored for the moment, and the 
             interrupt register we'll handle in that section")

The initial setup of the ADC consists of the following steps:
@comment(Rohit,"This is uncomfortably like a cookbook one can follow blindly")

  1) Power the device

Here we set the bit in `LPC_SC->PCONP` for the ADC, to turn the
power on. 
@@
This is essentially the same as for the Timers and most other
peripherals. 

~~~~~{.C}
    LPC_SC->PCONP |= 1 << 12; // Manual page 56-57
~~~~~

  2) Calculate the necessary clock (the ADC can only run at 13MHz)
     and choose a peripheral clock, and ADC clock divider setting.

The ADC, like most other components is connected to your choice of
peripheral clock and then run through its own divider. 
@@
The ADC is also limited to a 13 MHZ clock, so you must choose values
for its internal clock divider, and peripheral clock such that

  \[\frac{F_{\mathtt{pclk}x}}{N+1} < 13\text{MHz} \]
  
The easiest way to do this is to simply set your central clock to 
the 12MHz main oscillator, and the various other dividers to pass
that through unchanged.  

~~~~~{.C} 

  LPC_SC ->CLKSRCSEL = 1;   // Select main clock source
  LPC_SC ->PLL0CON = 0;     // Bypass PLL0, use clock source directly

  // Feed the PLL register so the PLL0CON value goes into effect
  LPC_SC ->PLL0FEED = 0xAA; // set to 0xAA
  LPC_SC ->PLL0FEED = 0x55; // set to 0x55

  // Set clock divider to 0 + 1=1
  LPC_SC ->CCLKCFG = 0;

~~~~~

But you can also use settings that will let your LPC run faster, and 
get more out the main processor while allowing the ADC to run as fast as 
possible,

  3) Set the peripheral clock

Here we use the undivided clock for the ADC, but as long as the final clock 
constraints are considered, you can choose any peripheral clock. 

~~~~~{.C}    
    // Choose undivided peripheral clock for ADC
    LPC_SC->PCLKSEL0 &= ~(3 << 24);
    LPC_SC->PCLKSEL0 |= (1 << 24);
~~~~~

  4) Set the ADC clock divider

The ADC control register, `LPC_ADC->ADCR` controls a number of functions,
but for the moment we'll use it to choose the setting for the ADC clock
divider.
@@
This is controlled by bits 8 through 16 of the control register and can be set
as follows. 

~~~~~{.C}
    SETBITS(LPC_ADC->ADCR,8,8,0); // Set clock divider to let the
                                  //  clock pass unchanged
~~~~~

  5) Put the pins you'll be using into ADC mode 

~~~~~{.C}
    SETBITS(LPC_PINCON->PINSEL1,14,2,0b01); // Connect AD0.0 to its pin
~~~~~

  6) Pull the ADC out of power down mode

The ADC also has its own internal power switch, so that you can change settings 
while conserving power that the conversion circuitry will use. 

~~~~~{.C}
    BITON(LPC_ADC->ADCR,21); // Turn on ADC internal power
~~~~~

The simplest method of actually getting data is synchronous collection of values
from the ADC. 
@@
You tell the ADC to go collect some data, wait for it to tell you it's done, 
and then read out the value. 

When trying to synchronously access one of the eight ADC lines,
do the following: 

  1) Select the ADC line you're going to read.

The first eight bits in `LPC_ADC->ADCR` control which input lines are active, and when
collecting data synchronously, you can only have one on at a time. 

~~~~~{.C}
    LPC_ADC->ADCR &= 0xFF; // Clear first 8 lines
    BITON(LPC_ADC->ADCR,0); // Choose line 0
~~~~~

  2) Start the conversion 

There are 3 bits in the ADC control register which let you choose the collection
mode, for the moment we'll focus on the first two.
@@
Setting bits 24 to 26 in the `ADCR` to 0 tells the ADC that you want no conversion
done, and setting them to 1 tell the ADC to start a conversion immediately. 

~~~~~{.C}
    SETBITS(LPC_ADC->ADCR,24,3,1); // Start the single conversion
~~~~~

  3) Spin on the done flag 

For single conversions you can look at the _General Data Register_ which will
store the results of the very last conversion.
@@
Because a conversion takes 65 of the ADC's clock cycles, where it'll spend time 
slowly increasing the precision of the value it recovers, you have to wait for it
to finish. 
@@
So you spin on the done flag in the final bit of the data register, which will 
turn to 1 when the conversion is finally finished. 

~~~~~{.C}
    while((LPC_ADC->ADGDR & (1 << 31)) == 0);
~~~~~

  4) Read and parse the output value

And now you can find your converted value in the same register, in bits 5 
through 12. 

~~~~~{.C}
    value = GETBITS(LPC_ADC->ADGDR,5,12);
~~~~~

## Interrupts ##

@inlinetodo("Explain how to use the ADC interrupt, when it's thrown, what
             you need to flip, and how to get periodic ADC interrupts")

If you want to sample asynchronously, using interrupts you can allow your
other code to run during the relatively long sampling process. 

The setup for interrupt based ADC use has a few extra steps: 

  1) Enabling the ADC interrupt in the NVIC.

~~~~~{.C}
    NVIC_EnableIRQ(ADC_IRQn);
~~~~~

  2) Setting the correct bits in the ADC Interrupt Enable register. 

~~~~~{.C}
    BITON(LPC_ADC->ADINTEN,0);
~~~~~

  3) Setting up the interrupt handler that will retrieve your value. 

Reading from the GDR will turn off the interrupt flag so you don't have 
to do it manually.

~~~~~{.C}
    void ADC_IRQHandler(void) {
        /** other stuff **/
        // Equivalent to above:
        analog_val = (LPC_ADC ->ADGDR >> 4) & 0x0fff;
        /** other stuff **/
    }
~~~~~

Then you can start a conversion the same way as before. 

~~~~~{.C}
    SETBITS(LPC_ADC->ADCR,24,3,1); // Start the single conversion
~~~~~

65 ADC clock cycles after you do, the interrupt will be thrown and you
can retrieve the value.


## Connecting to Timers ##

@inlinetodo("Explain how to connect to a timer, trigger on match registers,
            capture registers, how to use a match interrupt to trigger an
            ADC interrupt and then get a value while your main loop is 
            chugging along doing its thing.")

## Burst Mode ##

@inlinetodo("Explain what burst mode is and how to use it.")

## DMA ##

@inlinetodo("Write when we get to the DMA chapter")

## Project : Joystick Theramin ##




