#import "global.typ": *

= Grundlagen


== Graphentheorie

Straßennetzwerke werden in der Informatik als mathematische Graphen modelliert. Ein Graph G ist definiert als G = (V, E), wobei V die Menge der Knoten und E die Menge der Kanten bezeichnet [Zitat: Lehrbuch Graphentheorie — TODO: geeignete Quelle suchen, z.B. Cormen et al. 2009]. Knoten repräsentieren dabei Kreuzungen und Kanten die Straßenabschnitte zwischen ihnen. Kanten können zusätzlich mit einer Gewichtsfunktion w: E → ℝ⁺ versehen werden, die beispielsweise die Länge eines Straßenabschnitts oder die benötigte Fahrzeit kodiert. Darüber hinaus können Kanten eine Richtung besitzen, wodurch sich Einbahnstraßen natürlich abbilden lassen.
Der in dieser Arbeit verwendete Straßengraph ist sowohl gerichtet als auch gewichtet. Die Kantengewichte repräsentieren die Distanz in Metern, die Richtung der Kanten kodiert die Befahrbarkeit der jeweiligen Straßenabschnitte.
Ein Pfad P von Knoten u nach Knoten v ist eine Folge von Knoten (v₁, v₂, ..., vₙ) mit v₁ = u und vₙ = v, wobei zwischen je zwei aufeinanderfolgenden Knoten eine gerichtete Kante existiert. Der kürzeste Pfad ist derjenige Pfad, für den die Summe der Kantengewichte minimal ist.
Zur Speicherung des Graphen wird eine Adjazenzliste verwendet. Eine Adjazenzmatrix würde für einen Graphen mit N Knoten einen Speicherbedarf von O(N²) erfordern, was bei der Knotenzahl eines städtischen Straßennetzwerks nicht praktikabel wäre. Straßengraphen sind dünn besetzt, da jeder Knoten im Durchschnitt nur wenige Nachbarn besitzt — eine Kreuzung hat typischerweise drei bis vier eingehende oder ausgehende Verbindungen. Die Adjazenzliste benötigt daher nur O(N + E) Speicher und ist damit die geeignete Datenstruktur für diesen Anwendungsfall.

==  Kürzeste-Wege-Algorithmen

=== Dijkstra

Der Dijkstra-Algorithmus [Zitat: Dijkstra 1959] berechnet den kürzesten Weg von einem Startknoten zu allen anderen Knoten eines gewichteten Graphen. Der Algorithmus verwaltet eine Priority Queue, die stets den Knoten mit der aktuell geringsten bekannten Distanz zum Startknoten als nächstes zur Verarbeitung bereitstellt. Auf diese Weise wird sichergestellt, dass jeder Knoten beim ersten Besuch bereits mit dem kürzesten Weg erreicht wurde. Eine notwendige Voraussetzung für die Korrektheit des Algorithmus ist, dass alle Kantengewichte nicht-negativ sind [Zitat: Dijkstra 1959].
Wird nicht der kürzeste Weg zu allen Knoten, sondern nur zu einem bestimmten Zielknoten gesucht, kann der Algorithmus abgebrochen werden sobald der Zielknoten aus der Priority Queue entnommen wird. Zu diesem Zeitpunkt ist garantiert, dass der kürzeste Weg zum Zielknoten gefunden wurde.
In der vorliegenden Implementierung wird Dijkstra in zwei unterschiedlichen Rollen eingesetzt: Im Preprocessing dient er der Berechnung optimaler Kantengewichte zwischen Gate-Node-Paaren innerhalb eines Clusters. Im Benchmarking wird er als Referenzalgorithmus ohne hierarchische Erweiterung verwendet.

=== A\*

Der A\*-Algorithmus [Zitat: Hart et al. 1968] erweitert Dijkstra um eine Heuristikfunktion h(n), die die geschätzten Kosten vom aktuellen Knoten n zum Zielknoten abschätzt. Die Bewertungsfunktion lautet:
f(n) = g(n) + h(n)
wobei g(n) die tatsächlichen Kosten vom Startknoten bis zum Knoten n bezeichnet und h(n) die heuristische Schätzung der verbleibenden Kosten bis zum Ziel. Die Priority Queue priorisiert Knoten nach ihrem f(n)-Wert, wodurch die Suche zielgerichtet erfolgt und im Vergleich zu Dijkstra deutlich weniger Knoten expandiert werden müssen [Zitat: Hart et al. 1968].
Eine Heuristik gilt als admissibel, wenn sie die tatsächlichen Kosten zum Ziel niemals überschätzt. Nur unter dieser Bedingung garantiert A\* die Optimalität des gefundenen Pfades. In der vorliegenden Implementierung wird die Haversine-Formel als Heuristik verwendet, die den Großkreisabstand zwischen zwei geografischen Koordinaten berechnet. Da die Luftliniendistanz zwischen zwei Punkten stets kleiner oder gleich der tatsächlichen Wegstrecke im Straßennetz ist, erfüllt die Haversine-Formel die Admissibilitätsbedingung.

=== Breitensuche (BFS)

==  Hierarchisches Routing

