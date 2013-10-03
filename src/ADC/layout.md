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

~~~~~~{.C}
    BITON(LPC_ADC->ADCR,21); // Turn on ADC internal power
~~~~~~~

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

## Project : Optical Theramin ##


@missingfigure("Image of theramin/ someone playing a theramin")

A Theramin is a Russian musical instrument, invented in 1919, and is one 
of the few instruments played without ever being touched. 
@@
There are two large antennas on a theramin, which can detect the approximate
position of a musician's hands, and uses that to modulate the sound it produces.
@@
One hand is used to control the pitch, and the other is used to control the 
volume. @todo("Insert link to YouTube video of theramin?")

In a standard theramin the detection works by using its antennas and the 
hands of the artist as opposing plates in a capacitor. 
@@
By moving their hands around the artist can change the capacitance, and the 
instrument can use that change to generate different sounds. 

@smallfigure("Hand Sensor",assets/Light-Reflect.eps,0.5)

Our version will work of a slightly different principle, we'll use light
to sense the distance between the hand and our sensor.
@@
We'll place an LED below a photo resistor, so that when there's no hand
or other obstacle, the light from the LED will just shine onto the insensitive
read of the photoresistor. 
@@
But when we place our hands above the sensor, the light from the LED will
reflect back onto the sensitive portion of the photoresistor and give us
something we can sense. 
@@
The farther away the hand is, the less light will be reflected back, so
this setup will give us an approximate measure of distance.
@@
We can use those measurements to modulate the output of our DAC which will
be plugged into a speaker, giving us a simple optical theramin to play with. 

### Background ###

#### Voltage Dividers ####

Voltage Dividers are an essential part of the circuitry for our theramin,
and in order to understand how it all works, you must understand how these
components work.

@smallfigure("Voltage Divider Schematic",assets/Voltage-Divider.eps,0.1,Vol-Div-Scm)
    
A standard voltage diver circuit is made with two resistors placed in
series, the voltage at $V_{div}$ is the weighted average of the 
voltages at $V_{++}$ and $V_{--}$. 

  \[V_{div} = (V_{++} - V_{--})\frac{R1}{R1 + R2} + V_{--}\]

