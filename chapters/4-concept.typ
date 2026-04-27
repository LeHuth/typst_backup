#import "global.typ": *

= Konzept

== Systemübersicht

Das in dieser Arbeit entwickelte System gliedert sich in zwei klar getrennte
Phasen, die sich grundlegend in ihrer Ausführungshäufigkeit und ihrem
Ressourcenverhalten unterscheiden. Die Build-Phase wird einmalig pro
OSM-Extrakt ausgeführt und erzeugt aus dem Rohgraphen die für die
hierarchische Suche notwendigen Datenstrukturen. Die Query-Phase nutzt diese
vorberechneten Strukturen, um einzelne Pfadanfragen mit reduziertem
Suchaufwand zu beantworten. Diese Trennung ist die zentrale Idee
hierarchischen Routings: Aufwändige Berechnungen werden aus dem zeitkritischen
Anfragepfad in eine vorgelagerte Vorverarbeitung verschoben
@Botea:2004.

#figure(
  image("../figures/system_overview.png", width: 100%),
  caption: [Zwei-Phasen-Architektur des Systems. Die Build-Phase erzeugt
  einmalig den abstrakten Graphen aus dem OSM-Extrakt. Die Query-Phase
  nutzt diesen abstrakten Graphen, um Pfadanfragen zu beantworten.],
) <fig:system_overview>

Die Build-Phase verarbeitet den OSM-Extrakt in mehreren Schritten. Zunächst
wird der Graph aus den OSM-Rohdaten geladen und für die nachfolgende
Verarbeitung in ein metrisches Koordinatensystem (UTM) projiziert
(siehe Abschnitt @koordinatensysteme ). Auf dem projizierten Graphen wird
ein reguläres NxN-Gitter aufgespannt, dessen Rasterpunkte auf die jeweils
nächstgelegenen OSM-Knoten gesnapped werden. Diese gesnappten Knoten dienen
als Seeds für die anschließende Partitionierung. Die Partitionierung selbst
erfolgt durch einen simultanen Dijkstra-Lauf von allen Seeds aus, der jedem
Knoten des Graphen denjenigen Seed zuweist, der ihn auf kürzestem Netzwerkweg
erreicht. Das Verfahren entspricht dem Network Voronoi Diagram nach
Kolahdouzan und Shahabi und ist in Abschnitt
@voronoi-clustering beschrieben.

Im Anschluss an die Partitionierung werden die Gate Nodes identifiziert und
der abstrakte Graph konstruiert. Ein Knoten wird als Gate erkannt, wenn er
mit mindestens einer Kante an einen Knoten aus einem benachbarten Cluster
grenzt. Aus diesen Gate Nodes und den vorberechneten Übergangskosten
zwischen ihnen entsteht der abstrakte Graph (siehe Abschnitt
@gate-architektur). Der vollständige Build-Zustand, bestehend aus
Cluster-Zuordnung, Gate Nodes und abstraktem Graphen, soll persistent
gespeichert werden, sodass nachfolgende Anfragen ohne erneuten Build-Lauf
beantwortet werden können.

#text(red)[Persistenz der Build-Artefakte ist aktuell noch nicht
implementiert. Der Build-Lauf wird derzeit bei jedem Server-Start
wiederholt. Die konkrete Wahl des persistenten Speichers wird in Kapitel
Implementation diskutiert.]

Die Query-Phase #todo("Query-Phase ausgiebiger beschreiben, evl. eigenes Kapitel.") nimmt eine Pfadanfrage in Form von Start- und
Zielkoordinaten entgegen und liefert einen konkreten Pfad auf dem
Basisgraphen zurück. Sie nutzt den abstrakten Graphen, um den Suchraum
gegenüber einer reinen A\*-Suche auf dem Basisgraphen erheblich zu
reduzieren. Der konkrete Ablauf ist in #todo(
  "noch nicht geschrieben"
)
beschrieben.

== Motivation für hierarchisches Routing

