#import "global.typ": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/fletcher:0.5.7" as fletcher: diagram, node, edge
#show: codly-init.with()


= Implementierung <implementation>

== Systemarchitektur <sec:architektur>

Die in dieser Arbeit entwickelte Anwendung ist als verteiltes System mit drei voneinander entkoppelten _Komponenten_ realisiert: einem Backend für Algorithmik und Datenhaltung, einem Frontend für die interaktive Visualisierung sowie einer relationalen Datenbank zur Persistenz von Benchmark-Ergebnissen. Diese strukturelle Trennung verfolgt zwei Ziele. Zum einen erlaubt sie eine unabhängige Weiterentwicklung der einzelnen Komponenten, etwa den Austausch oder die Erweiterung der Pathfinding-Algorithmen ohne Eingriff in die Visualisierung. Zum anderen ermöglicht sie eine plattformunabhängige interaktive Demonstration des Algorithmenverhaltens über jeden modernen Webbrowser, ohne dass auf der Bewertungsumgebung eine GUI-Toolchain installiert werden muss.

=== Technologieauswahl

Das Backend ist in Python 3.11 unter Verwendung von FastAPI implementiert. FastAPI wurde gewählt, weil es nativ asynchrone Endpunkte und WebSocket-Verbindungen unterstützt. Letztere sind zentral für eine der Kernanforderungen der Anwendung: die schrittweise Live-Visualisierung des Suchprozesses, nicht nur des Endergebnisses. Über REST allein ließe sich diese Anforderung nicht erfüllen, da REST per Definition ein Anfrage-Antwort-Modell ohne serverseitiges Streaming vorsieht. Als Bibliothek für die Graphenrepräsentation und -manipulation kommt NetworkX @hagberg2008 zum Einsatz. Die Wahl ergibt sich primär aus der direkten Interoperabilität mit OSMnx, das OSM-Netzwerke nativ als networkx.MultiDiGraph zurückgibt und damit eine zusätzliche Konvertierungsschicht vermeidet. Die Anbindung an das OpenStreetMap-Ökosystem erfolgt über OSMnx, das die Beschaffung und Aufbereitung von OSM-Straßennetzen kapselt (siehe Abschnitt 5.2).

Das Frontend basiert auf Nuxt 4 (Vue 3) und nutzt Leaflet.js für die Kartendarstellung. Als Datenbank dient PostgreSQL 16, angesteuert über den asynchronen Treiber asyncpg, der sich nahtlos in den Async-Stack von FastAPI einfügt. Die Wahl von PostgreSQL gegenüber einer eingebetteten Lösung wie SQLite begründet sich primär durch die einheitliche Containerisierung (alle Dienste werden über Docker Compose orchestriert, siehe Abschnitt 5.9) und sekundär durch die Erweiterungsmöglichkeit auf PostGIS, falls in zukünftiger Arbeit raumbezogene Anfragen wie etwa die Zuordnung von Seed-Punkten zu OSM-Knoten über Spatial Indexes direkt in der Datenbank ausgeführt werden sollen.

=== Generator-basierte Algorithmusarchitektur

Eine zentrale Designentscheidung des Backends ist die Implementierung der Pathfinding-Algorithmen als Python-Generatoren. Die Methode a_star_generator() yieldet nach jedem Expansionsschritt einen Zustands-Dictionary, der den aktuellen Knoten, die aufgebauten Datenstrukturen sowie laufende Statistiken enthält. Das Iterator-Protokoll entkoppelt damit die Algorithmuslogik vollständig von der Transportschicht: Derselbe Generator wird sowohl vom WebSocket-Endpunkt für die Live-Visualisierung konsumiert als auch von den nicht-streamenden REST-Endpunkten und vom Benchmark-Adapter, indem dort schlicht alle Zwischenzustände verworfen und nur der finale Zustand verwertet wird. Diese Entkopplung erlaubt es, ein- und denselben Algorithmus-Codepfad in drei verschiedenen Nutzungskontexten einzusetzen, ohne dass die Algorithmusimplementierung Kenntnis von Netzwerkverbindungen oder Benchmark-Logik haben muss.

=== Startsequenz

Das Backend nutzt den FastAPI-Lifespan-Kontextmanager zur einmaligen Initialisierung beim Serverstart. Die Startsequenz umfasst sechs Schritte: 
+ Laden des OSM-Graphen aus dem lokalen Cache oder, falls nicht vorhanden, Live-Bezug über die Overpass-API
+ Initialisierung des A\*-Pathfinders über dem geladenen Graphen
+ Berechnung der Network-Voronoi-Partitionierung des Graphen mittels Multi-Source-Dijkstra (siehe Abschnitt 5.4.2)
+ Vorberechnung der Visualisierungs-GeoJSONs für Cluster, Gates und Seeds
+ Konstruktion des abstrakten Graphen für HPA\* (siehe Abschnitt 5.4.3) inklusive Vorberechnung aller Intra-Cluster-Distanzen
+ optionaler Aufbau des Datenbank-Connection-Pools, sofern die Umgebungsvariable DATABASE_URL gesetzt ist.

Die Anwendung läuft auch ohne Datenbankanbindung; in diesem Fall stehen lediglich die Benchmark-Persistenz-Endpunkte nicht zur Verfügung. Diese verzögerte Konstruktion sämtlicher Datenstrukturen beim Start ist gerechtfertigt, weil die Arbeit auf einen statischen Graphen ausgerichtet ist und alle Vorberechnungen damit nur einmal pro Serverstart anfallen, eine Konstellation, die für einen produktiven Routingdienst unrealistisch wäre, für die experimentelle Untersuchung jedoch angemessen ist.

#figure(
  diagram(
    node-stroke: 0.6pt,
    node-corner-radius: 4pt,
    spacing: (3em, 3em),
    node-inset: 7pt,

    node((0, 0), [
      #set align(center)
      *Frontend* \
      #text(size: 9pt)[Nuxt 4 / Vue 3 \ Leaflet.js]
    ], name: <frontend>),

    node((2, 0), [
      #set align(center)
      *Backend* \
      #text(size: 9pt)[FastAPI (Python 3.11) \ NetworkX, OSMnx]
    ], name: <backend>),

    node((4, 0), [
      #set align(center)
      *PostgreSQL 16* \
      #text(size: 9pt)[Benchmark-Persistenz]
    ], name: <db>),

    node((2, 1.6), [
      #set align(center)
      *Overpass API* \
      #text(size: 9pt)[(extern)]
    ], stroke: (thickness: 0.6pt, dash: "dashed"), name: <overpass>),

    edge(<frontend>, <backend>, "-|>",
      text(size: 9pt)[REST],
      label-side: center, bend: 25deg),
    edge(<frontend>, <backend>, "<|-|>",
      text(size: 9pt)[WebSocket],
      label-side: center, bend: -25deg),
    edge(<backend>, <db>, "<|-|>",
      text(size: 9pt)[SQL (asyncpg)],
      label-side: center),
    edge(<overpass>, <backend>, "-|>",
      text(size: 9pt)[HTTP (Start)],
      label-side: center,
      stroke: (thickness: 0.6pt, dash: "dashed")),
  ),
  caption: flex-caption(
    [Architektur des verteilten Systems. Frontend und Backend kommunizieren über REST sowie eine bidirektionale WebSocket-Verbindung für die Live-Visualisierung. Das Backend persistiert Benchmark-Ergebnisse in PostgreSQL und bezieht beim Serverstart einmalig den OSM-Straßengraphen über die Overpass-API.],
    [Systemarchitektur]
  ),
) <fig:architektur>

