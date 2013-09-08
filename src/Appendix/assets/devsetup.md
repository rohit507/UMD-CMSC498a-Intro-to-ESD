## Development Environment Setup ##

Executables destined for a microcontroller are somewhat different than
executables you intend to simply run. 
@@
Where a normal executable will be loaded by an OS, we need to make files
that can be flashed, bit for bit, onto the microcontroller's memory and run.
@@
To greatly simplify, an OS takes an executable file, loads it into memory, 
looks for a pointer to first instruction to execute in the executable's 
metadata, and starts a process with the program counter set to that location. 
@@
We have no OS to offload a lot of this work to, we must build files that can
be moved directly onto the LPC's memory, with the starting instruction and other
features in the correct locations. 

To do this we will be using a toolchain building applications for `arm-none-eabi`
, which means:

`arm`

  : The CPU architecture we're building our applications for, this determines the
    instructions and registers we have available, among other things.

`none`

  : This is the operating system we're building for, in this case we're building
    applications that run on the bare metal, with no intervening OS.

`eabi`

  : The Embedded Application Binary Interface, this defines the conventions for 
    data types, file formats, stack usage, register usage, and function parameter
    passing. Having a standard specification for this [^arm-eabi-spec] means 
    different libraries can be compatible with each other and your code. 
    
[^arm-eabi-spec]: The ARM EABI Standard : <http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042e/IHI0042E_aapcs.pdf>

This toolchain comes with a number of tools, :

`as`

  : The GNU assembler, which takes the assembly our compiler outputs, and gives
    us ARM compatible machine code.

`gcc`

  : The GNU compiler collection which will take our C code, and turn it into
    assembly.

`gdb`

  : The GNU debugger, you can use this to view your program as it's executing, 
    and see what its internal state is. 

`ld`

  : The GNU linker, which takes compiled object code and can correlate all the 
    symbols and link it into a single executable. 

