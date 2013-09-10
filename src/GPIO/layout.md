# GPIO #

## Prequisites ##

Read the following tutorials to get you up to speed with the electronics:

 - [How to read a schematic][Read_schem]
 - [How to use a breadboard][Use_Breadboard]
 - [Understanding LEDs][LED]
 - [Using Pull Up Resistors][Pull_Up]

All these tutorials are Arduino centric, but you can extrapolate to 
what you need to do for your LPC.

## What is GPIO? ##

We'll start with the most basic peripheral on the LPC, General Purpose 
Input Output.
@@
GPIO is what lets your microcontroller be something more than a weak auxiliary processor.
@@
With it you can interact with the environment, connecting up other devices
and turning your microcontroller into something useful. 


GPIO has two fundamental operating modes, input and output.
@@
Input lets you read the voltage on a pin, to see whether it's held low (0v) 
or high (3v) and deal with that information programmatically.
@@
Output lets you set the voltage on a pin, again either high or low.
@@
Every pin on the LPC can be used as a GPIO pin, and can be
independently set to act as an input or output. 


In this chapter we will show how to complete 2 tasks,
reading the state of a button, and making an LED blink.
@@
Using what you learn from that, you'll be able to start building more 
complex devices, and even implementing simple communications protocols.

## GPIO Output ##


GPIO output is a versatile and powerful tool, especially given that
it takes little effort to use and control it. 
@@
Once you've chosen a pin, the process to use it is straighforward:

  - tell the LPC that the pin should be used as an output
  - tell the LPC whether the pin should be held low or high. 

The interesting part is how exactly you can give the LPC instructions, and what
it does in order to carry them out. 

### Memory Mapped Registers ###

In order to talk to the GPIO controller, or any other peripheral, we have 
we have to use _memory mapped registers_. 
@@
In most computers these low level interfaces are hidden by the kernel, and
often only higher level interfaces are available to developers.
@@ 
The LPC however doesn't have a kernel or drivers hiding these interfaces from
you.
@@
This gives you the ability to work with them directly, without having to deal
with the virtual device abstraction a modern OS would impose. 



When we try to read or write to a normal chunk of memory, the address and
instruction are sent to the memory controller. 
@@
The memory controller then either retrieves data from memory and places it 
into a register, or takes data from a register and writes it to somewhere
in the memory.
@@
However, there are a number of privileged address, and when you try to
read from or write to these a different pathway is taken. 
@@
Here when the memory controller gets the instruction it notices the address 
is special, and instead of going to the memory module, it'll forward the 
request to a register that's located in the relevant peripheral.


These registers all have different functions, each of which is detailed in
the manual along with the register's memory address.
@@
The really important thing to notice is that you're not dealing with a
normal piece of memory, and these _memory mapped_ registers can act very 
differently. 


Unlike static memory where you can read or write pretty much anywhere, 
there are a number of these memory mapped registers which you can only read
from. 
@@
Trying to write to any of these will trap your system in a hard fault.
@@
Neither can you rely on the assumption that reads are nondestructive.
@@
There are some registers which are connected to FIFOs and other structures,
and reading from them is the same as popping from that queue, and the next
time you read from the same address, you'll get a different value.
@@
Even the usual guarantee that a write operation is idempotent is lost.
@@
There are registers where a write operation will trigger some change in the
peripheral, making the LPC turn an LED on, or send out a signal.


### Blinking Lights ###

So let's start with something simple: Blinking Lights. 
@@
Connect up an LED to pin `P0[9]` and ground, making sure to place the proper
current limiting resistor in series with it. 
@@
To actually turn on the LED you have to first tell the LPC that the pin is
to be used for output, and then set the state to be on. 
@@
If you look in the manual you'll see that `P0[9]`'s direction is controlled
by the 9th bit in a register located at `0x2009C000`, and that setting it 
to 1 makes it an output pin. @todo(Add cite for manual p.107)

~~~~~~~~~~{.C}
    ((uint32_t *) 0x2009C000) |= (1 << 9); // Set P0[9] to output
~~~~~~~~~~

Then there's another register at `0x2009C014` which controls the state of
the pin, so we can turn turn the light on and off by manipulating its 9th 
bit.

~~~~~~~~~~{.C}
    ((uint32_t *) 0x2009C014) |= (1 << 9);  // Turn On
    ((uint32_t *) 0x2009C014) &= ~(1 << 9); // Turn Off
