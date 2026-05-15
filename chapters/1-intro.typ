#import "global.typ": *

= Introduction

== Motivation <sec:motivation>
Routenplanung und Navigation sind ein alltäglicher Bestandteil des modernen Lebens. Anwendungen wie Google Maps oder OpenStreetMap-basierte Dienste ermöglichen es mobilen Endnutzern, innerhalb weniger Millisekunden präferierte Pfade zu berechnen. Je nach Fortbewegungsmittel etwa für das Auto, zu Fuß oder per Fahrrad.
Straßennetzwerke lassen sich als gewichtete Graphen modellieren, in denen Kreuzungen als Knoten und Straßenabschnitte als Kanten repräsentiert werden. Das Straßennetz einer Großstadt wie Berlin umfasst dabei #todo([Knotenzahl eigene Messung via osmnx])  Knoten. Der klassische A\*-Algorithmus @Hart:1968 stößt bei Graphen dieser Größenordnung an praktische Grenzen: Trotz seiner heuristischen, zielgerichteten Suchstrategie müssen in dichten urbanen Netzwerken bei einer einzelnen Anfrage potenziell tausende von Knoten expandiert werden @Botea:2004. Dies führt in zwei relevanten Szenarien zu Problemen: Beim zentralisierten Routing auf Servern entstehen unter hoher Last erhebliche Rechenkosten; beim dezentralisierten, gerätebasierten Routing kann die erforderliche Rechenleistung die Kapazität mobiler Endgeräte übersteigen und zu spürbaren Leistungseinbußen führen.
Ein vielversprechender Lösungsansatz liegt in der Einführung einer hierarchischen Struktur. Durch eine aufwändige Vorverarbeitung des Graphen – die einmalig offline durchgeführt wird – kann der Suchraum zur Anfragezeit erheblich eingeschränkt werden @Botea:2004. Ein Großteil der Rechenarbeit steht damit bei jeder Nutzeranfrage bereits vorberechnet zur Verfügung, was die Antwortzeit drastisch reduziert.
Ziel dieser Arbeit ist die Konzeption und prototypische Implementierung eines solchen hierarchischen Routingsystems auf Basis realer OpenStreetMap-Daten.

== Zielsetzung <sec:ziele>
Ziel dieser Arbeit ist die Untersuchung, inwiefern eine hierarchische Erweiterung des A\*-Algorithmus gegenüber dem klassischen A\* messbare Einsparungen an Rechenressourcen erzielt, bei gleichzeitig akzeptabler Pfadqualität. Als Grundlage dient eine reale OpenStreetMap-Karte, auf der beide Algorithmen mit identischen Start- und Zielpunkten ausgeführt und anschließend verglichen werden.
Der Vergleich erfolgt anhand folgender Metriken:

- Laufzeit in Millisekunden
- Anzahl expandierter Knoten und besuchter Kanten
- Pfadlänge in Metern als Maß für die Pfadqualität

Um statistisch aussagekräftige Ergebnisse zu erzielen, werden beide Algorithmen über eine hohe Anzahl zufälliger Start-/Zielpaar-Kombinationen #todo([genaue Anzahl festlegen, z.B. 1000 Testläufe]) auf derselben Karte ausgeführt. Die gewählte Evaluationsmethodik wird in Kapitel 6 im Detail beschrieben.
Als Qualitätskriterium wird die prozentuale Abweichung der von HPA\* berechneten Pfadlänge vom durch A\* ermittelten Referenzpfad herangezogen. Angestrebt wird dabei eine Abweichung von unter 1%, wie sie von Botea et al. (2004) @Botea:2004 für HPA\* nach Pfadglättung beschrieben wird. Ob diese Schwelle in der vorliegenden Implementierung erreicht wird, ist dabei selbst Teil der empirischen Untersuchung.

== Abgrenzung
Das im Rahmen dieser Arbeit entwickelte System dient ausschließlich der empirischen Analyse und dem Vergleich der beiden Algorithmen. Es ist kein produktionsreifes Routingsystem. Daraus ergeben sich mehrere bewusste Einschränkungen.

Die Partitionierung des Graphen in Cluster erfolgt über ein einfaches, reproduzierbares Verfahren, das die Kontrolle über Clustergröße und -anzahl begünstigt. Produktionssysteme verwenden deutlich aufwändigere Ansätze, etwa zur Reduktion der Grenzpunkte zwischen Clustern @OsmAnd:2024. Die vorliegende Arbeit verzichtet bewusst auf solche Optimierungen, da nicht ein optimal partitioniertes System entwickelt werden soll, sondern das Prinzip der hierarchischen Suche untersucht wird. Die konkrete Wahl der Clustering-Methode und die Konstruktion des abstrakten Graphen werden in Kapitel 4 beschrieben.

Darüber hinaus werden folgende Aspekte explizit nicht untersucht: mehrere Hierarchieebenen sowie dynamische Graphen. Als Datenbasis dient ausschließlich das Fahrradnetz der verwendeten OSM-Karte, da dieses eine strukturell simplere Variante des Gesamtgraphen darstellt. Im Preprocessing werden zudem Sackgassen, etwa Einfahrten und Stichstraßen, aus dem Graphen entfernt, um unnötige Suchschritte zu vermeiden.

