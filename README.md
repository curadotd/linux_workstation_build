# linux_workstation_build

Some convenience scripts to setup a workstation build for use in VFX, Animation and Photography for Linux desktops using DWM, Hyprland, MATE or KDE Plasma.

The scripts are organized per distribution, each folder is self-contained:

| Folder    | Distribution            |
|-----------|-------------------------|
| `arch/`   | Arch Linux              |
| `debian/` | Debian 13 (trixie)      |
| `rocky/`  | Rocky Linux 9           |
| `fedora/` | Fedora 44               |

## Clean Arch install

If you are doing a clean Arch install, there is a quick setup for installing the basic packages and setting up btrfs and snapshots in `arch/arch_install/`:

```sh
curl -fsSL https://raw.githubusercontent.com/curadotd/linux_workstation_build/main/arch/arch_install/arch_install_part1.sh | sh
```

## Prerequisites

### Debian

You might need to add your user to the sudo group first. Get a root shell:

```sh
su
```

Enter your password, then install sudo, git and vim, which we will use later on:

```sh
apt install sudo git vim
```

Now add your username to sudo:

```sh
usermod -aG sudo username
```

Log out or reboot, then check the group was added (you should see sudo):

```sh
groups username
```

### Rocky Linux / Fedora

```sh
sudo dnf install git vim
```

### Arch Linux

```sh
sudo pacman -S git vim
```

## Usage

Clone the repository and enter the folder for your distribution, for example on Arch:

```sh
mkdir $HOME/git
cd $HOME/git
git clone https://github.com/curadotd/linux_workstation_build.git
cd linux_workstation_build/arch
./first_install
```

Follow the instructions, then reboot. Once rebooted you can continue:

```sh
cd $HOME/git/linux_workstation_build/arch
./base_system
```

Follow the instructions again and by the end, you should be able to reboot and log in to your chosen desktop.

You can also run individual scripts, for example:

```sh
cd $HOME/git/linux_workstation_build/arch
./install_fonts
```

Replace `arch` with `debian`, `rocky` or `fedora` to match your distribution.