~~~~~~~~~~

So now you should be able to make the light blink, or by varying the amount
of time on and off, let it glow with varying levels of brightness.

### An Easier Way ###

Of course writing out the memory address every time you wish to change a 
register isn't easy, or readable. 
@@
You could replace it with a preprocessor macro, but writing those macros 
would be painful and tedious.
@@
Until you notice that the memory locations for these registers are 
structured, with registers performing related tasks placed close together.
@@
In fact, the adresses are chosen so that they can easily map to structs.
@@
Finding the base address of a particular block of registers, and
defining a suitable structure, will give you easy to use pointers to 
all the registers in that block. 
@@
There already exists a library that defines these structs and calculates
the proper base addresses.

**CMSIS** ^[CMSIS: Cortex Microcontroller Software Interface Standard] is a library
written by engineers at ARM, and it sets up all these memory addresses 
as human readable macros for you.
@@
To see how it works let's look at the setup for 
the DAC (Digital to Analog Converter).
@@
The DAC is a device which can take a digital value, and turns it into an analog
output, it's controlled with only 3 registers, the functions of which we'll
look at in a later chapter.
@@
In `LPC17xx.h` you'll find a long list of struct definitions and 
a series of raw memory addresses.
@@
The addresses point to the chunks of memory assigned to each peripheral and the
structs show the layout of each of those chunks of memory. 

~~~~~~~~~~{.C}
    /*----- Digital-to-Analog Converter (DAC) ------*/
    typedef struct
    {
        __IO uint32_t DACR;
        __IO uint32_t DACCTRL;
        __IO uint16_t DACCNTVAL;
    } LPC_DAC_TypeDef;

        ...

    #define LPC_APB1_BASE (0x40080000UL)
        ...

    #define LPC_DAC_BASE  (LPC_APB1_BASE + 0x0C000)

        ...

    #define LPC_DAC       ((LPC_DAC_TypeDef *) LPC_DAC_BASE )
~~~~~~~~~~

The DAC is an APB1[^APB1] peripheral and so `LPC_DAC_BASE` is the start of the 
memory mapped to DAC registers. 
@@
`LPC_DAC_Typedef` is a struct that's set up so that when it's aligned to that
base address, each of the struct's fields will align with a particular register
in the DAC memory space. 
@@
This whole setup means that you can write to the DAC Control Registers without
using a raw memory location. 

[^APB1]: APB stands for Applied Peripheral Bus, there are two in the LPC and
         some peripherals are connected to each.

~~~~~~~~~~{.C}
    LPC_DAC->DACCTRL = /* stuff */;
~~~~~~~~~~

If you look back at the code we wrote for LED manipulation, and refactor
it, you'll get something much easier to work with.  

~~~~~~~~~~{.C}
    LPC_GPIO0->FIODIR |= (1 << 9);  // Set P0[9] to write
    LPC_GPIO0->FIOPIN |= (1 << 9);  // Turn LED on
    LPC_GPIO0->FIOPIN &= ~(1 << 9); // Turn LED off
~~~~~~~~~~

Having a layer of macros like this also makes it easier to port your code
to another platform, since you'll have to only change the macro definitions
rather than all the pieces of code which use some registers. 

### More Registers ###

If you look closely there's 4 GPIO ports, each controlling up to 32 pins, and 
each of those blocks has 5 registers. 
@@
Strictly speaking you only need the `FIODIR` (set pin direction)  and 
`FIOPIN` (set or read pin state) registers to control each pin, but there
are three others, which allow you to perform operations much faster. 

`FIOSET` and `FIOCLR` are the two fast output control registers.[^FASTOCR]
@@
Writing a 1 to a bit in `FIOSET` will enable the corresponding pin, and 
writing to `FIOCLR` will disable the pin.

[^FASTOCR]: The fast in their moniker refers to the fact that using them takes
            fewer operations than using `FIOPIN`. 

~~~~~~~~~~{.C}
    LPC_GPIO0->FIOSET = 1 << 9; // Turn LED On
    LPC_GPIO0->FIOCLR = 1 << 9; // Turn LED Off
~~~~~~~~~~

`FIOSET` is a good example of how the usual guarantees of memory structure are
lost when working with memory mapped data.
@@
Writing a 1 to `FIOSET` will set the corresponding bit in `FIOPIN` to 1, while
writing a 0 will do nothing. 
@@
In effect '`FIOSET = ...`' is an alias for '`FIOPIN |= ...`'.
@@
However reading from `FIOSET` is a completely different action, it will return 
the value from the output state register, a register which stores the current
output value for all the pins, regardless of whether they are current being used
as such. 

