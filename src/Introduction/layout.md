# Introduction 

This class will teach you about the LPC1769, an ARM Cortex microcontroller.
@@
When compared to normal CPU the LPC is a simple device, with only one processor core
and a miniscure amount of memory, it still manages to be useful. 
@@
In fact this simplicity makes it a wonderful learning tool, allowing us to forgo 
kernel and driver interfaces and work at the lowest level possible, without 
coming too complicated to just dive into. 
@@
We'll exploit this to teach you about how processors are structured, how to deal
with many common protocols and tools, and even how some of the most fundamental
parts of an operating system work. 

The LPC itself has a number of modules, which encapsulate various features of the
processor.
@@
We'll be working our way through those modules, explaining why you would use them, 
how they work, and how to use them.
@@
With each module we learn about, we'll present execises and projects that will help
you cement that knowledge, and give you a practical examples of how these devices 
can be used. 

While we'll often be working with electronics, no initial knowledge is required, 
and we'll give you the resources to learn what you need to know as you go along. 

## Resources ##

This textbook will mainly work to help you build a conceptual framework around
these topics, there are other resources that will give you the fine detail.

### The LPC 17XX User Manual ###

The User Manual ([available here][LPC_Manual]^[<http://www.nxp.com/documents/user_manual/UM10360.pdf>]) will be the main document this textbook builds on.
@@ 
It contains detailed information on all of the available features of the LPC,
and how you can use them.
@@

Though this textbook is meant to give you all of the background that the manual
lacks, it is in no way a substitute.
@@
There will be a lot we cannot actually go over and to get the most out of this
course, after every chapter you read in this textbook, you should read the 
corresponding chapters in the manual. 

### The LPC1769 Schematic ###

The schematic ([available here][LPC_Schem]
^[<http://www.cs.umd.edu/class/fall2012/cmsc498a/manuals/lpcxpresso_lpc1769_schematic.pdf>])
is the only way to know how the pins on the dev boards we work with correspond
to the pins mentioned in the manual.
@@
You'll  need to cross reference this schematic with Chapter 8 of the manual
every time you need to figure out the physical location of any one particular
pin. 

### The LPC176X Data Sheet ###

The data sheet ([available here][LPC_Spec]^[<http://www.nxp.com/documents/data_sheet/LPC1769_68_67_66_65_64_63.pdf>])
is the last reference document you should keep handy. 
@@
It contains a lot of information about the limitations of the LPC, the 
tolerances of various features, and the full set of features the LPC has. 

[LPC_Manual]: http://www.nxp.com/documents/user_manual/UM10360.pdf
    'LPC17xx User Manual'
[LPC_Schem]: http://www.cs.umd.edu/class/fall2012/cmsc498a/manuals/lpcxpresso_lpc1769_schematic.pdf
    'LPC1769 Rev b Schematic'
[LPC_Spec]: http://www.nxp.com/documents/data_sheet/LPC1769_68_67_66_65_64_63.pdf
    'LPC176x Specificiation Sheet'
