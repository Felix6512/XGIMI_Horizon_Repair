# Chronik aller Versuche und das Bootverhalten

Vollständige Reihenfolge der Untersuchung mit Ergebnis, auch der Sackgassen. Die Kurzfassung steht im
[README](../README.md), die Rohdaten in [`../logs/`](../logs/). Wo etwas Deutung ist, steht es dabei.

## Bootverhalten des Geräts (so, wie es sich in den Logs zeigt)

| Situation | Was die Konsole zeigt |
|---|---|
| Netz anstecken | Bootrom, DDR-Test, Secure Boot, OP-TEE, U-Boot, eMMC (`29.12 GB`, HS400), dann `[GPIO_WAKE_SETTING]` … `Power Down`. Das Gerät geht von selbst in den Standby. Dauer ca. 3 s. |
| Power-Taste kurz | Neustart (`AC_ON`), U-Boot liest `key adc value:255` (keine Taste), startet normal. Bei dem defekten Gerät hing der Start danach in der DLP-Initialisierung. |
| Power-Taste lang (ca. 6 s) | `key adc value:18`, `sarKeyGetKeyCode key=160,hold=6000`, `processBootEvent:XGIMI_EN_BOOT_EVENT=2`. U-Boot sucht dann auf den drei USB-Ports einen Stick mit dem Upgrade-Image (`ota zip check`, `Check USB port[0..2]`). Ohne Stick: `FAIL : can not init usb!!`, danach normaler Start. |
| Mit passendem Stick (MBR, FAT32) | Upgrade-Modus: schnelles Blinken, Lüfter hoch, ca. 600 mA. Die Konsole bleibt dabei stumm. Nach rund 16 min Neustart. |

Die Konsole ist ab dem Kernelstart in der Werkseinstellung absichtlich abgeschaltet (`close_log yes` im Upgrade-Skript).
Der Watchdog ist an (`WDT_ENABLE 1`). Weitere Variablen aus `printenv` stehen in
[`logs/15_voll_diagnose_flash_zeit.txt`](../logs/15_voll_diagnose_flash_zeit.txt), unter anderem `force_upgrade=0x40`,
`ForceUpgradePath=<Dateiname des Images>`, `factory_poweron_mode=secondary`, `devicestate=lock`.

## Chronik

### Vor der Konsole (Notizen vom Anfang, siehe [anfangsnotizen](anfangsnotizen_vor_ursachenfindung.md))

| Versuch | Ergebnis |
|---|---|
| Beobachtung beim Einstecken | ca. 5 W, Status-LED blinkt langsam, kein Bild, kein Ton |
| Power-Taste lang gehalten, Stick eingesteckt | ca. 12 W, schnelles Blinken, **kein** sichtbarer Flash, kein Recovery-Bild |
| Bp-Stecker abgezogen | keine Änderung |
| Alle vier LED-Kanäle (R, G, B, Bp) einzeln mit Labornetzteil | alle leuchten, die LEDs sind in Ordnung |
| Spannungen an den LED-Testpunkten | R/G/B-Seite ca. 18,8 V, Gegenseite 14,9 V, Bp 0 V. **Das war rückblickend der Hinweis auf den Defekt**, wurde aber nicht so gedeutet. |
| Beide Temperatur-NTC | ca. 123 kΩ, plausibel, nicht die Ursache |
| Blaue LED extern versorgt, Gerät eingeschaltet | kurzes Aufflackern von Bildinhalt, Streifen, dann Dauerlicht. Der DMD wurde also kurz angesteuert. |
| UART am Debug-Stecker | TX gefunden (3,3 V, 115200 Baud), Bootlog bis `Power Down` lesbar |

### Mit Mitschnitt (Logs 01 bis 18)

