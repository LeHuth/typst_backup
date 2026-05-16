// * Add list of terms

#let gls-entries = (
    // --- Existing entries ---
    (
      key: "gc", short: "GC", long: "Garbage Collection", description: [Garbage collection is the common name for the term automatic memory management.],
    ),
    (
      key: "cow", short: "COW", long: "Copy on Write", description: [Copy on Write is a memory allocation strategy where arrays are copied if they
        are to be modified.],
    ),
    (
      key: "svg", short: "SVG", long: "Scalable Vector Graphics", description: [A vector image format.],
    ),
    (
      key: "csv", short: "CSV", long: "Comma-separated Values", description: [A human readable, plain text file format using commas to separate the values.],
    ),

    // --- Algorithmen & Datenstrukturen ---
    (
      key: "astar", short: "A*", long: "A*-Algorithmus", description: [Heuristischer Shortest-Path-Algorithmus, der eine Schätzfunktion (Heuristik) nutzt, um den Suchraum gegenüber Dijkstra zu reduzieren.],
    ),
    (
      key: "hpastar", short: "HPA*", long: "Hierarchical Pathfinding A*", description: [Hierarchische Erweiterung von A\*, die den Graphen in Cluster unterteilt und Pfade auf mehreren Abstraktionsebenen berechnet.],
    ),
    (
      key: "bfs", short: "BFS", long: "Breadth-First Search", description: [Breitensuche – ein Graphdurchlaufverfahren, das alle Knoten ebenenweise ausgehend vom Startknoten besucht.],
    ),
    (
      key: "ch", short: "CH", long: "Contraction Hierarchies", description: [Vorberechnungsbasierte Technik zur beschleunigten Kürzeste-Wege-Berechnung. Knoten werden schrittweise kontrahiert und Shortcut-Kanten eingefügt.],
    ),
    (
      key: "alt", short: "ALT", long: "A*, Landmarks, Triangle Inequality", description: [Beschleunigungsverfahren für Shortest-Path-Suche, das vorberechnete Distanzen zu ausgewählten Landmark-Knoten als admissible Heuristik verwendet.],
    ),
    (
      key: "dijkstra", short: "Dijkstra", long: "Dijkstra-Algorithmus", description: [Klassischer Algorithmus zur Berechnung kürzester Wege in gewichteten Graphen ohne negative Kantengewichte.],
    ),
    (
      key: "priority-queue", short: "Priority Queue", long: "Prioritätswarteschlange", description: [Datenstruktur, in der Elemente nach ihrem Prioritätswert geordnet entnommen werden. In A\* und Dijkstra meist als Min-Heap realisiert.],
    ),
    (
      key: "min-heap", short: "Min-Heap", long: "Min-Heap", description: [Binärer Heap, bei dem das Element mit dem kleinsten Schlüssel stets an der Wurzel liegt. Ermöglicht Einfügen und Minimum-Extraktion in O(log n).],
    ),
    (
      key: "lazy-deletion", short: "Lazy Deletion", long: "Lazy Deletion", description: [Heap-Strategie, bei der Elemente nicht sofort gelöscht, sondern beim Entnehmen als veraltet markiert und übersprungen werden.],
    ),
    (
      key: "decrease-key", short: "Decrease-Key", long: "Decrease-Key", description: [Heap-Operation, die den Schlüssel eines bereits enthaltenen Elements verringert und die Heap-Eigenschaft wiederherstellt.],
    ),

    // --- Graphentheorie & Routenplanung ---
    (
      key: "nvd", short: "NVD", long: "Network Voronoi Diagram", description: [Voronoi-Zerlegung auf einem Graphen: Jedem Knoten wird das nächstgelegene Seed zugewiesen, gemessen in Graphdistanz.],
    ),
    (
      key: "gate-node", short: "Gate Node", long: "Gate Node", description: [Grenzknoten zwischen zwei Clustern in HPA\*. Entry-Gates liegen auf der eingehenden Seite, Exit-Gates auf der ausgehenden Seite eines Clusters.],
    ),
    (
      key: "cluster", short: "Cluster", long: "Cluster", description: [Zusammenhängende Partition des Straßengraphen, gebildet durch Voronoi-Zerlegung um Seed-Knoten.],
    ),
    (
      key: "seed-node", short: "Seed Node", long: "Seed Node", description: [Startknoten der Voronoi-Partitionierung. Jeder Cluster wird ausgehend von einem Seed-Knoten durch Multi-Source-Dijkstra aufgebaut.],
    ),
    (
      key: "shortcut-edge", short: "Shortcut Edge", long: "Shortcut-Kante", description: [Direkte Kante zwischen zwei Knoten, die einen längeren Pfad über zwischenliegende Knoten ersetzt (z. B. in Contraction Hierarchies).],
    ),
    (
      key: "search-space", short: "Suchraum", long: "Suchraum", description: [Menge aller Knoten, die ein Pathfinding-Algorithmus während der Suche exploriert oder öffnet.],
    ),
    (
      key: "detour-factor", short: "Detour-Faktor", long: "Detour-Faktor", description: [Verhältnis der tatsächlichen Pfadlänge zur Luftlinienentfernung zwischen Start und Ziel. Ein Wert von 1,0 entspricht dem direkten Weg.],
    ),
    (
      key: "heuristic", short: "Heuristik", long: "Heuristik", description: [Schätzfunktion in informierten Suchalgorithmen, die die verbleibende Distanz zum Ziel abschätzt. Eine admissible Heuristik überschätzt nie die tatsächliche Distanz.],
    ),
    (
      key: "haversine", short: "Haversine-Distanz", long: "Haversine-Distanz", description: [Formel zur Berechnung der Großkreisentfernung zwischen zwei Punkten auf einer Kugelober­fläche anhand Längen- und Breitengrad.],
    ),
    (
      key: "adjacency-list", short: "Adjazenzliste", long: "Adjazenzliste", description: [Graphrepräsentation, bei der für jeden Knoten eine Liste seiner Nachbarknoten (und ggf. Kantengewichte) gespeichert wird. Speichereffizient bei dünn besetzten Graphen.],
    ),
    (
      key: "adjacency-matrix", short: "Adjazenzmatrix", long: "Adjazenzmatrix", description: [n×n-Matrix zur Darstellung eines Graphen mit n Knoten. Eintrag (i, j) gibt das Gewicht der Kante von i nach j an.],
    ),
    (
      key: "weighted-graph", short: "Gewichteter Graph", long: "Gewichteter Graph", description: [Graph, in dem jede Kante ein numerisches Gewicht (z. B. Distanz oder Fahrzeit) trägt.],
    ),
    (
      key: "directed-graph", short: "Gerichteter Graph", long: "Gerichteter Graph", description: [Graph, in dem Kanten eine Richtung besitzen (Einbahnstraßen entsprechen gerichteten Kanten).],
    ),
    (
      key: "abstract-graph", short: "Abstrakter Graph", long: "Abstrakter Graph", description: [Vereinfachte Graphdarstellung auf höherer Abstraktionsebene, z. B. bestehend nur aus Gate Nodes und Inter-Cluster-Kanten in HPA\*.],
    ),
    (
      key: "refinement", short: "Verfeinerung", long: "Verfeinerung (Refinement)", description: [Schritt in hierarchischen Pathfinding-Verfahren, bei dem ein abstrakter Pfad in einen konkreten Pfad auf dem Originalgraphen überführt wird.],
    ),
    (
      key: "precomputation", short: "Vorberechnung", long: "Vorberechnung (Precomputation)", description: [Offline-Berechnung von Hilfsdaten (z. B. Cluster, Gate-Distanzen), die zur Laufzeit die Anfragebeantwortung beschleunigt.],
    ),
    (
      key: "intra-cluster-edge", short: "Intra-Cluster-Kante", long: "Intra-Cluster-Kante", description: [Kante, deren beide Endknoten demselben Cluster angehören.],
    ),
    (
      key: "inter-cluster-edge", short: "Inter-Cluster-Kante", long: "Inter-Cluster-Kante", description: [Kante, die zwei verschiedene Cluster verbindet und damit als Gate-Verbindung fungiert.],
    ),

    // --- Geodaten & Koordinaten ---
    (
      key: "osm", short: "OSM", long: "OpenStreetMap", description: [Freies, kollaborativ erstelltes Kartenprojekt mit weltweiten Geodaten, die unter der Open Database License (ODbL) stehen.],
    ),
    (
      key: "wgs84", short: "WGS84", long: "World Geodetic System 1984", description: [Internationales Referenzkoordinatensystem für GPS, das Längen- und Breitengrad sowie Höhe definiert.],
    ),
    (
      key: "utm", short: "UTM", long: "Universal Transverse Mercator", description: [Kartenprojektionssystem, das die Erde in 60 Zonen unterteilt und Koordinaten in Metern auf einer ebenen Fläche darstellt.],
    ),
    (
      key: "geojson", short: "GeoJSON", long: "GeoJSON", description: [Auf JSON basierendes Datenformat zur Kodierung geografischer Strukturen wie Punkte, Linien und Polygone.],
    ),
    (
      key: "bounding-box", short: "Bounding Box", long: "Bounding Box", description: [Achsenparalleles Rechteck, das einen geografischen Bereich umschließt und durch minimale/maximale Längen- und Breitengrade definiert wird.],
    ),
    (
      key: "odbl", short: "ODbL", long: "Open Database License", description: [Offene Datenbankli­zenz unter der OpenStreetMap-Daten veröffentlicht werden. Sie erlaubt freie Nutzung und Weitergabe unter gleichen Bedingungen.],
    ),
    (
      key: "gps", short: "GPS", long: "Global Positioning System", description: [Satellitengestütztes Navigationssystem zur weltweiten Positionsbestimmung auf Basis von WGS84-Koordinaten.],
    ),
    (
      key: "graphml", short: "GraphML", long: "GraphML", description: [XML-basiertes Dateiformat zur Beschreibung von Graphen inklusive Knoten- und Kantenattributen.],
    ),
    (
          key: "overpassapi", short: "Overpass-API", long: "Overpass-API", description: [Abfrageschnittstelle für OpenStreetMap-Daten, die es ermöglicht, gezielt Teilmengen der OSM-Datenbank nach räumlichen und attributiven Kriterien zu extrahieren.],
        ),

    // --- Technologie-Stack ---
    (
      key: "fastapi", short: "FastAPI", long: "FastAPI", description: [Modernes, asynchrones Python-Webframework zur Erstellung von REST-APIs mit automatischer OpenAPI-Dokumentation.],
    ),
    (
      key: "networkx", short: "NetworkX", long: "NetworkX", description: [Python-Bibliothek zur Erstellung, Manipulation und Analyse von Graphen und Netzwerken.],
    ),
    (
      key: "osmnx", short: "OSMnx", long: "OSMnx", description: [Python-Bibliothek zum Herunterladen und Analysieren von OpenStreetMap-Straßengraphen; gibt Graphen als NetworkX-MultiDiGraph zurück.],
    ),
    (
      key: "leaflet", short: "Leaflet.js", long: "Leaflet.js", description: [Leichtgewichtige Open-Source-JavaScript-Bibliothek zur Darstellung interaktiver Karten im Browser.],
    ),
    (
      key: "asyncio", short: "asyncio", long: "asyncio", description: [Python-Standardbibliothek für asynchrone Programmierung auf Basis von Coroutinen und Event Loops.],
    ),
    (
      key: "cors", short: "CORS", long: "Cross-Origin Resource Sharing", description: [HTTP-Mechanismus, der Browsern erlaubt, Anfragen an eine andere Domain als die der aktuellen Seite zu senden.],
    ),
    (
      key: "jsonb", short: "JSONB", long: "JSON Binary", description: [Binäres JSON-Speicherformat in PostgreSQL, das schnelle Indizierung und Abfrage von JSON-Dokumenten ermöglicht.],
    ),
    (
      key: "rest", short: "REST", long: "Representational State Transfer", description: [Architekturstil für verteilte Systeme, bei dem Ressourcen über standardisierte HTTP-Methoden (GET, POST, …) adressiert und manipuliert werden.],
    ),
    (
      key: "websocket", short: "WebSocket", long: "WebSocket", description: [Protokoll für bidirektionale, vollduplexe Kommunikation über eine einzelne TCP-Verbindung, oft für Echtzeit-Anwendungen genutzt.],
    ),
    (
      key: "openapi", short: "OpenAPI", long: "OpenAPI", description: [Maschinenlesbare Spezifikation für REST-APIs (früher Swagger), die Endpunkte, Parameter und Antwortformate beschreibt.],
    ),
    (
      key: "docker-compose", short: "Docker Compose", long: "Docker Compose", description: [Tool zur Definition und gemeinsamen Ausführung mehrerer Docker-Container mittels einer YAML-Konfigurationsdatei.],
    ),
    (
      key: "multidigraph", short: "MultiDiGraph", long: "MultiDiGraph", description: [Gerichteter Multigraph in NetworkX, der parallele Kanten zwischen denselben Knoten erlaubt – typisch für OSM-Straßendaten mit mehreren Fahrspuren.],
    ),
    (
      key: "cli", short: "CLI", long: "Command Line Interface", description: [Textbasierte Benutzeroberfläche, über die Programme durch Eingabe von Befehlen in einem Terminal gesteuert werden.],
    ),

    // --- Evaluation & Metriken ---
    (
      key: "benchmark", short: "Benchmark", long: "Benchmark", description: [Systematisches Messverfahren zur Bewertung der Leistung von Algorithmen oder Systemen unter kontrollierten Bedingungen.],
    ),
    (
      key: "speedup", short: "Speedup", long: "Speedup", description: [Verhältnis der Laufzeit eines Referenzalgorithmus zur Laufzeit des zu bewertenden Algorithmus. Ein Speedup > 1 bedeutet eine Beschleunigung.],
    ),
    (
      key: "crossover-point", short: "Crossover-Punkt", long: "Crossover-Punkt", description: [Punkt (z. B. eine Pfadlänge), ab dem ein Algorithmus A gegenüber Algorithmus B schneller wird.],
    ),
    (
      key: "build-phase", short: "Build-Phase", long: "Build-Phase", description: [Offline-Vorberechnungsphase eines Algorithmus, in der Hilfsdaten (z. B. Cluster, abstrakte Graphen) erzeugt werden.],
    ),
    (
      key: "query-phase", short: "Query-Phase", long: "Query-Phase", description: [Laufzeit-Abfragephase, in der eine einzelne Shortest-Path-Anfrage unter Nutzung vorberechneter Daten beantwortet wird.],
    ),
    (
      key: "amortisation", short: "Amortisation", long: "Amortisation", description: [Verteilung der Kosten der Build-Phase auf viele Query-Phase-Anfragen, sodass sich der Gesamtaufwand pro Anfrage reduziert.],
    ),
    (
      key: "distance-bucketing", short: "Distance Bucketing", long: "Distance Bucketing", description: [Stratifizierung von Testinstanzen nach Pfadlänge, um die Algorithmusleistung in verschiedenen Distanzbereichen getrennt auszuwerten.],
    ),
    (
      key: "transit-node", short: "Transit Node", long: "Transit Node", description: [Knoten in einem Straßennetz, über den ein großer Anteil aller Shortest Paths verläuft – typischerweise Autobahnauffahrten oder Kreuzungen mit hohem Durchsatz.],
    ),
)

// Hints:
// * Usage within text will then be #gls(<key>) or plurals #glspl(<key>)
