# TinyFPGA BX Playground

I wanted an empty place that I could slowly build up a project from scratch,
that's what this directory is for. I'll be building up my notes on the project
here probably in some sort of unorganized manner that evolves over time. At
some point I'll go back and aggregate changes, decisions, and corrections and
summarize things up to a point but no telling when. This really is for me and
anyone that wants to follow along my mental journey.

## Initial Project Setup

I started a fresh Fedora 32 install in a VM to ensure I hit all the dependency
setups. I'll be doing USB passthrough of the TinyFPGA BX once I get to that
point so it should otherwise be indistinguishable from a normal host. Packages
on other versions of Fedora or other distributions are likely to be different
so YMMV.

### Basic Environment Setup

This is probably not necessary for most people, this is setting up a minimal
version of my editing environment so I'm comfortable to work in it.

```
sudo dnf install git-core neovim tmux -y

cat << 'EOF' > ~/.bashrc
export GIT_COMMITTER_EMAIL="sstelfox@bedroomprogrammers.net"
export GIT_COMMITTER_NAME="Sam Stelfox"
export GIT_AUTHOR_EMAIL=$GIT_COMMITTER_EMAIL
export GIT_AUTHOR_NAME=$GIT_COMMITTER_NAME

export HISTCONTROL="ignoreboth"
export HISTIGNORE="ls:bg:fg:history"
export HISTSIZE=-1
export HISTTIMEFORMAT="%F %T "

# Update the path for the python tools we'll be installing
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:~/.local/bin"

# Since this isn't sourcing any system default bashrc, we need to set our prompt
# to something that won't get in the way
export PS1="\w \$ "

alias gl='git log --graph --pretty=format:"%Cred%h%Creset - %G? %C(yellow)%d%Creset%s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=rfc'
alias gs='git status'
alias vim='nvim'
EOF

cat << 'EOF' > ~/.gitconfig
[apply]
  whitespace = fix

[user]
  useConfigOnly = true

[transfer]
  fsckobjects = true
EOF

cat << 'EOF' > ~/.tmux.conf
set -g prefix C-A

set -g status-bg black
set -g status-fg green
set -g status-interval 30

set -g status-left ' '
set -g status-right '#[fg=cyan]%H:%M#[default]'

setw -g mouse off

bind C-a last-window
bind a send-prefix

unbind %
bind \\ split-window -h
bind - split-window -v

set-window-option -g mode-keys vi
bind-key k select-pane -U
bind-key j select-pane -D
bind-key h select-pane -L
bind-key l select-pane -R
EOF

# This is definitely not expected... Man this project is managed poorly...
mkdir -p ~/.config/nvim
cat << 'EOF' > ~/.config/nvim/init.vim
set expandtab shiftwidth=2 tabstop=2 textwidth=120
set list listchars=tab:>-,trail:-
set noswapfile
set number
set smartcase
EOF
```

### FPGA Development Environment

Definitely a work in progress, I'll add packages, configs, etc to here as my
environment develops. The hardware rules are specific to the TinyFPGA BX board,
if you're using something else you might have to adjust them accordingly.

```
# Note: the following change requires you to logout and back in to have the new
# group stick to you
sudo usermod -a -G dialout $(whoami)
```

Create the following file at `# /etc/udev/rules.d/80-fpga-serial.rules`

```
# Disable ModemManager for TinyFPGA BX
ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6130", ENV{ID_MM_DEVICE_IGNORE}="1"
```

Run the following commands:

```
sudo udevadm control --reload-rules
sudo udevadm trigger
```

When you plug in the TinyFPGA BX you should see the following show up in `dmesg`:

```
[ 3969.897491] usb 1-4: new full-speed USB device number 3 using xhci_hcd
[ 3970.036596] usb 1-4: New USB device found, idVendor=1d50, idProduct=6130, bcdDevice= 0.00
[ 3970.036598] usb 1-4: New USB device strings: Mfr=0, Product=0, SerialNumber=0
[ 3970.059379] cdc_acm 1-4:1.0: ttyACM0: USB ACM device
```

