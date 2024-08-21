# linux_workstation_build
Some convince scripts to setup a workstation build for use in VFX, Animation and Photography for Linux desktops using DWM Window Manager or Mate Desktop.

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
sudo usermd -aG sudo username
```
Once you log out or reboot.

You can check it is added by running, and you should see sudo.
```sh
groups username	
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
