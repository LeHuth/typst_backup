#import "global.typ": *

= Konzept

Dieses Kapitel entwickelt das konzeptionelle System für die hierarchische Pfadsuche und gliedert sich nach der klassischen Trennung in Struktur, Datenmodell und Dynamik. @sec:systemstruktur stellt die Komponenten und ihre statischen Beziehungen vor. @sec:datenmodell spezifiziert die zugrunde liegenden Datenstrukturen, insbesondere die Voronoi-Partitionierung des Basisgraphen und den abstrakten Graphen mit Gate Nodes. @sec:dynamik beschreibt schließlich das Zusammenspiel der Komponenten in Form der Build- und Query-Phase. Die Darstellung baut durchgehend auf den in @hierarchisches-routing eingeführten Grundlagen hierarchischen Routings auf.

== Systemstruktur <sec:systemstruktur>

Das konzeptionelle System besteht aus sechs Komponenten des Routing-Kerns und zwei zusätzlichen Komponenten der wissenschaftlichen Auswertung. Die Komponenten ordnen sich entlang ihrer Datenflussbeziehungen einander zu; der vorliegende Abschnitt stellt diese Beziehungen statisch dar. Der zeitliche Ablauf der Komponenten in Build- und Query-Phase folgt in @sec:dynamik.

#todo("Strukturabbildung erstellen und einbinden: acht Komponenten als Blöcke, Pfeile für Datenflussbeziehungen (Konsumenten zeigen auf Quellen, Visualisierung und Benchmark zeigen auf die beobachteten beziehungsweise angesteuerten Komponenten). Rein statische Sicht, keine Phasenabfolge.")

Eingangspunkt der Datenflusskette ist die Basisgraph-Quelle. Sie liefert einen gerichteten Multigraphen mit geokodierten Knoten und längengewichteten Kanten, gewonnen aus einem OSM-Extrakt. Dieser Basisgraph ist die einzige externe Eingabe des Systems; alle weiteren Komponenten leiten ihre Daten aus ihm und voneinander ab.

Die Partitionierungskomponente operiert auf dem Basisgraphen und stellt eine Cluster-Zuordnung bereit, die jedem Basisgraph-Knoten genau einen Voronoi-Cluster zuweist. Die Theorie des zugrunde liegenden Network Voronoi Diagrams ist in @voronoi-clustering ausgeführt.

Die Abstraktionsschicht ist datentechnisch von Basisgraph und Cluster-Zuordnung abhängig. Sie stellt den abstrakten Graphen bereit, dessen Knoten reale Basisgraph-Knoten an den Clustergrenzen sind (Gate Nodes) und dessen Kanten zwei Sorten umfassen: Intra-Cluster-Kanten für die Durchquerung eines Clusters sowie Inter-Cluster-Kanten für die direkten Übergänge zwischen Nachbarclustern. Die Definition dieser Strukturen folgt in @gate-architektur.

Auf den so aufgebauten Datenstrukturen setzen zwei alternative Pfadsuch-Komponenten auf, deren Vergleich Gegenstand dieser Arbeit ist. Die A\*-Suche arbeitet ausschließlich auf dem Basisgraphen und dient als Referenzverfahren ohne hierarchische Vorverarbeitung. Die HPA\*-Suche nutzt primär die Abstraktionsschicht und greift ergänzend auf den Basisgraphen zur Verfeinerung der abstrakten Pfadsequenz zurück. Die explizite Trennung beider Suchverfahren in zwei eigenständige Komponenten unterstreicht den Charakter der Arbeit als vergleichende Untersuchung: Gegenstand ist nicht die Optimierung eines einzelnen Verfahrens, sondern die Gegenüberstellung beider Strategien auf identischen Eingabedaten.

Die Anfrageschnittstelle bildet die externe Zugriffsschicht des Routing-Kerns. Sie nimmt Pfadanfragen in Form von Start- und Zielkoordinaten entgegen, leitet sie an das jeweils gewählte Suchverfahren weiter und gibt den resultierenden Pfad an den Konsumenten zurück. Sie kapselt die internen Datenstrukturen und stellt die Suchverfahren unabhängig vom konkreten Konsumenten bereit. Konsument ist im laufenden Betrieb der interaktive Client, im Evaluationsbetrieb das Benchmark-Framework.