I'm going to be using a fully open source toolkit for my FPGA development since
target FPGA (Lattice iCE40LP8K on a [TinyFPGA-BX][1] board, available for sale
through the projects [website][2]) can use open source tolling. You can do
almost everything except see your code working in person without actually
having the hardware though.

```
sudo dnf install icestorm make nextpnr yosys -y
pip install tinyprog --user
```

I'll likely also want the following packages, but I don't want to explicitly
add them to the install list until I do:

* gtkwave
* iverilog

At this point you should be able to test that the system can see my board:

```
$ tinyprog -l

    TinyProg CLI
    ------------
    Using device id 1d50:6130
    Only one board with active bootloader, using it.
    Boards with active bootloaders:

        /dev/ttyACM0: TinyFPGA BX 1.0.0
            UUID: e99a03e7-632e-4393-ab1f-0e2106f8afdb
            FPGA: ice40lp8k-cm81

```

Make sure the bootloader is up to date:

```
tinyprog --update-bootloader
```

### Project Initialization

The following commands setup a basic project directory with some working
minimal code. I would leave the project truly empty a "no-op" config, but it
seems yosys doesn't recognize empty modules as existing, and it produces
warnings without any clocks. To initialize the project in a way that can work
from the get go, a minimal pin configuration and the blink example were brought
in.

```
mkdir -p ~/workspace/electronics/fpga-playground/{cfg,rtl,src}
cd workspace/electronics/fpga-playground

cat << 'EOF' > Makefile
# Note: If the FPGA family, or the package changes then the build commands will have to be updated.
BOARD_PIN_DEFS = cfg/tinyfpga_bx
TARGET_MHZ = 16

out/hardware.bin: tmp/hardware.asc
	mkdir -p out/
	icetime -d lp8k -c $(TARGET_MHZ) -m -t -r tmp/hardware.rpt tmp/hardware.asc
	icepack tmp/hardware.asc out/hardware.bin

tmp/hardware.asc: $(BOARD_PIN_DEFS).pcf $(BOARD_PIN_DEFS)_addl_clks.py tmp/hardware.json
	nextpnr-ice40 --lp8k --package cm81 --pcf $(BOARD_PIN_DEFS).pcf --pre-pack $(BOARD_PIN_DEFS)_addl_clks.py --json tmp/hardware.json --asc tmp/hardware.asc

tmp/hardware.blif tmp/hardware.json &: rtl/hardware.v
	mkdir -p tmp/
	yosys -Q -q -l tmp/hardware.log -p 'synth_ice40 -top hardware -blif tmp/hardware.blif -json tmp/hardware.json' $^

build: out/hardware.bin

clean:
	rm -f out/hardware.bin tmp/hardware.{asc,blif,json,log,rpt}

upload: out/hardware.bin
	tinyprog -p out/hardware.bin

.DEFAULT_GOAL := build
.PHONY: build clean upload
EOF

cat << 'EOF' > cfg/tinyfpga_bx.pcf
# https://github.com/YosysHQ/nextpnr/blob/master/docs/constraints.md
# https://github.com/YosysHQ/nextpnr/blob/master/docs/ice40.md

#set_io [-nowarn] [-pullup yes|no] [-pullup_resistor 3P3K|6P8K|10K|100K] port pin
#set_frequency net frequency

set_io clk_16mhz B2
set_io user_led B3
set_io usb_pullup A3
EOF

cat << 'EOF' > cfg/tinyfpga_bx_addl_clks.py
#ctx.addClock("csi_rx_i.dphy_clk", 96)
#ctx.addClock("video_clk", 24)
#ctx.addClock("uart_i.sys_clk_i", 12)
EOF

cat << 'EOF' > rtl/hardware.v
module hardware (
  input clk_16mhz,

  output user_led,
  output usb_pullup
);
  // Drive the USB pull-up resistor low to disable USB
  assign usb_pullup = 0;

  // Incrementing clock to slow down our selection of the bit pattern being
  // output to the LED
  reg [25:0] blink_counter = 0;

  // Pattern that will be displayed on the LED over time
  wire [31:0] blink_pattern = 32'b101011110000101011110000101011110000;

  // Update our clock counter every clock cycle
  always @(posedge clk_16mhz) begin
    blink_counter <= blink_counter + 1;
  end

  // Use the high order bits of our blink counter to select the position in
  // our blink pattern we should be outputting
  assign user_led = blink_pattern[blink_counter[25:21]];
endmodule
EOF

git init
git add -A
git commit -m "initial project creation"
```

