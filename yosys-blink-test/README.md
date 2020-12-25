# Blinky Test

This is a minor adapatation of [blinky tinyfpga][1] example using yosys and
tinyprog directly instead of APIO as well as the pin map from the
updated-picosoc. I used it mostly to ensure that other project's pin map was
correct (at least for the clock and user LED) as the other example doesn't seem
to be working.

One thing I noted is that this project is setting the pull up resistor for USB
to low, the other one is setting it high as well as bringing both the positive
and negative USB pins to low... I'll probably have to review the schematic to
see which is actually the correct behavior.

[1]: https://github.com/lawrie/tinyfpga_examples
