> **Hinweis:** Das sind die Notizen vom Beginn der Fehlersuche, vor der Ursachenfindung. Die Vermutungen zu Bootloader, Recovery und Power-Sequencing sind überholt. Die Ursache und der Weg dorthin stehen im [README](../README.md).

# XGIMI Horizon XK03K – Diagnoseprojekt

## 1. Projektziel

Ziel ist die Fehlersuche an einem **XGIMI Horizon FHD, Modell XK03K**, der sich elektrisch einschalten lässt, aber **kein normales Bild, keinen Ton und keinen regulären Bootvorgang** zeigt.

Das Gerät wird auf Laborebene untersucht. Neben Leistungsaufnahme und Spannungen wurden bereits die LED-Lichtquelle, Temperatursensorik, DLP-/DMD-Einheit und die serielle Debug-Schnittstelle untersucht.

---

## 2. Ausgangsfehler

### Beobachtetes Verhalten

Nach Anschluss der Stromversorgung:

- Gerät zieht ungefähr **5 W**
- Status-LED blinkt **langsam**
- kein Bild
- kein Ton
- kein sichtbarer regulärer Bootvorgang

Bei langem Drücken der Power-Taste:

- Leistungsaufnahme steigt auf ungefähr **12 W**
- Status-LED blinkt **schnell**
- weiterhin kein normales Bild
- kein Ton
- mit eingestecktem USB-Stick startet kein sichtbarer Firmware-Flash

Dieses Verhalten passt grundsätzlich zu einem frühen Boot-/Recovery-Zustand.

---

## 3. USB-Recovery / Force-Brush

Für den Horizon existiert ein Recovery-/Force-Brush-Verfahren über USB.

Verwendet wurde ein USB-Stick mit Firmware im Recovery-Modus.

Beobachtung:

- Gerät erkennt offenbar den langen Tastendruck
- schnelles Blinken tritt auf
- Leistungsaufnahme steigt auf ca. 12 W
- es erscheint jedoch **kein Android-Recovery-Bild**
- kein sichtbarer Firmware-Flash
- kein normaler Bildaufbau

Später zeigte die UART-Diagnose, dass der lange Tastendruck tatsächlich einen **anderen Bootpfad** auslöst.

---

## 4. Lichtquelle

Der Horizon besitzt keine einzelne weiße Projektionslampe, sondern getrennte LED-Kanäle.

Vorhandene Anschlüsse:

- **R** – Rot
- **G** – Grün
- **B** – Blau
- **Bp** – zusätzlicher Blue-Pump-Kanal

Der Bp-Kanal ist separat ausgeführt.

### Bp-Test

Der Bp-Stecker wurde im stromlosen Zustand abgezogen.

Ergebnis:

- keine Änderung der Leistungsaufnahme
- keine Änderung des Blinkverhaltens
- kein Start
- kein Bild

Damit ist ein Bp-spezifischer Kurzschluss als alleinige Fehlerursache eher unwahrscheinlich.

---

## 5. Externer Test der LED-Kanäle

Alle vier Farbkanäle wurden separat mit einem Labornetzteil getestet.

Ergebnis:

- Rot leuchtet
- Grün leuchtet
- Blau leuchtet
- Bp leuchtet

Damit sind die eigentlichen LED-Module grundsätzlich funktionsfähig.

### Schlussfolgerung

Ein vollständiger Defekt der LED-Lichtquelle ist sehr unwahrscheinlich.

Die weitere Fehlersuche konzentriert sich daher auf:

- LED-Treiber
- Enable-/PWM-Signale
- Spannungsversorgung
- DLP-Steuerung
- Mainboard / Bootprozess

---

## 6. LED-Testpunkte und Spannungen

Identifizierte Testpunkte:

### Blau

- TP251–TP255
- gegenüberliegende Gruppe TP256–TP260

Gemessen:

- eine Seite: **18,8 V**
- andere Seite: **14,9 V**

