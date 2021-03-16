#!/bin/bash
clear

## 基础部分

# 基础修改
#使用 O3 级别的优化
sed -i 's/Os/O3/g' include/target.mk
#更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
#默认开启 Irqbalance
sed -i 's/0/1/g' feeds/packages/utils/irqbalance/files/irqbalance.config
#移除 SNAPSHOT 标签
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in
#维多利亚的秘密
rm -rf ./scripts/download.pl
rm -rf ./include/download.mk
wget -P scripts/ https://github.com/immortalwrt/immortalwrt/raw/master/scripts/download.pl
wget -P include/ https://github.com/immortalwrt/immortalwrt/raw/master/include/download.mk

# 必要的 Patch 们
#Patch arm cpu name
wget -P target/linux/generic/pending-5.4 https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/generic/hack-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
#Patch jsonc
patch -p1 < ../PATCH/new/package/use_json_object_new_int64.patch
#Patch dnsmasq
patch -p1 < ../PATCH/new/package/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/new/package/luci-add-filter-aaaa-option.patch
cp -f ../PATCH/new/package/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch

# Fullcone-NAT 部分
#Patch Kernel 以解决 fullcone 冲突
pushd target/linux/generic/hack-5.4
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
#Patch FireWall 以增添 fullcone 功能 
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/immortalwrt/immortalwrt/raw/master/package/network/config/firewall/patches/fullconenat.patch
#Patch LuCI 以增添 fullcone 开关
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_fullcone.patch
#FullCone 相关组件
cp -rf ../openwrt-lienol/package/network/fullconenat ./package/network/fullconenat

# Shortcut-FE 部分
#Patch Kernel 以支持SFE
pushd target/linux/generic/hack-5.4
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
popd
#Patch LuCI 以增添SFE开关
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_sfe_switch.patch
#SFE 相关组件
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe package/lean/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/lean/fast-classifier
cp -f ../PATCH/duplicate/shortcut-fe ./package/base-files/files/etc/init.d


## 获取额外的 Packages

# 基础 Packages
#AutoCore
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/autocore package/lean/autocore
rm -rf ./feeds/packages/utils/coremark
svn co https://github.com/immortalwrt/packages/trunk/utils/coremark feeds/packages/utils/coremark
#更换 Node 版本
rm -rf ./feeds/packages/lang/node
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node feeds/packages/lang/node
rm -rf ./feeds/packages/lang/node-arduino-firmata
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-arduino-firmata feeds/packages/lang/node-arduino-firmata
rm -rf ./feeds/packages/lang/node-cylon
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-cylon feeds/packages/lang/node-cylon
rm -rf ./feeds/packages/lang/node-hid
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-hid feeds/packages/lang/node-hid
rm -rf ./feeds/packages/lang/node-homebridge
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-homebridge feeds/packages/lang/node-homebridge
rm -rf ./feeds/packages/lang/node-serialport
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport feeds/packages/lang/node-serialport
rm -rf ./feeds/packages/lang/node-serialport-bindings
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport-bindings feeds/packages/lang/node-serialport-bindings
rm -rf ./feeds/packages/lang/node-yarn
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-yarn feeds/packages/lang/node-yarn
ln -sf ../../../feeds/packages/lang/node-yarn ./package/feeds/packages/node-yarn
#R8168驱动
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/r8168 package/new/r8168
#patch -p1 < ../PATCH/new/main/r8168-fix_LAN_led-for_r4s-from_TL.patch
sed -i '/r8169/d' ./target/linux/rockchip/image/armv8.mk
# UPX
sed -i '/patchelf pkgconf/i\tools-y += ucl upx' ./tools/Makefile
sed -i '\/autoconf\/compile :=/i\$(curdir)/upx/compile := $(curdir)/ucl/compile' ./tools/Makefile
svn co https://github.com/immortalwrt/immortalwrt/branches/master/tools/upx tools/upx
svn co https://github.com/immortalwrt/immortalwrt/branches/master/tools/ucl tools/ucl

