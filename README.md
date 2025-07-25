# linux_workstation_build
Some convenience scripts to setup a workstation build for use in VFX, Animation and Photography for Linux desktops using DWM Window Manager or Mate Desktop.

If you are doing a clean arsh install, I have done a quick setup for installing the basic packages and setting up btrfs and snapshots.

```sh
curl -fsSL https://github.com/curadotd/linux_workstation_build/blob/main/arch_install/arch_install_part1.sh | sh
```
Debian, Rocky and Arch Linux, so far tested.

On Debian, you might need to add SUDO to your groups.
You will first need to have *sudo privilegius:
```sh
su	
```
Enter your password, then install sudo, git and vim, which we will use later on.
```sh
apt install sudo git vim
```
Now add your username to sudo.
```sh
sudo usermod -aG sudo username
```
Once you log out or reboot.

You can check it is added by running, and you should see sudo.
```sh
groups username	
```

For Arch and Rocky, you might want to install git and vim.

Rocky:
```sh
sudo dnf install git vim
```
Arch:
```sh
sudo pacman -S git vim
```

```sh
mkdir $HOME/git
cd $HOME/git
git clone https://github.com/curadotd/linux_workstation_build.git
cd linux_workstation_build
./first_install
```
Follow the instrunctions, then reboot, once rebooted you can continue.
```sh
cd $HOME/git/linux_workstation_build
./base_system
```
Follow the instructions again and by the end, you should be able to reboot, and login to DWM,

You can also run individual scripts by running, for example.
```sh
cd $HOME/git/linux_workstation_build
./install_fonts
```
