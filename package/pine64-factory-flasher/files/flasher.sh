#!/bin/sh

###########################################################
#                                                         #
#   Pine64 Factory Flasher Utility - written by Danct12   #
#                                                         #
###########################################################

EMMC_DEV=""
SPI_DEV=""
BRAND=""
MODEL=""

[ ! -f /etc/deviceinfo ] && exit 1
. /etc/deviceinfo

# Internal Variables
BACKTITLE="Pine64 Factory Flasher - Running on ${BRAND} ${MODEL}"
EMMC_IMAGE_FILE=/root/emmc.img
SPI_IMAGE_FILE=/root/spi.img
EMMC_FLASH_FINISHED=0
SPI_FLASH_FINISHED=0
ALL_FLASH_FINISHED=""
MD5SUM_FILE=""

# Functions
checksum_emmc() {
    echo "Verifying ${EMMC_IMAGE_FILE} integrity, this may take a while.."
    if [ -f ${EMMC_IMAGE_FILE} ] && [ -f ${EMMC_IMAGE_FILE}.md5 ]; then
        MD5SUM_FILE=$(md5sum ${EMMC_IMAGE_FILE} | cut -f 1 -d ' ')
        MD5SUM_FILE_EXP=$(cat ${EMMC_IMAGE_FILE}.md5)

        [ "${MD5SUM_FILE}" = "${MD5SUM_FILE_EXP}" ] || \
            { dialog --backtitle "${BACKTITLE}" \
                --msgbox "EMMC FILE CHECKSUM !!FAILED!!\n\
Got:\n${MD5SUM_FILE}\n\n\
Expected:\n${MD5SUM_FILE_EXP}" \
                10 \
                50; return 1; }
    fi
}

checksum_spi() {
    echo "Verifying ${SPI_IMAGE_FILE} integrity.."
    if [ -f ${SPI_IMAGE_FILE} ] && [ -f ${SPI_IMAGE_FILE}.md5 ]; then
        MD5SUM_FILE=$(md5sum ${SPI_IMAGE_FILE} | cut -f 1 -d ' ')
        MD5SUM_FILE_EXP=$(cat ${SPI_IMAGE_FILE}.md5)

        [ "${MD5SUM_FILE}" = "${MD5SUM_FILE_EXP}" ] || \
            { dialog --backtitle "${BACKTITLE}" \
                --msgbox "SPI FILE CHECKSUM !!FAILED!!\n\
Got:\n${MD5SUM_FILE}\n\n\
Expected:\n${MD5SUM_FILE_EXP}" \
                10 \
                50; return 1; }
    fi
}

flash_os_menu() {
    exec 3>&1
    MENUSELECT=$(dialog --backtitle "${BACKTITLE}" \
        --title "Flash OS to Internal Storage" \
        --clear \
        --no-cancel \
        --menu "Which part do you want to flash?" \
        10 \
        40 \
        4 \
        "1" "All" \
        "2" "eMMC (OS)" \
        "3" "SPI (Bootloader)" \
        2>&1 1>&3)

    case ${MENUSELECT} in
        1)
            clear
            if [ -f ${EMMC_IMAGE_FILE} ]; then
                if flash_emmc; then
                    EMMC_FLASH_FINISHED=1
                else
                    dialog --backtitle "${BACKTITLE}" --msgbox "eMMC flash !!FAILED!!" 7 70
                fi
            else
                    # Nothing to do, let's just pretend we did it.
                    EMMC_FLASH_FINISHED=1
            fi

            if [ -f ${SPI_IMAGE_FILE} ]; then
                if flash_spi; then
                    SPI_FLASH_FINISHED=1
                else
                    dialog --backtitle "${BACKTITLE}" --msgbox "SPI flash !!FAILED!!" 7 70
                fi
            else
                    # Nothing to do, let's pretend we did it.
                    SPI_FLASH_FINISHED=1
            fi

            if [ ${EMMC_FLASH_FINISHED} -eq 1 ] && [ ${SPI_FLASH_FINISHED} -eq 1 ]; then
                dialog --backtitle "${BACKTITLE}" --msgbox "Flash ALL successful!" 7 70
            else
                dialog --backtitle "${BACKTITLE}" --msgbox "Flash ALL !!FAILED!!" 7 70
            fi

            # If everything is flashed, we have nothing to do next
            # so we go back to main menu for the peaceful shut down.
            #
            # The idea is that the factory people can insert the card,
            # hit power button to do the next thing.
            main_menu
            ;;
        2)
            clear
            if flash_emmc; then
                EMMC_FLASH_FINISHED=1
                dialog --backtitle "${BACKTITLE}" --msgbox "eMMC flash successful!" 7 70
            else
                dialog --backtitle "${BACKTITLE}" --msgbox "eMMC flash !!FAILED!!" 7 70
            fi
            ;;
        3)
            clear
            if flash_spi; then
                SPI_FLASH_FINISHED=1
                dialog --backtitle "${BACKTITLE}" --msgbox "SPI flash successful!" 7 70
            else
                dialog --backtitle "${BACKTITLE}" --msgbox "SPI flash !!FAILED!!" 7 70
            fi
            ;;
    esac
}

