# Third-party notices

## Alpine Linux 3.24

- Project: https://alpinelinux.org/
- Package repository: https://dl-cdn.alpinelinux.org/alpine/v3.24/
- Package sources: https://gitlab.alpinelinux.org/alpine/aports/
- Package license metadata: https://pkgs.alpinelinux.org/

`dist/alpine-v86-260722-x86.iso` is assembled from unmodified Alpine x86
packages with a local configuration overlay. Each package remains under the
license declared by its Alpine package metadata. The Linux kernel is licensed
under GPL-2.0; a copy is available at `licenses/GPL-2.0.txt`.

The image includes NetSurf 3.11, Openbox, tint2, xterm, curl, wget, fastfetch,
Xorg, and their Alpine-packaged dependencies.

## v86 0.5.424

- Project: https://github.com/copy/v86
- Package: https://www.npmjs.com/package/v86/v/0.5.424
- License: BSD-2-Clause

The browser runtime was extracted from the official npm package. BIOS images
were obtained from the v86 upstream repository. The v86 license is available
at `licenses/v86-BSD-2-Clause.txt`.

## SHA-256

```text
3d338f7998e2e861197d4324b3fd79270410f16a64e676c41ac04228b1858202  dist/alpine-v86-260722-x86.iso
b80fba71dacb7977e5b46800b3ba194bba7fe13e52fa3d22f80cc060ff015a4e  vendor/v86/libv86.js
aec2c16bb0a1618aa641bb44d9c0fe14681f8c1459fa08c32e3e0562020884e8  vendor/v86/v86.wasm
0859dc359024ee2ac04a1eade930043065a86a1d041d9c5115669ab3eba7cbed  vendor/v86/v86-fallback.wasm
73e3f359102e3a9982c35fce98eb7cd08f18303ac7f1ba6ebfbe6cdc1c244d98  vendor/v86/seabios.bin
a4bc0d80cc3ca028c73dafa8fee396b8d054ce87ebd8abfbd31b06b437607880  vendor/v86/vgabios.bin
```
