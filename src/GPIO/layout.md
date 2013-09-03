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
in the memory.@comment(Rohit,Insert diagram of ARM processor? It'll show all
connected components, which would be cool.)

However, there are a number of privileged address, and when you try to
read from or write to these a slightly different pathway is taken. 
@@
Here when the memory controller gets the instruction it notices the address 
is special, and instead of going to the memory module, it'll forward the 
request to a register that's located in the relevant peripheral.


These registers all have different functions, and you can read the manual
to figure out what any specific register does, and  which address in memory
it's mapped to. 
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
of instructions? is it relevant since ARM isn't a one cycle per instruction 
architecture?)
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

## GPIO Input ##

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
@comment(Rohit,"Do we really need this basic a drawing, esp since we're not
providing one for basic LED things?")

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
a button has been pressed before triggering an event and changing the circuit to 
debounce it.

### Interrupts ###

There's another way to get input from GPIO pins, this time without having to stop
and poll the state of your button waiting for something to happen. 
@@
With the correct settings the processor can wait for an event in the background
while letting your code run in the meantime. 
@@
When the event happens, the processor will pause your currently running code, run
code to respond to the event, and restart the execution of your main program. 

While there are many events the LPC can do this for, we'll quickly look at how
it works with GPIO. ^[We'll go into more detail and see more complex uses later.]
@@
These events, known as interrupts, can be initiated when a GPIO input
pin changes from 0 to 1 (known as a rising edge) and from 1 to 0 (a falling edge).
@@
When this change is detected, the GPIO Controller flips a flag in the NVIC
(Nested Vector Interrupt Controller) telling it to execute the GPIO Interrupt
Handler.
@@ 
When the flag is set the NVIC performs a context switch, it saves all the registers 
to the top of the stack, @todo("Figure out if/how else it modifies the stack") and
moves the program counter to the start of the interrupt handling function.  

The interrupt handler executes, doing whatever you programmed, when it's done the
NVIC takes control again. 
@@
If the interrupt flag is still set, the interrupt handler will execute the 
interrupt again, but if you unset it, it'll reset the register state to what it
saved to the stack, allowing your initial program to continue running. 

@missingfigure(Image of the changing stack as the interrupt executes)

#### Setting Up an Interrupt Handler ####

Setting up a GPIO interrupt is another relatively simple process, starting with
telling the NVIC to enable the relevant external interrupt. 
@@
Then in the struct `LPC_GPIOINT` you'll find the registers `IO0IntEnR` and 
`IO0IntEnF` which define which pins on GPIO Port 0 generate interrupts on a
rising and falling edge.^[There's corresponding registers for GPIO Port 2, the
other GPIO ports don't have interrupt support]

~~~~~~~~~~{.C} 
    // Turn on External Interrupt 3
    NVIC_EnableIRQ(EINT3_IRQn);
    // Enable Rising Edge Interrupt on P0[9]
    LPC_GPIOINT->IO0IntEnR |= (1 << 9);
    // Enable Falling Edge Interrupt on P0[9]
    LPC_GPIOINT->IO0IntEnF |= (1 << 9);
~~~~~~~~~~

@todo("Test code sample")

Once the interrupt is enabled and will trigger on the right pins, the handler has
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
        if((LPC_GPIOINT->IO0StatR >> 9) & 1){
            // Turn on P0[8]
            LPC_GPIO0->FIOPIN |= 1 << 8;      
        }
        // If the falling edge interrupt was triggered
        if((LPC_GPIOINT->IO0StatR >> 9) & 1){
            // Turn off P0[8]
            LPC_GPIO0->FIOPIN &= ~(1 << 8);      
        }
        // Clear the Interrupt on P0[9]
        LPC_GPIOINT->IO0IntClr |= (1 << 9);
    }
~~~~~~~~~~

@todo("Test Code Sample")

Because the same interrupt handler will be called for any event one has to check
the interrupt status registers to see which pin triggered the interrupt and on
which edge it was triggered for. 
@@ 
`IO0IntStatR` will have bits set when the relevant pin was triggered by a rising 
edge, and `IO0IntStatF` does the same for a falling edge. 
@@
Once you've done the relevant action you can clear a particular pin's interrupt
by writing a 1 to the relevant bit in `IO0IntClr`, if you don't do this the 
interrupt will be called again till all the pins have had their interrupts cleared.
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

### Reading ###

@inlinetodo("Find a good tutorial on shift registers, and link it here")

### Materials ###

@inlinetodo("Write a list of the basic components they'll need w/ links to a
 datasheet or two")

### Steps ###

 1. Wire up the following circuit

    @inlinetodo("Insert Diagram for 8 Leds + button ")

 2. Write a program that uses GPIO A as a clock, and GPIO B to shift in data
    slowly so that a single lit LED advances slowly across the line of LEDs.
    
    @inlinetodo("Insert Diagram for Shift register protocol ")

 3. Speed it up enough that a single cycle of 8 shifts is too fast to see and
    make it look like the lit LED is moving the other direction. 

 4. Detect the position of the button connected to GPIO C and use it to switch
    between the two patterns. 

 5. Use fast switching to make the LEDs glow at different brightnesses while 
    displaying some interesting pattern, and having some button interaction. 
    
 6. **Bonus:** Chain up two more shift registers, and use 8 RGB LEDs to display
    something. 

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
