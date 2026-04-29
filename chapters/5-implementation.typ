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

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/osm.py"), lastline: 33),
  ),
  caption: flex-caption(
    [Wrapper-Klasse für die Beschaffung und Persistenz des OSM-Graphen],[]
  ),
) <lst:osm_wrapper>

== A\*-Algorithmus

Die Implementierung des A\*-Algorithmus (siehe Abschnitt 2.2.2) erfolgt in der Klasse AStarPathfinder und kapselt sowohl die eigentliche Pfadsuche als auch die für die spätere Auswertung benötigte Erfassung von Laufzeit- und Strukturmetriken. Der Fokus dieses Abschnitts liegt auf den konkreten Implementierungsentscheidungen; eine erneute formale Darstellung des Algorithmus erfolgt nicht.

=== Heuristik
Als Heuristik wird die Haversine-Distanz zwischen zwei Knoten in Metern verwendet. Die Funktion bezieht ihre Eingaben aus den Knotenattributen x (Längengrad) und y (Breitengrad), die OSMnx beim Laden des Graphen vergibt. 
#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/haversine_distance.py"), lastline: 20),
  ),
  caption: flex-caption(
    [Haversine-Distanz als A\*-Heuristik],[]
  ),
) <lst:parallele_kanten>

\
Die Wahl der Haversine-Distanz gegenüber der euklidischen Distanz auf einer projizierten Ebene ist eine bewusste Entscheidung. Die in Abschnitt 2.2.2 dargestellte Optimalitätsgarantie von A\* setzt eine zulässige Heuristik voraus, die die tatsächliche Restdistanz zum Ziel niemals überschätzt. Die Haversine-Distanz erfüllt diese Eigenschaft global auf der Erdoberfläche, da sie die Großkreisdistanz zwischen zwei Punkten liefert und damit eine untere Schranke für jede mögliche Routenlänge entlang des Straßennetzes darstellt. Eine Projektion in ein lokales Koordinatensystem wie UTM (siehe Abschnitt 2.6) führt hingegen mit zunehmendem Abstand vom Bezugsmeridian zu Verzerrungen, die im Einzelfall zur Überschätzung der Restdistanz führen können. Da A\* auf dem unprojizierten OSM-Graphen operiert, in dem Knotenkoordinaten als geographische Koordinaten vorliegen, vermeidet die Verwendung der Haversine-Distanz zudem eine zusätzliche Projektionsschicht und behält die Zulässigkeit der Heuristik unter allen Bedingungen bei.

=== Datenstrukturen

Die Open Set wird als binärer Min-Heap über Tupel der Form (f_score, node_id) realisiert, implementiert mit Pythons heapq-Modul. Das Modul stellt Push- und Pop-Operationen in O(log n) bereit. Eine Decrease-Key-Operation, wie sie in der lehrbuchüblichen Beschreibung von A\* (etwa bei Cormen et al., 2009) angenommen wird, unterstützt heapq nicht direkt. Stattdessen wird die als Lazy Deletion bekannte Variante umgesetzt: Wird ein Knoten über einen kürzeren Pfad erreicht, fügt die Implementierung ihn erneut mit dem niedrigeren f-Wert in den Heap ein, ohne den veralteten Eintrag zu entfernen. Beim Pop prüft eine Wächter-Bedingung, ob der entnommene Knoten bereits in der Closed Set vorhanden ist; trifft das zu, wird der Eintrag verworfen. Diese Variante erhöht zwar den Speicherbedarf des Heaps gegenüber einer echten Decrease-Key-Implementierung, liegt asymptotisch jedoch in derselben Komplexitätsklasse und ist in der Praxis deutlich einfacher zu implementieren.
Drei weitere Datenstrukturen begleiten die Hauptschleife. Das Dictionary g_score speichert für jeden bisher erreichten Knoten die Länge des kürzesten bekannten Pfades vom Startknoten. Das Dictionary came_from hält die Eltern-Beziehung jedes erreichten Knotens für die spätere Pfadrekonstruktion. Die Menge closed_set markiert Knoten, deren endgültige Distanz bereits feststeht und die nicht erneut expandiert werden.

=== Behandlung paralleler Kanten

Da OSMnx den Graphen als networkx.MultiDiGraph zurückgibt, können zwischen zwei Knoten mehrere parallele gerichtete Kanten existieren, etwa durch separat erfasste Fahrradspuren oder Fahrtrichtungs-Varianten. Die Methode get_edge_weight löst diese Mehrdeutigkeit auf, indem sie unter allen vorhandenen Kanten die mit der geringsten Länge auswählt:

