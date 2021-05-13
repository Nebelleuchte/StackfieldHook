# StackfieldHook - Chatnachrichten und Aufgaben erstellen aus Ruby Skripten

Eine einfache Funktion zum erstellen von Chatnachrichten oder Aufgaben in Stackfield-Räumen
über die von Stackfield bereitgestellte Webhook-Api.
Chatnachrichten sind Type C, Tasks sind Type T

## Aufruf möglich über Konsole:

ruby StackfieldHook.rb --help

### Parameter

**Pflicht:**
type: "C" für Chatnachricht / "T" für Task (Aufgabe)
title: Titel der Aufgabe bzw. Text der Chatnachricht.

**optional:**
content: Beschreibung der Aufgabe
faelligkeitsdatum: Datum, zu dem die Aufgabe fällig ist im Format YYYY-MM-DD
zustaendig: Mailadresse des für die Aufgabe zuständigen Mitarbeiters (muss im Raum sein)
enddatum: Wenn es ein Start und ein Enddatum gibt

Zur Nutzung müssen die URL für die jeweiligen Bereiche Aufgaben (Task) bzw. Nachricht (Chat)
im jeweiligen Raum erzeugt und im Skript hinterlegt werden.

## Als Klasse in Ruby-Skripten

Die Klasse kann auch in anderen Ruby Skripten verwendet werden:

test = StackfieldHook.new('T','Aufgabe für Spaßvögel','Das ist mein Test.','2021-06-14',"m.findeisen@hagen.creditreform.de")
test.post

## Konfiguration

Im Skriptverzeichnis wird ein File 'config.yaml' benötigt mit folgendem Aufbau:

STACKFIELD_URL:
CHAT: "https://www.stackfield.com/apiwh/..."
TASK: "https://www.stackfield.com/apiwh/..."

LOG:
LOGFILE: "logfile.log"
DELETE: "weekly"
LEVEL: "debug" #debug / info / warning / error -> info empfohlen

Hier sind die im jeweiligen Stackfield-Raum erzeugten URL für Chatnachrichten bzw. Tasks zu hinterlegen.
Auch lässt sich hier das Log einstellen.

---

Maic Findeisen Creditreform Hagen Berkey & Riegel KG
m.findeisen@hagen.creditreform.de