== Datenbeschaffung und Graphaufbau <sec:datenbeschaffung>

Die in dieser Arbeit verwendete Datenbasis besteht aus realen Straßennetzen, die über das OpenStreetMap-Projekt (OSM) bezogen werden (siehe Abschnitt 2.5). Der Zugriff auf die Rohdaten sowie deren Aufbereitung zu einem für Graphalgorithmen unmittelbar nutzbaren Datenmodell erfolgt über die Bibliothek OSMnx @Boeing:2017 . OSMnx kapselt die Kommunikation mit der Overpass-API, führt eine geometrische Vereinfachung des Netzwerks durch und stellt das Ergebnis als networkx.MultiDiGraph zur Verfügung. Damit entfällt sowohl der Aufwand einer eigenen OSM-XML-Verarbeitung als auch eine Konvertierungsschicht zwischen Datenbeschaffung und Algorithmik.

=== Untersuchungsgebiet

Für die Entwicklung und die in Abschnitt 5.5 beschriebene Live-Visualisierung dient ein Ausschnitt von 5.000 m Radius um den Berliner Stadtkern (52.5200° N, 13.4050° O) als Standardkonfiguration. Dieser Ausschnitt repräsentiert ein dicht vernetztes innerstädtisches Straßennetz und eignet sich daher gut zur Veranschaulichung beider Algorithmen unter realistischen Bedingungen. Für die in Kapitel 6 durchgeführte Evaluation werden zusätzlich Ausschnitte mit unterschiedlicher Topologie und Knotendichte herangezogen, um das Verhalten der Algorithmen über verschiedene Netzcharakteristika hinweg vergleichen zu können.
Als Netzwerktyp wird bike verwendet. Diese Wahl reduziert die strukturelle Komplexität des Graphen gegenüber dem Straßennetz für Kraftfahrzeuge: Einbahnstraßen-Asymmetrien und mehrspurige Aufteilungen, die im KFZ-Netz häufig zu mehreren parallelen gerichteten Kanten zwischen denselben Knoten führen, treten im Fahrradnetz nur eingeschränkt auf. Da die vorliegende Arbeit nicht die Modellierung verkehrsrechtlicher Restriktionen, sondern den algorithmischen Vergleich von A* und HPA* zum Gegenstand hat, vereinfacht die Wahl des Fahrradnetzes die Interpretation der Ergebnisse, ohne die Vergleichbarkeit beider Algorithmen einzuschränken.


=== Graphdatenstruktur

OSMnx liefert das Netzwerk als gerichteten Multigraphen vom Typ networkx.MultiDiGraph. Knoten entsprechen OSM-Nodes und tragen als Attribute die geographischen Koordinaten (x für Länge, y für Breite). Kanten entsprechen OSM-Ways oder Way-Segmenten und tragen unter anderem das Attribut length (Kantenlänge in Metern, durch OSMnx aus den Knotenkoordinaten vorberechnet) sowie weitere OSM-Tags wie highway oder name. Da der MultiDiGraph mehrere parallele Kanten zwischen demselben Knotenpaar erlaubt, wählt der A\*-Pathfinder bei der Bestimmung des Kantengewichts stets die kürzeste verfügbare Kante (siehe Abschnitt 5.3).

=== Caching

Um wiederholte Anfragen an die #gls("overpassapi") zu vermeiden, persistiert die Anwendung den geladenen Graphen beim ersten Abruf als GraphML-Datei unter data/graph.graphml. Bei späteren Serverstarts wird der Graph aus diesem Cache geladen, sofern die Datei vorhanden und nicht leer ist. Listing 5.1 zeigt die hierfür zuständige Klasse Osm.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/osm.py"), lastline: 33),
  ),
  caption: flex-caption(
    [Wrapper-Klasse für die Beschaffung und Persistenz des OSM-Graphen],[]
  ),
) <lst:osm_wrapper>

== A\*-Algorithmus <sec:astar>

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
) <lst:haversine>

\
Die Wahl der Haversine-Distanz gegenüber der euklidischen Distanz auf einer projizierten Ebene ist eine bewusste Entscheidung. Die in Abschnitt 2.2.2 dargestellte Optimalitätsgarantie von A\* setzt eine zulässige Heuristik voraus, die die tatsächliche Restdistanz zum Ziel niemals überschätzt. Die Haversine-Distanz erfüllt diese Eigenschaft global auf der Erdoberfläche, da sie die Großkreisdistanz zwischen zwei Punkten liefert und damit eine untere Schranke für jede mögliche Routenlänge entlang des Straßennetzes darstellt. Eine Projektion in ein lokales Koordinatensystem wie UTM (siehe @koordinatensysteme) führt hingegen mit zunehmendem Abstand vom Bezugsmeridian zu Verzerrungen, die im Einzelfall zur Überschätzung der Restdistanz führen können. Da A\* auf dem unprojizierten OSM-Graphen operiert, in dem Knotenkoordinaten als geographische Koordinaten vorliegen, vermeidet die Verwendung der Haversine-Distanz zudem eine zusätzliche Projektionsschicht und behält die Zulässigkeit der Heuristik unter allen Bedingungen bei.

=== Datenstrukturen

Die Open Set wird als binärer Min-Heap über Tupel der Form (f_score, node_id) realisiert, implementiert mit Pythons heapq-Modul. Das Modul stellt Push- und Pop-Operationen in O(log n) bereit. Eine Decrease-Key-Operation, wie sie in der lehrbuchüblichen Beschreibung von A\* (etwa bei @Cormen:2009) angenommen wird, unterstützt heapq nicht direkt. Stattdessen wird die als Lazy Deletion bekannte Variante umgesetzt: Wird ein Knoten über einen kürzeren Pfad erreicht, fügt die Implementierung ihn erneut mit dem niedrigeren f-Wert in den Heap ein, ohne den veralteten Eintrag zu entfernen. Beim Pop prüft eine Wächter-Bedingung, ob der entnommene Knoten bereits in der Closed Set vorhanden ist; trifft das zu, wird der Eintrag verworfen. Diese Variante erhöht zwar den Speicherbedarf des Heaps gegenüber einer echten Decrease-Key-Implementierung, liegt asymptotisch jedoch in derselben Komplexitätsklasse und ist in der Praxis deutlich einfacher zu implementieren.
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
) <lst:astar_loop>
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
) <lst:reconstruct_path>

=== Erfassung von Laufzeitmetriken
Für die spätere Auswertung in @evaluation erfasst die Implementierung sechs Metriken pro Pfadanfrage und gibt sie in jedem Generator-Yield im Feld stats mit aus. Tabelle 5.1 fasst die erhobenen Größen und ihre Bedeutung zusammen.
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


