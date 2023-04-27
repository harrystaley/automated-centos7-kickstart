# CentOS 7 Automated Install ISO Creator

[TOC]

## About

Modifies a CentOS 7 (tested with CentOS-7-x86_64-DVD-1810.iso)
x86_64 iso with a kickstart that will automate Manpack Atom installations.

## Quickstart

To create the ISO image downlaod the CentOS 7 ISO file into this directory.

```terminal
$ sudo su
# ./createiso.sh CentOS-7-x86_64-DVD-1601-01.iso 
```

## Project Structure

```text
vagrantfile - This is used to create a CentOS 7 VM to run the script.
createiso.sh - installation script to modify CentOS 7 ISO image
/config - Files needed to modify the ISO image.
	/EFI/BOOT/grub.cfg - Menu Configuration for UEFI boot
	/isolinux/isolinux.cfg - Menu Configuration for Kickstart
	/ks/Atom_Kickstart.cfg - Kickstart Configuration (Calls menu.py in %pre)
```

**NOTE:** The directory structure in the `/config/` directory are copied over to the newly created iso.

## Execution

```bash
# As root execute the below command replacing <CentOS 7 ISO> with the path to your CentOS 7 ISO file.
$ ./createiso.sh <CentOS 7 ISO> 
```

## Sample Output

```terminal
# ./createiso.sh CentOS-7-x86_64-DVD-1601-01.iso 
Mounting CentOS DVD Image...
mount: /dev/loop1 is write-protected, mounting read-only
Done.
Copying CentOS DVD Image... Done.
Modifying CentOS DVD Image... Done.
Remastering CentOS DVD Image...
...
  0.23% done, estimate finish Wed Feb 10 07:34:24 2016
  0.46% done, estimate finish Wed Feb 10 07:37:59 2016
  0.70% done, estimate finish Wed Feb 10 07:36:47 2016
  0.93% done, estimate finish Wed Feb 10 07:36:11 2016

...

 99.87% done, estimate finish Wed Feb 10 07:34:35 2016
Total translation table size: 2048
Total rockridge attributes bytes: 417876
Total directory bytes: 712704
Path table size(bytes): 158
Max brk space used 3af000
2157808 extents written (4214 MB)
Done.
Signing CentOS iso Image...
Inserting md5sum into iso image...
md5 = e526291fc5ff0c83a7de64c183f27b78
Inserting fragment md5sums into iso image...
fragmd5 = 631648db156318da3cf5aef0db4d65efa7a774fcceabc45e9ecd7476f22b
frags = 20
Setting supported flag to 0
Done.
ido Created. [centos7-x86_64-Manpack_Atom.iso]
```

## Troubleshooting

### Kickstart Validation

```bash
$ ksvalidator /ks/Atom_Kickstart.cfg
```

## References

- [Syslinux ISOLINUX](https://wiki.syslinux.org/wiki/index.php?title=ISOLINUX)
- [mkisofs man page](https://linux.die.net/man/8/mkisofs)
- [RedHat: Making the Kickstart File Available](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/installation_guide/s1-kickstart2-putkickstarthere)
- [centos 7 install via Kickstart File](https://www.smorgasbork.com/2014/07/16/building-a-custom-centos-7-kickstart-disc-part-1/)
- [Tutorial CentOS 7 Install via USB](https://softpanorama.org/Commercial_linuxes/RHEL/Installation/Kickstart/modifing_iso_image_to_include_kickstart_file.shtml#Extracting_the_source)
- [Setup CentOS 7 Install USB](https://gist.github.com/abrahamrhoffman/6dae37d7bb533ae50ccb)
- [CentOS Kickstart File Documentation](https://docs.centos.org/en-US/centos/install-guide/Kickstart2/)
- [Python Kickstart Tool Documentation](https://pykickstart.readthedocs.io/en/latest/)
- [Kickstart File Generator](https://access.redhat.com/labs/kickstartconfig/)
  **NOTE** Select RHEL 7 from the dropdown