@inlinetodo("Work through a few examples of voltage divider calculations,
            explain how this only applies when there's little to no load.")
##### Potentiometers #####

@smallfigure("Potentiometer Divider Schematic",assets/Pot-Divider.eps,
            0.1,Pot-Div-Scm)

Potentiometers are a special type of voltage divider which you can adjust 
on the fly. 
@@
A potentiometer is essentially a long resistor, where you can move $V_{div}$
up and down along it. 
@@
As such, $R1 + R2$ is always going to be constant and the voltage at $V_{Div}$
depends on the position of the potentiometer's dial. 
@@
The actual value can go all the way from $V_{++}$, to $V_{--}$ since you can 
lower either $R1$ or $R2$ down to 0.

@inlinetodo("Diagram of the internals of an actual potentiometer and an
             explanation of the physical devices.")

##### Photoresistors #####

@missingfigure("Image of photoresistor circuit")

@inlinetodo("Explain photoresistors and math for finding optimal resistance values")

##### RC-Filters #####

@inlinetodo("Expand the following")

 - Signals having frequency components 
 - DAC producing impure signals because of the difference between transition
   time and rest time. 
 - Need to remove the high frequency components so that we only preserve the
   frequency we want to output
   

#### Op-Amps ####

@smallfigure("Op-Amp Schematic",assets/Basic-Op-Amp.eps,0.6,Bas-OA-Sch)

_Operational Amplifiers (Op-Amps)_ are some of the most powerful standard
circuit components. 
@@
They are circuits that run an extremely simple algorithm that can be
leveraged in very powerful ways. 

The Op-Amps can either push or pull current through their output, and 
thanks to Ohm's law $V=IR$ this means that they can control the voltage
at their output as well. 

In figure @ref(Bas-OA-Sch) the Op-Amp is connected through a resistor to
a voltage source. 
@@
Depending in the state of its inputs it can choose to do one of three things.
@@
First among these is to prevent the flow of current either in or out, 
in this case there will be no current flowing cross the resistor and the
voltage at $V_{out}$ will be 1.5v.

Next it could push current outwards, meaning there'll be a current flowing
from the output to the 1.5 volt source. 
@@
Because of Ohm's law, the voltage at the output will increase, if the 
resistor is large, the voltage will increase very quickly, until it 
hits the limit of 3 volts imposed by the Op-Amp's power source. 
@@
Alternatively if the resistor is very small, it'll take a lot of current
to increase the voltage a small amount, to the point that the power
source simply can't supply more current.
@@
If that happens the voltage at the output will hover at whatever value the
current available can sustain. 

Op-Amp modulate their output voltage with a simple algorithm.
@@
If their two inputs are held at the same voltage, the Op-Amp will keep
the output stable. 
@@
If $V_{in+} > V_{in-}$ then the Op-Amp will raise the voltage at its
output, and if $V_{in+} < V_{in-}$ then the Op-Amp will lower the voltage. 

This property can be exploited to create a number of useful circuits. 

##### Op-Amp Voltage Follower #####

@smallfigure("Op-Amp Voltage Follower Schematic"
    ,assets/Voltage-Follower.eps,0.4,Vol-Fol-Sch)

An Op-Amp voltage follower has a simple function, basically it makes sure
that the output voltage is always equal to the input voltage.
@@
To understand how this is useful we've got to first understand how loads 
can change the voltages at a point.

@smallfigure("Load Voltage Schematic"
            ,assets/Load-Voltage-Change.eps,0.7,Load-Vol-Sch)

In figure @ref(Load-Vol-Sch), we've set up two voltage dividers, using
the same $R_1$ and $_2$ but the second divider has an extra load resistor
applied to it. 
@@
$V_{1}$ will be the same value as before, but because of the
existence of the additional load resistor, $V_{2}$ will be
a different, higher, voltage. 

If, instead of connecting the load resistor directly to your divider,
you connected the divider to the voltage follower's input, 
and the load resistor to the output, as with the third setup,
the voltages at $V_{1}$, $V_3$ and $V_4$ will all be equal.
@@
Here the Op-Amp is compensating for the change in voltage the 
load would otherwise cause.

What is happening is that when $V_{in+} > V_{in-}$ the Op-Amp
will increase the voltage at the output, and that will (being
directly connected) increase the voltage at $V_{in-}$.
@@
When the opposite is true and $V_{in+} < V_{in-}$ the Op-Amp
will decrease the voltage at output, and $V_{in-}$. 
@@
Both of those actions will correct the imbalance, and make
$V_{in+} = V_{in-}$ and therefore $V_{in+} = V_{out}$. 
@@
The Op-Amp will automatically sense changes in the load, and
compensate so that the output is always equal to the input.
 

##### Op-Amp Voltage Comparator #####
 
@smallfigure("Op-Amp Voltage Comparator Schematic"
    ,assets/Voltage-Comparator.eps,0.4,Vol-Cmp-Sch)

This is very similar to the Voltage Follower, but where the 
voltage follower has a feedback loop, this circuit has no
connection at all. 
@@
This means that when $V_{in+} > V_{in-}$ the output voltage
will keep on going up till it hits the maximum voltage the 
Op-Amp can sustain, in our case usually 3v. 
@@
Likewise when $V_{in+} < V_{in-}$ the voltage will go down
until it hits the lower limit, namely 0v. 

So the output is limited to 0 and 3v, and its state will
tell whether $V_{in+} > V_{in-}$ or not, comparing the
two input values.

##### Op-Amp Voltage Amplifier #####

@smallfigure("Op-Amp Voltage Amplifier Schematic"
    ,assets/Voltage-Amplifier.eps,0.4,Vol-Cmp-Sch)

The amplifier is based off the same principle, but
instead of a direct connection, it uses a voltage 
divider. 
@@
The voltage divider formula tells us that the,
voltage at $V_{in-} = (V_{out} - V_{ref})\frac{R_2}{R_1+R_2} + V_{ref}$.

Thanks to it's nature as a feedback loop, the Op-Amp will
change $V_{out}$ so that $V_{in-} = V_{in+}$.
@@
If we assume that $V_{ref} = 0v$, then we can solve the equation
for $V_{out}$ and see the following holds:

  \[V_{out} = V_{in+}\frac{R_1+R_2}{R_2}\]

So, $V_{out}$ is a straightforward multiple of $V_{in+}$, and the amount
by which it is multiplied, $\frac{R_1+R_2}{R_2}$ is the gain of the 
amplifier. 
@@
You can do the same thing for other values of $V_{ref}$ to see that 
it's esentially the midpoint around which you're multiplying. 
@@
So if $V_{in+} = V_{ref} + 2v$ then 
$V_{out} = V_{ref} + \text{gain}\cdot2v$. 


### Materials ###

  - 2 x LED (use the bright blue ones on the strip)
  - 2 x Photoresistor
  - 2 x 2 kOhm Resistor 
  - 1 x 22 Ohm Resistor
  - 2 x 10 kOhm Resistor
  - 1 x Speaker
  - 1 x 1 Microfarad Capacitor
  - 1 x Potentiometer (Higher Resistance is better)
  - 2 x [TLV2461](http://www.ti.com/lit/ds/symlink/tlv2461-q1.pdf) Op-Amp


### Steps ###

  1) Build 2 Hand Sensors, test with oscilloscope.

@smallfigure("Hand Sensor Circuit",assets/Hand-Sensor.eps,0.25)

These are voltage dividers which will use the changing resistance of the
photoresistor to change the voltage at the ADC input. 
@@
Once the circuit is assembled connect the oscilloscope probe to the ADC 
input and wave your hand above the sensor to get something like figure
@ref(Osc-Hand-Wave).

@smallfigure("Hand Sensor Oscilloscope Trace"
    ,assets/Hand-Wave-Sense.png,0.6,Osc-Hand-Wave)

  2) Connect the hand sensors to your LPC and check if you can receive
     ADC values with GDB or semi-hosting.

  3) Get DAC to output sin waves, verify with oscilloscope. 