Before we do much design we need to understand what we're building for, the
Makefile above is specific to the iCE40LP8K-CM81 ([datasheet][4]). If your
target differs you'll have to adjust the build commands to match. How the
package is physically connected on the board is going to define our pin
mapping. Luckily our board has all the hardware specific information
[available][5].

The project has handy images in the root directory that have pin mappings of
all the exposed pins with what pads they are connected to and in some cases
hints at what the pins intended use are (such as the SPI pins). It is missing
at the very least the clock pin on the rendered images.

Things you'll want to find in the schematic:

* Which pins are used on the FPGA package
* Which FPGA pins are connected to what peripherals
* Which FPGA pins have general pads exposed for GPIO (can be used for additional
  peripherals or as debug pins)
* Which pins are connected to external clocks (and what is their frequency)

I haven't designed a FPGA board from scratch, but there is some additional
things being taken care of for us with this board. Specifically it has been
setup already to pull a bootloader bitstream automatically (I assume from the
onboard flash) that allows us to program a bitstream and firmware (referred to
as user data) using a easy USB serial interface.

If I had to do a fresh design I would probably need to figure out how to
configure where the FPGA finds its initial bitstream, how that is stored, and
how to program the raw device.

## Project Style Guidelines

I tried to find a good style guideline for a Verilog project and couldn't find
anything about the structure, just coding [guidelines][3]. It's probably highly
subjective to different environments but these are highlights that I want to
keep close at hand. This will very likely evolve over time.

* 2 space indentation (not tabs)
* Use the suffixes `_in`, `_out`, and `_reg` for module signals representings
  inputs, outputs, and registers respectively.
* At most one module per file
* One Verilog statement per line
* One port declaration per line
* Preserve port order as defined between the port declarations and definitions
  in modules
* Line length not to exceed 120 characters
* Modules, tasks, and functions must not modify nets or variables not passed as
  ports into the module.
* Partition separate clock domains into separate modules. The synchronization
  logic should be part of the receiving clock domain.
* Asynchronous logic should be partitioned from synchronous logic.
* Combinational feedback loops must not be used.
* Avoid ports of type `inout`
* Verilog files will live in the `rtl` directory in the root of the project
* Source code belonging to firmware, or additional user data that will live on
  top of the verilog design belong in the `src` directory in the root of the
  project
* Board pin configuration for specific hardware should live in a `cfg` directory
  named after the board and version where appropriate.
* All build artifacts should be ignored from the git directory
* The project `Makefile` should define `build`, `clean`, and `program` phony
  targets. The `build` target should be the default and build both the verilog
  design and any required firmware, the `clean` target should remove all build
  artifacts, and the `program` target should handle uploading the currently
  built design to the attached hardware.
* Commonly `top.v` is used for the entrypoint into the project, I prefer
  `hardware.v` as its more descriptive for what is being built.
* Logical groups of modules should be kept in subdirectories (for example
  components of an ALU)

## Verilog HDL Notes

Operators:

* `+` binary addition
* `-` binary subtraction
* `&` bitwise AND
* `&&` logical AND
* `|` bitwise OR
* `||` logical OR
* `^` bitwise XOR
* `~` bitwise NOT (invert a bit pattern, ~1010 == 0101)
* `!` logical NOT (non zero values true or 1, only zero value is false or 0)
* `==` equality
* `>` greater than
* `<` less than
* `{}` concatenation
* `?:` conditional (this is a ternary operator like output = condition ? truthy statement : falsey statement)

