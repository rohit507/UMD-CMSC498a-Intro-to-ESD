# DMA #

@inlinetodo("Finish the intro")

Often, when building embedded devices you'll have to deal with large amounts of
incoming and outgoing data. Be it reading thousands of samples per second from 
the ADC as you record sound, reading megabytes per second external memory, or
sending large chunks of data over Ethernet quickly.

The simplest way to deal with these large data streams is using the CPU.
Loop or timer based mechanisms can move large amounts of data back and forth
but at the cost of using CPU time to perform routine memcopy style tasks. 
Occasionally it's simply not passible to handle data at full speed, or satisfy
IO timing requirements using the CPU, and other methods are needed. 

This is where _Direct Memory Access (DMA)_ comes in, DMA is a special deeply 
integrated peripheral that can perform memory manipulation tasks independent
of the CPU. This means that it's possible to perform routine data gathering
tasks faster than the CPU could, without wasting CPU time, and with a level 
of timing precision that the CPU can't match. 

@missingfigure("ARM-M3 block diagram and/or DMA block diagram")

The most basic use of DMA is a memory-to-memory transfer, which will copy data
from one block of memory to another. This is analogous to a standard memcpy 
operation, albeit without blocking. One can also choose to have an interrupt 
thrown when the copy is completed in order to avoid race conditions.

The next two uses for the DMA controller are memory-to-peripheral tranfers, and
peripheral to memory transfers. These data transfers are deeply integrated 
with the revelant peripherals, and can be used to automatically gather data from
an input, or automatically send data to an output. 

Consider the output case, where we have a buffer of data we wish to write out 
to the DAC at specifically timed intervals. The DAC has a programmable countdown
timer, which can ask the DMA controller for a new piece of data after an interval. 
When the DAC timer finishes and a DMA request is sent, the DMA controller will
write a word into the DAC output register, and trigger an automatic outut update. 
At this point, the DAC will reset the timer, and start counting down to another
update, and the DMA controller will ready the next byte of data for the DAC. 
In this way you can fill a buffer with sound data, and write it out at the same
rate it was recorded. 

@missingfigure("DAC DMA Diagram?")

For the input case we can look at the ADC. Like the DAC, the ADC has a timer, 
which can trigger a conversion, and then assert a DMA request when it's done. 
Here, when the ADC timer counts down, it'll immidiately start a conversion, and
reset itself. When the conversion finishes, the DMA controller will read the 
ADC input register, and store returned data in the predefined output buffer.

@missingfigure("ADC DMA Diagram?")

For SSP and other serial communications peripherals, the DMA controller can 
read or write data as fast as it can, sequentially storing or sending large
chunks of data. 

The final case is a peripheral-to-peripheral transfer which can be useful to
forward data from one communications protocol to another without manual
intervention. @todo("Flesh this out, haven't really used p-to-p transfers")

@inlinetodo("Add detail, in the meantime read pages 607-615 of the manual")

## GPDMA in the LPC ##

The DMA controller in the LPC is called the _General Purpose DMA (GPDMA)_
controller. Mostly to reflect the fact that it can work 

@missingfigure("DMA Linked list diagram, see the figure on page 613 of the
                manual.")

## DMA with the ADC ##

@inlinetodo("ADC DMA Instructions go here. In the meantime read the 
             DMA, and ADC sections of the manual")

## DMA with the DAC ##

@inlinetodo("DAC DMA Instructions go here. In the meantime read the
             DMA, and DAC sections of the manual")

## DMA and Power Control ##

@inlinetodo("Explain how DMA interacts with sleep mode and other power
             control features")

## Project : Sound Recorder ##

This project will have you using the LPC to record sound, store it on
an SD Card, and play it back on demand. You'll have to use DMA to gather
audio samples at precise frequencies, and use external storage to make up
for the miniscule amount of onboard storage the LPC has. 

## Suggested Steps ##

  1) Get DMA and the DAC working to output standard waveforms (sine 
     waves, sawtooth functions, triangle waves), test using the 
     oscilloscope and speaker circuit from the theramin project. 

  2) Use the signal generator, or your DAC output to test reading data
     in with ADC and DMA

  3) Make sure you can send and retrieve data with SPI and your SD-Cards.

  4) Build the Microphone circuit, make sure you get sensible output
     on both the oscilliscope, and when you read data into your LPC.

  5) Add some IO LEDs and connect all the parts together so you can record
     at least 30 seconds of audio. 

## Microphone Circuit ##

### Floating Ground ###

@smallfigure("Floating Ground",assets/Floating-Ground.eps,0.6)

  - Test by making sure the voltage on the 1.5v node is correct.

We're using the Op-Amp to create a voltage source at Vcc/2, since we 
need a center point for our final signal to go above and below. This
center point also needs to be able to sustain a significant current
draw for our other components, which is why we use an Op-Amp. If we
simply used a voltage divider, the resistance of the divider itself
would keep the other components from drawing the current they need, 
you could try making the resistors small, but then the current 
traveling through the divider itself would be problematic.

### Microphone Assembly ###

@smallfigure("Mic Assembly",assets/Coarse-Mic.eps,0.6)

  - The electrolytic capacitors (the big cylindrical ones) are polarized,
    the negative side has a stripe on it.
  - Make sure that when you connect the oscilloscope to this (ground to 1.5v,
    probe to Coarse Out) you see a sound signal in the millivolt range.
  - Electret Mics also have a polarity, the negative pad on the bottom has a
    little bronze dash etched onto the PCB next to it. It's the only asymmetry
    on the bottom of the mic. 
    
These microphones are basically air pressure sensitive transistors, and with the
2k resistor, it acts like a transistor amplifier, with the input replaced by air
pressure. The capacitor and the 10 resistor together form a high pass filter, 
what this does is filter out the DC element of the air pressure, and any 
components too low in frequency to hear.

### Filters ###

@smallfigure("Filter Stage",assets/Mic-Filter.eps,0.75)

  - Test by connecting the oscilliscope to this portion of the circuit
    (ground to 1.5v, and probe to Fine Mic Out), and making sure you see
    a signal in the millivolt range. 

This is two low pass filters in series, which will significantly reduce the
amplitude of high frequency noise. 

### Offset Voltage ###

  - Test the voltage at the Offset Voltage point, and make sure that 
    it moves up and down when you fiddle with the potentiometer.

@smallfigure("Offset Voltage",assets/Offset-Voltage.eps,0.2)

The output from the microphone and the filter aren't perfectly centered 
on the 1.5v value so this offset voltage lets you tweak the final centering 
of the signal to fix that. In the final output, this pot will move the
signal up and down on the oscilloscope.

### Amplifier ###

@smallfigure("Microphone Amplifier",assets/Mic-Amp.eps,0.6)

  - Make sure the output changes scale with the new potentiometer, and 
    moves up and down with the offset potentiometer, and that you can
    get output signals that have a 3v amplitude. 

Here we use an Op-Amp amplifier to scale the microphone's signal to levels
which our LPC can read. 
    