Zwei weitere Komponenten dienen ausschließlich der vergleichenden Auswertung, die im Titel dieser Arbeit angekündigt ist. Die Inspektions- und Visualisierungskomponente macht die Zwischenzustände der Routing-Kern-Komponenten sichtbar: die Cluster-Zuordnung, die Verteilung der Gate Nodes und der Fortschritt der Suchexpansion lassen sich über eine kartenbasierte Darstellung beobachten. Diese Sichtbarkeit ist Voraussetzung für die qualitative Beurteilung des Algorithmenverhaltens jenseits aggregierter Kennzahlen. Die Benchmark- und Evaluationskomponente ist die treibende Komponente der quantitativen Auswertung. Sie ist mit beiden Suchverfahren gekoppelt, steuert sie wiederholt mit denselben Eingaben an und aggregiert die anfallenden Laufzeit- und Qualitätsmetriken zu einer nach Pfadlängenklassen aufgeschlüsselten Statistik. Beide Auswertungskomponenten gehören nicht zum produktiven Routing-Kern, sind aus konzeptioneller Sicht aber integraler Bestandteil des Systems, da die im Titel angekündigte vergleichende Untersuchung ohne sie nicht durchführbar wäre.

== Datenmodell <sec:datenmodell>

Das Datenmodell des Routing-Kerns baut auf dem Basisgraphen auf, dem gerichteten Multigraphen mit metergewichteten Kanten und geokodierten Knoten, der aus einem OSM-Extrakt gewonnen wird. Auf diesem Basisgraphen werden zwei zusätzliche Strukturen definiert: eine Voronoi-Partitionierung, die jeden Knoten genau einem Cluster zuordnet, und ein abstrakter Graph, dessen Knoten als Gate Nodes an den Clustergrenzen liegen. Beide Strukturen werden in den folgenden Unterabschnitten statisch definiert; wie sie zur Build- und Query-Zeit erzeugt und verwendet werden, behandelt @sec:dynamik.

=== Voronoi-Partitionierung des Basisgraphen

Die Partitionierung des Basisgraphen in Cluster orientiert sich am Konzept des Network Voronoi Diagrams (NVD). Kolahdouzan und Shahabi @Kolahdouzan:2004 definieren das NVD als eine Spezialisierung des Voronoi-Diagramms für Graphen, bei der die Distanz zwischen zwei Knoten nicht die euklidische, sondern die kürzeste Netzwerkdistanz ist. Bezogen auf eine Menge ausgezeichneter Seed-Knoten partitioniert das NVD den Basisgraphen, indem es jeden Knoten demjenigen Seed zuweist, zu dem er die geringste Netzwerkdistanz aufweist. Die so entstehenden Cluster sind zusammenhängende Teilbereiche des Basisgraphen; ihre Grenzen verlaufen entlang jener Knoten, an denen zwei Seeds gleich nah sind.

Die Wahl der Netzwerkdistanz statt der euklidischen ist für Straßennetze konstitutiv: Geographische Barrieren wie Flüsse, Bahnlinien oder nicht überquerbare Straßen werden durch die tatsächliche Graphstruktur korrekt abgebildet. Eine rein euklidische Zuweisung könnte Knoten zusammenfassen, die im Netzwerk weit voneinander entfernt oder gar nicht verbunden sind.

=== Abstrakter Graph mit Gate Nodes <gate-architektur>

Auf der Voronoi-Partitionierung baut der abstrakte Graph auf. Eine naive Konstruktion würde jeden Cluster durch genau einen Knoten im abstrakten Graphen repräsentieren. Dieser Ansatz ist jedoch problematisch: Ein solcher Knoten entspricht keinem realen Punkt im Basisgraphen, weshalb keine sinnvolle Kantengewichtung zwischen zwei benachbarten Cluster-Knoten definiert werden kann. Die Kosten für den Übergang von Cluster A nach Cluster B hängen nicht nur davon ab, welche Cluster benachbart sind, sondern konkret davon, an welcher Stelle die Grenze überquert wird.

Das Problem wird durch die Einführung von Gate Nodes gelöst, wie sie analog auch bei @Botea:2004 als Transition Points beschrieben werden. Gate Nodes sind reale Knoten des Basisgraphen, die an der Grenze zwischen zwei Clustern liegen. Der abstrakte Graph kennt zwei Arten von Kanten: Inter-Cluster-Kanten verbinden Gate Nodes aus benachbarten Clustern und repräsentieren den Übergang zwischen Clustern; Intra-Cluster-Kanten verbinden Gate Nodes innerhalb desselben Clusters und repräsentieren die optimalen Traversierungskosten zwischen ihnen unter Beschränkung auf den Teilgraphen des jeweiligen Clusters. Diese Beschränkung ist konstitutiv: Nur so repräsentiert eine Intra-Cluster-Kante tatsächlich die Kosten zum Durchqueren des Clusters und nicht die eines beliebigen Pfades über den Gesamtgraphen.