The opensource version of Yosys doesn't support all of the features of
SystemVerilog, officially it only supports Verilog 2005 but there are some very
useful features that are available, namely typedefs and enums both of which can
help reduce errors during development and provide more clarity when reading.

### Cheat Sheet

#### Wires

```
wire input a,b;
wire output y;
wire input a2[1:0],b2[1:0];
wire output y2[1:0];
wire output y3[2:0];
```

#### Assignment

An assign statement is used for modeling only combinational logic and it is
executed continuously. So the assign statement is called 'continuous assignment
statement' as there is no sensitive list (see always blocks later).

```
assign y = a;
```

#### Logic Bitwise Primitives

*Negation:*

```
assign y = ~a;
```

*AND Gate:*

```
assign y = a & b;
```

*OR Gate:*

```
assign y = a | b;
```

*Exclusive OR Gate:*

```
assign y = a ^ b;
```

*Reduction:*

```
assign y = | a2;
```

Is equivalent to:

```
assign y = a2[1] | a2[0];
```

*Concatenation and Replication:*

```
assign y2 = {a, b};
assign y2 = {a, 1'b0};
assign y3 = {a, b, 1'b1};
assign y3 = {a, 2'b10};
assign y3 = {a, a2};
assign y3 = {a, a2[0], 1'b1};
assign {y2, y} = {y3[1:0], a};
assign y3 = {a, 2{1'b1}};
```

*Shifting:*

```
// a         a >> 2    a >>> 2   a << 2    a << 3
// 01001111  00010011  00010011  00111100  01111000
// 11001111  00110011  11110011  00111100  01111000
assign y2 = a2 >> 1; // Logical 0's shifted in
assign y2 = a2 >>> 1; // Arithemtic MSB sign bit shifted in
assign y2 = a2 << 1; // Logical shift left same result as
assign y2 = a2 <<< 1; // Arithmetic shift left
```

*Rotate right 1 bit:*

```
assign y3r = {y3[0], y3[2:1]};
```

*Rotate right 2 bit:*

```
assign y3r = {y3[1:0], y3[2]};
```

*Operator precedence:*

```
!,~,+,-(uni),**,*,/,%,+,-(bin),>>,<<,>>>,<<<,==,!=,===,!==,&,^,|,&&,||,?: */
```

*Tertiary Conditional Assignment:*

```
assign max = (a > b) ? a : b;
```

*If/Else:*

```
if(a < b) begin
    assign min = a;
end else begin
    assign min = b;
end

if (boolean) begin
    // if code
end else if (boolean) begin
    // if else 1 code
end else begin
    // else code
end

if (boolean) begin
    // if code
end else begin
    // else code
end
```

*Synthesis of Z and X Values:*

Z values can only be synthesized by tristate buffers and thus infer them these
have output enable inputs to control their output state for example here is a
single bit tristate buffer with an output enable

```
assign y = (oen) ? a : 1'bz;
```

This sort of construct is useful for bidirectional ports or buses.

The synthesis of X is don't care, the value may be either 0 or 1, this can
improve the efficiency or optimization of combinational circuits

```
assign y = (a == 2'b00) ? 1'b0:
               (a == 2'b01) ? 1'b1:
                   (a == 2'b10) ? 1'b1:
                       1'bx; // i == 2'b11
```

*Behavioral Blocks:*

Procedural blocks using always block, these black box sections describe
behavior using procedural statements, always behavioral blocks are defined with
an event control expression or sensitivity list:

```
always @(sensitivity list) begin [Optional label]
    [optional local variable declarations];

    [procedural statements];
end [optional label]
```

*Procedual Assignment:*

```
[variable] = [expression];  // blocking, assigned before next statement like normal C
[variable] <= [expression]; // non blocking, assigned at end of always block
```