Differenz:

```text
18,8 V - 14,9 V = ca. 3,9 V
```

Das liegt in einer plausiblen Größenordnung für einen blauen LED-Kanal.

### Grün

Zuordnung:

- TP241–TP245
- Gegenkontaktgruppe vermutlich TP246–TP250

### Rot

Gefundene Testpunkte:

- TP574
- TP575
- TP188
- TP167
- TP166

### Bp

Zuordnung:

- TP262–TP266
- Gegenkontaktgruppe TP267–TP271

Gemessen:

- 0 V
- 0 V

Damit ist Bp im aktuellen Bootzustand nicht aktiv versorgt.

### Interpretation

Der Bp-Kanal wird offenbar nicht eingeschaltet. Das muss jedoch nicht bedeuten, dass der Bp-Treiber defekt ist. Möglich ist, dass Bp erst später in der Bootsequenz freigegeben wird.

Da der Projektor offensichtlich nicht vollständig bootet, kann 0 V am Bp-Ausgang eine Folge des frühen Bootabbruchs sein.

---

## 7. Temperatursensorik

Auf der Platine wurden Temperatur-Testpunkte gefunden.

Unter anderem:

```text
TEMP1 / H1
```

Gemessene Spannung:

```text
ca. 3,01 V
```

Zunächst bestand der Verdacht auf einen offenen Sensorpfad.

Anschließend wurden beide NTCs gemessen.

### NTC-Werte

Beide Sensoren:

```text
ca. 123 kΩ
```

Auf der Platine bei abgezogenem Sensor:

```text
ca. 11 kΩ gegen Masse
```

### Bewertung

Die beiden NTCs zeigen nahezu denselben Widerstand und wirken plausibel.

Die 3,01 V am Temperatursignal lassen sich mit einem typischen Spannungsteiler plausibel erklären.

Damit ist ein Fehler der beiden Temperatursensoren aktuell **nicht der Hauptverdacht**.

---

## 8. DLP-/DMD-Platine

Eine separate Platine wurde als DLP-/Displaycontroller identifiziert.

Aufdruck / PCB-Nummer:

```text
310-00844-003
```

Auf der Platine befinden sich typische DLP-Schnittstellen, unter anderem:

- `DMD`
- `POWER`
- `TO MAIN`

Die Platine ist damit der Controller zwischen Mainboard und DMD-Spiegelchip.

---

## 9. Extern versorgte blaue LED als DMD-Test

Der blaue LED-Kanal wurde extern mit dem Labornetzteil versorgt, während der Projektor gestartet wurde.

Beobachtung im Schnellblink-/Recovery-Zustand:

- kurzzeitig flackert Bildinhalt auf
- teilweise erscheinen Streifen
- anschließend dauerhaft blaues Licht
- sehr viele kleine Punkte sichtbar

### Bedeutung

Dieser Test zeigt:

- die Optik funktioniert grundsätzlich
- Licht erreicht den DMD
- der DMD wird zumindest kurzzeitig angesteuert
- die DLP-Elektronik lebt teilweise
- es existiert zumindest zeitweise eine Initialisierung des DMD

Das spricht gegen einen vollständig toten DMD oder eine vollständig tote DLP-Platine.

Die Streifen und Punkte wirken eher wie:

- Initialisierung
- Reset-Zustand
- fehlender gültiger Bilddatenstrom
- statischer DMD-Zustand

Ein defekter DMD ist weiterhin nicht vollständig ausgeschlossen, erklärt aber den gesamten Bootfehler nicht.

---

## 10. Mainboard-Debug-Schnittstelle

Auf der anderen Seite des Mainboards befindet sich ein dedizierter **DEBUG-Stecker**.

Mit dem Oszilloskop wurde ein TX-Signal gefunden.

Eigenschaften:

- High-Pegel ungefähr **3,3 V**
- Bitzeit ungefähr **8,4 µs**

Das entspricht sehr gut:

```text
115200 Baud
```