Once you connect your DAC output to the oscilloscope, you should see
something like figure @ref(Osc-DAC-Sin).

@smallfigure("DAC Sine Wave Oscilliscope Trace"
    ,assets/Dac-Sin-Wave.png,0.6,Osc-DAC-Sin)

  4) Build Voltage Reference 

@smallfigure("Voltage Reference Circuit",assets/Voltage-Reference.eps,0.4)

Since your DAC is limited to values between 0 and 3 volts, we can't amplify
the output around 0v, so we're constructing a reference voltage for the amplifier.
@@
First we use a voltage divider to get a point at 1.5v and then a voltage 
follower so that we can attach loads to that point, and have it stay stable. 

Once you've constructed this section of the circuit, use the oscilloscope
or multimeter to check that the voltage at $V_{ref}$ is 1.5.

  5) Build RC Filter

@smallfigure("RC Filter Schematic",assets/RC-Filter.eps,0.1,RC-Fil-Scm)

The RC filter is a component we use to smooth out the jagged edges of the 
DAC output. 
@@
At high frequencies the output of your DAC will look like figure @ref(Osc-DAC-Jag)
, with an obvious step from one output voltage value to another.
@@
When you play this sound you'll be able to hear the high frequency shifts
as a seperate tone from the sine wave you're otherwise playing. 

@smallfigure("High Frequency DAC Sine Wave Oscilliscope Trace"
    ,assets/Dac-Out-Jagg.png,0.6,Osc-DAC-Jag)

To fix this you can build an RC filter, this circuit will smooth out 
the wave by forcing it to pour energy into the capacitor and slowing
the change in voltage. 
@@
The exact workings of the filter are outside the scope of this book, but
suffice to say that it, when connected, will transform the raw DAC output
in figure @ref(Osc-DAC-Jagg) into the signal seen in figure @ref(Osc-DAC-Smooth),
where the signal in yellow is the DAC after it's connected, and the signal
in pink is the voltage at $V_{smooth}$.

@smallfigure("High Frequency RC Filter Oscilliscope Trace"
    ,assets/Dac-Out-Smooth.png,0.6,Osc-DAC-Smooth)

  6) Build Amplifier 

@smallfigure("Speaker Amplifier Circuit",assets/Speaker-Amp.eps,0.4)

We can use the amplifier to change the volume of the final sound, and
the amount of current the Op-Amp will supply. 

If you connect up the oscilloscope now (before adding the speaker), 
and have your DAC output a sine wave, you should be able to modulate
output to any gain between 1 and infinity, effectively turning the 
amp from a voltage follower to a voltage comparator and anywhere in 
between.

Sample traces are shown in figures @ref(Osc-Spa-Gain) and @ref(Osc-Spa-Comp),
with $V_{smooth}$ in pink, $V_{ref}$ in green, and $V_{speaker}$ in blue.

@smallfigure("Speaker Amplifier with Small Gain"
    ,assets/Speaker-Amp-Gain.png,0.6,Osc-Spa-Gain)
@smallfigure("Speaker Amplifier Acting As Comparator"
    ,assets/Speaker-Amp-Comp.png,0.6,Osc-Spa-Comp)

  7) Connect Speaker Circuit

@smallfigure("Speaker Circuit",assets/Speaker-Circuit.eps,0.75)

Connect up your speaker to the other circuit components, and play some
sound.

  8) Add Calibration Routines and Basic IO

In order to actively use the theramin you'll have to set up a calibration
routine. 

The amount of light on the photo-sensors, and therefore the voltage coming
into your ADCs can vary wildly depending on the brightness of the room, 
the relative position of your sensors and LEDs and a number of other
environmental factors.
@@
So in order to actually play your theramin you'll have to set up a routine
to tell your LPC what range of inputs it should expect in the current 
environment. 

This means you'll have to set up a routine where you tell the LPC to record
the maximum and minimum voltages for each hand, and scale the output frequency
and amplitude accordingly. 

  9) **Bonus:** Play something recognizable with your newly created instrument. 