== Hierarchisches Pathfinding mit HPA\* <sec:hpastar>
Die in dieser Arbeit implementierte Variante des Hierarchical Pathfinding A\* (HPA\*) folgt dem Grundgerüst von Botea et al. @Botea:2004 und überträgt es auf die spezifischen Eigenschaften eines OSM-Straßennetzes. Sie weicht in zwei Punkten vom ursprünglichen Vorschlag ab. Erstens werden die abstrakten Knoten nicht als Paare aus Entry- und Exit-Punkten pro Cluster-Border modelliert, sondern jeder Border-Knoten ist ein einzelner abstrakter Knoten, der zugleich Exit für den einen und Entry für das benachbarte Cluster darstellt. Zweitens erfolgt die Cluster-Bildung nicht über das in @Botea:2004 verwendete reguläre Gitter, das ein dichtes Grid voraussetzt, sondern über eine Network-Voronoi-Partitionierung des Graphen, da OSM-Straßennetze keine gitterartige Struktur besitzen (siehe Abschnitt 2.4). Beide Adaptionen werden in den folgenden Unterabschnitten begründet.
=== Übersicht der Laufzeitphasen
Die Implementierung verteilt die Arbeit auf eine einmalige Vorberechnung beim Start und eine Query-Phase pro Pfadanfrage. Die Vorberechnung umfasst zwei Schritte: die Network-Voronoi-Partitionierung des Graphen (Abschnitt 5.4.2) und die Konstruktion des abstrakten Graphen (Abschnitt 5.4.3). Die Query-Phase besteht aus der abstrakten A\*-Suche über dem Gate-Graphen (Abschnitt 5.4.4) und der anschließenden Verfeinerung der gefundenen Gate-Sequenz zu einem konkreten OSM-Pfad (Abschnitt 5.4.5).
Die Trennung in Vorberechnung und Query ist die zentrale Idee hierarchischer Pathfinding-Verfahren: Aufwand, der einmal anfällt, wird aus der Query-Schleife herausgezogen, sodass jede einzelne Pfadanfrage von einer reduzierten Suchraumgröße profitiert. Für eine Anwendung mit statischem Straßennetz, wie sie hier untersucht wird, ist diese Aufteilung uneingeschränkt vorteilhaft. Eine Diskussion der Folgen für dynamische Szenarien findet sich in @sec:outlook.
=== Network-Voronoi-Clustering
Die Cluster-Bildung erfolgt in der Klasse RegionGrow und basiert auf einem Multi-Source-Dijkstra-Lauf, der von einem regelmäßigen Gitter aus Seed-Punkten ausgeht. Das Verfahren gliedert sich in drei Schritte.
Zunächst wird der OSM-Graph in das lokale UTM-Koordinatensystem projiziert (siehe @koordinatensysteme). Über die Bounding-Box des projizierten Graphen wird ein gleichmäßiges $n times n$-Gitter aus Seed-Punkten gelegt, wobei $n$ über den Parameter grid_size konfigurierbar ist. Anschließend wird jeder Gitter-Punkt auf den nächstgelegenen OSM-Knoten abgebildet. Die Projektion in UTM ist hierbei ausschließlich für die Konstruktion des Gitters notwendig und beeinflusst weder die Distanzberechnung noch die nachfolgende Pfadsuche.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/create_seed_nodes.py"), lastline: 8),
  ),
  caption: flex-caption(
    [Erzeugung der Seed-Knoten aus einem regelmäßigen Gitter über der Bounding-Box],[]
  ),
) <lst:create-seed-nodes>
\

Die abschließende Deduplizierung über dict.fromkeys ist notwendig, da auf einem realen Straßennetz mehrere Gitterpunkte auf denselben OSM-Knoten abgebildet werden können, insbesondere in dünn besiedelten Bereichen mit weiten Abständen zwischen den Knoten. Die tatsächliche Anzahl der Seeds liegt dadurch in der Regel unter $n^2$.
Im zweiten Schritt expandiert ein Multi-Source-Dijkstra-Lauf von allen Seeds gleichzeitig. Die Priority Queue wird initial mit allen Seeds bei Distanz 0 belegt; jeder Heap-Eintrag trägt zusätzlich die ID des Seeds, von dem aus der Knoten erreicht wurde. Sobald ein Knoten zum ersten Mal aus der Queue entnommen wird, wird er endgültig demjenigen Seed zugeordnet, der ihn erreicht hat. Da Dijkstra optimal ist, entspricht diese Zuordnung garantiert dem nach Straßennetz-Distanz nächstgelegenen Seed. Das Ergebnis ist eine Network-Voronoi-Partition des Graphen, also die diskrete Variante eines Voronoi-Diagramms, in der die Distanzfunktion nicht der euklidischen Metrik, sondern der Kantenlänge entlang des Graphen folgt (siehe Abschnitt 2.4).

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/core_msd.py"), lastline: 119),
  ),
  caption: flex-caption(
    [Kern des Multi-Source-Dijkstra für die Voronoi-Partitionierung],[]
  ),
) <lst:msd>
\

Eine Designentscheidung dieses Schritts betrifft die Behandlung von Einbahnstraßen. Der OSM-Graph ist als gerichteter Multigraph (MultiDiGraph) modelliert, in dem Einbahnstraßen entsprechend nur in einer Richtung passierbar sind. Für die Voronoi-Partitionierung wird der Graph jedoch durch die Methode to_undirected() zu einem ungerichteten Graphen reduziert. Dieser Schritt ist gerechtfertigt, weil die Voronoi-Zugehörigkeit eines Knotens eine räumliche Eigenschaft ist und keine routenabhängige Größe. Würde die Partitionierung Einbahnstraßen respektieren, könnten sich entlang asymmetrischer Straßen ungewollt streifenartige Cluster bilden, die nicht der geographischen Nachbarschaft entsprechen. Da die Partitionierung ausschließlich der Strukturierung des Suchraums dient und nicht der Vorberechnung von Routen, ist die Reduktion auf den ungerichteten Graphen unkritisch.
Das Ergebnis der Cluster-Bildung wird in einem Dictionary zurückgegeben, das vier Werte enthält: die Cluster selbst (clusters als Mapping von Seed-Knoten auf Knotenliste), die inverse Zuordnung (node_region als Mapping von Knoten auf Seed), die Liste der Seeds (seed_nodes) sowie die Distanz jedes Knotens zu seinem Seed (dist). Diese vier Strukturen bilden die Eingabe für die HPA\*-Konstruktion.

=== Konstruktion des abstrakten Graphen

Auf Grundlage der Voronoi-Partition konstruiert die Klasse HPAStarPathfinder in der Methode build_abstract_graph einen abstrakten Graphen, dessen Knoten und Kanten die Cluster-Struktur explizit machen. Die Konstruktion folgt der in @Botea:2004 vorgeschlagenen Struktur, weicht jedoch in der Modellierung der Gate-Knoten ab.
In der ursprünglichen Variante von HPA\* werden für jede Cluster-Border zwei abstrakte Knoten eingeführt, einer für den Eintritt in das eine Cluster und einer für den Austritt in das benachbarte. Diese Verdopplung ist sinnvoll für gitterbasierte Karten mit breiten Border-Bereichen, in denen sich Entry- und Exit-Punkt geographisch unterscheiden können. Auf einem OSM-Straßennetz hingegen ist die Cluster-Border keine flächige Region, sondern eine einzelne Kante zwischen zwei Knoten in unterschiedlichen Clustern. Die Verdopplung wäre hier inhaltsleer; jeder OSM-Knoten, der Endpunkt einer cluster-überschreitenden Kante ist, wird daher als ein einzelner abstrakter Knoten modelliert und übernimmt sowohl die Rolle des Exits aus seinem eigenen Cluster als auch die des Entries für das benachbarte.
Die Konstruktion läuft in zwei Durchgängen. Im ersten Durchgang werden alle Kanten des OSM-Graphen daraufhin geprüft, ob sie zwischen Knoten verschiedener Cluster verlaufen. Trifft das zu, werden beide Endpunkte als abstrakte Knoten registriert und durch eine Inter-Cluster-Kante mit dem Gewicht der OSM-Kantenlänge verbunden. Gleichzeitig werden die Endpunkte den Exit- und Entry-Listen ihrer jeweiligen Cluster hinzugefügt.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/inter_cluster_edges.py"), lastline: 17),
  ),
  caption: flex-caption(
    [Identifikation und Eintragung von Inter-Cluster-Kanten],[]
  ),
) <lst:inter_cluster_edges>
\