# LuCI应用，主题和依赖们
#访问控制
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-accesscontrol package/lean/luci-app-accesscontrol
cp -rf ../PATCH/duplicate/luci-app-control-weburl ./package/new/luci-app-control-weburl
#广告过滤 Adbyby
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-adbyby-plus package/lean/luci-app-adbyby-plus
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/adbyby package/lean/adbyby
#广告过滤 AdGuard
cp -rf ../openwrt-lienol/package/diy/luci-app-adguardhome ./package/new/luci-app-adguardhome
rm -rf ./feeds/packages/net/adguardhome
svn co https://github.com/openwrt/packages/trunk/net/adguardhome feeds/packages/net/adguardhome
sed -i '/\t)/a\\t$(STAGING_DIR_HOST)/bin/upx --lzma --best $(GO_PKG_BUILD_BIN_DIR)/AdGuardHome' ./feeds/packages/net/adguardhome/Makefile
sed -i '/init/d' feeds/packages/net/adguardhome/Makefile
#Argon 主题
git clone -b master --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/new/luci-theme-argon
git clone -b master --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/new/luci-app-argon-config
#ARP 绑定
svn co https://github.com/QiuSimons/OpenWrt_luci-app/trunk/lean/luci-app-arpbind package/lean/luci-app-arpbind
#定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot package/lean/luci-app-autoreboot
#Boost 通用即插即用
svn co https://github.com/ryohuang/slim-wrt/trunk/slimapps/application/luci-app-boostupnp package/new/luci-app-boostupnp
sed -i 's,https://api.ipify.org,http://members.3322.org/dyndns/getip,g' ./package/new/luci-app-boostupnp/root/usr/sbin/boostupnp.sh
#ChinaDNS
git clone -b luci --depth 1 https://github.com/pexcn/openwrt-chinadns-ng.git package/new/luci-app-chinadns-ng
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/chinadns-ng package/new/chinadns-ng
#内存压缩
#wget -O- https://patch-diff.githubusercontent.com/raw/openwrt/openwrt/pull/2840.patch | patch -p1
wget -O- https://github.com/NoTengoBattery/openwrt/commit/40f1d5.patch | patch -p1
wget -O- https://github.com/NoTengoBattery/openwrt/commit/a83a0b.patch | patch -p1
wget -O- https://github.com/NoTengoBattery/openwrt/commit/6d5fb4.patch | patch -p1
mkdir ./package/new
cp -rf ../NoTengoBattery/feeds/luci/applications/luci-app-compressed-memory ./package/new/luci-app-compressed-memory
sed -i 's,include ../..,include $(TOPDIR)/feeds/luci,g' ./package/new/luci-app-compressed-memory/Makefile
cp -rf ../NoTengoBattery/package/system/compressed-memory ./package/system/compressed-memory
#CPU 控制相关
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/luci-app-cpufreq package/lean/luci-app-cpufreq
cp -rf ../PATCH/duplicate/luci-app-cpulimit ./package/lean/luci-app-cpulimit
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ntlf9t/cpulimit package/lean/cpulimit
#动态DNS
rm -rf ./feeds/packages/net/ddns-scripts
rm -rf ./feeds/luci/applications/luci-app-ddns
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_aliyun package/lean/ddns-scripts_aliyun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_dnspod package/lean/ddns-scripts_dnspod
svn co https://github.com/openwrt/packages/branches/openwrt-18.06/net/ddns-scripts feeds/packages/net/ddns-scripts
svn co https://github.com/openwrt/luci/branches/openwrt-18.06/applications/luci-app-ddns feeds/luci/applications/luci-app-ddns
svn co https://github.com/QiuSimons/OpenWrt_luci-app/trunk/others/luci-app-tencentddns package/lean/luci-app-tencentddns
svn co https://github.com/kenzok8/openwrt-packages/trunk/luci-app-aliddns package/new/luci-app-aliddns
#Docker 容器（会导致OpenWrt出现UDP转发问题，慎用）
#sed -i 's/+docker/+docker \\\n\t+dockerd/g' ./feeds/luci/applications/luci-app-dockerman/Makefile
rm -rf ./feeds/luci/applications/luci-app-dockerman
cp -rf ../openwrt-lienol/package/diy/luci-app-dockerman ./feeds/luci/applications/luci-app-dockerman
#Edge 主题
git clone -b master --depth 1 https://github.com/garypang13/luci-theme-edge.git package/new/luci-theme-edge
#FRP 内网穿透
rm -rf ./feeds/luci/applications/luci-app-frps
rm -rf ./feeds/luci/applications/luci-app-frpc
rm -rf ./feeds/packages/net/frp
rm -f ./package/feeds/packages/frp
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-frps package/lean/luci-app-frps
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-frpc package/lean/luci-app-frpc
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/frp package/lean/frp
#IPSec
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ipsec-vpnd package/lean/luci-app-ipsec-vpnd
#IPv6 兼容助手
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipv6-helper package/lean/ipv6-helper
#京东签到 By Jerrykuku
git clone --depth 1 https://github.com/jerrykuku/node-request.git package/new/node-request
git clone --depth 1 https://github.com/jerrykuku/luci-app-jd-dailybonus.git package/new/luci-app-jd-dailybonus
pushd package/new/luci-app-jd-dailybonus
sed -i 's/wget-ssl/wget/g' root/usr/share/jd-dailybonus/newapp.sh luasrc/controller/jd-dailybonus.lua
popd
#回滚通用即插即用
#rm -rf ./feeds/packages/net/miniupnpd
#svn co https://github.com/coolsnowwolf/packages/trunk/net/miniupnpd feeds/packages/net/miniupnpd
#Moschinadns
svn co https://github.com/QiuSimons/openwrt-packages/branches/main/mos-chinadns package/new/mos-chinadns
svn co https://github.com/QiuSimons/openwrt-packages/branches/main/luci-app-moschinadns package/new/luci-app-moschinadns
#流量监管
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-netdata package/lean/luci-app-netdata
#上网 APP 过滤
git clone -b master --depth 1 https://github.com/destan19/OpenAppFilter.git package/new/OpenAppFilter
#OLED 驱动程序
git clone -b master --depth 1 https://github.com/NateLol/luci-app-oled.git package/new/luci-app-oled
#OpenClash
git clone -b master --depth 1 https://github.com/vernesong/OpenClash.git package/new/luci-app-openclash
#花生壳内网穿透
svn co https://github.com/teasiu/dragino2/trunk/package/teasiu/luci-app-phtunnel package/new/luci-app-phtunnel
svn co https://github.com/QiuSimons/dragino2-teasiu/trunk/package/teasiu/luci-app-oray package/new/luci-app-oray
svn co https://github.com/teasiu/dragino2/trunk/package/teasiu/phtunnel package/new/phtunnel
#Pandownload
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/pandownload-fake-server package/lean/pandownload-fake-server
#Passwall
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/luci-app-passwall package/new/luci-app-passwall
sed -i 's,default n,default y,g' package/new/luci-app-passwall/Makefile
sed -i '/V2ray:v2ray/d' package/new/luci-app-passwall/Makefile
sed -i '/plugin:v2ray/d' package/new/luci-app-passwall/Makefile
cp -f ../PATCH/new/script/move_2_services.sh ./package/new/luci-app-passwall/move_2_services.sh
pushd package/new/luci-app-passwall
bash move_2_services.sh
popd
rm -rf ./feeds/packages/net/https-dns-proxy
svn co https://github.com/Lienol/openwrt-packages/trunk/net/https-dns-proxy feeds/packages/net/https-dns-proxy
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/tcping package/new/tcping
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-go package/new/trojan-go
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/brook package/new/brook
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-plus package/new/trojan-plus
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/ssocks package/new/ssocks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/xray-core package/new/xray-core
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray package/new/v2ray
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray-plugin package/new/v2ray-plugin
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/xray-plugin package/new/xray-plugin
#qBittorrent 下载
svn co https://github.com/garypang13/openwrt-static-qb/trunk/qBittorrent-Enhanced-Edition package/lean/qBittorrent-Enhanced-Edition
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-qbittorrent package/lean/luci-app-qbittorrent
sed -i 's/+qBittorrent +python3/+qBittorrent-Enhanced-Edition/g' package/lean/luci-app-qbittorrent/Makefile
#清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree package/lean/luci-app-ramfree
#ServerChan 微信推送
git clone -b master --depth 1 https://github.com/tty228/luci-app-serverchan.git package/new/luci-app-serverchan
#SmartDNS
rm -rf ./feeds/packages/net/smartdns
mkdir package/new/smartdns
wget -P package/new/smartdns/ https://github.com/HiGarfield/lede-17.01.4-Mod/raw/master/package/extra/smartdns/Makefile
sed -i 's,files/etc/config,$(PKG_BUILD_DIR)/package/openwrt/files/etc/config,g' ./package/new/smartdns/Makefile
#SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus package/lean/luci-app-ssr-plus
rm -rf ./package/lean/luci-app-ssr-plus/po/zh_Hans
pushd package/lean
#wget -qO - https://patch-diff.githubusercontent.com/raw/fw876/helloworld/pull/430.patch | patch -p1
popd
sed -i 's,default n,default y,g' package/lean/luci-app-ssr-plus/Makefile
sed -i 's,Xray:xray ,Xray:xray-core ,g' package/lean/luci-app-ssr-plus/Makefile
sed -i '/V2ray:v2ray/d' package/lean/luci-app-ssr-plus/Makefile
sed -i '/plugin:v2ray/d' package/lean/luci-app-ssr-plus/Makefile
sed -i '/result.encrypt_method/a\result.fast_open = "1"' package/lean/luci-app-ssr-plus/root/usr/share/shadowsocksr/subscribe.lua
sed -i 's,ispip.clang.cn/all_cn.txt,raw.sevencdn.com/QiuSimons/Chnroute/master/dist/chnroute/chnroute.txt,g' package/lean/luci-app-ssr-plus/root/etc/init.d/shadowsocksr
sed -i 's,YW5vbnltb3Vz/domain-list-community/release/gfwlist.txt,Loyalsoldier/v2ray-rules-dat/release/gfw.txt,g' package/lean/luci-app-ssr-plus/root/etc/init.d/shadowsocksr
#SSRP 依赖
rm -rf ./feeds/packages/net/xray-core
rm -rf ./feeds/packages/net/kcptun
rm -rf ./feeds/packages/net/shadowsocks-libev
rm -rf ./feeds/packages/net/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev package/lean/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt package/lean/pdnsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/kcptun package/lean/kcptun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2 package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/proxychains-ng package/lean/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks package/lean/ipt2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev package/lean/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan package/lean/trojan
svn co https://github.com/fw876/helloworld/trunk/naiveproxy package/lean/naiveproxy
svn co https://github.com/fw876/helloworld/trunk/shadowsocks-rust package/lean/shadowsocks-rust
#订阅转换
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/subconverter package/new/subconverter
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/jpcre2 package/new/jpcre2
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/rapidjson package/new/rapidjson
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/duktape package/new/duktape
#网易云音乐解锁
git clone --depth 1 https://github.com/immortalwrt/luci-app-unblockneteasemusic.git package/new/UnblockNeteaseMusic
#USB 打印机
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-usb-printer package/lean/luci-app-usb-printer
#UU加速
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-uugamebooster package/lean/luci-app-uugamebooster
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/uugamebooster package/lean/uugamebooster
#Vlmcsd 激活助手
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-vlmcsd package/lean/luci-app-vlmcsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/vlmcsd package/lean/vlmcsd
#VSSR
git clone -b master --depth 1 https://github.com/jerrykuku/luci-app-vssr.git package/lean/luci-app-vssr
git clone -b master --depth 1 https://github.com/jerrykuku/lua-maxminddb.git package/lean/lua-maxminddb
sed -i 's,default n,default y,g' package/lean/luci-app-vssr/Makefile
sed -i '/V2ray:v2ray/d' package/lean/luci-app-vssr/Makefile
sed -i '/plugin:v2ray/d' package/lean/luci-app-vssr/Makefile
sed -i '/result.encrypt_method/a\result.fast_open = "1"' package/lean/luci-app-vssr/root/usr/share/vssr/subscribe.lua
sed -i 's,ispip.clang.cn/all_cn.txt,raw.sevencdn.com/QiuSimons/Chnroute/master/dist/chnroute/chnroute.txt,g' package/lean/luci-app-vssr/luasrc/controller/vssr.lua
sed -i 's,ispip.clang.cn/all_cn.txt,raw.sevencdn.com/QiuSimons/Chnroute/master/dist/chnroute/chnroute.txt,g' package/lean/luci-app-vssr/root/usr/share/vssr/update.lua
#网络唤醒
svn co https://github.com/sundaqiang/openwrt-packages/trunk/luci-app-services-wolplus package/new/luci-app-services-wolplus
#流量监视
git clone -b master --depth 1 https://github.com/brvphoenix/wrtbwmon.git package/new/wrtbwmon
git clone -b master --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon.git package/new/luci-app-wrtbwmon
#迅雷快鸟宽带加速
git clone --depth 1 https://github.com/garypang13/luci-app-xlnetacc.git package/lean/luci-app-xlnetacc
#Zerotier
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/luci-app-zerotier package/lean/luci-app-zerotier
cp -f ../PATCH/new/script/move_2_services.sh ./package/lean/luci-app-zerotier/move_2_services.sh
pushd package/lean/luci-app-zerotier
bash move_2_services.sh
popd
rm -rf ./feeds/packages/net/zerotier/files/etc/init.d/zerotier


## 最后的收尾工作
#Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../PATCH/new/script/fuck package/base-files/files/usr/bin/fuck
cp -f ../PATCH/new/script/chinadnslist package/base-files/files/usr/bin/chinadnslist
#最大连接
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
#生成默认配置及缓存
rm -rf .config

exit 0
