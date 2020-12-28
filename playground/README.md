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

# Since this isn't sourcing any system default bashrc, we need to set our prompt
# to something that won't get in the way
export PS1="\W \$ "

# Use neovim as just our normal vim
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

cat << 'EOF' > ~/.vimrc
set expandtab shiftwidth=2 tabstop=2
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

### Project Initialization

```
mkdir -p ~/workspace/electronics/fpga-playground
cd workspace/electronics/fpga-playground
git init
```
