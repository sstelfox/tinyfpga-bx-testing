# Update PicoSOC Example

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

[1]: https://github.com/tinyfpga/TinyFPGA-BX.git
[2]: https://pypi.org/project/tinyprog/
