#!/bin/sh
# REPACK v11: Enlarge tmpfs root to 512MB via overlay_size=512 kernel param
set -eu

PROJ=/home/phablet/alpine-browser-iso
ORIG="$PROJ/dist/alpine-v86-original.iso"
ISO_BASENAME=alpine-v86-260722-x86

echo "=== Repacking v11: overlay_size=512 ==="

docker run --rm \
  --network host \
  -v "$PROJ:/project:rw" \
  --entrypoint sh \
  alpine-iso-toolchain:3.24 -euxc '
set -e
ORIG=/project/dist/alpine-v86-original.iso
ISO_BASENAME='"$ISO_BASENAME"'
WORK=/tmp/repack
OUTDIR=/project/dist

rm -rf "$WORK"
mkdir -p "$WORK/orig" "$WORK/new"

echo ">>> Extracting original ISO"
xorriso -osirrox on -indev "$ORIG" -extract / "$WORK/orig" 2>&1 | tail -2

cp -a "$WORK/orig/." "$WORK/new/"

# Add overlay_size=512 to kernel cmdline in boot configs
echo ">>> Adding overlay_size=512 to boot configs"
for cfg in "$WORK/new/boot/syslinux/syslinux.cfg" "$WORK/new/boot/grub/grub.cfg"; do
    test -f "$cfg" || continue
    echo "  Patching: $cfg"
    cp "$cfg" "$cfg.bak"
    # Append overlay_size=512 to the APPEND / linux line
    sed -i "s/\(.*append.*\)/\1 rootflags=size=768M/" "$cfg"
    sed -i "s/\(.*linux.*vmlinuz-virt.*\)/\1 rootflags=size=768M/" "$cfg"
    echo "  Result:"
    cat "$cfg"
done

echo ">>> Generating apkovl"
cd "$WORK/orig"
fakeroot sh /project/genapkovl-alpine-v86.sh alpine-v86 2>&1 | tail -15
APKOVL="$WORK/orig/alpine-v86.apkovl.tar.gz"
test -f "$APKOVL"
ls -la "$APKOVL"

rm -f "$WORK/new/alpine-v86.apkovl.tar.gz"
cp "$APKOVL" "$WORK/new/"

echo ">>> Rebuilding ISO"
VOLID="alpine-v86 260722 x86"
OUT="$OUTDIR/$ISO_BASENAME.iso"
ISOHDPFX="$WORK/new/boot/syslinux/isohdpfx.bin"

xorriso -as mkisofs \
  -quiet \
  -output "$OUT" \
  -full-iso9660-filenames \
  -joliet \
  -rational-rock \
  -sysid LINUX \
  -volid "$VOLID" \
  -isohybrid-mbr "$ISOHDPFX" \
  -c boot/syslinux/boot.cat \
  -b boot/syslinux/isolinux.bin \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -follow-links \
  "$WORK/new" 2>&1 | tail -3

echo "=== Output ==="
ls -la "$OUT"
sha256sum "$OUT" > "$OUT.sha256"
sha512sum "$OUT" > "$OUT.sha512"
cat "$OUT.sha256"
'

echo "=== Repack complete ==="
ls -la "$PROJ/dist/$ISO_BASENAME.iso"