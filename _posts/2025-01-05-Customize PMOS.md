---
layout: post
title: "定制PostmarketOS"
date:   2025-01-05
tags: [全球首发,PostmarketOS,手机]
comments: true
author: gmicroul
---

为了实现PMOS轻量化，让其在没有桌面的条件下实现在线音乐/视频播放，体验容器，进行如下定制。
#### 首先值得点赞的是24.12开始，PMOS已经收集到很多用户需求也满足用户体验，默认phosh已经集成podman,hkdm（buffyboard）tty键盘，在PMOS称为ttyescape。
#### 第一步先把wifi，声音（第一次启动默认选的是speaker，只需要把声音调到最大），时区，电源优化只保留熄屏时间1分钟。
#### 搞定好，就开始做作了。
#### 先调节repo如下，别问为什么，一是要快，二是所需，三搞完可以去掉testing，防止误更新。
##### oneplus-fajita:~$ cat /etc/apk/repositories 

#http://mirror/postmarketOS/master

https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/main

https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/community

https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/testing

#https://dl-cdn.alpinelinux.org/alpine/edge/testing/

http://mirror.postmarketos.org/postmarketos/v24.12

#http://dl-cdn.alpinelinux.org/alpine/v3.21/main

#http://dl-cdn.alpinelinux.org/alpine/v3.21/community

##### oneplus-fajita:~$ 
##### oneplus-fajita:~$ sudo vi /etc/apk/repositories 
##### oneplus-fajita:~$ sudo apk update

fetch https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/main/aarch64/APKINDEX.tar.gz

fetch https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/community/aarch64/APKINDEX.tar.gz

fetch https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/testing/aarch64/APKINDEX.tar.gz

fetch http://mirror.postmarketos.org/postmarketos/v24.12/aarch64/APKINDEX.tar.gz

v3.22.0_alpha20241224-687-gbee53b60e00 [https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/main]

v3.22.0_alpha20241224-690-g584c75f8414 [https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/community]

v3.22.0_alpha20241224-680-g4a72ba08d09 [https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/testing]

2025-01-05 12:54:37.580599+00:00 [http://mirror.postmarketos.org/postmarketos/v24.12]

OK: 34764 distinct packages available

##### oneplus-fajita:~$ sudo apk add nmon fastfetch 
##### 还是说明一下吧，nmon在testing repo，fastfetch在community
##### oneplus-fajita:~$ sudo apk add mpv yt-dlp git ......mpv/yt-dlp为了在线播放B，git就不说了。

### 差不多了，清凉的PMOS，尽情享受听着音乐，看着视频，玩玩容器，开开心心每一天。
完蛋，忘记第二步了。

目标是无桌面，默认进入了phosh后调节完第一步，就用一句话。搞定。

##### oneplus-fajita:~$ sudo rc-update del tinydm
然后重启即可。

重启后你会发现进入了tty。然后开始抓狂。当然你懂就没事，没事去wiki看看。


# -------------------------------------------------------K.A.O---> 
音乐音乐，没有音乐何来调节心情,去吧。。。

去 https://github.com/gmicroul/go-musicfox/releases/tag/musicfox-pmos 这里下吧，解压后加x运行即可。



Just-For-Myself:

https://pkgs.alpinelinux.org/packages?name=nmon&branch=edge&repo=&arch=aarch64&origin=&flagged=&maintainer=

