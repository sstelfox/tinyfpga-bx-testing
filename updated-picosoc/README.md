# Updated PicoSOC Example

Most of this was sourced from the [TinyFPGA-BX][1] project. That project was
cleaned up a little bit and updated to use nextpnr and the riscv tooling that
is available in Fedora.

To run the example on Fedora you'll need to install the following packages:

* gcc-riscv64-linux-gnu
* icestorm
* nextpnr
* yosys

To compile the solution:

```
make build
```

This also relies on [tinyprog][2] being available in your path to upload to a
target board. Once it is available you can upload it to the target board using
the following command:

```
make upload
```

While the compilation and upload have no issues, I believe this example isn't
working and I'm not sure where the error it is. Based on the contents of
firmware this seems like it should be making the LED blink, but in practice its
staying steady off.

I need to go through all the pieces to see if there are incorrect addresses
somewhere, or perhaps the clock became too fast for the blinking with the
updated software...

[1]: https://github.com/tinyfpga/TinyFPGA-BX.git
[2]: https://pypi.org/project/tinyprog/