Der A\*-Algorithmus liefert auf Graphen mit einer zulässigen Heuristik garantiert optimale Pfade @Hart:1968. Auf großen Straßennetzen entsteht jedoch ein praktisches Problem: Bei Anfragen über längere Distanzen expandiert A\* eine sehr große Anzahl von Knoten, da der Suchhorizont sich weit über die direkte Route hinaus ausbreitet. Zwar lenkt die euklidische Distanzheuristik die Suche in die richtige Richtung, dennoch werden zahlreiche Knoten und Kanten besucht, die für den tatsächlichen Pfad irrelevant sind. Für interaktive Navigationssysteme, die in Echtzeit antworten müssen, ist dieses Verhalten bei wachsender Graphgröße ein ernsthaftes Problem.
Die Grundidee hierarchischen Routings besteht darin, den Graphen in mehrere Abstraktionsebenen zu überführen. Auf einer höheren Ebene existiert eine kompaktere Repräsentation, die die grobe Struktur des Graphen erhält, aber nur einen Bruchteil der ursprünglichen Knoten und Kanten enthält. Eine Suchanfrage wird zunächst auf dieser abstrakten Ebene bearbeitet, wo sie wesentlich günstiger ist, und anschließend auf der Basisebene verfeinert. @Botea:2004 zeigen mit HPA\*, dass dieser Ansatz die Anzahl expandierter Knoten erheblich reduzieren kann, bei nur geringfügiger Einbuße an Pfadqualität.

== Graphpartitionierung via Voronoi-Clustering

Voraussetzung für eine solche Hierarchie ist eine Zerlegung des Basisgraphen in zusammenhängende Teilbereiche, sogenannte Cluster. In der vorliegenden Arbeit wird dazu ein Verfahren verwendet, das sich am Konzept des Network Voronoi Diagrams (NVD) orientiert. #todo("Kolahdouzan und Shahabi (2004) Quelle einpflegen") definieren das NVD als eine Spezialisierung des Voronoi-Diagramms für Graphen, bei der die Distanz zwischen zwei Objekten nicht die euklidische, sondern die kürzeste Netzwerkdistanz ist. Jeder Knoten des Graphen wird dem Seed-Knoten zugewiesen, zu dem er die geringste Netzwerkdistanz aufweist.
In der Praxis wird dieses Clustering durch einen simultanen Dijkstra-Lauf von allen Seed-Knoten gleichzeitig realisiert. Der Dijkstra-Lauf wird dabei auf einer ungerichteten Sicht des Basisgraphen
ausgeführt, obwohl der Basisgraph selbst gerichtet ist. Diese Entscheidung
ist für Straßennetze notwendig: Ein gerichteter Dijkstra würde an
Einbahnstraßen abgebrochen werden und dadurch geografisch zerrissene Cluster
erzeugen, deren Form durch die Verkehrsführung statt durch die räumliche
Nähe bestimmt wäre. Da das Clustering ausschließlich der Partitionierung
dient und nicht der Routenberechnung, ist die Vernachlässigung der
Kantenrichtung in dieser Phase unproblematisch. Die Wellenfront jedes Seeds breitet sich im Graphen aus, bis alle Knoten einem Cluster zugewiesen sind. Knoten, an denen zwei Wellenfronten aufeinandertreffen, markieren die Clustergrenzen. Die Wahl netzwerkbasierter statt euklidischer Distanz ist dabei für Straßennetze entscheidend: Geographische Barrieren wie Flüsse, Bahnlinien oder nicht überquerbare Straßen werden durch die tatsächliche Graphstruktur korrekt abgebildet. Eine rein euklidische Zuweisung könnte Knoten zusammenfassen, die im Netzwerk weit voneinander entfernt oder gar nicht verbunden sind.
Als Seed-Strategie wird in dieser Arbeit ein reguläres Gitter über das
projizierte Kartengebiet (UTM) gelegt, dessen Rasterpunkte auf die jeweils
nächstgelegenen OSM-Knoten gesnapped werden. Diese Methode ist für den vorliegenden Anwendungsfall geeignet: Da die verwendeten OSM-Extrakte rechteckige Gebiete abdecken, erzeugt ein gleichmäßiges Gitter eine hinreichend ausgewogene Initialverteilung der Seeds. Alternativen, wie die Auswahl zufälliger unbesetzter Knoten, könnten organischere Cluster erzeugen, wurden jedoch im Rahmen dieser Arbeit nicht implementiert, da die Optimierung der Clustering-Methode selbst nicht Gegenstand der Untersuchung ist.

== Gate-Node-Architektur <gate-architektur>

