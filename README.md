# Packet CentOS Image

This repository contains Packer.io templates for building CentOS that we provision at Packet. **This is currently a work in progress! Not all options are available publicly at this time.**

### Supported CentOS versions
- CentOS 7 

### Overview
The templates make use of the docker "builder" in Packer to create a base image for the operating system the template defines. The image is archived as a .tar.gz and can be deployed (with [packet-cli](https://github.com/packethost/packet-cli)) on to the hardware type you specify using Packet's [custom image ](https://support.packet.com/kb/articles/custom-images) functionality automatically.

### Dependencies
There is only a small list of deps required to run image builds, but we recommend a dedicated
machine or VM for this purpose simply to keep things isolated. This repo makes use of [git-lfs](https://git-lfs.github.com/) for installation asset storage.

 - [Packer](http://www.packer.io) - version 1.3.3 and up
 - [packet-cli](https://github.com/packethost/packet-cli) - optional
 - [git-lfs](https://github.com/git-lfs/git-lfs) - optional
 - Linux host on top of CentOS7 / Ubuntu 16

### Example image build
Due to some issues with file permissions (RedHat ships certain files without read permissions, e.g. shadow/gshadow), you must perform the Packer build with root privileges.

Packer image build of CentOS 7 on a t1.small.x86 instance in Packet's AMS1 facility:

    [image-centos/]$ sudo packer build -var 'plan=t1.small.x86' -var 'fac=ams1' -var 'os=centos_7' -var 'mode=install' 7/templates/centos-7.json


Packer image build of CentOS 7 on a t1.small.x86 instance in Packet's AMS1 facility with **hardware customization**:

    [image-centos/]$ sudo packer build -var 'plan=t1.small.x86' -var 'fac=ams1' -var 'os=alpine_3' -var 'mode=customize' 7/templates/centos-7.json


### Hardware customization
Images can be customized to a particular piece of hardware by specifying the `mode=customize` option. **Generic images containing default initial ramdisks may not boot on all hardware types.** The initrd/initramfs will need to be customized to add kernel driver support for some types of hardware across some operating systems. This customization is tested under a target OS image chroot running on top of Alpine Linux 3 and may in some cases require some manual intervention. See example above.
