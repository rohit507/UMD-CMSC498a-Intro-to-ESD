# GPIO #

## Prequisites ##

Read the following tutorials to get you up to speed with the electronics:

 - [How to read a schematic][Read_schem]
 - [How to use a breadboard][Use_Breadboard]
 - [Understanding LEDs][LED]
 - [Using Pull Up Resistors][Pull_Up]

All these tutorials are a bit Arduino centric, but you should be able to 
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


## Memory Mapped Registers ##


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
in the memory. 

However, there are a number of privileged address, and when you try to
manipulate these a slightly different pathway is taken. 
@@
Here when the memory controller gets the instruction it notices the address 
is special, and instead of going to the memory module, it'll forward the 
request to a register that's located in the relevant peripheral.


These registers all have different functions, and you can read the manual
^[TODO: insert manual ref] to figure out what any specific register does, and 
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


## Blinking Lights ## 

So let's start with something simple; Blinking Lights. 
@@
Connect up an LED to pin `P0[9]` and ground, making sfure to place the proper
current limiting resistor in series with it. 
^[Use the schematic to figure which pin it is.]
@@
To actually turn on the LED you have to first tell the LPC that the pin is
to be used for output, and then set the state to be on. 
@@
If you look in the manual you'll see that `P0[9]`'s direction is controlled
by the 9th bit in a register located at `0x2009C000`, and that setting it 
to 1 makes it an output pin. [@LPCManual, p.107]

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

## An Easier Way ##

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

## More Registers ##

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

@>
These seem redundant until you start looking at what happens when you 
write code that uses them. 

~~~~~~~~~~{.gnuassembler}
    @   LPC_GPIO0->FIOPIN |= (1 << 9);  // Turn LED on
 	mov.w	r3, 0xc000
  	movt	r3, 0x2009
   	ldr	    r2, [r3, 20]
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


@>
 - Blinking Lights
    - Connecting things up
       - LED resistor calculations
    - Go through making a few LEDs blink without using CMSIS
 - An Easier Way
    - Convert the example to CMSIS
       - Explain with DAC CMSIS Stuff
    - Explain `FIOSET` and `FIOCLR`
       - Registers having more complex interactions than usual
 - Reading Input
    - Polling
    - Basic interrupts 
 - Project
    - Bit Banging : Control a set of leds with a shift register
      and GPIO
       - Make version that can handle 3 colors
       - Use interrupt based IO and buttons to manipulate the pattern
       - Make things move fast enough that you can vary LED brightness
         with PWM
 
<@

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

@>
# GPIO Old #

GPIO is the most basic peripheral on the LPC, and it's what allows the 
microcontroller to be more than a weak auxilary processor. It allows one
bit input and output, controlling or sensing the voltage on each of its 
pins.

## Control Registers ##

All the peripherals on the LPC are controlled through memory mapped IO 
registers where, instead of using ports or other mechanisms to communicate,
all the settings and state data are located at particular memory addresses 
that can be read from, or written to. 

Modifying the data at those memory locations makes corresponding changes
in the state of the peripheral. It is important to note that while the IO
registers look like chunks of memory to your code, they can often act very
differently. Reading from or writing to them can trigger various secondary 
effects and often they do not just simply store the data you place in them. 

If you look in `LPC17xx.h` you'll find a long list of struct definitions and 
a series of raw memory addresses. The adresses point to the chunks of memory
assigned to each peripheral and the structs show the layout of each of those
chunks of memory. 

Take the sections relevant to the digital-to-analog converter: 

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
memory allocated to DAC registers. `LPC_DAC_Typedef` is a struct that's set up
so that when it's aligned to that base address, each of the struct's fields will
align with a particular register in the DAC memory space. This whole setup means
that you can write to the DAC Control Registers with:

~~~~~~~~~~{.C}
LPC_DAC->DACCTRL = ...
~~~~~~~~~~
 
rather than having to make note of a raw memory location. 

## Pin Connect ##

In order to use GPIO or any other peripheral, one must first fiddle with the
Pin connect block. This is the device which connects various inputs and
outputs of LPC peripherals with the actual pins on the chip. There are four
possible functions for each pin, and you can choose which is currently active
by writing to the pin function select registers. 

Each pin is assigned 2 bits in a `PINSEL` register and each value corresponds with
a function that the pin can take on. You can find a table of these values in
Chapter 8 of the manual [@UM10360, p.107] arranged by the relevant register. 

Once you have these registers set up, the LPC has connected the correct pins to the
GPIO block, and you can move onto actually doing something with your LPC. 
 
## Basic Output ##

GPIO output is very simple with the LPC, it basically amounts to:
    
  1) Set the function of the relevant pin to GPIO
  2) Set the direction of the relevant pin to output
  3) Write to the pin to change the voltage


## TODO ##

- !! GPIO
  - Explanation
    - Basic GPIO
    - Pin connect
    - Output
      - FIOSET / FIOCLR
    - Input
      - Interrupts 
    - Circuits
      - Pull Up/Down Resistors
      - LED Resistor values
      - Common Anode/Cathode devices
  - Examples
    - Single Led
    - Button Polling
  - Exercises
    - RGB Led
    - Button Interrupt
<@
