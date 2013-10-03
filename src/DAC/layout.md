# DAC #

@inlinetodo("Intro Paragraph")

The DAC is the analog counterpart to GPIO's digital output. Your LPC has one output
line, and

## Working Theory ##

@inlinetodo("How does the DAC work, nyquist sampling, frequency? also rename this section")

## Usage ##

To set up the DAC one has to connect a particular peripheral clock to the 
DAC and connect the DAC output to the corrent pin. 

~~~~{.C}
    LPC_SC->PCLKSEL0 |= (1 << 22); // Set pclk to 1
    LPC_PINCON->PINSEL1 |= 1 << 21; // Set H[18] to AOUT
~~~~

To use the DAC one has to write to the DAC converter register.

~~~~{.C}
    SETBITS(LPC_DAC->DACR.6,10,1035); // Set DAC to 1035 
~~~~
