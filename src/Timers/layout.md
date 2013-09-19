# Timers #

@inlinetodo("Intro Paragraph for Timers, something about real time systems?")

## Basic Description ##

Timers are peripherals within the LPC that are mainly internal, they
use the CPU clock to keep track of time, and make that ability available
to the user in a number of ways. 

Timers can send out periodic events, make very precise measurements, 
simply make the time available for your applications, among other things.
@@
This means you can start using temporal information in your program, 
without having to use unwieldy spin loops, and other ill advised hacks.

There are four timers within the LPC, Tim0, Tim1, Tim2 and Tim3.
@@
All are identical, but can have options set independently, and can be
used without interfering with each other. `

## Speed Settings ##

@figure("Timer Counter Block Diagram",assets/Timer-Counter.eps,Tim-Cnt-Dia)

All timers are built around an internal _Timer Counter (TC)_,
which is a 32 bit register that is incremented periodically. 
@@
The rate of change is derived from the current speed of the CPU clock,
which peripheral clock you've connected up and what the prescale counter
is set to.

There's nothing more to it than that, the prescale counter is a 
clock divider like so many others, and the Timer counter is a 32 bit register,
and as long as nothing else intervenes it's count from `0x00000000` to 
`0xFFFFFFFF`, overflow, and do it all over again. 

### Powering Devices ###

Before we can get to choosing the peripheral clock, and setting the 
prescale register, we need to actually tun on the timer. 

On reset most of the LPC's peripherals are off, and aren't being supplied
power by the microcontroller. 
@@
This can save a lot of energy, but a few core peripherals are turned on 
when the LPC starts, among these GPIO and Tim0 and Tim1.
@@
But this means that Tim2 and Tim3 start off, and if you need them you'll
have to turn them on. 
@@
Additionally, if you don't need Tim0 or Tim1, you can turn them off
to save some power. 

Power control is considered a system feature, and is controlled by register
`LPC_SC->PCONP`.
@@
Each bit in that register is assigned to a peripheral, with a 0 meaning
unpowered, and a 1 meaning that the peripheral is powered. 

~~~~~{.C}
    BITON(LPC_SC->PCONP,22); // Turn on Tim2
    BITOFF(LPC_SC->PCONP,2); // Turn off Tim1
~~~~~

You can find the full table of peripheral to bit mappings on pages 63 and
64 of the manual.

It's probably a good idea to note that you can get some very weird 
results if you try to work with a peripheral that's off. 
@@
The whole situation has undefined results, but in practice, writes to
registers in unpowered peripherals don't do anything, and reads always
return 0. 

### Choosing a Peripheral Clock ###

Likewise, choosing a peripheral clock is a system function, and the settings
for all the peripherals are on `LPC_SC->PCLKSEL0` and `LPC_SC->PCLKSEL1`.

~~~~~{.C}
    SETBITS(LPC_SC->PCLKSEL0,4,2,0b10); // Set Tim1 to use pclk2
    SETBITS(LPC_SC->PCLKSEL1,14,2,0b00); // Set Tim3 to use pclk4
~~~~~

You can find the bit assignments, and settings for the peripheral clock
selection on pages 56 and 57 of the manual.^[The choice of bits to select
each clock is somewhat odd, so do look at the manual]

### Setting the Prescale Counter ###

Once you've made sure your chosen timer is on, and is using the peripheral
clock you want, you can move onto setting the prescale counter and actually
using it to perform timing related tasks. 

The prescale counter is basically a 32 bit factor register inside a clock divider.
@@
You can set it using the `LPC_TIMx->PC` register. 

~~~~~{.C}
    LPC_TIM3->PC = 14; // Divide the incoming clock by 15. 
~~~~~

All of this can be found on page 495 of the manual. 

### Reset and Enable ###

Before the timer counter can actually start incrementing, there are two flags
within the _Timer Control Register (TCR)_.

The enable flag, when set to one, disables the timer counter's ability to
increment.

~~~~{.C}
    BITON(LPC_TIM2->TCR,0); // Disable the timer counter
    BITOFF(LPC_TIM2->TCR,0); // Enable the timer counter
~~~~

The reset flag, when set to one, forces the timer counter's value to zero. 

~~~~{.C}
    BITON(LPC_TIM0->TCR,0); // Disable the timer counter
        // The couter's value is stuck wherever we stopped it
    BITON(LPC_TIM0->TCR,1); // Reset the timer counter to zero
        // The counter's value is zero
    BITOFF(LPC_TIM0->TCR,0); // Enable the timer counter
        // The counter's value is *still* zero, since the reset bit is still on
    BITOFF(LPC_TIM0->TCR,1); // Disable the reset flag
        // The counter's value will now start incrementing, since the
        //   reset flag is gone. 
~~~~

Once you're done with setting those value properly, you can watch your timer 
counter increment. 

~~~~{.C}
    Current_Timer_Val = LPC_TIM3->TC; 
~~~~

## Match Registers ##

@figure("Match Register Block Diagram",assets/Match-Register.eps,Mat-Reg-Blk)

Within each timer are four match registers, 32 bit registers which can store a
specific match value. 
@@
When the timer counter and match register are equal, certain events can be
triggered.

Choosing the match value is just a matter of setting the match register,
`LPC_TIMx->MRx`.

~~~~{.C}
    LPC_TIM0->MR3 = (uint32_t) 4000; // Set match register 3 on timer 0
    LPC_TIM2->MR1 = (uint32_t) 453;  // Set match register 1 on timer 2
~~~~~

### Match Settings ###

There are three events a match can trigger, a reset of the timer counter,
disabling the timer counter and sending an interrupt. 
@@
The disable and reset events work by modifying the timer control register,
and using its features to control the timer counter. 

The match register's disable event sets the disable flag in the TCR to 1,
requiring you to manually toggle it back.
@@
On the other hand, the reset event simply toggles the flag in the TCR,
setting the timer counter to 0, but allowing it to continue incrementing,

@inlinetodo("Insert timing diagrams showing outcome of disable and reset flags")

To actually change which events are triggered on match requires manipulating
the register at `LPC_TIMx->MCR`. 
@@
All the flags for all the timer registers are mapped to various bits in
the _Match Control Register (MCR)_.
@@
This mapping can be found on page 496 on the manual. 

~~~~~{.C}
    BITON(LPC_TIM0->MCR,10); // Reset on match for 
                             // match register 3 in timer 0
    BOTON(LPC_TIM2->MCR,5);  // Disable on match for 
                             // match register 3 in timer 2
~~~~~

### Match Interrupts ###

Like a GPIO interrupt, there are multiple triggers which all trigger 
an interrupt on the same channet. @todo("Explain: Interrupt channel or
make sure it's used earlier")
@@
Each of the match registers can trigger interrupts, and so can other
components of each timer.

To tell these interrupts apart, you can use each timer's _Interrupt 
Register (IR)_.
@@
When a component of the timer triggers the interrupt a flag in 
the IR is flipped and you can use that to determine what's already going
on. 

### External Match Registers ###

## Capture Registers ## 

## Project : Morse Code Reader ##

### Background ###

### Materials ###

### Steps ###