Verwendete UART-Konfiguration:

```text
115200 Baud
8 Datenbits
keine Parität
1 Stopbit
kein Flow Control
```

Damit konnte der Bootloader erfolgreich mitgelesen werden.

---

## 11. UART – normaler AC-Start

Wichtige Bootmeldungen:

```text
UART_115200

AC_ON
01-2L-SM-10-20201028
B44
MIU0_DQS-OK
BIST0-OK
optee teeloader entry

CusConfig
eMMC_RPMB_Check_Program_Key
Auth reeloader...
Decrypt reeloader...
Check reeloader magic ID...
Version check on reeloader...
Auth CKB...
Decrypt CKB...
Check CKB magic ID...

NOTICE: BL3-1: v1.1(debug):8ad6fdab
NOTICE: BL3-1: Built : 14:48:41, Jun 28 2022

[Ramlog] ramlog_init init success

U-Boot 2011.06 (Oct 21 2022 - 21:17:20)

eMMC HS400 5.1 200MHz
eMMC 29.12 GB
eMMC used life: 0~10%
```

Danach:

```text
CRC Check OPEN: 1

[GPIO_WAKE_SETTING]

WOW_GPIO_NUM        = 0
WOBT_GPIO_NUM       = 13
WOEWBS_GPIO_NUM     = 255

[PM_GPIO_WAKE_SETTING]

WOW_PM_GPIO_NUM     = 17
WOBT_PM_GPIO_NUM    = 7
WOEWBS_PM_GPIO_NUM  = 0

BTW = FF

0x8709

Power Down
```

### Interpretation

Der normale AC-Start zeigt:

- RAM-Initialisierung erfolgreich
- MIU / DDR-Test erfolgreich
- Secure-Boot-Komponenten werden geladen
- OP-TEE/Trusted Firmware startet
- U-Boot startet
- eMMC wird korrekt erkannt
- eMMC läuft mit HS400
- 29,12 GB verfügbar
- eMMC-Verschleiß wird mit 0–10 % angegeben

Damit funktionieren wesentliche Teile des Mainboards:

- CPU / SoC
- RAM
- eMMC
- Boot-ROM
- Secure Boot
- U-Boot

Der Projektor fährt nach dem Anlegen der Versorgung anschließend gezielt in einen **Power-Down-/Standby-Zustand**.

---

## 12. UART – Verhalten nach Power-Tastendruck

Nach `Power Down` und anschließendem Einschaltversuch startet die Bootsequenz erneut mit:

```text
UART_115200
AC_ON
...
```

Es erscheint erneut:

```text
MIU0_DQS-OK
BIST0-OK
...
U-Boot
...
eMMC HS400
...
CID
```

Bei einem beobachteten Startversuch kam anschließend ein erneuter Start der Bootsequenz.

### Auffällig

Es erscheint wieder:

```text
AC_ON
```

statt eines klar erkennbaren Wake-from-Standby-Pfads.

Das kann bedeuten:

- vollständiger Hardware-Reset
- Power-Sequencing-Problem
- Watchdog-Reset
- Brownout
- fehlerhafte PM-/Standby-Sequenz

---

## 13. UART – Recovery-/Force-Brush-Test

Testablauf:

1. Stromversorgung anschließen
2. Gerät bootet bis `Power Down`
3. USB-Stick steckt
4. Power-Taste ungefähr 7 Sekunden gedrückt halten
5. Gerät wechselt in Schnellblinkmodus

UART danach:

```text
UART_115200
AC_ON
...
MIU0_DQS-OK
BIST0-OK
...
U-Boot 2011.06
...
eMMC HS400 5.1 200MHz
eMMC 29.12 GB
eMMC used life: 0~10%

CID
0xXXXXXXXX
0xXXXXXXXX
0xXXXXXXXX
0xXXXXXXXX
```

Danach fehlt die normale Sequenz:

```text
CRC Check OPEN
GPIO_WAKE_SETTING
PM_GPIO_WAKE_SETTING
Power Down
```

### Interpretation

Der lange Power-Tastendruck erzeugt offensichtlich einen **anderen Bootpfad**.

Damit wird der Recovery-/Force-Brush-Modus wahrscheinlich erkannt.

Der Bootprozess bleibt jedoch sehr früh hängen, offenbar ungefähr nach der eMMC-Initialisierung und bevor der normale Standby-Pfad weiterläuft.

Das ist aktuell einer der wichtigsten Befunde.

---

## 14. Aktueller technischer Stand

Bereits relativ sicher ausgeschlossen:

- vollständig defekte LED-Lichtquelle
- vollständig toter DMD
- vollständig tote DLP-Platine
- vollständig tote eMMC
- fehlende RAM-Initialisierung
- beide Temperatur-NTCs als offensichtliche Fehlerursache

Nachgewiesen funktionsfähig:

- R-LED
- G-LED
- B-LED
- Bp-LED
- DMD zeigt bei externer Beleuchtung zumindest Aktivität
- Main-SoC startet
- DDR initialisiert
- U-Boot läuft
- eMMC wird erkannt
- UART funktioniert

Noch offen:

- warum der reguläre Power-On nicht vollständig durchläuft
- warum der Force-Brush-Modus nach eMMC-Initialisierung hängenbleibt
- ob USB im Recovery-Boot wirklich initialisiert wird
- ob eine Spannungsrail kurzzeitig einbricht
- ob der SoC einen Watchdog-/Brownout-Reset bekommt
- ob PM-/Standby-Controller fehlerhaft arbeitet
- ob ein Boot-Flag / GPIO / Power-Enable fehlt
- ob die USB-Recovery-Datei überhaupt gesehen wird

---

## 15. Aktuell wahrscheinlichste Fehlergruppen

### 1. Power-Sequencing / Spannungsversorgung

Sehr plausibel.

Zu prüfen:

- 19-V-Eingang
- 5-V-Rail
- 3,3-V-Rail
- 1,8-V-Rail
- SoC-Core-Rail
- DDR-Rail
- DLP-Versorgung
- USB-5-V-Rail

Wichtig ist die Messung direkt im Moment des zweiten Bootstarts bzw. Reset-Ereignisses.

### 2. Standby-/PM-Controller

Die UART-Ausgabe enthält:

```text
GPIO_WAKE_SETTING
PM_GPIO_WAKE_SETTING
Power Down
```

Das deutet auf eine separate Power-Management-/Standby-Logik hin.

Mögliche Probleme:

- Wake-Signal wird falsch interpretiert
- Enable-Signal für Hauptversorgung fehlt
- Power-Good fehlt
- PM-Controller löst Reset aus
- Watchdog greift ein

### 3. USB-Recovery-Pfad

Da der lange Tastendruck einen abweichenden Bootpfad auslöst, ist ein Recovery-Start wahrscheinlich.

Zu prüfen:

- USB-Port hat 5 V
- USB-Stick wird elektrisch erkannt
- USB-Host startet
- FAT32 wird erkannt
- Partitionstabelle wird erkannt
- Firmware-Datei wird gefunden
- Firmware-Datei wird akzeptiert

### 4. U-Boot / Bootparameter

Da TX erfolgreich gefunden wurde, sollte als nächstes auch RX identifiziert und verwendet werden.

Ziel:

- U-Boot-Autoboot stoppen
- Bootumgebung auslesen
- USB manuell initialisieren
- Dateisystem auf dem Stick testen
- Recovery-Flags prüfen

Nur lesende Diagnosebefehle verwenden.

---

## 16. Empfohlene nächste Schritte

### A. UART-RX finden

Am Debug-Stecker:

- GND identifizieren
- TX ist bereits gefunden
- RX bestimmen
- VCC nicht verbinden
- nur 3,3-V-TTL verwenden

Danach versuchen, U-Boot zu unterbrechen.

