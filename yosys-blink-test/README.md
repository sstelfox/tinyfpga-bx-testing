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

This project is pretty simple, but I'm trying to learn "the correct" way to
handle these projects including testing, simulation, and organization all of
which are missing from this project right now. There is a lot to learn but I'll
be expanding this project as I learn.

I covered this in the README I wrote for the updated-picosoc project (which was
largely a cleanup process, and switching PnR tools), but I'm using Fedora 32 as
my development environment. I already had tinyprog installed and available
(only required if you want to program a TinyFPGA BX with this project), which
likely just came from `pip install` as it isn't available in the package repo,
other than that the following packages are required to build and run this
project:

* icestorm
* make
* nextpnr
* yosys

Additional packages I'll likely be pulling in for testing:

* gtkwave
* iverilog

I also have the following udev rules in `/etc/udev/rules.d/80-fpga-serial.rules`
setup to allow my user access to prevent the crappy ModemManager from trying to
steal my device when I plug it in.

```
# Disable ModemManager for TinyFPGA BX
ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6130", ENV{ID_MM_DEVICE_IGNORE}="1"
```

You may need to add yourself to the `dialout` group to get access to the serial
devices by default.

[1]: https://github.com/lawrie/tinyfpga_examples