Im zweiten Durchgang werden die Intra-Cluster-Kanten ergänzt. Für jedes Cluster wird die exakte Distanz zwischen jedem Paar aus Entry- und Exit-Gate vorab über einen vollständigen A\*-Lauf bestimmt und als Kantengewicht im abstrakten Graphen hinterlegt. Diese Vorberechnung ist der teuerste Schritt der Initialisierung; ihr Aufwand wächst quadratisch in der Anzahl der Gates pro Cluster. Sie erfolgt jedoch nur einmal pro Serverstart und entlastet jede nachfolgende Query um eine entsprechende Anzahl A\*-Läufe.

Eine bewusste Vereinfachung dieser Konstruktion betrifft die Auswahl der Gates. In erweiterten Varianten von HPA\* werden Gate-Mengen durch Pruning-Verfahren reduziert, etwa indem nur die geographisch repräsentativsten Border-Knoten als Gates erhalten bleiben. Die vorliegende Implementierung verzichtet auf jegliches Pruning. Jeder Border-Knoten ist ein Gate. Diese Entscheidung folgt dem Grundsatz, dass mehr Gates die Korrektheit der abstrakten Suche begünstigen, indem sie ihr mehr Routing-Optionen geben. Pruning ist eine Optimierungsfrage und wirkt sich nicht auf die Korrektheit aus; ein systematischer Vergleich verschiedener Pruning-Strategien wird in @sec:outlook als zukünftige Arbeit vorgeschlagen.

=== Abstrakte A\*-Suche

Die zweite Phase der Query findet auf dem abstrakten Graphen statt und sucht eine optimale Sequenz von Gates vom Start- zum Zielcluster. Die Methode abstract_astar ist im Kern eine reguläre A\*-Suche mit derselben Haversine-Heuristik wie auf dem OSM-Graphen (siehe @sec:astar). Die einzige strukturelle Besonderheit liegt in der Behandlung des Start- und Zielknotens, die selbst keine Gates sind und damit nicht im abstrakten Graphen vorkommen.

In der ursprünglichen HPA\*-Variante werden Start- und Zielknoten als temporäre Gates in den abstrakten Graphen eingefügt und über A\*-Läufe innerhalb ihres jeweiligen Clusters mit den existierenden Gates verbunden. Die vorliegende Implementierung folgt diesem Ansatz mit einem Detail, das die Vorberechnung in den abstrakten Graphen wirksam überträgt.

Die Anbindungs-A\*-Läufe sind über einen optionalen Parameter node_allowlist der Low-Level-Methode a_star auf die Knotenmenge des jeweiligen Clusters beschränkt. Die A\*-Suche kann damit das Cluster nicht verlassen, was die Suchtiefe pro Anbindung scharf begrenzt.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/allowlist_filter.py"), lastline: 5),
  ),
  caption: flex-caption(
    [Optionale Knotenmengen-Beschränkung in der Low-Level-A\*-Schleife],[]
  ),
) <lst:allowlist_filter>
\

Diese Komposition ist ein Vorteil der generischen A\*-Implementierung. Die HPA\*-Schicht benötigt keine eigene Variante einer Intra-Cluster-Suche, sondern parametriert dieselbe Methode durch eine Knotenmenge. Eine frühere Variante der Implementierung verwendete an dieser Stelle eine Approximation, die die Distanz vom Startknoten zum Gate als Summe der Voronoi-Distanzen $"dist"["start"] + "dist"["gate"]$ ausdrückte. Diese Summe entspricht der Distanz über den Cluster-Seed und überschätzt im Allgemeinen die echte direkte Distanz. Da A\* für die Optimalitätsgarantie eine zulässige, also nicht überschätzende Heuristik benötigt, hätte diese Approximation den von HPA\* gefundenen Pfad gegenüber dem von Standard-A\* gefundenen suboptimal werden lassen. Die jetzige Implementierung mit echten, cluster-beschränkten A\*-Läufen erhält die Optimalität strikt, allerdings zum Preis einer messbaren Anbindungs-Latenz pro Query, die in @evaluation untersucht wird.

Der Aufbau des Heaps für die abstrakte Suche erfolgt entsprechend, indem für jedes Exit-Gate des Startclusters die echte Distanz vom Startknoten bestimmt und mit der Haversine-Heuristik zum Zielknoten zu einem f-Wert kombiniert wird. Symmetrisch wird für jedes Entry-Gate des Zielclusters die echte Distanz zum Zielknoten vorab berechnet und in einem Dictionary end_extra hinterlegt. Erreicht die Suche während der Expansion ein Entry-Gate des Zielclusters, wird durch Addition von end_extra ein Kandidat für die Gesamtkosten gebildet und mit dem bisher besten Kandidaten verglichen. Die Suche terminiert, sobald der nächste aus dem Heap entnommene f-Wert diesen besten Gesamtwert nicht mehr unterbieten kann.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/endpoint_attach_astar.py"), lastline: 13),
  ),
  caption: flex-caption(
    [Aufbau der echten Anbindungs-Distanzen für Start- und Zielknoten],[]
  ),
) <lst:endpoint_attach>
\

=== Verfeinerung der abstrakten Pfadsequenz

Die abstrakte Suche liefert eine Sequenz von Gate-Knoten, die das Skelett des endgültigen Pfades bildet. In der dritten Phase wird diese Sequenz in einen vollständigen OSM-Pfad überführt, indem zwischen aufeinanderfolgenden Gates die konkreten Zwischenknoten ergänzt werden.

Die Verfeinerung unterscheidet zwei Fälle anhand des inter-Attributs der abstrakten Kante. Eine Inter-Cluster-Kante repräsentiert die direkte OSM-Verbindung zwischen zwei Gates verschiedener Cluster und wird durch eine einzelne Kantentraversierung aufgelöst, ohne dass weitere Knoten zu durchsuchen sind. Eine Intra-Cluster-Kante hingegen repräsentiert die vorberechnete kürzeste Verbindung zwischen zwei Gates desselben Clusters; ihr konkreter Verlauf muss zur Query-Zeit durch einen weiteren A\*-Lauf rekonstruiert werden. Eine Vorberechnung auch der konkreten Knotenfolgen aller Gate-Paare wäre möglich, würde aber den Speicherbedarf der Vorberechnung deutlich erhöhen, ohne die Query-Antwortzeit substanziell zu verändern.

Die Verfeinerungs-A\*-Läufe nutzen die unveränderte Low-Level-Methode ohne node_allowlist. Da Start- und Zielknoten dieser Sub-Anfragen jeweils Gates sind und der direkte Pfad zwischen ihnen per Konstruktion innerhalb eines Clusters verläuft, ist eine Beschränkung nicht erforderlich. Die Statistiken jedes Sub-Laufs werden zu den Gesamtstatistiken der Query addiert, sodass Größen wie visited_nodes_count am Ende den Gesamtaufwand aller Phasen widerspiegeln.

