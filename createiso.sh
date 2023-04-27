#!/bin/bash
#  Creates embedded kickstart from CentOS ISO.

# GLOBAL VARIABLES
PWD=$(pwd)

# USAGE STATEMENT
function usage() {
cat << EOF
usage: $0 centos-7.X-x86_64-dvd.iso

Requires CentOS 7.4+ (1708)

EOF
}

# OPTIONS

while getopts ":vhq" OPTION; do
	case $OPTION in
		v)
			echo "$0: CentOS 7 automated install iso creator v. 0.01"
			;;
		h)
			usage
			exit 0
			;;
		q)
			QUIET=1
			;;
		?)
			echo "ERROR: Invalid Option Provided!"
			echo
			usage
			exit 1
			;;
	esac
done
shift $((OPTIND-1))

if [ -z "$1" ];
then
	usage
	exit 1
fi

# ENVIRONMENT CHECKS AND SETUP

# Check for root user
if [[ $EUID -ne 0 ]];
then
	if [ -z "$QUIET" ];
	then
		echo
		tput setaf 1;echo -e "\033[1mThis script will attempt to use sudo execute commands as root!\033[0m";tput sgr0
		SUDO="sudo -u root"
	else
		SUDO="sudo -nu root"
	fi
else
	SUDO=""
fi

# If genisoimage is not found install it.
if ! which genisoimage &> /dev/null;
then
	$SUDO yum install -y genisoimage || $SUDO apt-get install -y genisoimage || {
		which genisoimage || exit 1
	}
fi

# If isohybrid is not found install it.
if ! which isohybrid &> /dev/null;
then
	$SUDO yum install -y syslinux || $SUDO apt-get install -y syslinux || {
		which syslinux || exit 1
	}
fi

# If implantisomd5 is not found install it.
if ! which implantisomd5 &> /dev/null;
then
	$SUDO yum install -y isomd5sum || $SUDO apt-get install -y isomd5sum || {
		which implantisomd5 || exit 1
	}
fi

# CHECK ISO AND PREP FOR CREATION

# Determine if iso is Bootable
if ! file "$1" | grep -q -e "9660.*boot" -e "x86 boot" -e "DOS/MBR boot" ;
then
	echo "Mounting CentOS iso Image..."
	mkPWD -p "$PWD"/original-mnt
	mkPWD "$PWD"/custom-tmp
	$SUDO mount -o loop "$1" "$PWD"/original-mnt

	if [[ -e $PWD/original-mnt/.discinfo && -e $PWD/original-mnt/.treeinfo ]];
	then
		CENTOS_VERSION=$(grep -E "^7\.[0-9]+" "$PWD"/original-mnt/.discinfo)
		MAJOR=$(echo "$CENTOS_VERSION" | awk -F '.' '{ print $1 }')
		MINOR=$(echo "$CENTOS_VERSION" | awk -F '.' '{ print $2 }')
		BUILD=$(cd "$PWD"/original-mnt/Packages/ || exit 1; ls centos-release* | awk -F '.' '{ print $2 }')
		ARCH=$(cd "$PWD"/original-mnt/Packages/ || exit 1; ls centos-release* | awk -F '.' '{ print $5 }')
		CUSTOM_ISO="CentOS-$MAJOR.$MINOR-$ARCH-DVD-$BUILD-Manpack_Atom.iso"
		if [[ $MAJOR -ne 7 ]];
		then
			echo "ERROR: Image is not CentOS 7.4+"
			$SUDO umount "$PWD"/original-mnt
			$SUDO rm -rf "$PWD"/original-mnt
			exit 1
		fi
		if [[ $MINOR -lt 4 ]];
		then
			echo "ERROR: iso image is not CentOS 7.4+"
			$SUDO umount "$PWD"/original-mnt
			$SUDO rm -rf "$PWD"/original-mnt
			exit 1
		fi
	else
		echo "ERROR: Image is not CentOS"
		$SUDO umount "$PWD"/original-mnt
		$SUDO rm -rf "$PWD"/original-mnt
		exit 1
	fi
	echo "Done."

	echo -n "Copying CentOS iso Image..."
  # Copy all files preserving all attributes.
	cp -a "$PWD"/original-mnt/* "$PWD"/custom-tmp/
	cp -a "$PWD"/original-mnt/.*info "$PWD"/custom-tmp/
	echo " Done."
  # unmount and delete the original-mnt PWDectory.
	$SUDO umount "$PWD"/original-mnt
	rm -rf "$PWD"/original-mnt
else
	echo "ERROR: ISO image is not bootable."
	exit 1
fi

# CREATE ISO CUSTOM ISO

echo -n "Modifying CentOS iso Image..."
# Copies contents of the config PWDectory to their spots where they need to be on the iso.
cp -a "$PWD"/config/* "$PWD"/custom-tmp/
echo " Done."
echo "Remastering CentOS iso Image..."
cd "$PWD"/custom-tmp || exit 1
chmod u+w isolinux/
find . -name TRANS.TBL -exec rm -f '{}' \; 
# Generate the ISO file
genisoimage -l -r -J -V "CentOS-7-x86_64" -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -c isolinux/boot.cat -o "$PWD"/"$CUSTOM_ISO" -eltorito-alt-boot -e images/efiboot.img -no-emul-boot .

# Delete the /custom-tmp Directory since you are done.
cd "$PWD" || exit 1
rm -rf "$PWD"/custom-tmp
echo "Done."

echo "Making UEFI Bootable and Signing CentOS iso Image..."
# Make the ISO bootable
/usr/bin/isohybrid --uefi "$PWD"/"$CUSTOM_ISO" &> /dev/null
# Add an MD5 hash to the ISO file.
/usr/bin/implantisomd5 "$PWD"/"$CUSTOM_ISO"
echo "Done."

echo "iso Created. [$PWD/$CUSTOM_ISO]"

echo "Creating the iso metadata file..."
FULL_USER_NAME=$(getent passwd "$(whoami)" | cut -d ':' -f 5)
CREATION_DATE=$(date --utc --rfc-2822)
SCRIPT_NAME=$(basename "$0")
SCRIPT_VERSION=$(grep -iE "# +version" createiso.sh | tail -1 | cut -d ' ' -f 3)
ORIGINAL_ISO_HASH=$(sha256sum "$1")
CUSTOM_ISO_HASH=$(sha256sum "$PWD"/"$CUSTOM_ISO")
SCRIPT_HASH=$(sha256sum "$SCRIPT_NAME")
cat <<EOF > "$PWD/${CUSTOM_ISO%.*}.info.txt"
  Prepared By: $FULL_USER_NAME
Creation Date: $CREATION_DATE

Compile Script: $SCRIPT_NAME
       Version: $SCRIPT_VERSION
          Hash: $SCRIPT_HASH
Project Source: automated-centos7-kickstart
   Project URL: https://github.com/harrystaley/automated-centos7-kickstart

$ORIGINAL_ISO_HASH
$CUSTOM_ISO_HASH

Mainline Downloads: https://www.centos.org/download/
 Rolling Downloads: https://buildlogs.centos.org/rolling/7/isos/x86_64/
EOF
echo "Done."

exit 0
