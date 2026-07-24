#!/bin/sh -e

hostname="${1:-alpine-v86}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Inject pre-installed packages into apkovl
echo "--- Injecting: python3 py3-pip bash openssh git ---"
PKGDIR="/project/fetched-apks"

for apk_file in "$PKGDIR"/python3-*.apk "$PKGDIR"/py3-pip-*.apk \
                "$PKGDIR"/bash-*.apk "$PKGDIR"/openssh-*.apk \
                "$PKGDIR"/openssh-server-*.apk "$PKGDIR"/openssh-sftp-server-*.apk \
                "$PKGDIR"/git-*.apk "$PKGDIR"/sqlite-libs-*.apk "$PKGDIR"/libexpat-*.apk; do
    [ -f "$apk_file" ] || continue
    echo "  Extracting: $(basename "$apk_file")"
    tar xzf "$apk_file" -C "$tmp" 2>/dev/null
done

# Run bash post-install
if [ -x "$tmp/.post-install" ]; then
    echo "  Running .post-install"
    ( cd "$tmp" && sh .post-install ) 2>/dev/null || true
    rm -f "$tmp/.post-install"
fi

echo "  Packages injected."

# Install hermes-agent + all dependencies from wheels
echo "--- Injecting: hermes-agent + dependencies ---"
SITE_PKGS="$tmp/usr/lib/python3.14/site-packages"
mkdir -p "$SITE_PKGS" "$tmp/usr/bin"

# Install main hermes wheel
if [ -f /project/hermes-agent.whl ]; then
    echo "  Extracting hermes-agent"
    unzip -o /project/hermes-agent.whl -d "$SITE_PKGS/" 2>/dev/null || true
fi

# Install all dependency wheels
if [ -d /project/hermes-deps ]; then
    echo "  Installing dependencies"
    for whl in /project/hermes-deps/*.whl; do
        [ -f "$whl" ] || continue
        pkg=$(basename "$whl")
        echo "    $pkg"
        unzip -o "$whl" -d "$SITE_PKGS/" 2>/dev/null || true
    done
fi

# Create hermes wrapper
cat > "$tmp/usr/bin/hermes" <<'HERMESWRAP'
#!/bin/sh
exec /usr/bin/python3 -m hermes_cli.main "$@"
HERMESWRAP
chmod +x "$tmp/usr/bin/hermes"
echo "  hermes-agent ready"

make_file() {
	owner="$1"
	mode="$2"
	path="$3"
	mkdir -p "$(dirname "$tmp/$path")"
	cat > "$tmp/$path"
	chown "$owner" "$tmp/$path"
	chmod "$mode" "$tmp/$path"
}

rc_add() {
	mkdir -p "$tmp/etc/runlevels/$2"
	ln -sf "/etc/init.d/$1" "$tmp/etc/runlevels/$2/$1"
}

make_file root:root 0644 etc/hostname <<EOF
$hostname
EOF

make_file root:root 0644 etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

make_file root:root 0644 etc/modules <<'EOF'
bochs
zram
EOF

make_file root:root 0644 etc/sysctl.d/99-zram.conf <<'EOF'
vm.swappiness=100
vm.page-cluster=0
EOF

make_file root:root 0755 etc/init.d/zram-swap <<'EOF'
#!/sbin/openrc-run

description="Compressed RAM swap for the v86 desktop"

depend() {
	need modules
	before local
}

start() {
	ebegin "Enabling 512 MB zram swap"
	modprobe zram
	[ -e /dev/zram0 ] || mdev -s
	echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null || true
	echo 536870912 > /sys/block/zram0/disksize
	mkswap /dev/zram0 >/dev/null
	swapon -p 100 /dev/zram0
	eend $?
}

stop() {
	ebegin "Disabling zram swap"
	swapoff /dev/zram0
	echo 1 > /sys/block/zram0/reset
	eend $?
}
EOF

make_file root:root 0644 etc/apk/world <<'EOF'
alpine-base
ca-certificates
curl
doas
fastfetch
pciutils
wget
EOF

make_file root:root 0644 etc/passwd <<'EOF'
root:x:0:0:root:/root:/bin/ash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/mail:/sbin/nologin
news:x:9:13:news:/usr/lib/news:/sbin/nologin
uucp:x:10:14:uucp:/var/spool/uucppublic:/sbin/nologin
cron:x:16:16:cron:/var/spool/cron:/sbin/nologin
ftp:x:21:21::/var/lib/ftp:/sbin/nologin
sshd:x:22:22:sshd:/dev/null:/sbin/nologin
games:x:35:35:games:/usr/games:/sbin/nologin
ntp:x:123:123:NTP:/var/empty:/sbin/nologin
guest:x:405:100:guest:/dev/null:/sbin/nologin
alpine:x:1000:1000:Alpine User:/home/alpine:/bin/ash
nobody:x:65534:65534:nobody:/:/sbin/nologin
EOF

make_file root:root 0644 etc/group <<'EOF'
root:x:0:root
bin:x:1:root,bin,daemon
daemon:x:2:root,bin,daemon
sys:x:3:root,bin
adm:x:4:root,daemon
tty:x:5:
disk:x:6:root
lp:x:7:lp
kmem:x:9:
wheel:x:10:root,alpine
floppy:x:11:root
mail:x:12:mail
news:x:13:news
uucp:x:14:uucp
cron:x:16:cron
audio:x:18:alpine
cdrom:x:19:
dialout:x:20:root
ftp:x:21:
sshd:x:22:
input:x:23:alpine
tape:x:26:root
video:x:27:root,alpine
netdev:x:28:alpine
kvm:x:34:
games:x:35:
shadow:x:42:
www-data:x:82:
users:x:100:games
ntp:x:123:
utmp:x:406:
ping:x:999:
alpine:x:1000:
nogroup:x:65533:
nobody:x:65534:
EOF

make_file root:root 0600 etc/shadow <<'EOF'
root:*::0:::::
bin:!::0:::::
daemon:!::0:::::
lp:!::0:::::
sync:!::0:::::
shutdown:!::0:::::
halt:!::0:::::
mail:!::0:::::
news:!::0:::::
uucp:!::0:::::
cron:!::0:::::
ftp:!::0:::::
sshd:!::0:::::
games:!::0:::::
ntp:!::0:::::
guest:!::0:::::
alpine::20000:0:99999:7:::
nobody:!::0:::::
EOF

make_file root:root 0400 etc/doas.d/alpine.conf <<'EOF'
permit nopass alpine as root
EOF

make_file root:root 0644 etc/ssh/sshd_config <<'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication yes
PermitEmptyPasswords yes
Subsystem sftp /usr/lib/ssh/sftp-server
EOF

make_file root:root 0644 etc/inittab <<'EOF'
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default

tty1::respawn:/sbin/getty -n -l /usr/local/bin/autologin 38400 tty1
tty2::respawn:/sbin/getty 38400 tty2
tty3::respawn:/sbin/getty 38400 tty3
tty4::respawn:/sbin/getty 38400 tty4

::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/openrc shutdown
EOF

make_file root:root 0755 usr/local/bin/autologin <<'EOF'
#!/bin/sh
exec /bin/login -f alpine
EOF

make_file 1000:1000 0644 home/alpine/.profile <<'EOF'
echo "=== Alpine v86 ready ==="
echo "hermes-agent preinstalled. Run: hermes"
EOF

chown -R 1000:1000 "$tmp/home/alpine"

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit
rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add zram-swap boot
rc_add networking boot
rc_add seedrng boot
rc_add sshd default
rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

tar -c -C "$tmp" etc home usr | gzip -9n > "$hostname.apkovl.tar.gz"