Eine während der Entwicklung als Debug-Hilfe entstandene zweite Verfeinerungsvariante (hpa_star_partial_generator) führt A\*-Läufe nur im Start- und Zielcluster durch und überspringt die mittleren Cluster, indem sie deren Gates direkt aneinanderreiht. Diese Variante ist nicht Teil der Evaluation und bleibt hier nur der Vollständigkeit halber erwähnt.

=== Erfasste Metriken

HPA\* erfasst zusätzlich zu den in @sec:astar beschriebenen A\*-Metriken vier Größen, die die spezifische Struktur des Algorithmus widerspiegeln. Tabelle 5.2 fasst sie zusammen.

#figure(
  caption: [Zusätzliche Laufzeitmetriken der HPA\*-Implementierung.],
  table(
    columns: (auto, 1fr),
    align: (left, left),
    table.header[Metrik][Bedeutung],
    [precomputation_ms], [Dauer der einmaligen Konstruktion des abstrakten Graphen beim Serverstart, einschließlich der Vorberechnung aller Intra-Cluster-Distanzen.],
    [abstract_search_ms], [Dauer der reinen abstrakten A\*-Suche in der Query-Phase, ohne die Anbindungs-A\*-Läufe für Start und Ziel.],
    [abstract_search_nodes_visited], [Anzahl der im abstrakten Graphen expandierten Gate-Knoten.],
    [refinement_ms], [Dauer der Verfeinerung, also der Summe aller Sub-A\*-Läufe zwischen den Gates der abstrakten Pfadsequenz.],
    [gate_crossings], [Anzahl der im rekonstruierten Pfad enthaltenen Inter-Cluster-Übergänge.],
  ),
) <tbl:hpastar_metriken>

Diese Aufschlüsselung erlaubt in @evaluation eine Differenzierung des Gesamtaufwands nach Phasen. Insbesondere lässt sich der Anteil der einmaligen Vorberechnung von der wiederholten Query-Last trennen und untersuchen, ab welcher Pfadlänge der Vorberechnungsaufwand sich amortisiert.

== Visualisierung und WebSocket-Streaming <sec:visualisierung>

Eine Kernanforderung der Anwendung ist die schrittweise Live-Darstellung des Suchprozesses, nicht nur des Endergebnisses. Diese Anforderung lässt sich nicht über das klassische REST-Modell erfüllen, in dem ein einzelner Antwortkörper die vollständige Antwort transportiert. Stattdessen kommt ein bidirektionaler WebSocket-Kanal zum Einsatz, über den der Server die in @sec:astar und @sec:hpastar beschriebenen Generator-Zustände als Folge einzelner Nachrichten an den Browser streamt. Dieser Abschnitt beschreibt das verwendete Protokoll, den serverseitigen Endpunkt und die clientseitige Verarbeitung.

=== WebSocket-Protokoll

Das Protokoll ist asymmetrisch und zustandslos auf Verbindungsebene. Der Client sendet pro Anfrage eine einzelne JSON-Nachricht mit Start- und Zielkoordinaten sowie zwei optionalen Steuerparametern: realtime entscheidet, ob alle Zwischenzustände gestreamt werden oder nur das Endergebnis, und delay_ms erlaubt es, einen künstlichen Zeitversatz zwischen Nachrichten einzufügen, um die Visualisierung in der Demonstration verlangsamen zu können. Der Server antwortet mit einer Folge von Zustands-Nachrichten, deren Format unmittelbar dem in @sec:astar definierten Generator-Yield entspricht. Jede Nachricht trägt ein type-Feld mit einem von vier Werten: visiting für einen aus der Open Set entnommenen Knoten, exploring für einen erstmals oder verbessert in die Open Set eingefügten Knoten, complete für das gefundene Pfadergebnis sowie no_path für den Fall einer erfolglosen Suche. Jede Nachricht enthält zusätzlich das Feld stats mit dem aktuellen Stand der in @tbl:hpastar_metriken aufgeführten Laufzeit- und Strukturmetriken.

#let code(lang: "html", body) = highlight(
  radius: 1pt,
  extent: 0.5pt,
  fill: silver,
  top-edge: 1.1em,
  bottom-edge: -0.3em,
  raw(body, lang: lang)
)

Das Backend stellt drei separate WebSocket-Endpunkte bereit: #code("/ws") für A\*, /ws/hpa für HPA\* sowie  #code("/ws/hpa_partial") für die in @sec:hpastar erwähnte Debug-Variante. Die Trennung in eigene Endpunkte statt eines gemeinsamen Endpunkts mit Algorithmus-Parameter wurde aus Gründen der Übersichtlichkeit gewählt; alle drei Endpunkte folgen demselben Nachrichtenschema und unterscheiden sich nur in dem aufgerufenen Generator.

=== Serverseitiger Endpunkt

Die Implementierung des A\*-WebSocket-Endpunkts in main.py demonstriert das Zusammenspiel zwischen FastAPI, dem als Generator implementierten Pathfinder und dem asynchronen Versand der Zustände. @lst:ws_endpoint zeigt die wesentliche Schleife in vereinfachter Form.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/ws_endpoint.py"), lastline: 12),
  ),
  caption: flex-caption(
    [Serverseitiger A\*-WebSocket-Endpunkt],[]
  ),
) <lst:ws_endpoint>
\

Drei Eigenschaften dieser Implementierung sind hervorzuheben. Erstens benötigt der Endpunkt keinerlei algorithmusspezifischen Code; er konsumiert lediglich den Generator und reicht jeden ge-yieldeten Zustand unverändert an den WebSocket weiter. Damit wird die in @sec:architektur eingeführte Entkopplung zwischen Algorithmuslogik und Transportschicht praktisch wirksam. Zweitens erlaubt die await-basierte Schleife eine kooperative Unterbrechung zwischen den einzelnen Sendevorgängen, sodass das delay_ms-Throttling ohne aktives Warten realisiert werden kann. Drittens würde derselbe Generator bei einem nicht-streamenden REST-Endpunkt schlicht zu Ende konsumiert und nur der letzte Zustand zurückgegeben, ohne dass am Generator-Code etwas verändert werden müsste. Die in main.py vorhandenen REST-Endpunkte /path, /hpa_path und der Benchmark-Adapter aus @sec:hpastar nutzen genau dieses Muster.

=== Clientseitige Verarbeitung

Auf der Clientseite ist die Visualisierung im Vue-3-Composable usePathfinder.ts zentralisiert. Das Composable kapselt für jeden Algorithmus eine eigene WebSocket-Verbindung sowie drei Leaflet-LayerGroup-Objekte: einen für besuchte Knoten (rote Punkte), einen für in die Open Set eingefügte Knoten (magenta Punkte) und einen für den finalen Pfad (Polyline in algorithmus-spezifischer Farbe). Eingehende Nachrichten werden anhand des type-Feldes auf den passenden Layer verteilt. @lst:ws_client zeigt diese Logik in komprimierter Form.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/ws_client.ts"), lastline: 30),
  ),
  caption: flex-caption(
    [Clientseitige Verarbeitung der WebSocket-Nachrichten],[]
  ),
) <lst:ws_client>
\

Die Verwendung getrennter Layer pro Nachrichtentyp ermöglicht es dem Benutzer, einzelne Visualisierungsebenen über Schaltflächen ein- und auszublenden, ohne die zugrunde liegenden Daten neu anfordern zu müssen. Da Leaflet-LayerGroups Vue-reaktiv über shallowRef referenziert werden, lassen sich die Layer auch nach Verbindungsabbrüchen oder Algorithmus-Wechseln gezielt zurücksetzen, ohne die Karte als Ganzes neu zu rendern.