Das Grundprinzip hierarchischen Routings besteht darin, vom ursprünglichen Graphen eine abstrahierte Version zu erzeugen, auf der zunächst eine grobe Wegplanung durchgeführt wird, die anschließend schrittweise verfeinert wird [Zitat: Botea et al. 2004]. Dieser Ansatz reduziert den Suchraum erheblich, da der Großteil der Suche auf dem deutlich kleineren abstrakten Graphen stattfindet.
Die Erstellung der Hierarchie erfolgt in einer einmaligen Build-Phase. Der Graph wird zunächst in disjunkte Cluster partitioniert. Anschließend werden die Grenzknoten zwischen benachbarten Clustern als Gate Nodes definiert. Jedes Gate wird zu einem Knoten im abstrakten Graphen. Gate Nodes desselben Clusters werden durch vorberechnete Kanten verbunden, deren Gewichte den optimalen Pfadkosten zwischen diesen Gates innerhalb des Clusters entsprechen. In der vorliegenden Implementierung werden diese Kantengewichte mittels lokalem A\*, beschränkt auf die Grenzen des jeweiligen Clusters, berechnet. Diese Entscheidung stellt sicher, dass der abstrakte Graph die tatsächlichen Kosten eines A\*-Laufs abbildet, was die Vergleichbarkeit beider Algorithmen gewährleistet.
Die Vorberechnung aller Kantengewichte im abstrakten Graphen hat eine Komplexität von O(k² · A\*) pro Cluster, wobei k die Anzahl der Gate Nodes pro Cluster bezeichnet. In dicht besiedelten Regionen kann ein Cluster eine erhebliche Anzahl an Gate Nodes aufweisen, was die Vorberechnungskosten entsprechend erhöht. Produktionssysteme begegnen diesem Problem durch gezielte Gate-Selektion, die nur die relevantesten Übergänge zwischen Clustern berücksichtigt [Zitat: OsmAnd 2025].
Zur Anfragezeit wird zunächst mit A\* vom Startpunkt zum nächsten Gate des eigenen Clusters navigiert. Anschließend wird A\* auf dem abstrakten Graphen ausgeführt, wobei die durchlaufenen Cluster gespeichert werden. Nach Erreichen des Zielclusters wird erneut auf die untere Abstraktionsebene gewechselt und mit A\* zum Zielknoten navigiert. Abschließend wird für jeden durchlaufenen Cluster A\* vom Entry Gate zum Exit Gate ausgeführt, um den vollständigen Pfad zu rekonstruieren [Zitat: Botea et al. 2004].

== Network Voronoi

== OpenStreetMap als Datenbasis

OpenStreetMap (OSM) ist ein offenes, gemeinschaftlich gepflegtes Kartenprojekt, das geografische Daten unter der Open Database License (ODbL) frei zur Verfügung stellt [Zitat: OpenStreetMap Foundation — TODO: OSM-Referenz suchen, z.B. Haklay & Weber 2008]. Im Gegensatz zu kommerziellen Kartendiensten sind die Daten kostenlos zugänglich, reproduzierbar und für andere Forschende einsehbar, was OSM besonders für wissenschaftliche Arbeiten geeignet macht.
Das OSM-Datenmodell basiert auf drei Grundelementen. Nodes sind einzelne Punkte mit geografischen Koordinaten in Form von Längen- und Breitengraden und repräsentieren beispielsweise Kreuzungen oder Points of Interest. Ways sind geordnete Listen von Nodes und repräsentieren Straßen, Wege oder Flächen. Relations gruppieren mehrere Nodes, Ways oder andere Relations zu einer definierten Beziehung, etwa einer Fahrradroute. Alle drei Elemente können mit Tags versehen werden, die aus Schlüssel-Wert-Paaren bestehen, beispielsweise highway=cycleway oder oneway=yes, und semantische Informationen über das jeweilige Element kodieren.
Zur Abfrage und Verarbeitung der OSM-Daten wird in dieser Arbeit die Python-Bibliothek osmnx verwendet [Zitat: Boeing 2017 — TODO: osmnx Paper suchen]. Über die Funktion graph_from_point() wird ein Graph anhand eines Mittelpunkts, eines Radius und eines Netzwerktyps abgefragt. Als Netzwerktyp wird network_type="bike" verwendet, wodurch ausschließlich das für Fahrräder befahrbare Straßennetz geladen wird. Das Ergebnis ist ein networkx MultiDiGraph — ein gerichteter Graph der mehrere parallele Kanten zwischen denselben Knoten erlaubt, was notwendig ist da Straßenabschnitte in unterschiedlichen Richtungen verschiedene Eigenschaften besitzen können.
Standardmäßig vereinfacht osmnx den Graphen mit simplify=True: Knoten die lediglich geometrische Wegpunkte auf geraden Straßen darstellen und keine echten Kreuzungen repräsentieren, werden entfernt und die zugehörigen Kanten direkt verbunden. Dies reduziert die Graphgröße erheblich ohne die topologische Struktur des Netzwerks zu verändern. Der resultierende Graph wird im GraphML-Format lokal gespeichert, um wiederholte Abfragen der OSM-Server zu vermeiden.

== Koordinatensysteme 