| Nr. | Versuch | Ergebnis |
|---|---|---|
| 01 | Passiver Mitschnitt: Einstecken, kurzer Tastendruck | wie in den Notizen: Standby, nach Tastendruck Stille nach der eMMC-Meldung |
| 02–05 | U-Boot per Enter anhalten, mit und ohne DTR/RTS | **ohne Wirkung.** Der Bootloader hat nie auf Eingaben reagiert. Der Empfangskanal wurde nicht geklärt (RX-Pin, Pegel, oder Eingabe ist gesperrt). |
| 06 | Drei Starts nacheinander mitgeschnitten | reproduzierbar, aber ohne Zeitangabe |
| 07 | Mitschnitt mit Zeitstempeln | **Reset exakt 60,2 s nach dem Tastendruck, zweimal gleich.** Deutung: Watchdog. |
| 08 | Dauer-Enter beim Start | kein Effekt, Reset wieder nach 60,2 s |
| 09 | Flachbandkabel zur DLP-Platine abgezogen | unverändert |
| 10 | Alle Peripheriestecker abgezogen | unverändert. Der Standby-Pfad dauerte einmal 8 s statt 3 s, später relativiert (Schwankung). |
| 11 | Nur Tastenmodul angesteckt | wieder 60,2 s. Es war damit klar, dass der Fehler nicht an der Peripherie hängt. |
| – | Taste als Ursache geprüft | `key adc value:255` ohne Druck: die Taste klemmt nicht |
| – | USB-Stick untersucht | Stick war **GPT**. Image-Format: 16-kB-Klartextskript, Partitionsdaten, Abschluss mit zwei CRC32. Keine Signatur. |
| 12 | Stick auf **MBR** umgestellt, Image kopiert (Prüfsumme verglichen), langer Tastendruck | **Upgrade läuft, ca. 16 min, Neustart mit anderem Bootloader (August statt Oktober 2022).** Danach einmal stummer Zustand: 300 mA, langsames Blinken, Taste ohne Wirkung. |
| 13 | Erster Start nach dem Flash | stumm, kein Standby; kein 60-s-Reset mehr. Nach Stromtrennung später wieder normaler Standby. |
| 14 | 20-kB-Diagnose-Image (nur Konsole an, keine Partitionen) | **wurde nicht ausgeführt.** Gerät blieb im Upgrade-Wartezustand. Ein zweites kleines Image wurde gebaut, aber nicht getestet. |
| 15 | Volles Image mit denselben zwei geänderten Zeilen (`tools/make_diag_image.py`) | Flash ok, ab dem Neustart **offene Konsole**. Sie zeigt: Der Start hängt in der DLP-Initialisierung. |
| – | Netzwerk-Scan des Heimnetzes | Der Projektor tauchte nicht auf. Das passt dazu, dass der Start vor Android hängt. |
| 16 | Start mit offener Konsole | `read 0xD4 retry` in Serie, `DLP IIC Read Failed`, `Host IRQ check fail`, dann `Power_Off` / `Power_On` in Endlosschleife |
| 17 | Dauer-Enter bei offener Konsole | ohne Wirkung. DLP-Fehler auch ohne aufgesetzten DMD. |
| 18 | Flexboard mit den Speichern angesteckt, DMD abgenommen | unverändert |

### Messungen an den Platinen (ohne Mitschnitt)

| Messung | Ergebnis | Folgerung |
|---|---|---|
| DLP-Platine: 1,1 V Kernspannung (`P1P1V1`) | 1,115 V | in Ordnung |
| DLP-Platine: Versorgung am `POWER`-Stecker | 1,8 V, 3,3 V und 5 V vorhanden | in Ordnung |
| Oszillator `OSC2` | 24 MHz | Taktquelle in Ordnung |
| Taktverteiler `U2` (`CDCLVC1102`) | am Eingang kein Takt | **falsche Spur.** `U2` verteilt vermutlich einen anderen Takt (Pixeltakt), nicht den von `OSC2`. |
| `HOST_IRQ` beider DLP-Controller | bleibt dauerhaft auf 3,3 V (High) | Controller schließen den Start nie ab |
| Firmware-Speicher | auf der DLP-Platine unbestückt, **auf dem Flexboard** zwei Winbond W25Q32JV | Controller lesen dort je einmal einen Block |
| Beide Speicher mit Raspberry Pi und `flashrom` ausgelesen, je zweimal | **identischer Inhalt**, sauber aufgebaut | Speicherinhalt unauffällig. Ein Chip war dabei kurz verpolt angeschlossen und hat es überlebt. |
| DLPA3005 (unter dem Kühlkörper) | `PROJ_ON` kommt an, `RESET_Z` wird frei, 1,1 V und 1,8 V stimmen, über SPI antwortet er mit der Kennung `E3` (aus Oszilloskop-Zeiten gedeutet) | Chip ist wach und wird angesprochen |
| Zuerst gemessen: 2,0 V und 1,25 V an den Schaltreglerdrosseln | falsch angezeigt | mit genauerem Messgerät 1,822 V und 1,113 V, also im Soll |
| `INT_Z` des DLPA3005 | ca. 300 ms High, dann Low | Chip meldet einen Fehler |
| `VOFS`, `VBIAS`, `VRST` | ohne DMD gar nicht, mit DMD ca. 240 ms bzw. 160 ms auf Sollwert, dann aus | DMD-Versorgung selbst ist in Ordnung |
| LED-Spannung während der 300 ms | rampt gleichmäßig bis zur Eingangsspannung, `INT_Z` fällt, wenn sie ankommt, kein Lichtblitz | Überspannungsschutz bei offenem LED-Kreis |
| Diodentest der Leistungstransistoren | `QD10`: 0 V in beiden Richtungen, ca. 1 Ω zwischen 19 V und RGB-Anode. `QM7` zum Vergleich: 600 mV | **`QD10` ist kurzgeschlossen.** |
| Ersatz eingelötet | Gerät lief wieder vollständig | Ursache bestätigt |

## Was nicht geklärt ist

- Warum der Bootloader keine Eingaben über den Debug-Stecker annimmt.
- Warum `QD10` ausgefallen ist (Alterung, Überhitzung oder eine Ursache dahinter).
- Welche Bedeutung die zwei Bestückungsvarianten haben (`QD10` / `QD7`, `U4`/`U5` auf der DLP-Platine).
- Ob die Abgleichdaten (Farbe, Fokus, Trapezkorrektur) nach den Flashs wieder stimmen. Sie wurden auf Werkswerte zurückgesetzt.