Auf dem in main.py konfigurierten Frontend, dargestellt in PathfinderMap.vue, werden zusätzlich die statischen Visualisierungsdaten der Vorberechnung angezeigt: Cluster-Polygone, Seed-Knoten, Cluster-Border-Kanten (Gates) sowie der vollständige abstrakte Graph. Diese Daten werden beim Mount der Komponente einmalig per REST über die Endpunkte /clusters, /seeds, /gates und /abstract_graph bezogen und als eigene Leaflet-Layer eingeblendet. Sie verändern sich während einer Pfadsuche nicht und erfordern daher kein Streaming.

#todo("Abbildung 5.2: Screenshot der Live-Visualisierung mit aktiver A*-Suche, sichtbaren Cluster-Layern und Statistik-Panel.")

== REST-API <sec:rest>

Neben den in @sec:visualisierung beschriebenen WebSocket-Endpunkten stellt das Backend eine konventionelle REST-API bereit, die für nicht-streamende Pfadanfragen, den Abruf statischer Visualisierungsdaten und die Persistenz von Benchmark-Ergebnissen genutzt wird. Alle Endpunkte sind in main.py definiert und nutzen FastAPIs Pydantic-basierte Request- und Response-Modellierung. Eine vollständige OpenAPI-Spezifikation wird zur Laufzeit unter /docs automatisch generiert. @tbl:rest_endpoints listet die Endpunkte gruppiert nach Funktion auf.
#show figure: set block(breakable: true)
#figure(
  caption: [REST-Endpunkte des Backends.],
  table(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header[*Methode \& Pfad*][*Gruppe*][*Beschreibung*],
    [`GET /`],                          [Karte],          [Liefert das vorberechnete Straßennetz als GeoJSON FeatureCollection für das initiale Karten-Rendering im Frontend.],
    [`POST /path`],                     [Pathfinding],    [Führt eine A\*-Suche zwischen zwei Koordinaten aus und liefert das Ergebnis als GeoJSON LineString mit Laufzeit- und Strukturmetriken in den Properties.],
    [`POST /hpa_path`],                 [Pathfinding],    [Wie /path, jedoch unter Verwendung von HPA\*.],
    [`GET /clusters`],                  [Visualisierung], [Voronoi-Cluster-Regionen als GeoJSON-Polygone (konvexe Hüllen pro Cluster).],
    [`GET /seeds`],                     [Visualisierung], [Cluster-Seed-Knoten als GeoJSON-Punkte.],
    [`GET /gates`],                     [Visualisierung], [Cluster-Border-Kanten als GeoJSON LineStrings.],
    [`GET /abstract_graph`],            [Visualisierung], [Vollständiger abstrakter Graph (Gate-Knoten und abstrakte Kanten) als GeoJSON.],
    [`GET /benchmark/runs`],            [Benchmark],      [Liste aller persistierten Benchmark-Läufe, neueste zuerst.],
    [`GET /benchmark/runs/{id}`],       [Benchmark],      [Einzelner Benchmark-Lauf mit allen zugehörigen Pfadergebnissen.],
    [`GET /benchmark/runs/{id}/geojson`],[Benchmark],     [Alle Pfade eines Laufs als GeoJSON FeatureCollection für die kartographische Auswertung.],
  ),
) <tbl:rest_endpoints>

Die Pfadendpunkte (`/path`, `/hpa_path`) konsumieren denselben Generator-Code wie die WebSocket-Endpunkte, geben jedoch nur den finalen Zustand zurück. Die Benchmark-Endpunkte sind nur verfügbar, wenn die Anwendung mit gesetzter `DATABASE_URL` gestartet wurde.

== Benchmark-Framework <sec:benchmark>

Der systematische Vergleich von A\* und HPA\* ist der zentrale empirische Beitrag dieser Arbeit. Damit der Vergleich aussagekräftig wird, ist eine Infrastruktur notwendig, die reproduzierbare Testfälle erzeugt, mehrere Algorithmen auf identischen Problemen laufen lässt und Ergebnisse für eine spätere Auswertung persistiert. Diese Infrastruktur ist als eigenständiges Python-Paket Benchmark im Backend organisiert und folgt methodisch dem von Sturtevant @Sturtevant:2012 vorgeschlagenen Vorgehen, übertragen auf die Eigenheiten von OSM-Straßennetzen.

=== Architektur und Designprinzipien

Das Benchmark-Paket ist um drei Designprinzipien herum aufgebaut. Erstens ist die Steuerung vollständig algorithmus-agnostisch: Weder der Problem-Generator noch der Runner kennen die konkreten Klassen AStarPathfinder oder HPAStarPathfinder. Beide kommunizieren ausschließlich über ein schlankes Protokoll, das in @lst:pathfinder_protocol gezeigt wird.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/pathfinder_protocol.py"), lastline: 6),
  ),
  caption: flex-caption(
    [Algorithmus-agnostisches Protokoll für alle benchmarkbaren Pathfinder],[]
  ),
) <lst:pathfinder_protocol>
\

Zweitens existiert für jeden konkreten Algorithmus genau ein Adapter (`AStarAdapter`, `HPAStarAdapter`), dessen einzige Aufgabe es ist, den jeweiligen Generator vollständig zu konsumieren und das letzte ge-yieldete Zustands-Objekt in ein einheitliches PathResult-Datenobjekt zu überführen. Das Hinzufügen eines neuen Algorithmus zum Benchmark erfordert daher das Schreiben einer einzigen neuen Adapter-Klasse, ohne Änderungen am Runner, am Problem-Generator oder am Reporting.

Drittens ist die Trennung zwischen einmaliger Problem-Generierung und wiederholter Problem-Ausführung explizit. Eine Problemmenge wird einmal erzeugt, als JSON-Datei persistiert und kann anschließend beliebig oft gegen verschiedene Algorithmen-Mengen oder Konfigurationen ausgeführt werden, ohne die Stichprobe selbst zu verändern. Diese Trennung ist Voraussetzung für reproduzierbare Vergleiche zwischen Konfigurationen.

=== Problem-Generierung

Die Erzeugung der Testfälle folgt dem Vorgehen aus Sturtevant 2012, §III. Aus der größten schwach zusammenhängenden Komponente des Graphen werden zufällige Knotenpaare gezogen. Für jedes Paar wird mittels einer Referenz-A\*-Suche die optimale Pfadlänge bestimmt. Die Probleme werden anschließend nach optimaler Distanz in äquidistante Buckets einsortiert (Standardbreite 500 m), und pro Bucket werden bis zu `max_per_bucket` Probleme aufgenommen. @lst:bucketing zeigt die zugehörige Schleife.

#figure(
  align(
    left,
    fhjcode(code: read("/code-snippets/bucketing.py"), lastline: 15),
  ),
  caption: flex-caption(
    [Distance-Bucketing nach Sturtevant 2012],[]
  ),
) <lst:bucketing>
\

Zwei Eigenschaften dieses Vorgehens verdienen Erwähnung. Erstens stellt die Bucketing-Stratifikation sicher, dass die Stichprobe das gesamte Spektrum von Pfadlängen abdeckt und nicht durch die natürliche Häufigkeitsverteilung kurzer Pfade in dichten Stadtnetzen verzerrt wird. Ohne Bucketing wäre die Mehrheit zufällig gezogener Paare relativ kurz, da kurze Pfade in einem urbanen Graphen weit häufiger sind als lange. Für die Untersuchung der erwarteten Vorteile von HPA\* bei langen Pfaden ist eine ausreichende Repräsentation der höheren Distanzklassen jedoch zentral.