flash_emmc() {
    if [ ! -f "${EMMC_IMAGE_FILE}" ]; then
        dialog --backtitle "${BACKTITLE}" \
            --msgbox "This image does not support flashing to eMMC." 6 70
        return 1
    fi

    # If eMMC image checksum fails, DO NOT FLASH!!
    checksum_emmc || return 1

    [ ! -b "${EMMC_DEV}" ] && ( dialog \
        --backtitle "${BACKTITLE}" \
        --msgbox "Device ${EMMC_DEV} not found (or is not a block device)!\n
Please check if your eMMC is turned off, or there is a problem with your eMMC." 10 70 \
        && return 1)

    echo "Flashing ${EMMC_IMAGE_FILE} to ${EMMC_DEV}..."
    if ! (pv -pra ${EMMC_IMAGE_FILE} | dd of=${EMMC_DEV} oflag=direct status=none); then
        return 1
    fi
}

flash_spi() {
    if [ ! -f "${SPI_IMAGE_FILE}" ]; then
        dialog --backtitle "${BACKTITLE}" \
            --msgbox "This image does not support flashing bootloader to SPI." 6 70
        return 1
    fi

    # If SPI image checksum fails, DO NOT FLASH!!
    checksum_spi || return 1

    [ ! -c "${SPI_DEV}" ] && ( dialog \
        --backtitle "${BACKTITLE}" \
        --msgbox "Device ${SPI_DEV} not found (or is not a block device)!
Please check if your SPI is turned off, or there is a problem with your SPI." 10 70 \
        && return 1)

    # -A = erase-all before flashing
    # We want to make sure that the SPI is completely blank
    # before flashing to avoid unexpected behaviors.
    echo "Flashing ${SPI_IMAGE_FILE} to ${SPI_DEV}..."
    flashcp -v -A ${SPI_IMAGE_FILE} ${SPI_DEV} || return 1
}

main_menu() {
    # If flash all is done, default to power off.
    if [ "${EMMC_FLASH_FINISHED}" -gt 0 ] && [ "${SPI_FLASH_FINISHED}" -gt 0 ]
    then
        ALL_FLASH_FINISHED="--default-item 2"
    fi

    exec 3>&1
    MENUSELECT=$(dialog --backtitle "${BACKTITLE}" \
        --title "Factory Flasher Menu" \
        --clear \
        ${ALL_FLASH_FINISHED} \
        --no-cancel \
        --menu "Please select:" \
        10 \
        40 \
        4 \
        "1" "Flash OS to Internal Storage" \
        "2" "Power Off" \
        2>&1 1>&3)

    case ${MENUSELECT} in
        1)
            flash_os_menu
            ;;
        2)
            power_off
            ;;
    esac
}

power_off() {
    sync
    sleep 2
    poweroff -f
}

# The program should never exit, there's no escape.
while true
do
    main_menu
done