### B. U-Boot-Kommandos

Sobald ein Prompt erreichbar ist:

```text
help
printenv
```

Danach USB diagnostizieren, sofern Befehle vorhanden:

```text
usb start
usb tree
usb storage
usb part
fatls usb 0:1 /
```

Alternativ:

```text
fatls usb 0 /
```

Keine schreibenden Befehle verwenden.

Insbesondere vermeiden:

```text
saveenv
erase
mmc write
nand write
resetenv
```

### C. USB-Stick prüfen

Empfehlung:

- kleiner USB-2.0-Stick
- 8–32 GB
- MBR
- genau eine FAT32-Partition
- Firmware-Datei direkt im Root
- keine zusätzlichen Partitionen

Optimal wäre ein USB-Stick mit Aktivitäts-LED.

So kann geprüft werden, ob beim Force-Brush-Boot überhaupt Lesezugriffe stattfinden.

### D. Oszilloskop an Spannungsrails

Trigger auf Reset-/Bootmoment.

Zu beobachten:

```text
19 V
5 V
3,3 V
1,8 V
Core-Rail
DDR-Rail
```

Besonders interessant ist der Moment, an dem im UART erneut erscheint:

```text
UART_115200
AC_ON
```

Falls unmittelbar davor eine Rail einbricht, ist ein Power-Sequencing-/Brownout-Problem sehr wahrscheinlich.

---

## 17. Arbeitshypothese

Der Projektor ist **nicht grundsätzlich tot**.

Die frühe Hardware funktioniert weitgehend:

```text
Boot-ROM
→ DDR init
→ Secure Boot
→ OP-TEE
→ U-Boot
→ eMMC
```

Der Fehler liegt wahrscheinlich **nach der frühen Bootinitialisierung**, möglicherweise im Bereich:

```text
Power Management
USB Recovery
Wake/Standby
Power Sequencing
Boot Flags
spätere Systeminitialisierung
```

Der Force-Brush-Modus wird offenbar erkannt, erreicht aber nicht den eigentlichen Firmware-Flash.

---

## 18. Besonders wichtige Messwerte

| Messung | Ergebnis |
|---|---:|
| Standby-Leistungsaufnahme | ca. 5 W |
| Schnellblink-/Recovery-Leistung | ca. 12 W |
| RGB-Versorgung | ca. 18,8 V |
| Blau zweite Seite | ca. 14,9 V |
| Blau Differenz | ca. 3,9 V |
| Bp | 0 V / 0 V |
| TEMP1/H1 | ca. 3,01 V |
| NTC 1 | ca. 123 kΩ |
| NTC 2 | ca. 123 kΩ |
| UART-Pegel | 3,3 V |
| UART-Baudrate | 115200 |
| eMMC | 29,12 GB |
| eMMC-Modus | HS400 5.1 / 200 MHz |
| eMMC used life | 0–10 % |

---

## 19. Wichtigste Erkenntnis bisher

Die wichtigste Erkenntnis des gesamten Diagnoseverlaufs ist:

> Der Main-SoC startet, RAM und eMMC funktionieren, U-Boot läuft, und der Force-Brush-Tastendruck erzeugt einen abweichenden Bootpfad. Der Fehler liegt daher sehr wahrscheinlich nicht in der Lichtquelle selbst, sondern in der späteren Boot-, Recovery-, Wake- oder Power-Sequencing-Logik.

---

## 20. Nächster Meilenstein

Der nächste entscheidende Schritt ist:

> **U-Boot über UART-RX interaktiv öffnen und USB + Bootparameter direkt diagnostizieren.**

Damit sollte sich klären lassen, ob:

- USB-Hardware funktioniert
- der Stick erkannt wird
- FAT32 lesbar ist
- die Firmwaredatei gefunden wird
- Recovery-Flags korrekt gesetzt werden
- der Fehler vor oder nach dem eigentlichen Firmware-Loader liegt