Zweitens behält der Generator nur die größte zusammenhängende Sequenz vollständig gefüllter Buckets. Buckets, die nicht voll werden, etwa weil im untersuchten Graphausschnitt keine Pfade dieser Länge möglich sind, werden ebenso entfernt wie Lücken im Spektrum. Damit wird sichergestellt, dass alle Algorithmen über einen vergleichbaren, lückenlosen Distanzbereich evaluiert werden.

=== Metriken

Das Benchmark-Framework erhebt zwei Klassen von Metriken. Die erste Klasse umfasst pro Anfrage erhobene algorithmische Metriken, die direkt aus den Generator-Statistiken stammen und in @sec:astar (Tabelle 5.1) sowie in @tbl:hpastar_metriken aufgeführt sind. Aus diesen werden im Runner zwei abgeleitete Größen pro Pfadergebnis berechnet, die in @tbl:derived_metrics zusammengefasst sind.

#figure(
  caption: [Im Runner abgeleitete Metriken pro Pfadergebnis.],
  table(
    columns: (auto, 1fr),
    align: (left, left),
    table.header[Metrik][Bedeutung],
    [`suboptimality_ratio`], [Verhältnis der vom Algorithmus gefundenen Pfadlänge zur optimalen, durch die Referenz-A\*-Suche bestimmten Pfadlänge @Botea:2004[S.~18]. Werte von 1.0 entsprechen optimalen Pfaden; Werte größer 1.0 quantifizieren den Optimalitätsverlust einer heuristischen Variante. Die Metrik entspricht der von Botea et al. definierten Fehlerformel $e = (h_l - o_l) / o_l dot 100$, ausgedrückt als Verhältnis statt als Prozentwert.],
    [`detour_factor`], [Verhältnis der gefundenen Pfadlänge zur Luftlinien-Distanz (Haversine) zwischen Start und Ziel. Charakterisiert die Topologie des Straßennetzes im Bereich des konkreten Pfades und ist algorithmen-übergreifend konstant für ein gegebenes Problem.],
  ),
) <tbl:derived_metrics>

Die zweite Klasse umfasst Map-Level-Metriken, die das untersuchte Straßennetz als Ganzes charakterisieren und somit die Vergleichbarkeit von Ergebnissen zwischen verschiedenen geographischen Ausschnitten ermöglichen. Diese Metriken folgen Sturtevant @Sturtevant:2012, §IV, und sind in @tbl:map_metrics aufgeführt.

#figure(
  caption: [Map-Level-Metriken nach Sturtevant 2012, §IV.],
  table(
    columns: (auto, 1fr),
    align: (left, left),
    table.header[Metrik][Bedeutung],
    [`num_states`, `num_edges`], [Anzahl Knoten und Kanten des Graphen.],
    [`estimated_max_path_m`], [Heuristische obere Schranke des längsten kürzesten Pfades im Graphen, ermittelt durch ein Double-Sweep-Verfahren.],
    [`dimension`], [Quadratischer Koeffizient einer Polynom-Regression über die kumulative BFS-Frontgröße (§IV.D). Werte nahe Null deuten auf eindimensionale Strukturen wie ländliche Hauptstraßen hin, größere Werte auf zweidimensionale Stadtnetze.],
    [`transit_node_count`], [Mittlere Anzahl von Transit-Knoten in einem festen Radius (§IV.C), berechnet bei zwei verschiedenen Radien. Misst die Engstellen-Charakteristik des Netzes.],
    [`heuristic_accuracy`], [Mittleres Verhältnis von Luftlinien- zu optimaler Pfaddistanz über die längsten Probleme. Werte nahe 1.0 zeigen, dass die Haversine-Heuristik den tatsächlichen Suchaufwand eng abschätzt.],
  ),
) <tbl:map_metrics>

Diese Map-Metriken sind unabhängig vom Algorithmus und werden einmal pro Graphausschnitt erhoben. Sie erlauben es in @evaluation, beobachtete Unterschiede in den Algorithmus-Metriken kausal mit strukturellen Eigenschaften des Netzes zu verknüpfen, anstatt sie nur als Berlin-spezifische Beobachtungen darzustellen.

=== CLI-Workflow

Das Benchmark-Paket ist als ausführbares Python-Modul (`python -m Benchmark`) konzipiert und stellt vier Sub-Kommandos bereit. @tbl:benchmark_cli fasst sie zusammen.

#figure(
  caption: [Sub-Kommandos der Benchmark-CLI.],
  table(
    columns: (auto, 1fr),
    align: (left, left),
    table.header[Kommando][Funktion],
    [`generate`], [Erzeugt eine stratifizierte Problemmenge und persistiert sie als JSON-Datei. Parameter steuern Stichprobengröße, Bucket-Breite und Maximum pro Bucket.],
    [`run`], [Führt eine ausgewählte Algorithmen-Menge auf einer geladenen Problemmenge aus, schreibt die rohen Ergebnisse als JSON oder CSV und speichert den Lauf bei vorhandener Datenbankverbindung als Benchmark-Run.],
    [`metrics`], [Berechnet Map-Level-Metriken (@tbl:map_metrics) für einen Graphausschnitt und gibt sie als JSON aus.],
    [`report`], [Aggregiert eine zuvor gespeicherte Ergebnisdatei zu einer Bucket-weisen Zusammenfassung und gibt sie als JSON oder CSV aus.],
  ),
) <tbl:benchmark_cli>

Die Aufteilung in vier Kommandos folgt der oben beschriebenen Trennung von Problem-Generierung, Ausführung und Reporting. In der Praxis besteht ein typischer Evaluations-Workflow aus einem einmaligen `generate`-Lauf pro Graphausschnitt, einem oder mehreren `run`-Aufrufen für die zu vergleichenden Algorithmen-Konfigurationen und abschließenden `metrics`- und `report`-Aufrufen für die statistische Auswertung.

=== Persistenz der Ergebnisse <sec:datenbank>

Die Benchmark-Ergebnisse werden optional in einer PostgreSQL-16-Datenbank persistiert, um Auswertungen über mehrere Läufe und Graphausschnitte hinweg zu ermöglichen. Das Schema besteht aus zwei Tabellen: `benchmark_runs` für die Lauf-Metadaten (Graphausschnitt, Algorithmen, Zeitstempel) und `benchmark_results` für die einzelnen Pfadergebnisse mit allen erfassten Metriken. Pfadkoordinaten werden als `JSONB`-Spalte gespeichert, da sie ausschließlich als Ganzes gelesen werden.

Die Datenbankanbindung ist optional. Ist die Umgebungsvariable `DATABASE_URL` nicht gesetzt, läuft der Server ohne Persistenz und die Benchmark-Endpunkte sind deaktiviert. Die Pathfinding-Funktionalität bleibt davon unberührt.

== Containerisierung <sec:container>

