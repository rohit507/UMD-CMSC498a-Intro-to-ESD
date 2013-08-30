# GPIO #

## Prequisites ##

Read the following tutorials to get you up to speed with the electronics:

 - [How to read a schematic][Read_schem]
 - [How to use a breadboard][Use_Breadboard]
 - [Understanding LEDs][LED]
 - [Using Pull Up Resistors][Pull_Up]

All these tutorials are Arduino centric, but you should be able to 
easily extrapolate to what you need to do for your LPC.

Additionally, you should keep the following documents handy, as they contain
lots of useful information we're not going to be duplicating:

 - [LPC176x Product Data Sheet][LPC_Spec]
 - [LPC17xx User Manual][LPC_Manual]
 - [LPC1769 Schematic][LPC_Schem]

## What is GPIO? ##

We'll start with the most basic peripheral on the LPC, General Purpose 
Input Output.
@@
GPIO is what lets your microcontroller be something more than an absurdly 
weak auxiliary processor for your computer.
@@
With it you can interact with the outside world, connecting up all manner
of tools and turning your microcontroller into something genuinely useful. 


GPIO has two fundamental operating modes, input and output.
@@
Input lets you read the voltage on a pin, to see whether it's held low (0v) 
or high (3v) and deal with that information programmatically.
@@
Output lets you set the voltage on a pin, again either high or low.
@@
Each and every pin on the LPC can be used as a GPIO pin, and each can 
independently set to either mode. 


Throughout this chapter we'll be walking you through two simple projects,
reading the state of a button, and making an LED blink.
@@
Using what you learn from that, you'll be able to start building more 
complex devices.

## GPIO Output ##

The first half of GPIO is the output, and it's a relatively simple system,
compared to the other parts of the LPC, but it's also one of the most 
versatile and powerful. 
@@
For the moment we'll limit ourselves to turning LEDs on and off, but the same
tools can be used to create much more complex devices.
@@
You can control the output through a simple process, first you tell the LPC
that a specific pin should be used as an output, and then you tell the LPC
whether the pin should be held low or high. 
@@
The interesting part is how exactly you can give the LPC instructions, and what
it does in order to carry them out. 

### Memory Mapped Registers ###


On a normal machine most of your hardware access is done through a kernel
interface of some sort, but here, there is no kernel.
@@
So in order to talk to the GPIO controller, or any other peripheral, we have 
what're known as memory mapped registers. 


When we try to read or write to a normal chunk of memory, the address and
instruction are sent down a bus to the memory controller. 
@@
The memory controller then either retrieves data from memory and places it 
into a register, or takes data from a register and writes it to somewhere
in the memory.@todo(Insert diagram of ARM processor?)

However, there are a number of privileged address, and when you try to
read from or write to these a slightly different pathway is taken. 
@@
Here when the memory controller gets the instruction it notices the address 
is special, and instead of going to the memory module, it'll forward the 
request to a register that's located in the relevant peripheral.


These registers all have different functions, and you can read the manual
@todo(insert manual ref) to figure out what any specific register does, and 
which address in memory it's mapped to. 
@@
The really important thing to notice is that you're not dealing with a
normal piece of memory, and these memory mapped registers can act very 
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
Even the usual guarantee that a write operation is modular and won't do
anything other than change the value of a particular piece of memory is lost.
@@
There are registers where a write operation will trigger some change in the
peripheral, making the LPC turn an LED on, or send out a signal.


### Blinking Lights ###

So let's start with something simple; Blinking Lights. 
@@
Connect up an LED to pin `P0[9]` and ground, making sfure to place the proper
current limiting resistor in series with it. 
@todo(Use the schematic to figure which pin it is.)
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
Thankfully there's already a library of macros and structures that already
exists, and which exploits the fact that the memory addresses for each single
peripheral are laid out close together, and are tightly packed. 


CMSIS is a library by NXP which sets up all these memory addresses as macros
for you. To see how it works let's look at the setup for the DAC 
(Digital to Analog Converter). 
@@
In `LPC17xx.h` you'll find a long list of struct definitions and 
a series of raw memory addresses.
@@
The addresses point to the chunks of memory assigned to each peripheral and the
structs show the layout of each of those chunks of memory. 

\pagebreak

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

The DAC is an APB1 peripheral and so `LPC_DAC_BASE` is the very start of the 
memory allocated to DAC registers. 
@@
`LPC_DAC_Typedef` is a struct that's set up so that when it's aligned to that
base address, each of the struct's fields will align with a particular register
in the DAC memory space. 
@@
This whole setup means that you can write to the DAC Control Registers without
using a raw memory location. 

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
to another platform that uses the same interface.

### More Registers ###

If you look closely there's 4 GPIO units, each controlling 32 pins, and 
each of those blocks has 5 registers. 
@@
Strictly speaking you only need the `FIODIR` (set pin direction)  and 
`FIOPIN` (set or read pin state) registers to control each pin, but there
are three others, which allow you to perform operations much faster. 