Writes to `FIOCLR` can be similarly thought of as an alias, in this case from
'`FIOPIN &= ~ ...`' to '`FIOCLR = ...`'. 
@@
But reading from `FIOCLR` is undefined, there is simply nothing that operation
can look at when pointed at `FIOCLR`. 

This idea of memory mapped registers being aliases for more complex commands 
hints at why these registers are called the "_fast_ output control registers". 
@@
Trying to change the value of a single pin with `FIOPIN` requires at least 3 operations
operations, a read , a bitwise logic operation, and a write. 
@@
To make the same change using the fast registers requires only a write operation,
the rest of the stuff is done in hardware, which is much faster. 

`FIOMASK` is, in effect, a filter for `FIOPIN`,`FIOSET`, and `FIOCLR`.
@@
If a bit in `FIOMASK` is a 1, then none of those registers can cause any
change in that pin's state.
@@
This means that you can change a subset of the bits very quickly, without having to
perform a masking operation every time. 
@@
By default all of `FIOMASK`'s bits are set to 0, meaning that the other control 
registers can operate over all bits.


## GPIO Input ##

Reading a pin uses the same registers we've already used, once a pin's mode is 
set to input in `FIODIR`, the corresponding bit in `FIOPIN` holds the currently
read value.
@@
In addition to simply reading the registers to figure out the voltage on a pin,
we've also got access to interrupts, which will notify your program when the 
state of a pin changes, while allowing you to do something else in the meantime. 

### Basics ###

Reading the current state of a pin in the middle of your code is simple, we
take the same two registers as before `FIODIR` and `FIOPIN`, and use them 
slightly differently. 

~~~~~~~~~~{.C}
    LPC_GPIO0->FIODIR &= ~(1 << 9);          // Set P0[9] to Input
    PinState = (LPC_GPIO0->FIOPIN >> 9) & 1; // Get P0[9] State
~~~~~~~~~~

Here a zero in a particular position in `FIODIR` means the pin is used for 
input, and the relevant bit in `FIOPIN` contains its current state. 
@@
Writes to `FIOPIN`,`FIOCLR` or `FIOSET` don't affect input pins, and making changes
to the value of an input pin is basically a no-op. 

@sidefigure(
"A pull-down resistor allows for more predictable connections
 between logic gates and inputs.
 With the resistor, when the button is released, the ground will pull 
 the voltage back down to 0v. 
 Without the resistor, a sufficiently isolated pin might
 stay at 3v even after the button is released, giving an 
 incorrect reading. 
 Additionally, having a large resistor is important since
 it will only draw a small amount of current when the button 
 is pressed. 
 A small resistor might draw enough to stress the power
 supply and keep other portions of your device from functioning"
 ,assets/Pull-Down.eps,0.5)

Once you have this set up, you can connect up a switch with a pull down resistor
to the input pin, and be able to read the state of your button in software.

### Bouncing ###

So if you want to toggle an LED whenever you press a button you might do 
something like the following. 

~~~~~~~~~~{.C}
    int state, prevstate = 0;
    while(1){ 
        // Get state of P0[9]
        state = (LPC_GPIO0->FIOPIN >> 9) & 1;  
        // If there's a change from 0 to 1
        if(!prevstate && state) {    
            // Toggle P0[8]
            LPC_GPIO0->FIOPIN ^= 1 << 8;      
        }
        prevstate = state;
    }
~~~~~~~~~~

When you try that, you'll notice some odd behavior, not only will the LED change
when you press the button, but it will occasionally also change when you release
the button. 
@@
Sometimes it'll miss button presses completely, and not change the LED's state. 

@smallfigure("What button presses actually look like."
,assets/Bouncy_Switch.png,0.75)


This happens because buttons aren't perfect, and instead of getting smooth 
transitions from connected to disconnected, the transitions are disjointed
and shaky, this phenomenon is known as bouncing.[^Button-Bounce-Cite]
@@
Because the GPIO pins can only read if something is low or high these jitters 
result in a number of very fast transitions before the voltage stabilizes.
@@
Your LPC will see some of these transitions as a separate button presses 
and toggle the LED accordingly.
@@
Most of the time, the bouncing will happen between reads of the pin state but
sometimes, a read will happen in the middle of the bouncing and cause anomalous
output. 