Die in den vorausgegangenen Abschnitten beschriebenen Komponenten werden als voneinander isolierte Container bereitgestellt und über Docker Compose orchestriert. Die zentrale Datei `docker-compose.yml` im Projekt-Root deklariert die beteiligten Dienste, ihre Abhängigkeiten und die zwischen Hostsystem und Containern geteilten Verzeichnisse. Die Containerisierung erfüllt in der vorliegenden Arbeit zwei zentrale Funktionen: Sie sichert die Reproduzierbarkeit der Benchmark-Umgebung und beseitigt Versionskonflikte zwischen den Laufzeiten von Backend (Python 3.11), Frontend (Node.js für Nuxt 4) und Dokumentation (Node.js für VitePress).

=== Dienste

Die Compose-Konfiguration umfasst vier Dienste. Der Dienst `postgres` läuft auf dem offiziellen `postgres:16`-Image und stellt die in @sec:datenbank beschriebene Persistenzschicht bereit. Der Dienst `backend` baut das in `./backend/Dockerfile` definierte Image mit der FastAPI-Anwendung samt OSMnx-, NetworkX- und asyncpg-Abhängigkeiten. Der Dienst `frontend` baut analog das Nuxt-4-Projekt aus `./frontend/Dockerfile` und bedient den in @sec:visualisierung beschriebenen Browser-Client. Der vierte Dienst `docs` rendert eine begleitende VitePress-Dokumentation des Projekts. Diese Dokumentation ist nicht Bestandteil der wissenschaftlichen Arbeit; sie unterstützt während der Entwicklung das Nachschlagen von API-Konventionen und ist im laufenden System unter Port 4000 erreichbar.

Jeder Dienst wird auf einen Host-Port abgebildet (`8000` für das Backend, `3000` für das Frontend, `5432` für PostgreSQL, `4000` für die Dokumentation), sodass die Komponenten gleichzeitig vom Hostsystem aus zugänglich sind. Diese Port-Aufteilung dient ausschließlich der Entwicklungsumgebung. In einer produktiven Bereitstellung würde der direkte Zugriff auf den Datenbank-Port unterbunden und ausschließlich das Frontend hinter einem Reverse-Proxy exponiert.

=== Volumes und Persistenz

Drei benannte Volumes regeln die Persistenz von Daten, die einen Container-Neubau überdauern müssen. Das Volume `postgres-data` ist an `/var/lib/postgresql/data` gebunden und enthält den eigentlichen Datenbankzustand. Das Volume `backend-data` enthält die in @sec:datenbeschaffung beschriebene GraphML-Datei, sodass nach einem Neustart der OSM-Graph nicht erneut über die Overpass-API bezogen werden muss; angesichts der Größe des Berliner Untersuchungsgebiets (siehe @sec:datenbeschaffung) erspart diese Persistenz pro Neustart mehrere Sekunden Wartezeit und entlastet zugleich die externe Overpass-Infrastruktur. Das Volume `backend-cache` enthält den HTTP-Cache von OSMnx selbst und greift auf einer tieferen Ebene als der GraphML-Cache: Er konserviert die Antworten einzelner Overpass-Anfragen, die OSMnx beim Aufbau eines Graphen stellt, und ist insbesondere dann relevant, wenn weitere Untersuchungsgebiete mit teils überlappenden Bounding-Boxes geladen werden.

Eine andere Rolle übernimmt der Bind-Mount `./backend/app:/app`, der das Quellverzeichnis des Backends direkt in den Container einblendet. Dadurch übernimmt der Container Änderungen am Quellcode ohne Neubau des Images; diese Hot-Reload-Konfiguration ist auf die Entwicklung zugeschnitten und entfällt in einem produktiven Image, das den Code stattdessen in das Image kopiert. Eine analoge Konfiguration besteht für das Frontend, in der zusätzlich ein anonymes Volume `/app/node_modules` den Bind-Mount überdeckt; ohne diese Überlagerung würde das im Container installierte `node_modules` durch das im Hostsystem unter Umständen leere Verzeichnis verdrängt, was den Frontend-Build unmittelbar funktionsunfähig machen würde.

#figure(
  caption: [Volume-Übersicht des Compose-Stacks.],
  table(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header[*Volume*][*Typ*][*Zweck*],
    [`postgres-data`],          [Named],     [Datenbank-Zustand für Benchmark-Persistenz aus @sec:datenbank.],
    [`backend-data`],           [Named],     [GraphML-Cache (`graph.graphml`) zur Vermeidung wiederholter Overpass-Anfragen.],
    [`backend-cache`],          [Named],     [OSMnx-eigener HTTP-Antwort-Cache.],
    [`./backend/app:/app`],     [Bind],      [Hot-Reload des Backend-Quellcodes während der Entwicklung.],
    [`./frontend:/app`],        [Bind],      [Hot-Reload des Frontend-Quellcodes.],
    [`/app/node_modules`],      [Anonym],    [Schutz der containerseitigen Node-Abhängigkeiten vor dem Frontend-Bind-Mount.],
  ),
) <tbl:volumes>

=== Service-Abhängigkeiten und Konfiguration

Die Reihenfolge des Container-Starts ist über `depends_on` zwischen den Diensten festgelegt. Der Backend-Container startet erst, wenn der Postgres-Container den definierten Healthcheck `pg_isready -U pfad -d pfadgenossin` erfolgreich besteht, und nicht bereits dann, wenn der Postgres-Prozess gestartet ist. Diese Unterscheidung ist relevant, weil PostgreSQL nach dem Prozess-Start eine kurze, aber nicht zu vernachlässigende Initialisierungsphase durchläuft, in der eingehende Verbindungen abgewiesen werden. Ohne den Healthcheck würde der asyncpg-Pool im Lifespan-Handler aus @sec:datenbank gelegentlich auf eine noch nicht annahmebereite Datenbank treffen und mit einem Verbindungsfehler abbrechen. Der Frontend-Container ist analog vom Backend abhängig, allerdings ohne Healthcheck, da das Frontend einen kurzzeitig nicht verfügbaren Backend-Endpunkt vorübergehend toleriert und der Benutzer im Zweifelsfall ein erneutes Laden auslösen kann.

Konfigurationsparameter werden über Umgebungsvariablen mit Defaultwerten an die Container weitergereicht. Die Syntax `${VAR:-default}` in der Compose-Datei erlaubt es, dieselbe Konfiguration sowohl mit als auch ohne lokale `.env`-Datei zu starten. Drei Variablen sind dabei relevant: `DATABASE_URL` adressiert den Postgres-Dienst aus dem Backend-Container heraus über den Compose-internen DNS-Namen `postgres`; `CORS_ORIGINS` legt die zulässigen Frontend-Ursprünge für die in @sec:rest beschriebenen REST-Endpunkte fest; `NUXT_PUBLIC_API_BASE` informiert das Frontend über die zur Laufzeit gültige Backend-Adresse. Die Default-Werte zielen auf die lokale Entwicklung ab; produktive Deployments setzen die Variablen in einer Umgebungsdatei oder über das verwendete Deployment-Werkzeug.

Eine bewusste Eigenschaft des Stacks ist die Beschränkung auf Docker Compose anstelle eines Cluster-Orchestrators wie Kubernetes. Compose ist für Einzelhost-Stacks wie die hier vorliegende Entwicklungs- und Evaluationsumgebung deklarativ ausreichend; die zusätzlichen Garantien eines Cluster-Orchestrators bezüglich Skalierung, Lastverteilung und Selbstheilung wären für die im Rahmen dieser Arbeit durchgeführten, sequenziellen Benchmark-Läufe ohne Wirkung. Eine Migration auf Kubernetes wäre möglich, ist aber nicht Gegenstand der vorliegenden Implementierung.