`FIOSET` and `FIOCLR` are the two fast output control registers.
@@
Writing a 1 to a bit in `FIOSET` will enable the corresponding pin, and 
writing to `FIOCLR` will disable the pin.

~~~~~~~~~~{.C}
    LPC_GPIO0->FIOSET = 1 << 9; // Turn LED On
    LPC_GPIO0->FIOCLR = 1 << 9; // Turn LED Off
~~~~~~~~~~

Each of these transactions takes a single write command, while the previous
method had to first read the register, do a computation and write back the 
result.
@@
It is also important to note that a read operation on `FIOSET` connects to 
a different register than a write operation to the same memory address.
@@
In this case, reading from `FIOSET` will get you the current output state 
of each of the pins, regardless of their mode; whereas a write sends data
to a separate circuit that makes changes in a number of other registers.
@@
`FIOCLR` has a similar write operation, but no read operation at all instead
@todo("Figure out if it returns 0s,gibberish, or a hard fault")

@inlinecomment(Rohit,Should we insert assembly here? Showing the different numbers
of instructions?)
@>
These seem redundant until you start looking at what happens when you 
write code that uses them. 

~~~~~~~~~~{.gnuassembler}
    @   LPC_GPIO0->FIOPIN |= (1 << 9);  // Turn LED on
  	mov.w	r3, 0xc000
  	movt	r3, 0x2009
    mov.w	r2, 0xc000
  	movt	r2, 0x2009
   	ldr	    r2, [r2, 20]
 	orr.w	r2, r2, 0x200
   	str	    r2, [r3, 20]
~~~~~~~~~~
~~~~~~~~~~{.gnuassembler}
    @   LPC_GPIO0->FIOSET = 1 << 9; // Turn LED On
    mov.w	r3, 0xc000
   	movt	r3, 0x2009
  	mov.w	r2, 0x200
   	str	    r2, [r3, 24]
~~~~~~~~~~
<@

`FIOMASK` serves a similar purpose, allowing you to disable various pins
by writing ones to their respective bits. 
@@
Disabling a pin via `FIOMASK` means that `FIOSET` and `FIOCLR` will do nothing
to change the state of that pin, and that `FIOPIN` will always read a zero. 

## Input ##

Getting information into the LPC via GPIO is also very simple, using the same
registers we've already looked at.
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
Writing something to `FIOPIN` won't affect any of the bits of input pins, so
you can have some pins set as input and some as output. 

Once you have this set up, you can connect up a switch with a pull down resistor
to the input pin, and be able to read the state of your button in software.

@missingfigure(Diagram of button circuit w/ tiny explanation)

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
when you press the button, but it will also change when you release the button. 
@@
And even when it changes it'll not simply toggle, but choose a new state randomly.
@@
It might stay the same or switch state with an approximately 50% chance of either.

@missingfigure(Insert figure showing zoomed in button press on oscilloscope)

This happens because buttons aren't perfect, and instead of getting smooth 
transitions from connected to disconnected, the transitions are disjointed
and shaky, this phenomenon is known as bouncing.
@@
Because the GPIO pins can only read if something is low or high these jitters 
result in a number of very fast transitions before the voltage stabilizes.
@@
Your LPC will see each of these transitions as a separate button press and toggle
the LED that many times.
@@
Since the number of transitions is random, the final state of the LED is also
random. 

There's a number of ways to combat bouncing, including keeping track of how long
a button has been pressed before triggering an event and changing the circuit. 


### Interrupts ###

@inlinetodo(Insert basic tutorial on interrupts, and how cmsis uses them)

## Project : Bit Banging ##

Bit banging is the process of implementing a serial communication protocol using
software instead of dedicated hardware. 
@@
In this case we're going to be sending data to a series of shift registers,
using GPIO pins to control 8 LEDs.


### Reading ###

@inlinetodo("Find a good tutorial on shift registers, and link it here")

### Materials ###

@inlinetodo("Write a list of the basic components they'll need w/ links to a
 datasheet or two")

### Steps ###

@inlinetodo("Large scale project steps")


\todototoc
\listoftodos

[Read_Schem]: https://learn.sparkfun.com/tutorials/how-to-read-a-schematic
    'How to read a schematic'
[Use_Breadboard]: https://learn.sparkfun.com/tutorials/how-to-use-a-breadboard/introduction
    'How to use a breadboard'
[LED]: https://learn.sparkfun.com/tutorials/light-emitting-diodes-leds
    'Understanding LEDs'
[Pull_Up]: https://learn.sparkfun.com/tutorials/pull-up-resistors/introduction
    'Understanding Pull Up and Pull Down Resistors'
[LPC_Manual]: http://www.nxp.com/documents/user_manual/UM10360.pdf
    'LPC17xx User Manual'
[LPC_Schem]: http://www.cs.umd.edu/class/fall2012/cmsc498a/manuals/lpcxpresso_lpc1769_schematic.pdf
    'LPC1769 Rev b Schematic'
[LPC_Spec]: http://www.nxp.com/documents/data_sheet/LPC1769_68_67_66_65_64_63.pdf
    'LPC176x Specificiation Sheet'