Blocking tends to be used for combinational circuits, non-blocking for
sequential

In a procedural assignment, an expression can only be assigned to an output
with one of the variable data types, which are reg, integer, real, time, and
real time. The reg data type is like the wire data type but used with a
procedural output. The integer data type represents a fixed-size (usually 32
bits) signed number in 2's-complement format. Since its size is fixed, we
usually don't use it in synthesis. The other data types are for modeling and
simulation and cannot be synthesized.

*Registers:*

A register is simple memory wire to hold state, normally implemented as D-Types

```
output reg
```

*Conditional Examples:*

Binary encoder truth table:

```
en      a1      a2      y
0       -       -       0000
1       0       0       0001
1       0       1       0010
1       1       0       0100
1       1       1       1000
```

```
module pri_encoder (
    input wire [3:0] r,
    output wire en
    output wire [1:0] y
);

    always @* begin
        if (r[3]) begin
            {en, y} = 3'b111;
        end else if (r[2]) begin
            {en, y} = 3'b110;
        end else if (r[1]) begin
            {en, y} = 3'b101;
        end else if (r[0]) begin
            {en, y} = 3'b100;
        end else begin
            {en, y} = 3'b000;
        end
    end
endmodule

module decoder_1 (
    input wire [1:0] a,
    input wire en,
    output reg [3:0] y
);

    always @* begin
        if (~en) begin
            y = 4'b0000;
        end else if (a == 2'b00) begin
            y = 4'b0001;
        end else if (a == 2'b01) begin
            y = 4'b0010;
        end else if (a == 2'b10) begin
            y = 4'b0100;
        end else begin
            y = 4'b1000;
        end
    end
endmodule
```

*Case:*

```
module decoder_2 (
    input wire [1:0] a,
    input wire en,
    output reg [3:0] y
)

    always @* begin
      case ({en, a})
          3'b000, 3'b001,3'b010,3'b011: y = 4'b0000;
          3'b100: y = 4'b0001;
          3'b101: y = 4'b0010;
          3'b110: y = 4'b0100;
          3'b111: y = 4'b1000;
      endcase // {en, a}
    end
endmodule

module decoder_3 (
    input wire [1:0] a,
    input wire en,
    output reg [3:0] y
);

    always @* begin
        case ({en, a})
            3'b100: y = 4'b0001;
            3'b101: y = 4'b0010;
            3'b110: y = 4'b0100;
            3'b111: y = 4'b1000;
            default: y = 4'b0000;
        endcase // {en, a}
    end
endmodule
```

*Casex:*

```
module decoder_4 (
    input wire [1:0] a,
    input wire en,
    output reg [3:0] y
);

    always @* begin
        casex ({en, a})
            3'b0xx: y = 4'b0000;
            3'b100: y = 4'b0001;
            3'b101: y = 4'b0010;
            3'b110: y = 4'b0100;
            3'b111: y = 4'b1000;
        endcase // {en, a}
    end
endmodule
```

When the values in the item expressions are mutually exclusive (i.e., a value
appears in only one item expression), the statement is known as a parallel case
statement. When synthesized, a parallel case statement usually infers a
multiplexing routing network and a non-parallel case statement usually infers a
priority routing network. Unlike C where conditional constructs are executed
serially using branches and jumps, with HDL these are realized by routing
networks.

*Casez:*

```
module decoder_4 (
    input wire [1:0] a,
    input wire en,
    output reg [3:0] y
);

    always @* begin
        casez ({en, a})
            3'b0??: y = 4'b0000;
            3'b100: y = 4'b0001;
            3'b101: y = 4'b0010;
            3'b110: y = 4'b0100;
            3'b111: y = 4'b1000;
        endcase // {en, a}
    end
endmodule
```

In `casez`, the `?` is used to indicate either `X` or `Z` state.


*Tasks & Functions:*

