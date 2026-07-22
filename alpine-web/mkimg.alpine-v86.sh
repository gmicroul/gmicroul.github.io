profile_alpine_v86() {
	# Start from Alpine's base profile, not the standard/virt profile. The
	# latter pulls servers, PPP, wireless tooling and other packages that are
	# not useful in a v86 desktop and can exhaust a 512 MB guest rootfs.
	profile_base
	profile_abbrev="v86"
	title="Alpine v86 Desktop"
	desc="Alpine Linux x86 diskless desktop with NetSurf and network tools."
	arch="x86"
	image_ext="iso"
	output_format="iso"
	kernel_flavors="virt"
	kernel_addons=
	image_name="alpine-v86"
	output_filename="alpine-v86-${RELEASE}-${ARCH}.iso"
	hostname="alpine-v86"
	apkovl="genapkovl-alpine-v86.sh"
	syslinux_prompt=0
	syslinux_timeout=1
	# v86 exposes a Bochs VBE adapter. Keep kernel mode setting enabled so the
	# bochs DRM module creates /dev/dri/card0 for Xorg's modesetting driver.
	kernel_cmdline="$kernel_cmdline rootflags=size=450M"

	desktop_apks="
		ca-certificates curl dbus dbus-x11 doas fastfetch font-dejavu
		netsurf openbox pciutils setxkbmap tint2 wget xsetroot
		xf86-input-libinput xf86-video-fbdev xf86-video-vesa
		xinit xorg-server xrandr xterm
	"
	apks="alpine-base busybox dhcpcd doas openssl tzdata wget $desktop_apks"
}

# Virtual hardware does not need the multi-gigabyte firmware bundle.
section_kernels() {
	local _f _a _pkgs id
	for _f in $kernel_flavors; do
		_pkgs="linux-$_f linux-firmware-none wireless-regdb $modloop_addons"
		for _a in $kernel_addons; do
			_pkgs="$_pkgs $_a-$_f"
		done
		id=$( (echo "$initfs_features::$_hostkeys"; apk fetch --root "$APKROOT" --simulate alpine-base $_pkgs | sort) | checksum)
		build_section kernel "$ARCH" "$_f" "$id" $_pkgs
	done
}