#figure(
  align(
    left,
    // we use a custom template (style), defined in fh.typ
    // the files are expected in subfolder "source"
    // optionally, specify firstline/lastline
    fhjcode(code: read("/code-snippets/get_edge_weight.py"), lastline: 9),
  ),
  // we use a custom flex-caption), to allow long and short captions
  // (the short one appears in the outline List of Figures).
  // This is defined in `lib.typ`.
  caption: flex-caption(
    [Auflösung paralleler Kanten in A\*],[]
  ),
) <lst:parallele_kanten>
\

Diese Wahl ist konsistent mit dem Ziel des Algorithmus. A\* sucht den kürzesten Pfad; existieren zwischen zwei Knoten mehrere Verbindungen, ist für die Optimalitätsgarantie nur die kürzeste relevant. Eine Auswahl der ersten Kante (Reihenfolge der Speicherung im MultiDiGraph) oder eines Mittelwertes wäre nicht nur weniger sinnvoll, sondern könnte im Extremfall zur Auswahl suboptimaler Pfade führen.

=== Hauptschleife

Die Hauptschleife folgt der lehrbuchüblichen Struktur von A\*, ist jedoch als Python-Generator umgesetzt. Nach jedem Expansionsschritt yieldet die Methode einen Zustands-Dictionary, der den aktuellen Knoten, dessen Koordinaten, die zugehörigen f- und g-Werte sowie die laufenden Statistiken enthält. Im Anschluss werden alle Nachbarn des entnommenen Knotens betrachtet; für jeden verbesserten Pfad wird ein zusätzlicher Zustand vom Typ exploring ausgegeben. 

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/a_star_loop.py"), lastline: 34),
  ),
  caption: flex-caption(
    [Kern der A\*-Hauptschleife],[]
  ),
) <lst:parallele_kanten>
\
Die Generator-Form bringt zwei Vorteile mit sich, die in Abschnitt 5.1 bereits skizziert wurden. Erstens bleibt die Algorithmusimplementierung frei von Annahmen über die spätere Verwendung der Zwischenzustände; das WebSocket-Streaming, der nicht-streamende REST-Aufruf und der Benchmark-Adapter konsumieren denselben Generator. Zweitens lassen sich die ausgegebenen Zustände direkt für die Live-Visualisierung im Frontend nutzen, ohne dass der Algorithmus selbst Kenntnis vom Übertragungsweg haben muss.

=== Pfadrekonstruktion

Wird der Zielknoten aus der Open Set entnommen, rekonstruiert die Methode reconstruct_path den Pfad rückwärts über das came_from-Dictionary. Anschließend wandelt get_path_coordinates die Knoten-IDs in Lat/Lon-Tupel um, die das Frontend als GeoJSON-LineString rendern kann.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/reconstruct_path.py"), lastline: 6),
  ),
  caption: flex-caption(
    [Rückwärts-Rekonstruktion des Pfades aus der Eltern-Beziehung.],[]
  ),
) <lst:parallele_kanten>

=== Erfassung von Laufzeitmetriken
Für die spätere Auswertung in Kapitel 7 erfasst die Implementierung sechs Metriken pro Pfadanfrage und gibt sie in jedem Generator-Yield im Feld stats mit aus. Tabelle 5.1 fasst die erhobenen Größen und ihre Bedeutung zusammen.
#figure(
caption: [Erfasste Laufzeitmetriken pro A\*-Anfrage.],
table(
columns: (auto, 1fr),
align: (left, left),
table.header[Metrik][Bedeutung],
[visited_nodes_count], [Anzahl Knoten, die endgültig aus der Open Set entnommen und expandiert wurden.],
[explored_edges_count], [Anzahl Kantenrelaxierungen, also Auswertungen der Methode get_edge_weight.],
[heap_pushes], [Anzahl Push-Operationen auf den Min-Heap. Übersteigt potenziell visited_nodes_count aufgrund der Lazy-Deletion-Variante.],
[heap_pops], [Anzahl Pop-Operationen auf den Min-Heap.],
[max_open_set_size], [Maximale Größe der Open Set während der Suche, als Indikator für den Speicherbedarf.],
[runtime_ms], [Zeit zwischen Methodenstart und aktuellem Yield in Millisekunden, gemessen mit time.perf_counter.],
),
)
Diese Granularität erlaubt es, in der Auswertung nicht nur die Gesamtlaufzeit zu vergleichen, sondern auch zwischen den Komponenten zu differenzieren, die zur Laufzeit beitragen, etwa zwischen Suchraumgröße (visited_nodes_count) und Heap-Verwaltungsaufwand (heap_pushes und heap_pops).
#todo("Kapitel 7: Stats systematisch über alle Algorithmen und Ausschnitte aggregieren und visualisieren.")