Tasks and Functions are used when a set of operations are commonly repeated and
used, this save you writing the same thing out over and over a gain. Functions
can only be used for modeling combinational logic cannot drive more than one
output and cannot contain delays, unlike tasks which can. Tasks also can not
return a value unlike functions which can.

Below shows a function for calculating parity, something that may be used
frequently in digital logic design.

```
function parity;
    input [31:0] data;
    integer i;

    begin
        parity = 0;
        for (i= 0; i < 32; i = i + 1) begin
            parity = parity ^ data[i];
        end
    end
endfunction
```

*Common Errors:*

* Variable assigned in multiple always blocks
* Incomplete sensitivity list
* Incomplete branch and incomplete output assignment

Multiple assignment:

```
always @*
    if (en) y = 1'b0;

always @*
    y = a & b;
```

`y` is the output of two circuits which could be contradictory, this an not be
synthesized. Below is how this should have been written:

```
always @* begin
    if (en) begin
        y = 1'b0;
    end else begin
        y = a & b;
    end
end
```

Incomplete sensitivity list:

Incomplete sensitivity list (missing `b`). `b` could change but the `y` output
would not, causing unexpected behavior again this can not be synthesized.

```
always @(a) begin
    y = a & b;
end

/* Fixed versions */
always @(a, b) begin
    y = a & b;
end

/* or simple cure all */
always @* begin
    y = a & b;
end
```

Incomplete branch or output assignment:

Incomplete branch or output assignment, do not infer state in combinational
circuits.

```
always @* begin
    if (a > b) begin
        gt = 1'b1; // no eq assignment in branch
    end else if (a == b) begin
        eq = 1'b1; // no lt assignment in branch
    // final else branch omiitted
    end
end
```

Here we break both incomplete output assinment rules and branch According to
Verilog definition gt and eq keep their previous values when not assigned which
implies internal state, unintended latches are inferred, these sort of issues
cause endless hair pulling avoid such things. Here is how we could correct
this:

```
always @* begin
    if (a > b) begin
        gt = 1'b1;
        eq = 1'b0;
    end else if (a == b) begin
        gt = 1'b0;
        eq = 1'b1;
    end else begin
        gt = 1'b0;
        eq = 1'b0;
    end
end
```

Or easier still assign default values to variables at the beginning of the
always block

```
always @* begin
    gt = 1'b0;
    eq = 1'b0;

    if (a > b) begin
        gt = 1'b1;
    end else if (a == b) begin
        eq = 1'b1;
    end
end
```

Similar errors can creep into case statements:

```
case (a)
    2'b00: y =1'b1;
    2'b10: y =1'b0;
    2'b11: y =1'b1;
endcase
```

Here the case `2'b01` is not handled, if `a` has this value `y` gets it's
previous value and a latch is assumed, the solution is to include the missing
case, assign `y` a value before the case or add a default clause.

```
case (a)
    2'b00: y =1'b1;
    2'b10: y =1'b0;
    2'b11: y =1'b1;
    default: y = 1'b1;
endcase
```

*Adder with carry:*

```
module adder #(parameter N=4) (
    input wire [N-1:0] a,b,
    output wire [N-1:0] sum,
    output wire cout
);

    /* Constant Declaration */
    localparam N1 = N-1;

    /* Signal Declaration */
    wire [N:0] sum_ext;

    /* module body */
    assign sum_ext = {1'b0, a} + {1'b0, b};
    assign sum = sum_ext[N1:0];
    assign cout = sum_ext[N];
endmodule

module adder_example (
    input wire [3:0] a4,b4,
    output wire [3:0] sum4,
    output wire c4
);
    // Instantiate a 4 bit adder
    adder #(.N(4)) four_bit_adder (.a(a4), .b(b4), .sum(sum4), .cout(c4));
endmodule
```

*Local Params:*

```
localparam N = 4
```

## Reference Documentation and Projects

* [Project IceStorm Documentation][6]

### CPUs & SoCs

