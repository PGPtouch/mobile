# PGPtouch (mobile)

Datenschutzerklärung - Stand: 12. November 2026

Diese Erklärung beschreibt, welche personenbezogenen Daten die Android-App „PGPtouch“ (Paket `com.jhubi1.apps.pgptouch`, Quellcode unter <https://github.com/PGPtouch/mobile>) verarbeitet, zu welchem Zweck und welche Rechte du nach der Datenschutz-Grundverordnung (DSGVO) hast.

### Geltungsbereich

Diese Erklärung gilt nur für offizielle Eigenveröffentlichungen (First-Party-Builds) der App, die vom Verantwortlichen veröffentlicht und korrekt mit dessen Signaturschlüssel signiert wurden. Für veränderte, neu signierte oder von Dritten bereitgestellte Builds gilt diese Erklärung nicht. Solche Builds können sich anders verhalten; der Verantwortliche hat darauf keinen Einfluss und trägt dafür keine Verantwortung.

### Kurz gesagt

Deine Schlüssel, Kontakte und Einstellungen bleiben auf deinem Gerät. Die App hat keine Benutzerkonten und zeigt keine Werbung. Anonyme Nutzungsstatistiken werden nur gesendet, wenn du einwilligst. Alle Server, mit denen die App selbstständig kommuniziert (Feature-Flags und Statistiken), werden vom Verantwortlichen betrieben und nicht von einem Dritten.

## 1. Verantwortlicher

JHubi1 (Entwickler von PGPtouch)
E-Mail: [me@jhubi1.com](mailto:me@jhubi1.com)

Ein Datenschutzbeauftragter ist nicht benannt; bitte nutze für alle Datenschutzfragen die oben genannte Adresse.

## 2. Überblick

| Verarbeitung                                    | Daten                                                       | Verlässt das Gerät?                        | Rechtsgrundlage                                         |
| ----------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------ | ------------------------------------------------------- |
| Lokale Speicherung von Schlüsseln und Kontakten | Schlüssel, User-IDs, Passphrasen, Einstellungen             | Nein                                       | Keine Verarbeitung durch den Verantwortlichen (siehe 3) |
| Schlüsselaustausch per NFC und Bluetooth        | Öffentliche Schlüssel, User-IDs, kryptografische Signaturen | Nur direkt an das andere Gerät             | Deine Anweisung, Art. 6 Abs. 1 lit. b DSGVO             |
| Schlüsselsuche und -aktualisierung              | E-Mail-Adresse, Schlüssel-Fingerabdruck, IP-Adresse         | Ja, an Schlüsselserver und E-Mail-Anbieter | Deine Anweisung, Art. 6 Abs. 1 lit. b DSGVO             |
| Anonyme Nutzungsstatistiken                     | Ereignisdaten, Gerätemodell, Betriebssystemversion, Sprache | Ja, nur mit deiner Einwilligung            | Einwilligung, Art. 6 Abs. 1 lit. a DSGVO                |
| Feature-Flags                                   | Zufällige Flag-Nummer, Beta-Einstellung, IP-Adresse         | Ja                                         | Berechtigtes Interesse, Art. 6 Abs. 1 lit. f DSGVO      |

## 3. Daten, die nur auf deinem Gerät gespeichert werden

Die folgenden Daten werden lokal erzeugt und gespeichert. Der Verantwortliche hat darauf keinen Zugriff und erhält keine Kopie; er verarbeitet sie daher nicht. Sie werden gelöscht, wenn du die Daten in der App entfernst oder die App deinstallierst.

### Identitäten (deine eigenen Schlüssel)

Öffentliche und private OpenPGP-Schlüssel, deren Fingerabdrücke, Erstellungs- und Ablaufdaten, Widerrufsstatus sowie Namen, Kommentare und E-Mail-Adressen in den User-IDs. Sie liegen in einer verschlüsselten Datenbank (SQLite3 Multiple Ciphers, SQLCipher-kompatibel). Der Datenbankschlüssel ist ein Zufallswert, der über den Android Keystore im Secure Storage liegt und durch starke biometrische Authentifizierung (Fingerabdruck oder Gesicht, je nach Gerät) geschützt ist. Die App fordert diese Authentifizierung an, um deine Schlüssel zu entsperren. Ist der private Schlüssel selbst durch eine Passphrase geschützt, bleibt er durch diese geschützt.

### Gemerkte Passphrasen

Wenn du dir die Passphrase eines Schlüssels merken lässt, wird sie im selben biometrisch geschützten Secure Storage abgelegt. Du kannst sie jederzeit wieder löschen.

### Kontakte

Öffentliche Schlüssel anderer Personen mit User-IDs (Namen, Kommentare, E-Mail-Adressen), Fingerabdrücken und Daten. Diese Datenbank wird ohne gesonderte App-Verschlüsselung gespeichert, da sie nur öffentliche Informationen enthält. Es gilt die dateibasierte Verschlüsselung des Android-Gerätespeichers.

### Einstellungen

Die für Austausche gewählte Identität (Datenbank-ID, Anzeigename und Ablaufdatum), deine Schlüsselserver-Auswahl, die Beta-Einstellung, deine Entscheidung zu Nutzungsstatistiken und eine zufällige Flag-Nummer (siehe 7). Sie liegen in den App-Einstellungen (Preferences).

### Exporte und Backups

Wenn du Schlüssel exportierst oder ein verschlüsseltes Backup erstellst, schreibt die App eine Datei an den Ort, den du im System-Dateidialog wählst. Das Backup wird mit einem dir angezeigten Backup-Code verschlüsselt. Exportierte unverschlüsselte private Schlüssel schützt die App nicht; bewahre sie sicher auf. Die App lädt Exporte nirgendwohin hoch.

### Zwischenablage und Dateien

Die App liest die Zwischenablage oder eine Datei nur, wenn du beim Import von Schlüsseln „Aus Zwischenablage einfügen“ oder „Aus Datei“ wählst. Kopieren (z. B. einer E-Mail-Adresse oder eines Fingerabdrucks) schreibt nur auf deine Aktion hin in die Zwischenablage.

Da diese Daten bei dir liegen und nicht an den Verantwortlichen übermittelt werden, kann er sie nicht für dich einsehen, berichtigen oder löschen. Das kannst du selbst in der App oder durch Löschen der App-Daten tun.

## 4. Berechtigungen und Gerätefunktionen

| Berechtigung / Funktion                                      | Zweck                                                                                                                                                                                                                                  |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Bluetooth-Scan, -Verbindung und -Advertising (ab Android 12) | Finden und Kommunizieren mit dem anderen Gerät beim Austausch. Die Scan-Berechtigung ist als „niemals für Standort“ deklariert.                                                                                                        |
| Standort (nur Android 11 und älter)                          | Von Android auf diesen Versionen für Bluetooth-Low-Energy-Scans vorausgesetzt. Die App liest und nutzt deinen Standort nicht.                                                                                                          |
| NFC                                                          | Erkennen des anderen Geräts und Starten eines Austauschs. Die App liest außerdem die NFC-Antennenposition und zugehörige NFC-Systemeinstellungen, um dir zu zeigen, wo du die Geräte aneinanderhalten musst. Das bleibt auf dem Gerät. |
| Biometrie                                                    | Entsperren des Schlüsselspeichers (siehe 3). Die App erhält keine biometrischen Daten; die Prüfung führt das Android-System durch.                                                                                                     |
| Internet                                                     | Schlüsselsuche und -aktualisierung (siehe 6), Feature-Flags (siehe 7) und, falls du eingewilligt hast, Statistiken (siehe 8).                                                                                                          |
| Vibration                                                    | Haptisches Feedback beim Austausch.                                                                                                                                                                                                    |

Du kannst die Laufzeitberechtigungen in den Android-Systemeinstellungen widerrufen. Der Schlüsselaustausch funktioniert dann nicht mehr.

## 5. Schlüsselaustausch zwischen zwei Geräten

Beim Austausch kommunizieren dein Gerät und das andere Gerät direkt über NFC und Bluetooth Low Energy. Dein Gerät sendet deinen gewählten öffentlichen Schlüssel samt User-IDs und signiert Daten mit deinem privaten Schlüssel; es empfängt dasselbe vom anderen Gerät. Es ist kein Server beteiligt, und der Verantwortliche sieht den Austausch nicht. Nach einem erfolgreichen Austausch zeigt die App dir die User-IDs und den Fingerabdruck des empfangenen Schlüssels an; sie speichert ihn nicht von selbst als Kontakt.

Die andere Person erhält die für den Austausch gewählten öffentlichen Daten (Name, E-Mail-Adresse und weitere User-ID-Bestandteile deines öffentlichen Schlüssels, Fingerabdruck). Wähle die geteilte Identität daher bewusst. Bluetooth-Geräte in der Nähe können erkennen, dass während des Austauschs ein Bluetooth-Signal gesendet wird.

## 6. Schlüsselsuche und -aktualisierung (Schlüsselserver)

Wenn du nach dem Schlüssel eines Kontakts suchst oder einen vorhandenen Schlüssel aktualisierst, kontaktiert die App auf deine Anforderung hin Schlüsselquellen, ausschließlich per HTTPS:

- Web Key Directory (WKD) der Domain der E-Mail-Adresse. Der Server dieser Domain erhält die E-Mail-Adresse.
- HKP-Schlüsselserver, die du in den Einstellungen auswählst. Sie erhalten die gesuchte E-Mail-Adresse. Wenn du einen Schlüssel aktualisierst, erhalten sie möglicherweise zusätzlich den Fingerabdruck dieses Schlüssels. Standardmäßig sind `keys.openpgp.org`, `keys.mailvelope.com` und `keyserver.ubuntu.com` aktiv. Zusätzlich wählbar sind `api.protonmail.ch`, `pgp.mit.edu`, `pgp.surfnet.nl`, `pgp.circl.lu`, `pgpkeys.eu` und `keyserver.dobrev.eu`.

Diese Server erhalten außerdem deine IP-Adresse und technische Verbindungsdaten. Sie werden von Dritten betrieben, die eigenständig Verantwortliche sind; der Verantwortliche dieser App erhält weder die Anfragen noch die Antworten. Bitte beachte die Datenschutzerklärungen der jeweiligen Betreiber. Einige Betreiber können ihren Sitz außerhalb des Europäischen Wirtschaftsraums haben; die Übermittlung erfolgt nur zur Erfüllung deiner Anforderung (Art. 49 Abs. 1 lit. b DSGVO). Auf diesem Weg gefundene öffentliche Schlüssel werden dir angezeigt und nur gespeichert, wenn du sie hinzufügst.

## 7. Feature-Flags

Beim Start fragt die App einen Feature-Flag-Dienst, welche Funktionen für deine Installation aktiv sind (z. B. Beta-Funktionen oder schrittweise Einführungen). Der Dienst wird vom Verantwortlichen betrieben und nicht von einem Dritten. Dazu sendet die App:

- eine zufällig erzeugte, 32-stellige Flag-Nummer, die bei der ersten Nutzung erstellt wird (nicht von Gerät, Konto oder Schlüsseln abgeleitet),
- deine Einstellung „Beta-Funktionen“,
- deine IP-Adresse und technische Verbindungsdaten (bei jeder Internetanfrage unvermeidbar).

Die Flag-Nummer wird in den App-Einstellungen gespeichert und bleibt bestehen, bis du die App-Daten löschst oder die App deinstallierst. Sie ist eine pseudonyme Kennung und damit ein personenbezogenes Datum. Diese Anfrage erfolgt unabhängig von deiner Entscheidung zu Statistiken in Abschnitt 8. Du kannst deine Flag-Nummer unter Einstellungen → Datenschutz → Feature-Rollout einsehen.

### Zweck und Rechtsgrundlage

Kontrollierte Einführung von Funktionen und Fehlereingrenzung. Rechtsgrundlage ist das berechtigte Interesse des Verantwortlichen, Art. 6 Abs. 1 lit. f DSGVO. Du kannst jederzeit widersprechen (siehe 10).

### Hosting und Speicherdauer

Der Server läuft bei der Hetzner Online GmbH in Nürnberg, Deutschland. Hetzner stellt die Hardware als Auftragsverarbeiter im Auftrag des Verantwortlichen bereit; die Daten werden nicht außerhalb der Europäischen Union übermittelt. Daten deiner Anfragen (z. B. Flag-Nummer, angefragte Funktion, Ergebnis und Verbindungsdaten) können in Protokolldateien des Servers enthalten sein. Sie werden gemeinsam mit diesen Protokolldateien gelöscht, wenn diese rotiert oder gelöscht werden.

## 8. Anonyme Nutzungsstatistiken

In Release-Versionen der App für Endnutzer werden keine Nutzungsstatistiken gesendet, solange du nicht einwilligst. Du kannst deine Einwilligung erteilen oder ablehnen, wenn die App danach fragt, und jederzeit unter Einstellungen → Datenschutz („Tracking aktivieren“). Ablehnen ist genauso einfach wie Einwilligen, und die App funktioniert in beiden Fällen gleich. Solange du nicht eingewilligt hast, werden keine Ereignisse gesendet. Mit demselben Schalter kannst du deine Einwilligung jederzeit widerrufen; danach werden keine weiteren Ereignisse gesendet. Deine Entscheidung wird nur auf deinem Gerät gespeichert.

### Zweck und Rechtsgrundlage

Verstehen, wie zuverlässig und schnell die App arbeitet (z. B. wie oft Austausche gelingen und wo sie scheitern), um sie zu verbessern. Rechtsgrundlage ist deine Einwilligung, Art. 6 Abs. 1 lit. a DSGVO und § 25 Abs. 1 TDDDG. Der Widerruf berührt die Rechtmäßigkeit der bis dahin erfolgten Verarbeitung nicht.

### Hosting und Speicherdauer

Ereignisse werden per HTTPS an einen Analyse-Server gesendet. Er wird vom Verantwortlichen betrieben und nicht von einem Dritten. Der Server läuft bei der Hetzner Online GmbH in Nürnberg, Deutschland; Hetzner stellt die Hardware als Auftragsverarbeiter im Auftrag des Verantwortlichen bereit, und die Daten werden nicht außerhalb der Europäischen Union übermittelt. Ereignisse werden 5 Jahre lang gespeichert und danach automatisch gelöscht.

### Mit jedem Ereignis gesendete Daten

Ereigniszeit, App-Version, Name und Version des Betriebssystems, Systemsprache und -region, ob es sich um eine Debug-Version handelt, und eine zufällige Sitzungs-ID, die nach einer Stunde Inaktivität erneuert wird. Sie ist weder mit der Flag-Nummer aus Abschnitt 7 noch mit Gerätekennungen oder deinen Schlüsseln verknüpft.

Beim Empfang eines Ereignisses leitet der Server zusätzlich deinen ungefähren Standort (Land, Region und Stadt) aus der IP-Adresse ab und erzeugt aus IP-Adresse, Browserkennung und einem alle 24 Stunden ersetzten Salt einen pseudonymen Tages-Nutzer-Hash. Die IP-Adresse selbst wird nicht gespeichert. Sobald das Salt gelöscht ist, lässt sich der Hash weder umkehren noch mit deinen Ereignissen an anderen Tagen verknüpfen.

### Mit bestimmten Ereignissen gesendete Daten

Es werden nur grobe Ergebnisse, Kategorien, Zähler und Dauern gesendet:

| Ereignis                             | Inhalt                                                                                                                                                                                                                                         |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `initialized`                        | App-Start                                                                                                                                                                                                                                      |
| `exchangeAttempt`                    | Ergebnis und Grund, Rolle im Austausch (Sender oder Empfänger), erreichte Phase, Dauer der Schritte, Anzahl der Wiederholungen, wie oft die App in den Hintergrund ging, ob die NFC-Antennenposition bekannt ist, Gerätehersteller und -modell |
| `keyStoreUnlock`                     | Ergebnis, Auslöser, Dauer, technischer Fehlercode bei Fehlschlag                                                                                                                                                                               |
| `passphrasePrompt`                   | Ergebnis, Anzahl der Versuche, ob eine gespeicherte Passphrase fehlschlug oder gemerkt wurde, Dauern                                                                                                                                           |
| `identityCreated`                    | Algorithmus, RSA-Schlüssellänge, Anzahl der User-IDs, ob ein Ablaufdatum gesetzt ist, ob er verschlüsseln kann, Erzeugungsdauer                                                                                                                |
| `addIdentityFlow` / `addContactFlow` | Ergebnis, Anzahl hinzugefügter Schlüssel und Duplikate, Anzahl gespeicherter Passphrasen, Dauer                                                                                                                                                |
| `importSource`                       | Importquelle (Zwischenablage, Datei, …) und Ergebnis. Es werden weder Schlüsseldaten noch Dateiinhalte übertragen.                                                                                                                             |
| `contactSearch`                      | Ergebnis, Anzahl der Treffer, Anzahl gültiger Schlüssel, Dauer, Anzahl genutzter Server                                                                                                                                                        |
| `keyExport`                          | Ob Identität oder Kontakt, Format (unverschlüsselt oder Backup), Ergebnis                                                                                                                                                                      |
| `keyUpdate` / `keyDeleted`           | Ob Identität oder Kontakt, Ergebnis                                                                                                                                                                                                            |

### Nie gesendete Daten

Schlüsselmaterial, Fingerabdrücke, User-IDs, Namen, E-Mail-Adressen, Suchbegriffe, Dateinamen, Passphrasen, Kontaktlisten oder rohe Fehlermeldungen.

### Zuordenbarkeit

Da die Ereignisse keine dauerhafte Kennung enthalten und das tägliche Salt nicht aufbewahrt wird, lassen sie sich in der Regel nicht dir zuordnen. Anträge auf Auskunft, Berichtigung oder Löschung solcher Ereignisse können daher meist nicht erfüllt werden (Art. 11 DSGVO).

## 9. Weitere Verbindungen und Dritte

### Seite mit der Datenschutzerklärung

Wenn du in den Einstellungen „Datenschutzerklärung“ antippst, öffnet der In-App-Browser die Seite unter `privacy.jhubi1.com` samt deiner App-Sprache. Der Webserver erhält deine IP-Adresse und die üblichen Browserdaten.

### Anspruchsseite

Wenn du unter Einstellungen → Datenschutz → Feature-Rollout „Anspruch öffnen“ antippst, öffnet der In-App-Browser das Anspruchsformular unter `privacy.jhubi1.com` samt deiner Flag-Nummer, damit deine Daten gefunden werden können. Der Webserver erhält deine IP-Adresse, die üblichen Browserdaten und die Flag-Nummer.

Das Formular wird von Tally (Tally BV, Belgien) bereitgestellt, das die Formulardaten als Auftragsverarbeiter im Auftrag des Verantwortlichen auf Grundlage eines Auftragsverarbeitungsvertrags verarbeitet. Die Daten werden in Europa gespeichert; Tally kann weitere Dienstleister einsetzen, siehe die Datenschutzhinweise von Tally. Tally erhält deine IP-Adresse, die üblichen Browserdaten und alles, was du im Formular eingibst (z. B. deine E-Mail-Adresse, deine Flag-Nummer und den Inhalt deiner Anfrage). Diese Daten werden zur Bearbeitung deiner Anfrage verarbeitet (Art. 6 Abs. 1 lit. c DSGVO).

Die Daten werden bis zur Erledigung deiner Anfrage gespeichert und danach gelöscht. Stellt der Verantwortliche dir Rückfragen und antwortest du nicht, gilt die Anfrage nach zwei Wochen als ohne Ergebnis und ohne ergriffene Maßnahmen erledigt. Über das Formular kann pro E-Mail-Adresse jeweils nur eine Anfrage gleichzeitig offen sein. Wenn du weitere Anfragen stellen möchtest, schreibe bitte stattdessen eine E-Mail.

### E-Mail-Links

Das Antippen einer E-Mail-Adresse eines Schlüssels öffnet deine E-Mail-App. Was dort geschieht, richtet sich nach dieser App.

### Open-Source-Lizenzen und Projektseite

Der „Über“-Bildschirm listet Lizenzen aus der App selbst auf. Der Link zu GitHub öffnet sich in deinem Browser, wo die Datenschutzerklärung von GitHub gilt.

### Keine Werbung und keine weitere Erhebung

Die App enthält keine Werbung, keine Social-Media-Plugins und keine Werbe- oder Marketing-Software. Sie erhebt weder deinen Standort noch Kontakte aus deinem Adressbuch, Fotos, Kamera- oder Mikrofondaten.

## 10. Deine Rechte

Nach der DSGVO hast du das Recht auf:

- Auskunft (Art. 15), Berichtigung (Art. 16), Löschung (Art. 17), Einschränkung der Verarbeitung (Art. 18) und Datenübertragbarkeit (Art. 20) hinsichtlich deiner personenbezogenen Daten,
- Widerspruch gegen eine auf berechtigtem Interesse beruhende Verarbeitung jederzeit aus Gründen, die sich aus deiner besonderen Situation ergeben (Art. 21),
- Widerruf deiner Einwilligung jederzeit mit Wirkung für die Zukunft (Art. 7 Abs. 3), hier durch Ausschalten von „Tracking aktivieren“ unter Einstellungen → Datenschutz,
- Beschwerde bei einer Aufsichtsbehörde (Art. 77), insbesondere in dem EU-Mitgliedstaat deines gewöhnlichen Aufenthaltsorts, deines Arbeitsplatzes oder des Orts des mutmaßlichen Verstoßes.

Um Dateneinsicht oder -löschung anzufordern, tippe unter Einstellungen → Datenschutz → Feature-Rollout auf „Anspruch öffnen“, nutze das Anspruchsformular unter <https://privacy.jhubi1.com/claim> oder schreibe an [me@jhubi1.com](mailto:me@jhubi1.com). Der Verantwortliche kann nur Daten finden, die sich dir zuordnen lassen, z. B. über deine Flag-Nummer (siehe 7). Die meisten Daten liegen nur auf deinem Gerät und können von dir direkt gelöscht werden (siehe 3). Über das Formular kann pro E-Mail-Adresse nur eine Anfrage gleichzeitig offen sein; für weitere Anfragen schreibe bitte eine E-Mail an die oben genannte Adresse. Um die Flag-Nummer zurückzusetzen, lösche die App-Daten oder installiere die App neu.

## 11. Bereitstellung von Daten, automatisierte Entscheidungen

Du bist nicht verpflichtet, personenbezogene Daten bereitzustellen. Die App funktioniert auch ohne Einwilligung in Statistiken. Eine automatisierte Entscheidungsfindung oder ein Profiling im Sinne von Art. 22 DSGVO findet nicht statt.

## 12. Sicherheit

Die Schlüsseldatenbank ist verschlüsselt, ihr Schlüssel wird vom Android Keystore mit biometrischer Authentifizierung geschützt, alle Netzwerkanfragen nutzen HTTPS, und die App fordert nicht mehr Berechtigungen an als nötig. Vom Rooten oder anderweitigen Verändern deines Geräts wird abgeraten, da es den Schutz des Android Keystore und die Isolation der App schwächt. Kein System ist absolut sicher; halte dein Gerät und Betriebssystem aktuell und schütze private Schlüssel mit einer starken Passphrase.

## 13. Änderungen

Diese Erklärung kann angepasst werden, wenn sich die App oder die Rechtslage ändert. Die aktuelle Fassung ist unter <https://privacy.jhubi1.com/?app=4c2c4490f6164d4db7f399d1c87c18f9&hl=de> abrufbar. Das Datum oben zeigt, wann sie zuletzt geändert wurde.
