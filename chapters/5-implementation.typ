#import "global.typ": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
= Implementation <implementation>

== Systemarchitektur

Die in dieser Arbeit entwickelte Anwendung ist als verteiltes System mit drei voneinander entkoppelten Schichten realisiert: einer Algorithmik- und Datenschicht im Backend, einer interaktiven Visualisierungsschicht im Frontend sowie einer relationalen Datenbank zur Persistenz von Benchmark-Ergebnissen. Diese Trennung verfolgt zwei Ziele. Zum einen erlaubt sie eine unabhängige Weiterentwicklung der einzelnen Komponenten — etwa den Austausch oder die Erweiterung der Pathfinding-Algorithmen ohne Eingriff in die Visualisierung. Zum anderen ermöglicht sie eine plattformunabhängige interaktive Demonstration des Algorithmenverhaltens über jeden modernen Webbrowser, ohne dass auf der Bewertungsumgebung eine GUI-Toolchain installiert werden muss.

=== Technologieauswahl

Das Backend ist in Python 3.11 unter Verwendung von FastAPI implementiert. FastAPI wurde gewählt, weil es nativ asynchrone Endpunkte und WebSocket-Verbindungen unterstützt. Letztere sind zentral für eine der Kernanforderungen der Anwendung: die schrittweise Live-Visualisierung des Suchprozesses, nicht nur des Endergebnisses. Über REST allein ließe sich diese Anforderung nicht erfüllen, da REST per Definition ein Anfrage-Antwort-Modell ohne serverseitiges Streaming vorsieht. Als Bibliothek für die Graphenrepräsentation und -manipulation kommt NetworkX @hagberg2008 zum Einsatz. Die Wahl ergibt sich primär aus der direkten Interoperabilität mit OSMnx, das OSM-Netzwerke nativ als networkx.MultiDiGraph zurückgibt und damit eine zusätzliche Konvertierungsschicht vermeidet. Die Anbindung an das OpenStreetMap-Ökosystem erfolgt über OSMnx, das die Beschaffung und Aufbereitung von OSM-Straßennetzen kapselt (siehe Abschnitt 4.2).
Das Frontend basiert auf Nuxt 4 (Vue 3) und nutzt Leaflet.js für die Kartendarstellung. Als Datenbank dient PostgreSQL 16, angesteuert über den asynchronen Treiber asyncpg, der sich nahtlos in den Async-Stack von FastAPI einfügt. Die Wahl von PostgreSQL gegenüber einer eingebetteten Lösung wie SQLite begründet sich primär durch die einheitliche Containerisierung (alle Dienste werden über Docker Compose orchestriert, siehe Abschnitt 4.9) und sekundär durch die Erweiterungsmöglichkeit auf PostGIS, falls in zukünftiger Arbeit raumbezogene Anfragen — etwa die Zuordnung von Seed-Punkten zu OSM-Knoten über Spatial Indexes — direkt in der Datenbank ausgeführt werden sollen.

=== Generator-basierte Algorithmusarchitektur

Eine zentrale Designentscheidung des Backends ist die Implementierung der Pathfinding-Algorithmen als Python-Generatoren. Die Methode a_star_generator() yieldet nach jedem Expansionsschritt einen Zustands-Dictionary, der den aktuellen Knoten, die aufgebauten Datenstrukturen sowie laufende Statistiken enthält. Das Iterator-Protokoll entkoppelt damit die Algorithmuslogik vollständig von der Transportschicht: Derselbe Generator wird sowohl vom WebSocket-Endpunkt für die Live-Visualisierung konsumiert als auch von den nicht-streamenden REST-Endpunkten und vom Benchmark-Adapter, indem dort schlicht alle Zwischenzustände verworfen und nur der finale Zustand verwertet wird. Diese Entkopplung erlaubt es, ein- und denselben Algorithmus-Codepfad in drei verschiedenen Nutzungskontexten einzusetzen, ohne dass die Algorithmusimplementierung Kenntnis von Netzwerkverbindungen oder Benchmark-Logik haben muss.

=== Startsequenz

Das Backend nutzt den FastAPI-Lifespan-Kontextmanager zur einmaligen Initialisierung beim Serverstart. Die Startsequenz umfasst sechs Schritte: 
+ Laden des OSM-Graphen aus dem lokalen Cache oder, falls nicht vorhanden, Live-Bezug über die Overpass-API
+ Initialisierung des A\*-Pathfinders über dem geladenen Graphen
+ Berechnung der Network-Voronoi-Partitionierung des Graphen mittels Multi-Source-Dijkstra (siehe Abschnitt 4.4.1)
+ Vorberechnung der Visualisierungs-GeoJSONs für Cluster, Gates und Seeds
+ Konstruktion des abstrakten Graphen für HPA\* (siehe Abschnitt 4.4.2) inklusive Vorberechnung aller Intra-Cluster-Distanzen
+ optionaler Aufbau des Datenbank-Connection-Pools, sofern die Umgebungsvariable DATABASE_URL gesetzt ist.