Da der Basisgraph gerichtet ist, wird auch der abstrakte Graph als gerichteter Graph konstruiert. Für jede gerichtete Kante (u, v) im Basisgraphen, deren Endpunkte unterschiedlichen Clustern angehören, wird u als Exit-Gate seines Clusters und v als Entry-Gate des angrenzenden Clusters registriert. Intra-Cluster-Kanten verlaufen im abstrakten Graphen folglich gerichtet von Entry-Gates zu Exit-Gates desselben Clusters. Derselbe OSM-Knoten kann dabei in mehreren Rollen auftreten, ohne als separater Knoten dupliziert zu werden.

Die Definition der Intra-Cluster-Kantengewichte als reale, auf dem Basisgraphen berechenbare Traversierungskosten ist nur möglich, weil Gate Nodes echte Knoten des Basisgraphen sind. Die konkrete Berechnungsvorschrift wird in @sec:build-phase beschrieben; ihre algorithmische Umsetzung in @implementation.

== Dynamik <sec:dynamik>

Das System kennt zwei Laufzeitphasen, die sich grundlegend in ihrer Ausführungshäufigkeit und ihrem Ressourcenverhalten unterscheiden. Die Build-Phase wird einmalig pro OSM-Extrakt ausgeführt und erzeugt aus dem Rohgraphen die in @sec:datenmodell beschriebenen Datenstrukturen. Die Query-Phase nutzt diese vorberechneten Strukturen, um einzelne Pfadanfragen mit reduziertem Suchaufwand zu beantworten. Diese Trennung ist die zentrale Idee hierarchischen Routings: aufwändige Berechnungen werden aus dem zeitkritischen Anfragepfad in eine vorgelagerte Vorverarbeitung verschoben @Botea:2004.

#figure(
  image("../figures/system_overview.png", width: 100%),
  caption: [Zwei-Phasen-Architektur des Systems. Die Build-Phase erzeugt
  einmalig den abstrakten Graphen aus dem OSM-Extrakt. Die Query-Phase
  nutzt diesen abstrakten Graphen, um Pfadanfragen zu beantworten.],
) <fig:system_overview>

=== Build-Phase <sec:build-phase>

Die Build-Phase verarbeitet den OSM-Extrakt in mehreren Schritten. Zunächst wird der Basisgraph aus den OSM-Rohdaten geladen und für die nachfolgende Verarbeitung in ein metrisches Koordinatensystem (UTM) projiziert (siehe @koordinatensysteme).

Auf dem projizierten Graphen wird ein reguläres NxN-Gitter aufgespannt, dessen Rasterpunkte auf die jeweils nächstgelegenen OSM-Knoten gesnapped werden. Die gesnappten Knoten dienen als Seeds für die anschließende Partitionierung. Da die verwendeten OSM-Extrakte rechteckige Gebiete abdecken, erzeugt ein gleichmäßiges Gitter eine hinreichend ausgewogene Initialverteilung der Seeds. Alternativen wie die Auswahl zufälliger unbesetzter Knoten könnten organischere Cluster erzeugen, wurden im Rahmen dieser Arbeit jedoch nicht implementiert, da die Optimierung der Clustering-Methode selbst nicht Gegenstand der Untersuchung ist.

Mit den Seeds als Startpunkten wird die Voronoi-Partitionierung durch einen simultanen Dijkstra-Lauf realisiert: Die Wellenfront jedes Seeds breitet sich im Graphen aus, bis alle Knoten einem Cluster zugewiesen sind. Knoten, an denen zwei Wellenfronten aufeinandertreffen, markieren die Clustergrenzen. Der Dijkstra-Lauf wird dabei auf einer ungerichteten Sicht des Basisgraphen ausgeführt, obwohl der Basisgraph selbst gerichtet ist. Diese Entscheidung ist für Straßennetze notwendig: Ein gerichteter Dijkstra würde an Einbahnstraßen abgebrochen werden und dadurch geografisch zerrissene Cluster erzeugen, deren Form durch die Verkehrsführung statt durch die räumliche Nähe bestimmt wäre. Da das Clustering ausschließlich der Partitionierung dient und nicht der Routenberechnung, ist die Vernachlässigung der Kantenrichtung in dieser Phase unproblematisch.

