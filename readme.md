# NsfrtuRv32 :vampire:

<!-- Introduction -->
NsfrtuRv32 (pronounced Nosferatu) is my personal processor project in which I aim to build a functional RISC-V processor, with
all the features necessary for a basic high-performance microcontroller implementation, such as hardware multipliers and
dividers, a floating point unit, and more. This was originally my submission for a graduate school class on computer 
architecture, but I've since maintained it to further my understanding.

The name of course originates from my own personal love of horror movies, but does not actually mean anything about the
processor itself; you don't have to worry about it trying to turn you into a vampire.

## Goal
My current goal is to build it, verify it as best as I can using the tools I have at my disposal, namely:
1. GHDL
2. VUnit
3. OSVVM
4. Cocotb
5. Various open-source RISC-V verification tools

My stretch goal is to get it to run DOOM, as God intended. It would be awesome to see that, but since this is my pet project,
do not expect it to happen anytime soon.

Also, if you want to use it for some reason, file an issue and let me know! I don't expect it to compare to other designs like
the Neorv32 or anything that has a team of contributors backing it, but if there is interest I will happily share.

<!-- Features -->

<!-- Verification Stuff -->
## Verification Stuff
My method to verification is currently twofold:
1. Verify the component using directed testing, ensuring that it performs its expected behavior under all nominal and some 
off-nominal conditions (unit testing). I use VUnit and VHDL testbenches to accomplish this.
2. Verify the integration of components using more high level testing, ensuring that the set of components perform as expected
given an input stimuli and compared to golden models, using more UVM techniques (integration testing). I use Cocotb and 
other open source software to accomplish this.

I wish I had the knowhow and understanding to set up formal verification. The learning curve to set that up appears steep, if
repositories like riscv-formal have any bearing on that conversation. Setting up formal methods is a stretch goal, but if I 
can, I will eventually.

<!-- Getting Started -->