Nachdem der Graph partitioniert ist, muss eine abstrakte Repräsentation konstruiert werden. Eine naive Lösung wäre, jeden Cluster durch genau einen Knoten im abstrakten Graphen darzustellen. Dieser Ansatz ist jedoch problematisch: Ein solcher Knoten entspricht keinem realen Punkt im Basisgraphen, weshalb keine sinnvolle Kantengewichtung zwischen zwei benachbarten Cluster-Knoten definiert werden kann. Die Kosten für den Übergang von Cluster A nach Cluster B hängen nicht nur davon ab, welche Cluster benachbart sind, sondern konkret davon, an welcher Stelle die Grenze überquert wird.
Dieses Problem wird durch die Einführung von Gate Nodes gelöst, wie sie analog auch bei @Botea:2004 als Transition Points beschrieben werden. Gate Nodes sind reale Knoten des Basisgraphen, die an der Grenze zwischen zwei Clustern liegen. Im abstrakten Graphen gibt es zwei Arten von Kanten: Inter-Cluster-Kanten verbinden Gate Nodes aus benachbarten Clustern und repräsentieren den Übergang zwischen Clustern; Intra-Cluster-Kanten verbinden Gate Nodes innerhalb desselben Clusters und repräsentieren die Kosten, diesen Cluster von einem Eingang zu einem Ausgang zu durchqueren.
Die Gewichtung der Intra-Cluster-Kanten wird zur Build-Time berechnet. Für jedes Cluster wird A\* zwischen allen Paaren von Gate Nodes ausgeführt, wobei die Suche auf den Teilgraphen des jeweiligen Clusters beschränkt ist. Das resultierende Kantengewicht entspricht den tatsächlichen optimalen Traversierungskosten innerhalb des Clusters. Nur weil Gate Nodes echte Knoten des Basisgraphen sind, ist diese Kostenberechnung überhaupt möglich. Da der Basisgraph gerichtet ist, wird auch der abstrakte Graph als
gerichteter Graph konstruiert. Für jede gerichtete Kante (u, v) im
Basisgraphen, deren Endpunkte unterschiedlichen Clustern angehören, wird u
als Exit-Gate seines Clusters und v als Entry-Gate des angrenzenden Clusters
registriert. Intra-Cluster-Kanten verlaufen im abstrakten Graphen folglich
gerichtet von Entry-Gates zu Exit-Gates desselben Clusters. Derselbe
OSM-Knoten kann dabei in mehreren Rollen auftreten, ohne als separater
Knoten dupliziert zu werden. #todo("Die Vorberechnung der Intra-Cluster-Kantengewichte muss auf
den jeweiligen Cluster beschränkt werden. In der aktuellen Implementierung
läuft die A*-Suche zur Gewichtsberechnung uneingeschränkt auf dem
Gesamtgraphen, was die semantische Bedeutung der Intra-Cluster-Kanten
verletzt: Eine solche Kante repräsentiert dann nicht mehr die Kosten zum
Durchqueren des Clusters, sondern die Kosten eines beliebigen Pfades
zwischen den beiden Gate Nodes, der auch durch andere Cluster verlaufen
darf. Damit kodiert der abstrakte Graph Information, die er erst durch
Komposition gewinnen sollte, und verliert seine Eigenschaft als echte
Hierarchie-Ebene über dem Basisgraphen.")

== Zwei-Phasen-Architektur: Build-Time und Query-Time

Das System ist in zwei klar getrennte Phasen unterteilt. In der Build-Phase wird der OSM-Extrakt eingelesen, das Clustering durchgeführt, die Gate Nodes identifiziert und der abstrakte Graph mit vorberechneten Kantengewichten konstruiert. Das Ergebnis dieser Phase, bestehend aus der Cluster-Zuordnung, den Gate
Nodes und dem abstrakten Graphen mit vorberechneten Kantengewichten, wird
in einem persistenten Speicher abgelegt. Die konkrete Wahl der
Speichertechnologie ist eine Frage der Implementation und wird in Kapitel
@implementation diskutiert. Wesentlich für das Konzept ist nur, dass die
kostspielige Build-Phase einmalig pro OSM-Extrakt ausgeführt werden muss
und die berechneten Strukturen anschließend für beliebig viele
Pfadanfragen wiederverwendet werden können.

#todo("Persistenz der Build-Artefakte ist aktuell noch nicht
implementiert. Mögliche Umsetzung über die ohnehin im Projekt vorhandene
PostgreSQL-Instanz.") Der kostspielige Build-Prozess muss so nur einmal ausgeführt werden und steht danach dauerhaft zur Verfügung.
In der Query-Phase wird eine Pfadanfrage von Startknoten S nach Zielknoten T wie folgt verarbeitet: A\* läuft zunächst auf dem Basisgraphen, bis ein Gate Node erreicht wird. Ab diesem Punkt wechselt die Suche auf den abstrakten Graphen und läuft dort weiter, bis der Gate Node des Zielclusters erreicht ist. Damit sind Start-Cluster, Ziel-Cluster und alle dazwischen liegenden Cluster sowie die verwendeten Gate Nodes bekannt. Im abschließenden Refinement-Schritt wird A\* innerhalb jedes berührten Clusters separat ausgeführt, um den konkreten Pfad auf dem Basisgraphen zu rekonstruieren.