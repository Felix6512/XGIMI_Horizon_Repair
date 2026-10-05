#!/usr/bin/env python3
"""Erzeugt aus dem Original-USB-Upgrade-Image ein Diagnose-Image.

Geaendert werden genau zwei Zeilen im Skriptkopf der Datei:

    setenv close_log yes   ->   setenv close_log no
    ac loglevel 3          ->   ac loglevel 7

Danach hat das Geraet nach dem Flashen eine offene Debug-Konsole mit ausfuehrlichem
Log. Der Rest der Datei (alle Partitionsdaten) bleibt Byte fuer Byte gleich; die beiden
Pruefsummen am Dateiende werden neu berechnet.

Die Firmware selbst ist NICHT Teil dieses Repositories. Das Original-Image bekommt man
von XGIMI (siehe README). Das Image schreibt beim Flashen ALLE Partitionen neu und
setzt gespeicherte Einstellungen und Abgleichdaten auf Werkswerte zurueck.

Aufruf:   python make_diag_image.py ORIGINAL.bin AUSGABE.bin
"""
import os
import struct
import sys
import zlib

HEADER = 0x4000          # Skriptbereich am Dateianfang
FOOTER = 32              # "12345678" + CRC Kopf + CRC gesamt + 16 Byte Kopie des Anfangs
MAGIC = b"12345678"
CHUNK = 1 << 24


def crc_range(f, start, length, crc=0):
    f.seek(start)
    while length > 0:
        buf = f.read(min(CHUNK, length))
        if not buf:
            raise IOError("Datei zu kurz")
        crc = zlib.crc32(buf, crc)
        length -= len(buf)
    return crc & 0xFFFFFFFF


def check_source(path):
    size = os.path.getsize(path)
    with open(path, "rb") as f:
        header = f.read(HEADER)
        f.seek(size - FOOTER)
        foot = f.read(FOOTER)
        if foot[:8] != MAGIC:
            sys.exit("Fehler: Dateiende hat nicht das erwartete Format ('12345678').")
        crc_head, crc_all = struct.unpack("<II", foot[8:16])
        if crc_head != zlib.crc32(header) & 0xFFFFFFFF:
            sys.exit("Fehler: Pruefsumme des Skriptkopfs stimmt nicht.")
        if crc_all != crc_range(f, 0, size - 20):
            sys.exit("Fehler: Gesamtpruefsumme stimmt nicht. Datei beschaedigt?")
        if foot[16:] != header[:16]:
            sys.exit("Fehler: Kopie des Dateianfangs stimmt nicht.")
    return size, header


def main(src, dst):
    if os.path.exists(dst):
        sys.exit("Ausgabedatei existiert bereits, bitte anderen Namen waehlen.")
    size, header = check_source(src)
    end = header.index(b"\xff")
    script = header[:end]
    for old in (b"setenv close_log yes\n", b"ac loglevel 3\n"):
        if script.count(old) != 1:
            sys.exit("Fehler: Zeile %r nicht genau einmal gefunden." % old)
    script = script.replace(b"setenv close_log yes\n", b"setenv close_log no\n")
    script = script.replace(b"ac loglevel 3\n", b"ac loglevel 7\n")
    new_header = script + b"\xff" * (HEADER - len(script))

    with open(src, "rb") as fi, open(dst, "wb") as fo:
        fo.write(new_header)
        crc = zlib.crc32(new_header)
        fi.seek(HEADER)
        remaining = size - HEADER - FOOTER
        while remaining > 0:
            buf = fi.read(min(CHUNK, remaining))
            fo.write(buf)
            crc = zlib.crc32(buf, crc)
            remaining -= len(buf)
        tail = MAGIC + struct.pack("<I", zlib.crc32(new_header) & 0xFFFFFFFF)
        crc = zlib.crc32(tail, crc) & 0xFFFFFFFF
        fo.write(tail + struct.pack("<I", crc) + new_header[:16])

    check_source(dst)  # Ergebnis gegen dieselben Regeln pruefen
    print("Fertig:", dst, "(%d Bytes)" % os.path.getsize(dst))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
