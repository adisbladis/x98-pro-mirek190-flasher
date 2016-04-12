#!/bin/bash
# Mirek190 ROM Android 5.0 flasher
# See http://techtablets.com/forum/topic/x98_pro_android_5-1_mirek190_v1-0-rom/
#
# Flasher converted from Windows batch script by Adam Hose
# Licensed under WTFPL


function fastboot {
    sleep 2
    command fastboot "$@"
}

function echo_status {
    echo -e "\033[32m$1\e[0m"
}

function CHECK_FILE {
    if ! [ -e "$1" ]; then
        echo -e "\033[31m$1 missing, check it and try again\e[0m"
        exit 1
    fi
}

function FLASH_NORMAL {
    CHECK_FILE "ROM/system.img"
    CHECK_FILE "ROM/boot.img"
    CHECK_FILE "ROM/recovery.img"

    echo_status "Booting device"
    fastboot boot data/loader.efi
    sleep 15

    echo_status "Unlocking device"
    fastboot oem unlock

    if ! [ "$1" = "dirty" ]; then
        echo_status "Formatting data"
        fastboot format data
    fi

    echo_status "Formatting cache"
    fastboot format cache

    echo_status "Formatting config"
    fastboot format config

    echo_status "Flashing system"
    fastboot flash system "ROM/system.img"

    echo_status "Flashing kernel"
    fastboot flash boot "ROM/boot.img"

    echo_status "Flashing recovery"
    fastboot flash recovery "ROM/recovery.img"

    echo_status "Booting"
    fastboot continue
}


function INSTALL_REPARTITION {
    CHECK_FILE "ROM/loader.efi"
    CHECK_FILE "ROM/oemvars.txt"
    CHECK_FILE "ROM/oemvars-telephony-config-7260_V2_dataonly.txt"
    CHECK_FILE "ROM/bootloader"
    CHECK_FILE "ROM/system.img"
    CHECK_FILE "ROM/boot.img"
    CHECK_FILE "ROM/recovery.img"

    echo_status "Flashing osloader"
    fastboot flash osloader "ROM/loader.efi"

    echo_status "Booting device"
    fastboot boot "ROM/loader.efi"
    sleep 15

    echo_status "Unlocking device"
    fastboot oem unlock

    echo_status "Flashing oemvars"
    fastboot flash oemvars "ROM/oemvars.txt"

    echo_status "Flashing oemvars data"
    fastboot flash oemvars "ROM/oemvars-telephony-config-7260_V2_dataonly.txt"

    echo_status "Flashing GPT"
    fastboot flash gpt "$1"

    echo_status "Flashing bootloader"
    fastboot flash bootloader "ROM/bootloader"

    echo_status "Erasing misc"
    fastboot erase misc

    echo_status "Erasing persistent"
    fastboot erase persistent

    echo_status "Erasing metadata"
    fastboot erase metadata

    echo_status "Formatting config"
    fastboot format config

    echo_status "Formatting factory"
    fastboot format factory

    echo_status "Formatting cache"
    fastboot format cache

    echo_status "Flashing system"
    fastboot flash system "ROM/system.img"

    echo_status "Flashing kernel"
    fastboot flash boot "ROM/boot.img"

    echo_status "Flashing recovery"
    fastboot flash recovery "ROM/recovery.img"

    echo_status "Verifying OEM"
    fastboot oem verified

    echo_status "Formatting data"
    fastboot format data

    fastboot continue
}


function BUTTONS {
    SystemUI_apk="data/pro_buttons/$1-buttons/SystemUI.apk"

    CHECK_FILE "$SystemUI_apk"

    adb kill-server
    add wait-for-device
    adb root

    sleep 5

    adb shell mount -o rw,remount /system
    adb push "$SystemUI_apk" /data
    adb shell rm -f /system/priv-app/SystemUI/SystemUI.apk
    adb shell cp -R /data/SystemUI.apk /system/priv-app/SystemUI/
    adb shell chmod 644 /system/priv-app/SystemUI/SystemUI.apk
    adb shell chown root.root /system/priv-app/SystemUI/SystemUI.apk
    adb shell rm -rf /data/SystemUI.apk
    adb reboot
}


if ! [ $(id -u) -eq 0 ]; then
    echo "Flasher must run as root, exiting" >> /dev/stderr
    exit 1
fi

case "$1" in
    dirty)
        FLASH_NORMAL "dirty"
        ;;
    clean)
        FLASH_NORMAL "clean"
        ;;
    install_repartition)
        if [ "$#" -ne 2 ]; then
            echo "install_repartition requires path to gpt.bin, see PARTITIONS directory" >> /dev/stderr
            exit 1
        fi
        if ! [ -e "$2" ]; then
            echo "File '$2' not found"
        fi

        INSTALL_REPARTITION "$2"
        ;;
    buttons)
        if [ "$#" -ne 2 ]; then
            echo "buttons require argument number (3, 5 or 6)"
            exit 1
        fi

        BUTTONS "$2"
        ;;
    *)
        echo -e "Need one of the following arguments\n" >> /dev/stderr

        echo "dirty: " >> /dev/stderr
        echo -e "\tAndriod data and apps will be kept" >> /dev/stderr
        echo -e "\tWON'T REMOVE WINDOWS AND WINDOWS BOOT MENU" >> /dev/stderr
        echo "" >> /dev/stderr

        echo "clean: " >> /dev/stderr
        echo -e "\tAndroid data and apps will be removed" >> /dev/stderr
        echo -e "\tWON'T REMOVE WINDOWS AND WINDOWS BOOT MENU" >> /dev/stderr
        echo "" >> /dev/stderr

        echo "install_repartition: " >> /dev/stderr
        echo -e "\tYou can change partitions sizes" >> /dev/stderr
        echo -e "\tWILL REMOVE WINDOWS AND WINDOWS BOOT MENU" >> /dev/stderr
        echo "" >> /dev/stderr

        echo "buttons: " >> /dev/stderr
        echo -e "\tInstall buttons mod" >> /dev/stderr
        echo -e "\tInstall 3 (default), 5 or 6 button mod" >> /dev/stderr

        exit 1
esac
