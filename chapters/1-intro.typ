#import "global.typ": *

= Introduction

== Motivation
Routenplanung und Navigation sind ein alltäglicher Bestandteil des modernen Lebens. Anwendungen wie Google Maps oder OpenStreetMap-basierte Dienste ermöglichen es mobilen Endnutzern, innerhalb weniger Millisekunden präferierte Pfade zu berechnen – je nach Fortbewegungsmittel etwa für das Auto, zu Fuß oder per Fahrrad.
Straßennetzwerke lassen sich als gewichtete Graphen modellieren, in denen Kreuzungen als Knoten und Straßenabschnitte als Kanten repräsentiert werden. Das Straßennetz einer Großstadt wie Berlin umfasst dabei #todo([Knotenzahl — eigene Messung via osmnx])  Knoten. Der klassische A\*-Algorithmus @Hart:1968 stößt bei Graphen dieser Größenordnung an praktische Grenzen: Trotz seiner heuristischen, zielgerichteten Suchstrategie müssen in dichten urbanen Netzwerken bei einer einzelnen Anfrage potenziell tausende von Knoten expandiert werden @Botea:2004. Dies führt in zwei relevanten Szenarien zu Problemen: Beim zentralisierten Routing auf Servern entstehen unter hoher Last erhebliche Rechenkosten; beim dezentralisierten, gerätebasierten Routing kann die erforderliche Rechenleistung die Kapazität mobiler Endgeräte übersteigen und zu spürbaren Leistungseinbußen führen.
Ein vielversprechender Lösungsansatz liegt in der Einführung einer hierarchischen Struktur. Durch eine aufwändige Vorverarbeitung des Graphen – die einmalig offline durchgeführt wird – kann der Suchraum zur Anfragezeit erheblich eingeschränkt werden @Botea:2004. Ein Großteil der Rechenarbeit steht damit bei jeder Nutzeranfrage bereits vorberechnet zur Verfügung, was die Antwortzeit drastisch reduziert.
Ziel dieser Arbeit ist die Konzeption und prototypische Implementierung eines solchen hierarchischen Routingsystems auf Basis realer OpenStreetMap-Daten.

== Zielsetzung
Ziel dieser Arbeit ist die Untersuchung, inwiefern eine hierarchische Erweiterung des A\*-Algorithmus gegenüber dem klassischen A\* messbare Einsparungen an Rechenressourcen erzielt, bei gleichzeitig akzeptabler Pfadqualität. Als Grundlage dient eine reale OpenStreetMap-Karte, auf der beide Algorithmen mit identischen Start- und Zielpunkten ausgeführt und anschließend verglichen werden.
Der Vergleich erfolgt anhand folgender Metriken:

- Laufzeit in Millisekunden
- Anzahl expandierter Knoten und besuchter Kanten
- Pfadlänge in Metern als Maß für die Pfadqualität

Um statistisch aussagekräftige Ergebnisse zu erzielen, orientiert sich die Evaluationsmethodik an Sturtevant (2012) @Sturtevant:2012, der einen standardisierten Benchmarkrahmen für pfadsuchende Algorithmen beschreibt. Konkret werden beide Algorithmen über eine hohe Anzahl zufälliger Start-/Zielpaar-Kombinationen #todo([genaue Anzahl festlegen, z.B. 1000 Testläufe]) auf derselben Karte ausgeführt.
Als Qualitätskriterium wird die prozentuale Abweichung der von HPA\* berechneten Pfadlänge vom durch A\* ermittelten Referenzpfad herangezogen. Angestrebt wird dabei eine Abweichung von unter 1%, wie sie von Botea et al. (2004) @Botea:2004 für HPA\* nach Pfadglättung beschrieben wird. Ob diese Schwelle in der vorliegenden Implementierung erreicht wird, ist dabei selbst Teil der empirischen Untersuchung.

== Abgrenzung
Das im Rahmen dieser Arbeit entwickelte System dient ausschließlich der empirischen Analyse und dem Vergleich der beiden Algorithmen — es ist kein produktionsreifes Routingsystem. Daraus ergeben sich mehrere bewusste Einschränkungen.
Für die Partitionierung des Graphen in Cluster wird ein geografischer NxN-Grid-Ansatz verwendet: Seedpunkte werden gleichmäßig über die Karte verteilt und auf den jeweils nächsten OSM-Knoten gemappt. 
Dieser Ansatz vereinfacht die Kontrolle über Clustergröße und -anzahl erheblich, was insbesondere das Benchmarking begünstigt. Ein bekannter Nachteil ist, dass die resultierenden Cluster geografisch zwar gleichmäßig verteilt sind, jedoch unterschiedlich viele Knoten und Kanten enthalten, da die Dichte des Straßennetzes regional stark variiert. Diese Ungleichmäßigkeit wird bewusst hingenommen, da nicht das Ziel ist, ein optimal partitioniertes System zu entwickeln, sondern das Prinzip der hierarchischen Suche zu untersuchen.

Produktionssysteme wie OsmAnd verwenden deutlich aufwändigere Ansätze @OsmAnd:2024: Zur Bestimmung der Grenzpunkte zwischen Clustern wird der Ford-Fulkerson-Algorithmus eingesetzt, der natürliche Engpässe im Graphen identifiziert. Dadurch wird die Anzahl der Grenzpunkte pro Cluster stark reduziert, was die Größe des abstrakten Graphen und die Berechnungszeit erheblich verringert. In der vorliegenden Implementierung hingegen wird jeder Grenzknoten zwischen zwei Clustern als Gate behandelt, was zu einer deutlich höheren Kantendichte im abstrakten Graphen führt. Dies wird bewusst hingenommen, da es nicht um eine optimale Gate-Selektion geht, sondern um die Untersuchung des hierarchischen Prinzips.
Auf den Einsatz einer Geodatenbank zur räumlichen Abfrage des nächsten OSM-Knotens zu einem Seedpunkt wurde verzichtet, da der Seed-Mapping-Schritt einmalig im Preprocessing erfolgt und somit keinen Einfluss auf die Laufzeitperformance der eigentlichen Suchalgorithmen hat.
Darüber hinaus werden folgende Aspekte explizit nicht untersucht: mehrere Hierarchieebenen sowie dynamische Graphen. Als Datenbasis dient ausschließlich das Fahrradnetz der verwendeten OSM-Karte, da dieses eine strukturell simplere Variante des Gesamtgraphen darstellt. Im Preprocessing werden zudem Sackgassen — etwa Einfahrten und Stichstraßen — aus dem Graphen entfernt, um unnötige Suchschritte zu vermeiden.

