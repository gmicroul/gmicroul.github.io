# gmicroul.github.io

My Personal Blog via GitHub

成功后的镜像将会保存在 ~/.cache/kupfer/images

正常需要选择-full.img的后缀刷入机器

-boot.img还需要进一步处理（参考了kupferbootstrap源码的处理方式）

debugfs boot.img -R 'dump /aboot.img /tmp/aboot.img'

通过这种方式可以将生成的boot转换为安卓系统的boot镜像

最后通过fastboot工具刷入机器即可

http://dl-cdn.alpinelinux.org/alpine/edge/community/aarch64/nmon-16q-r0.apk
