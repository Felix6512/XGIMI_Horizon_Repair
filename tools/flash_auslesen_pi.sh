#!/bin/sh
# Liest einen SPI-Flash (hier: Winbond W25Q32JV) auf einem Raspberry Pi zweimal aus
# und vergleicht die Pruefsummen. NUR LESEN, es wird nichts geschrieben oder geloescht.
#
# Voraussetzungen: SPI am Pi eingeschaltet (raspi-config), flashrom installiert.
# Der Projektor muss stromlos sein, das Flexkabel abgezogen. Der Pi versorgt den Chip.
#
# Verdrahtung (Chip im SOIC-8, Pin 1 = Punkt auf dem Gehaeuse):
#   Chip-Pin 1 /CS   -> Pi-Pin 24 (CE0)      Chip-Pin 5 DI   -> Pi-Pin 19 (MOSI)
#   Chip-Pin 2 DO    -> Pi-Pin 21 (MISO)     Chip-Pin 6 CLK  -> Pi-Pin 23 (SCLK)
#   Chip-Pin 3 /WP   -> Pi-Pin 1  (3,3 V)    Chip-Pin 7 /HOLD-> Pi-Pin 1  (3,3 V)
#   Chip-Pin 4 GND   -> Pi-Pin 25 (GND)      Chip-Pin 8 VCC  -> Pi-Pin 1  (3,3 V)
# Niemals die 5-V-Pins (Pi-Pin 2 und 4) verwenden.
#
# Aufruf:  ./flash_auslesen_pi.sh u4

set -e
NAME="${1:?Aufruf: $0 NAME   (z. B. u4)}"
PROG="linux_spi:dev=/dev/spidev0.0,spispeed=1000"

flashrom -p "$PROG"                                  # nur erkennen
flashrom -p "$PROG" -c "W25Q32.V" -r "${NAME}_a.bin"
flashrom -p "$PROG" -c "W25Q32.V" -r "${NAME}_b.bin"
sha256sum "${NAME}_a.bin" "${NAME}_b.bin"
cmp "${NAME}_a.bin" "${NAME}_b.bin" && echo "Beide Lesungen identisch."