Die Anwendung läuft auch ohne Datenbankanbindung; in diesem Fall stehen lediglich die Benchmark-Persistenz-Endpunkte nicht zur Verfügung. Diese verzögerte Konstruktion sämtlicher Datenstrukturen beim Start ist gerechtfertigt, weil die Arbeit auf einen statischen Graphen ausgerichtet ist und alle Vorberechnungen damit nur einmal pro Serverstart anfallen — eine Konstellation, die für einen produktiven Routingdienst unrealistisch wäre, für die experimentelle Untersuchung jedoch angemessen ist. #todo("Abbildung 5.1: Architekturdiagramm — drei Boxen (Frontend, Backend, PostgreSQL), Pfeile mit Beschriftungen REST (/path, /hpa_path, /clusters, ...), WebSocket (/ws, /ws/hpa), SQL.")

== Datenbeschaffung und Graphaufbau

Die in dieser Arbeit verwendete Datenbasis besteht aus realen Straßennetzen, die über das OpenStreetMap-Projekt (OSM) bezogen werden (siehe Abschnitt 2.5). Der Zugriff auf die Rohdaten sowie deren Aufbereitung zu einem für Graphalgorithmen unmittelbar nutzbaren Datenmodell erfolgt über die Bibliothek OSMnx (Boeing, 2017). OSMnx kapselt die Kommunikation mit der Overpass-API, führt eine geometrische Vereinfachung des Netzwerks durch und stellt das Ergebnis als networkx.MultiDiGraph zur Verfügung. Damit entfällt sowohl der Aufwand einer eigenen OSM-XML-Verarbeitung als auch eine Konvertierungsschicht zwischen Datenbeschaffung und Algorithmik.

=== Untersuchungsgebiet

Für die Entwicklung und die in Abschnitt 5.5 beschriebene Live-Visualisierung dient ein Ausschnitt von 5.000 m Radius um den Berliner Stadtkern (52.5200° N, 13.4050° O) als Standardkonfiguration. Dieser Ausschnitt repräsentiert ein dicht vernetztes innerstädtisches Straßennetz und eignet sich daher gut zur Veranschaulichung beider Algorithmen unter realistischen Bedingungen. Für die in Kapitel 6 durchgeführte Evaluation werden zusätzlich Ausschnitte mit unterschiedlicher Topologie und Knotendichte herangezogen, um das Verhalten der Algorithmen über verschiedene Netzcharakteristika hinweg vergleichen zu können.
Als Netzwerktyp wird bike verwendet. Diese Wahl reduziert die strukturelle Komplexität des Graphen gegenüber dem Straßennetz für Kraftfahrzeuge: Einbahnstraßen-Asymmetrien und mehrspurige Aufteilungen, die im KFZ-Netz häufig zu mehreren parallelen gerichteten Kanten zwischen denselben Knoten führen, treten im Fahrradnetz nur eingeschränkt auf. Da die vorliegende Arbeit nicht die Modellierung verkehrsrechtlicher Restriktionen, sondern den algorithmischen Vergleich von A* und HPA* zum Gegenstand hat, vereinfacht die Wahl des Fahrradnetzes die Interpretation der Ergebnisse, ohne die Vergleichbarkeit beider Algorithmen einzuschränken.


=== Graphdatenstruktur

OSMnx liefert das Netzwerk als gerichteten Multigraphen vom Typ networkx.MultiDiGraph. Knoten entsprechen OSM-Nodes und tragen als Attribute die geographischen Koordinaten (x für Länge, y für Breite). Kanten entsprechen OSM-Ways oder Way-Segmenten und tragen unter anderem das Attribut length (Kantenlänge in Metern, durch OSMnx aus den Knotenkoordinaten vorberechnet) sowie weitere OSM-Tags wie highway oder name. Da der MultiDiGraph mehrere parallele Kanten zwischen demselben Knotenpaar erlaubt, wählt der A\*-Pathfinder bei der Bestimmung des Kantengewichts stets die kürzeste verfügbare Kante (siehe Abschnitt 5.3).

=== Caching

Um wiederholte Anfragen an die Overpass-API zu vermeiden, persistiert die Anwendung den geladenen Graphen beim ersten Abruf als GraphML-Datei unter data/graph.graphml. Bei späteren Serverstarts wird der Graph aus diesem Cache geladen, sofern die Datei vorhanden und nicht leer ist. Listing 5.1 zeigt die hierfür zuständige Klasse Osm.
#show figure: set block(breakable: true)
#figure(
  caption: [Wrapper-Klasse für die Beschaffung und Persistenz des OSM-Graphen.],
  kind: raw,
)[
#set par(spacing: 0em)
#codly( languages: codly-languages, 
        zebra-fill: none,
        header: [Osm.py],
        number-format: none,
      )
```python
class Osm:
    FILE_PATH = Path("data/graph.graphml")

    def __init__(self, latitude, longitude, distance, graph_type="bike"):
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.graph_type = graph_type
        self.graph = nx.MultiDiGraph()

    def get_graph(self):
        if self.load_graph():
            return self.graph
        self.graph = ox.graph.graph_from_point(
            center_point=(self.latitude, self.longitude),
            network_type=self.graph_type,
            dist=self.distance)
        self.save_osm_graph()
        return self.graph

    def load_graph(self):
        p = self.FILE_PATH
        if not p.exists() or p.stat().st_size == 0:
            return False
        try:
            self.graph = ox.load_graphml(str(p))
            return True
        except Exception:
            return False

    def save_osm_graph(self):
        self.FILE_PATH.parent.mkdir(parents=True, exist_ok=True)
        ox.save_graphml(self.graph, filepath=str(self.FILE_PATH))
```
]