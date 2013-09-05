Introduction to Embedded Systems Development with the LPC 1769 
======================

A textbook for computer scientists taking an ESD course at the 
University of Maryland

## Building ##

At the moment this requires the following software:

    Pandoc 1.11.1 (Ubuntu has an old version,
                   so you might just want to 
                   build it yourself.) 
    Ruby 2.0.0    (Use RVM)
    GPP 2.24
    Bibtool 2.55

Ideally with the `texlive-full` package or similar, so you'll have
a good selection of common LaTeX packages. 

To actually build the book : 

    rake book.pdf

To build each chapter seperately :

    cd src/<chapter>/
    rake layout.pdf