[^Button-Bounce-Cite]: Image taken from <http://en.wikipedia.org/wiki/File:Bouncy_Switch.png>

Removing the errors caused by bouncing can be done with hardware or software.
@@
In hardware, using a capacitor or a 
[Schmitt Trigger](http://en.wikipedia.org/wiki/Schmitt_trigger)
can sometimes solve the problem.
@@
In software, one can check if the input has been stable for a while before acting
upon an event.
@@
There are also many other [ways to deal with bouncing](http://www.eng.utah.edu/~cs5780/debouncing.pdf) 
that can be more complex but also more reliable. 

### Interrupts ###

There's another way to get input from GPIO pins, this time without having to stop
and poll the state of your button waiting for something to happen. 
@@
With the correct settings the processor can wait for an event in the background
while letting your code run in the meantime. 
@@
When the event happens, the processor will interrupt your currently running code, run
code to respond to the event, and restart the execution of your main program. 

These _interrupts_ can be very complex and so we're only going to touch on a 
small subset of their capabilities.
@@
For GPIO specifically, an interrupt can be triggered when the CPU detects a rising
or falling edge[^edge-exp] on an input pin.
@@
Once the edge is detected, the Interrupt Controller performs a context switch. 
@@
In this case, saving any of the current registers to the stack, and starting the
executing of the interrupt handler. 
@@
Once the interrupt handler is done, the processor will restore the previously
saved registers, and continue executing the original code. 

[^edge-exp]: A rising edge is the pin's value changing from a 0 to a 1, and a falling
             edge is the value changing from a 1 to a 0. 

The Interrupt Controller uses an internal flag to determine whether or not to 
perform a context switch, and this flag is not automatically turned off once
it has been set.
@@
This means that if you don't manually disable the flag, the interrupt handler
will execute repeatedly until the flag is disabled.
@@
_Interrupt chaining_ lets you keep your code small, and modular while still
being able to handle many quickly incoming events.
@@
By only disabling the flag for the particular event you've handled, you are
guaranteed to have your interrupt handler called again, so that it can handle
a different event. 

#### Setting Up an Interrupt Handler ####

Setting up a GPIO interrupt starts with telling the Interrupt Controller to
enable the relevant external interrupt. 
@@
Then in the struct `LPC_GPIOINT` you'll find the registers `IO0IntEnR` and 
`IO0IntEnF` which define which pins on GPIO Port 0 generate interrupts on a
rising and falling edge.^[These registers are for pins on GPIO Port 0. There are 
similar registers with `IO2` instead for pins on GPIO Port 2. The other GPIO
ports don't have support for interrupts, and don't have interrupt registers.]

~~~~~~~~~~{.C} 
    // Turn on External Interrupt 3
    NVIC_EnableIRQ(EINT3_IRQn);
    // Enable Rising Edge Interrupt on P0[9]
    LPC_GPIOINT->IO0IntEnR |= (1 << 9);
    // Enable Falling Edge Interrupt on P0[9]
    LPC_GPIOINT->IO0IntEnF |= (1 << 9);
~~~~~~~~~~

Once the interrupt is enabled on the right pins, the handler has
to be defined. 
@@
The interrupt handlers are found in `cr_startup_lpc176x.c` in each of your
project's source directories, defined as weak aliases to the default interrupt
handler. 
@@
Because they're weakly defined, defining a new function with the same 
name will make that the handler for the interrupt. 

~~~~~~~~~~{.C}
    // Turn on the LED when the button is pressed
    void EINT3_IRQHandler() {
        // If the rising edge interrupt was triggered
        if((LPC_GPIOINT->IO0IntStatR >> 9) & 1){
            // Turn on P0[8]
            LPC_GPIO0->FIOPIN |= 1 << 8;      
        }
        // If the falling edge interrupt was triggered
        if((LPC_GPIOINT->IO0IntStatF >> 9) & 1){
            // Turn off P0[8]
            LPC_GPIO0->FIOPIN &= ~(1 << 8);      
        }
        // Clear the Interrupt on P0[9]
        LPC_GPIOINT->IO0IntClr |= (1 << 9);
    }
~~~~~~~~~~

All the GPIO Interrupts share the same interrupt handler, so it has to check
which pins actually triggered the interrupt. 
@@
You can do this with the GPIO Interrupt Status Registers.
@@ 
`IO0IntStatR` will have bits set when the relevant pin was triggered by a rising 
edge, and `IO0IntStatF` does the same for a falling edge. 
@@
Once you've done the relevant action you can clear a particular pin's interrupt
by writing a 1 to the bit in `IO0IntClr`, if you don't do this the interrupt
will be called again till all the pins have had their interrupts cleared.
@@
This means you only have to handle one pin at a time, and as long as you clear 
that pin's interrupt flag, the handler will be called again to take care of the 
next triggered pin. 

## Project : Bit Banging ##

Bit banging is the process of implementing a serial communication protocol using
software instead of dedicated hardware. 
@@
In this case we're going to be sending data to a shift register, using 2 GPIO pins
to control 8 LEDs.

### Shift Registers ###

To control to many leds with so few outputs you need to implement a serial
communications protocol, a way of sending data one bit at a time to another
entity.
@@
In this case we are going to be sending the data to a CD4094B, which
has an interface based around 3 input lines, the clock, the data line, and
the stribe input. 

@include(assets/Shift-Register-Diagram.tikz)

The CD4094B has, in effect[^ShiftRegCaveat], two registers inside of it, a
shift register and an output register. 
@@
The shift register is used to load in data one bit at a time, so whenever
the clock signal moves from low to high it'll do two things.
@@
First, it'll shift the data it contains one bit to the right, and now that
the lowest bit is empty, it'll read the value on the data line and store it
in that bit. 
@@
So this way, through 8 clock cycles you can load one byte onto the shift
register, starting with the highest first. 

The output register is what is actually connected to the external pins, and
determine whether each output pin is held low or high. 
@@
This register waits till it sees a rising edge on the strobe input, and when 
it does, it'll copy over the values currently in the shift register.

With this, you can load in a byte of data with the clock and data lines, and
once you've finished, write it all at once to the output with the strobe line. 

[^ShiftRegCaveat]: Thinking of them as memory registers is an imperfect 
                   abstraction. While it'll serve for anything we need to do,
                   there are much more detailed explanations on
                   [Wikipedia][Wiki_Shift_Reg] and on the 
                   [CD4094B Data Sheet][Shift_Schem]

### Materials ###

Other than your LPC you'll need the following:

  - 1 x [CD4094B 8-Bit Shift Register][Shift_Schem]
  - 8 x LED of your choice
  - 8 x [2N2222A NPN Transistor][Trans_Schem_PN2222A] 
    ^[The 2N2222A and PN2222A are functionally equivalent transistors
     with different packages, so feel free to use either.]

### Steps ###

 1. Wire up the following circuit[^WhyTransistor]

@smallfigure("Shift Register Circuit",assets/Shift-Register-Circuit.eps,0.85)

 2. Implement the serial protocol needed to write to shift registers, and
    display some pattern that changes over time.
    
 4. Detect the position of the button connected to GPIO C and use it to switch
    between two patterns. 

 5. Use fast switching to make the LEDs glow at different brightnesses while 
    displaying some pattern, and having some interrupt based button interaction. 
    
 6. **Bonus:** Chain up two more shift registers, and use 8 RGB LEDs to display
    something.^[The shift register data sheet has a diagram showing how to chain
    them for more storage.]

[^WhyTransistor]: The shift register in this circuit can channel only 10mA of
                  current, and if you connected them directly to the LEDs you'd
                  get a glow that's barely visible. The transistors act as 
                  simple current amplifiers so that you can have brighter LEDs.

[Read_Schem]: https://learn.sparkfun.com/tutorials/how-to-read-a-schematic
    'How to read a schematic'
[Use_Breadboard]: https://learn.sparkfun.com/tutorials/how-to-use-a-breadboard/introduction
    'How to use a breadboard'
[LED]: https://learn.sparkfun.com/tutorials/light-emitting-diodes-leds
    'Understanding LEDs'
[Pull_Up]: https://learn.sparkfun.com/tutorials/pull-up-resistors/introduction
    'Understanding Pull Up and Pull Down Resistors'
[Shift_Schem]: http://www.ti.com/lit/ds/symlink/cd4094b.pdf
    'CD4094B Shift Register Schematic'
[Trans_Schem_PN2222A]: http://www.fairchildsemi.com/ds/PN/PN2222A.pdf
    'PN2222A NPN Transistor Schematic'
[Wiki_Shift_Reg]: http://en.wikipedia.org/wiki/Shift_register
    'Wikipedia: Shift Registers'
