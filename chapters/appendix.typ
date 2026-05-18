#import "global.typ": *

#heading("Hilfsmittelverzeichnis")

Dieses Verzeichnis listet die zur Erstellung der vorliegenden Arbeit eingesetzten Hilfsmittel auf. Bestandteile der untersuchten Anwendung selbst (Stack des Routing-Kerns und des Visualisierungs-Frontends) werden im Implementierungskapitel behandelt und sind hier nicht aufgeführt; aufgenommen sind ausschließlich Werkzeuge, die unmittelbar der Erstellung der Arbeit, der Erzeugung der Auswertungsabbildungen oder der Reproduzierbarkeit der durchgeführten Messungen dienen.

== Schreibumgebung

- *Typst* als Satzsystem
- *biblio.bib* (BibTeX-Format) als Literaturquelle, eingebunden über die Typst-eigene Bibliographieverwaltung im IEEE-Stil
- Typst-Pakete: *codly* und *codly-languages* für die Syntaxhervorhebung der Code-Listings, *fletcher* für die Strukturdiagramme

== Grafik- und Diagrammtools

- *fletcher* (Typst-Paket) für die statischen Komponenten- und Phasendiagramme in den Konzept- und Implementierungskapiteln
- *Matplotlib* (Python) zur Erzeugung der Benchmark- und Charakterisierungsplots im Auswertungskapitel
- Die in den Konzept- und Auswertungskapiteln gezeigten Visualisierungen der Build-Phase (Seed-Verteilung, Voronoi-Partitionierung, abstrakter Graph) sind Bestandteil der entwickelten Anwendung selbst; die in der Arbeit gezeigten Abbildungen wurden direkt aus dieser Live-Visualisierung als Screenshots gewonnen.

== Entwicklungsumgebungen

- *JetBrains WebStorm* für die Frontend-Entwicklung (Vue, Nuxt, TypeScript)
- *JetBrains PyCharm* für die Backend-Entwicklung (Python, FastAPI)

== Versionskontrolle

*Git* als Versionskontrollsystem;

== Containerisierung 
*Docker* mit Docker-Compose zur einfachen Entwicklung auf verschiedenen Systemen.

== KI-gestützte Werkzeuge

Im Rahmen dieser Bachelorarbeit wurden KI-gestützte Werkzeuge (Large Language Models) als Hilfsmittel eingesetzt. Die Nutzung erfolgte in folgenden Bereichen:

+ *Assistenz bei Visualisierungsskripten:* Die Konzeption der Diagramme und Charts, also welche Daten auf welche Weise visualisiert werden, erfolgte eigenständig durch den Autor. Zur zeitsparenden Umsetzung wurde KI als Assistenzwerkzeug für die Erstellung der zugehörigen Python-Skripte (Matplotlib) eingesetzt. Die generierten Skripte wurden anschließend manuell überprüft und bei Bedarf angepasst.


+ *Intelligente Fehlersuche:* Anstelle klassischer Fehlersuche (z.B. in StackOverflow) wurde KI als Recherchewerkzeug bei der Fehlersuche im Code eingesetzt.

+ *Rechtschreib- und Grammatikprüfung:* KI wurde zur Überprüfung von Texten auf Rechtschreib- und Grammatikfehler verwendet.

+ *Dokumentation:* KI wurde zur Unterstützung beim Verfassen von Teilen der Code-Dokumentation eingesetzt, um die Nachvollziehbarkeit des Codes auch nach längerer Zeit sicherzustellen.

Sämtliche KI-generierten Inhalte wurden kritisch geprüft, manuell überarbeitet und in den jeweiligen Kontext eingebettet. Die inhaltliche Verantwortung liegt vollständig beim Autor.

== Datenquellen

*OpenStreetMap* (OSM) als Quelle der Straßennetz-Rohdaten. Der Berliner Datensatz sowie der irische Vergleichsdatensatz für die Skalierungsanalyse wurden über die *Overpass API* bezogen.

== Hardware

Die im Auswertungskapitel berichteten Benchmark-Messungen wurden auf folgendem System ausgeführt:

- *CPU:* AMD Ryzen 7 9800X3D / Apple M4
- *Arbeitsspeicher:* 32gb DDR5 / 24gb DDR5
- *Betriebssystem:* Windows 11 / MacOS