* [Basic-SIMD-Processor-Verilog-Tutorial](https://github.com/zslwyuan/Basic-SIMD-Processor-Verilog-Tutorial)
* [BiRiscV](https://opencores.org/projects/biriscv) and [github repo](https://github.com/ultraembedded/biriscv)
* [darkriscv](https://github.com/darklife/darkriscv)
* [List of RiscV FPGA Cores & SoCs](https://github.com/riscv/riscv-cores-list)
* [Nyuzi Processor](https://github.com/jbush001/NyuziProcessor) and associated [video description](https://www.youtube.com/watch?v=ZP8rmAZUIa4)
* [picorv32](https://github.com/cliffordwolf/picorv32)
* [riscv-simple-sv](https://github.com/tilk/riscv-simple-sv)
* [TinyFPGA-SoC](https://github.com/tinyfpga/TinyFPGA-SoC)
* [tinyzip](https://github.com/ZipCPU/tinyzip)
* [ZipCPU](https://github.com/ZipCPU/zipcpu)

### Logic Analyzers

* [A Modular Logic Analyzer for FPGAs](https://hackaday.com/2019/05/26/a-modular-logic-analyzer-for-fpgas/)
* [Verifla (Logic Analyzer)](https://github.com/wd5gnr/verifla) and associated [blog post](https://hackaday.com/2018/10/12/logic-analyzers-for-fpgas-a-verilog-odyssey/).

### Misc

* [Building a very simple wishbone interconnect](https://zipcpu.com/blog/2017/06/22/simple-wb-interconnect.html)
* [Interrupt Controller](https://github.com/adibis/Interrupt_Controller)
* [Open FPGA Verilog Tutorial](https://github.com/Obijuan/open-fpga-verilog-tutorial) and [English Wiki](https://github.com/Obijuan/open-fpga-verilog-tutorial/wiki/Home_EN)
* [Random instruction generator for RISC-V processor verification](https://github.com/google/riscv-dv)
* [Taking a look at the TinyFPGA BX](https://zipcpu.com/blog/2018/10/05/tinyfpga.html)
* [TinyFPGA-Bootloader](https://github.com/tinyfpga/TinyFPGA-Bootloader)
* [TinyFPGA B-Series User Guide](https://tinyfpga.com/b-series-guide.html)
* [TinyFPGA-BX](https://github.com/tinyfpga/TinyFPGA-BX)
* [tinyfpga-bx-testing](https://github.com/sstelfox/tinyfpga-bx-testing/tree/main/updated-picosoc)
* [tinyfpga_bx_usbserial](https://github.com/nalzok/tinyfpga_bx_usbserial)
* [tinyfpga_examples](https://github.com/lawrie/tinyfpga_examples)
* [tiny-synth](https://github.com/gundy/tiny-synth)
* [toygpu](https://github.com/matt-kimball/toygpu)
* [understanding-tinyfpga-bootloader](https://github.com/mattvenn/understanding-tinyfpga-bootloader)
* [Verilog-Adders](https://github.com/mongrelgem/Verilog-Adders)
* [verilog-ethernet](https://github.com/alexforencich/verilog-ethernet)
* [ZipCPU Debug Bus Interfaces](https://github.com/ZipCPU/dbgbus)

### Software / Firmware / Operating Systems

* [xv6 for nyuzi processor](https://github.com/jbush001/xv6-nyuzi)
* [xv6 project documentation](https://pdos.csail.mit.edu/6.828/2016/xv6.html)

[1]: https://github.com/tinyfpga/TinyFPGA-BX
[2]: https://tinyfpga.com/
[3]: https://people.ece.cornell.edu/land/courses/ece5760/Verilog/FreescaleVerilog.pdf
[4]: https://www.mouser.com/datasheet/2/225/FPGA-DS-02029-3-5-iCE40-LP-HX-Family-Data-Sheet-1022803.pdf
[5]: https://github.com/tinyfpga/TinyFPGA-BX
[6]: http://www.clifford.at/icestorm/