Im Anschluss an die Partitionierung werden die Gate Nodes identifiziert. Ein Knoten wird als Gate erkannt, wenn er über mindestens eine Kante an einen Knoten aus einem benachbarten Cluster grenzt; die Gerichtetheit der Kante bestimmt zusätzlich, ob er als Entry- oder Exit-Gate registriert wird.

Aus den identifizierten Gate Nodes wird abschließend der abstrakte Graph konstruiert. Die Inter-Cluster-Kanten ergeben sich unmittelbar aus den cluster-überschreitenden Kanten des Basisgraphen und tragen deren Gewichte. Die Intra-Cluster-Kanten erfordern eine separate Vorberechnung: Für jedes Cluster wird A\* zwischen allen Paaren von Gate Nodes ausgeführt, wobei die Suche auf den Teilgraphen des jeweiligen Clusters beschränkt ist. Das resultierende Kantengewicht entspricht den optimalen Traversierungskosten innerhalb des Clusters; die Beschränkung auf den jeweiligen Teilgraphen wurde im Datenmodell bereits motiviert. Die konkrete Umsetzung dieser Beschränkung im Code wird in @implementation behandelt.

Der vollständige Build-Zustand, bestehend aus Cluster-Zuordnung, Gate Nodes und abstraktem Graphen, wird derzeit nicht persistent gespeichert. Bei jedem Serverstart wird die Build-Phase vollständig erneut ausgeführt. Eine persistente Speicherung in der ohnehin im Projekt vorhandenen PostgreSQL-Instanz ist geplant; ihre Umsetzung wäre Voraussetzung dafür, die Vorberechnungszeit über mehrere Serverlebenszyklen hinweg zu amortisieren.

=== Query-Phase <sec:query-phase>

Die Query-Phase nimmt eine Pfadanfrage in Form von Start- und Zielkoordinaten entgegen und liefert einen konkreten Pfad auf dem Basisgraphen zurück. Die Verarbeitung gliedert sich in vier Schritte: die Anbindung der Eingabekoordinaten an das Datenmodell, die abstrakte Suche, die Verfeinerung der abstrakten Pfadsequenz und die Aneinanderreihung der Teilpfade zum Gesamtergebnis.

Zunächst werden die Eingabekoordinaten an die Datenstrukturen angebunden. Für Start- und Zielkoordinaten wird jeweils der nächstgelegene Knoten im Basisgraphen bestimmt; über die Cluster-Zuordnung sind damit auch der Start- und der Zielcluster bekannt.

Die abstrakte Suche führt eine A\*-Suche auf dem abstrakten Graphen aus. Sie operiert ausschließlich auf Gate Nodes und nutzt die in der Build-Phase vorberechneten Inter- und Intra-Cluster-Kantengewichte. Als Heuristik kann dasselbe geographische Distanzmaß verwendet werden, das auch die Suche auf dem Basisgraphen leitet. Das Ergebnis der abstrakten Suche ist eine Sequenz von Gate Nodes, die die optimale Folge von Cluster-Übergängen vom Start- zum Zielcluster beschreibt; aus dieser Sequenz lassen sich die berührten Cluster und die jeweils verwendeten Gates ableiten.

Im Refinement-Schritt wird die abstrakte Gate-Sequenz in einen konkreten Pfad auf dem Basisgraphen übersetzt. Für jeden in der Sequenz berührten Cluster wird eine A\*-Suche auf dem cluster-internen Teilgraphen ausgeführt: im Startcluster vom Startknoten zum ersten Exit-Gate, in jedem dazwischenliegenden Cluster zwischen den jeweiligen Entry- und Exit-Gates, im Zielcluster vom letzten Entry-Gate zum Zielknoten. Die so gewonnenen Teilpfade werden zum finalen Pfad auf dem Basisgraphen aneinandergereiht.

Der reduzierte Suchaufwand gegenüber einer reinen A\*-Suche auf dem Basisgraphen ergibt sich aus zwei Effekten: Die abstrakte Suche operiert auf einer drastisch geringeren Anzahl an Knoten und Kanten, und die Cluster-internen Suchen im Refinement-Schritt sind auf vergleichsweise kleine Teilgraphen beschränkt. Wie stark dieser Effizienzgewinn ausfällt und unter welchen Bedingungen er die Vorberechnungskosten amortisiert, ist Gegenstand der quantitativen Auswertung im weiteren Verlauf der Arbeit.