There's also a number of less important tools from 
[Gnu Binutils](http://www.gnu.org/software/binutils/) that we'll be using, all
targeted to `arm-none-eabi`. 

### Install Steps ###

#### LPCXpresso ####

In order to save building these tools ourselves, and to get the tools which will
allow us to flash the LPC through the proprietary LPC-Link board, we'll have to
download and install LPCXpresso, a set of tools and Eclipse based IDE for working
with the LPC. 

To download the tools, visit the
[LPCXpresso Website](http://lpcxpresso.code-red-tech.com/LPCXpresso/) 
and register an account. 
@@
Once you have confirmed your email, you will be able to visit
the [download page](http://lpcxpresso.code-red-tech.com/LPCXpresso/Downloads). 
@@
There, download the latest version of LPCXpresso 5 for your operating system 
and follow the provided installation instructions. 
@@
Take note of the installation directory, we'll use it later.

At this point, you can launch LPCXpresso and use it, if you would like.
@@
It is recommended to launch it at least once and go through the
software activation step (no payment necessary, you are just verifying
your email again), as this upgrades the proprietary tools to handle a
larger file size. 

#### Git ####

You also need to install the [Git](http://git-scm.com/downloads)
version control system.
@todo("Windows Instructions,and path changes.")

Git is a similar tool to SVN or CVS and allows you to store your
code's history and synchronize development with other
programmers.

We use git to manage our build system.

#### CMake ####

Next, install the [CMake](http://www.cmake.org/) build system.
@todo("Windows Instructions,and path changes.")

CMake is a meta-build system.
@@
Instead of the standard UNIX `make`, which directly compiles source code
into the desired output format, CMake instead generates one of many
different types of build systems,which are then used to perform the 
actual compilation.
@@
This is useful for allowing different developers to use their preferred
development environment (POSIX, Visual Studio, Eclipse, etc...).
@@
In our example, we will use CMake to generate `Makefile`s.

#### MinGW ####

If you're on windows, you should also install 
[MinGW](http://www.mingw.org).

MinGW or Minimalist GNU for Windows is a package containing all of the
usual GNU tools, and GNU binutils, specifically targeted to compile windows
binaries. 

#### UMD LPC Build ####

The UMD LPC Build system was created in order to let us use the LPC with
our own choice of editors for coding, and a standard `gdb` session to 
debug, instead of having to deal with a clumsy, hard to use proprietary 
IDE. 

To install, start by cloning the repository from github, while in whatever
directory you wish to work out of:

~~~~~~~~~~{.bash}
    git clone https://github.com/rohit507/UMD-LPC1769-Build.git
~~~~~~~~~~

This will have git retrieve the latest version of the build system from 
github.
@@
We've also created a few submodules: separate repositories storing single
projects that let you manage them with git at the project level instead of
having to makes changes to the entire workspace whenever you wish to change
a project.
@@
To initialize these, run the following:

~~~~~~~~~~{.bash}
    # Get submodules
    cd GNU-LPC-Core/
    git submodule init
    git submodule update
~~~~~~~~~~

Next we need to run the setup script and set a few internal variables so
CMake will know where it should look for the `arm-none-eabi` toolchain, and
proprietary tools.
@@
Here the `DLPCXPRESSO_DIR` variable should be set to the root directory 
under which all of the necessary files can be found, this should contain
the `lpcxpresso` binary.@todo("Add Windows to footnote") ^[On Linux or OSX it
should look like `/usr/local/lpcxpresso_5.1.2_2065/lpcxpresso/`.  On Windows
it should look like `TODO: Insert actual path here`.] 

~~~~~~~~~~{.bash}
    # Run setup script
    cd _setup
    cmake . -DLPCXPRESSO_DIR=<LPCXpresso Root Dir>
~~~~~~~~~~

During setup, our script copied over the `CMSIS` library, this is a library that
provides some very basic LPC functionality, but we still need to unzip it.

On Linux or OS X: 

~~~~~~~~~~{.bash}
    # Extract CMSIS library .zip
    cd ..
    unzip CMSISv2p00_LPC17xx.zip -d CMSISv2p00_LPC17x
~~~~~~~~~~

On Windows: 

@inlinetodo("Add instructions here")

Now from within the `CMSIS` directory, we'll use CMake to generate a 
build system.

On Linux or OS X: 

~~~~~~~~~~{.bash}
    # Build CMSIS
    cd CMSISv2p00_LPC17xx/
    cmake . -G "Unix Makefiles"
    make
~~~~~~~~~~

On Windows: 

@inlinetodo("Add instructions here")

Now we can build our skeleton project, which is the bare template
all your projects will be build from.

On Linux or OS X: 

~~~~~~~~~~{.bash}
    # Build CMSIS
    cd ../Skeleton
    cmake . -G "Unix Makefiles"
    make
~~~~~~~~~~

On Windows: 

@inlinetodo("Add instructions here")

At this point all your installation steps are done and we can go over 
basic usage, and workflow.

### Available Targets ###


The default build target builds a .axf file with debug settings.

The following targets are provided:

`lst` 

  : Generate a .lst file, which includes an overview of all
    the sections and symbols in your output, along with a complete
    disassembly.

`hex` and `bin` 

  : Generate alternate formats of the normal .axf
    output, which may be useful if you want to use other tools.

`boot`

  : Boot the LPC-Link board. This is required before flashing
    or debugging the microcontroller using the LPC-Link board.

`flash`

  : Write the currently built output to the
    microcontroller. The microcontroller immediately starts running
    after the flash is complete.


`flash-halt` 

  : The same as `flash`, but the microcontroller is left
    in a stopped state.

`gdb`

  : Launch a gdb session. Complete debug information is also
    setup. Note that it is not always simple to restart the current
    program. `run` (`r`) will work for some programs, and sometimes,
    using `jump` (`j`) to jump to the entry point of the current image
    (found with `info files`) works. However, none of these completely
    reset the chip - the only command that will is the `load` command,
    however that will flash the entire image to the chip again, which
    may take a while for projects with large compiled binaries. Also
    note that some circuits (particularly when interfacing with other
    chips that have their own state) may require completely unplugging
    the circuit between program runs.

If using makefiles, these are directly accessible as `make lst`,
etc. (run in the root directory of the desired project). If you are
using a build system based around IDE project files (such as Eclipse
or Visual Studio), the targets should be accessible from a menu.

### Typical Workflows ###

These sections detail how to do many common tasks. They are written
under the assumption that a Makefile build system is being used, but
the calls to `make` can all be substituted with the appropriate action
in any other chosen build system.

#### Start a new project (by forking):

First go [here](https://github.com/rohit507/GNU-LPC-Skeleton) and fork
a new project. 

In your terminal:

~~~~~~~~~~{.bash}
    git submodule add http://github.com/yourname/newprojectname
    git add .gitmodules
    git commit -m "Added a submodule for NewProjectName"
    git submodule update
    cd NewProjectName
    YOUR_EDITOR CMakeLists.txt
    # Edit CMakeLists.txt, and change the project name.
    cmake . -G "Unix Makfiles"
    make
~~~~~~~~~~

#### Start a new project (by copying):
 
In your terminal: 

~~~~~~~~~~{.bash}
    cp -R Skeleton/ NewProjectName
    cd NewProjectName
    YOUR_EDITOR CMakeLists.txt
    # Edit CMakeLists.txt, and change the project name.
    cmake . -G "Unix Makfiles"
    make
~~~~~~~~~~

#### Work on an existing project

In your terminal:

~~~~~~~~~~{.bash}
    # Open source files in editor and make + save changes
    make
~~~~~~~~~~

#### Enabling semihosting for a project

Open a project's `CMakeLists.txt` file and uncomment the following line:

~~~~~~~~~~{.cmake}
    set(SEMIHOSTING_ENABLED True)
~~~~~~~~~~

Then just rebuild the project, and semihosting messages will be
viewable in gdb.

#### Adding compiler options

All compiler options are configured in
`Platform/LPC1769_project_default.cmake`. To add compiler
options to a single project, you can use CMake's `add_definitions`
command in that project's CMakeLists.txt.

In your `CMakeLists.txt`:

~~~~~~~~~~{.cmake}
    add_definitions(
      -Wall
      -Werror
      -02
      # Add more compiler flags here
    )
~~~~~~~~~~


#### Add a source file to a project

When adding source files to a project, remember to open that projects
CMakeLists.txt and add the file to the `SOURCES` variable.

In your `CMakeLists.txt`:

~~~~~~~~~~{.cmake}
    set(SOURCES
      src/cr_startup_lpc176x.c
      src/project.c
      # Add more source files here
    )
~~~~~~~~~~

#### Flash a program

In your terminal:

~~~~~~~~~~{.bash}
    # Plug in the LPC1769
    make
    make boot
    make flash
~~~~~~~~~~

#### Debug a program

In your terminal :

~~~~~~~~~~{.bash}
    # Plug in the LPC1769
    make
    make boot
    make gdb
~~~~~~~~~~

In GDB: 


@@ The {.ruby} is a hacky way to get pandoc to see `#` as a comment
~~~~~~~~~~{.ruby}
    b main
    load
    c

    # Make changes to the program

    make
    load
    c
~~~~~~~~~~

For more information on how use GDB refer to a 
[simple tutorial](http://www.cs.cmu.edu/~gilpin/tutorial/) or the
[full user manual](https://sourceware.org/gdb/current/onlinedocs/gdb/).
