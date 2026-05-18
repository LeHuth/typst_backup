#import "global.typ": *

= Zusammenfassung und Ausblick

Die vorliegende Arbeit hat eine Implementierung von Hierarchical Pathfinding A\* (HPA\*) auf realen OpenStreetMap-Daten konzipiert, umgesetzt und gegen klassisches A\* quantitativ ausgewertet. Die zentralen Befunde sind in @sec:eval-summary verdichtet. Dieses Schlusskapitel ergänzt sie um die Vorbehalte, unter denen sie zu lesen sind, und um die Anschlusspunkte, die sich aus ihnen für weiterführende Arbeiten ergeben.

== Limitierungen <sec:limitations>

Ein erster Vorbehalt betrifft die Datensatzauswahl. Die Auswertung stützt sich auf zwei OSM-Auszüge mit identischen Erhebungsparametern, die zwei extreme Punkte im Spektrum urbaner und ländlicher Straßennetze repräsentieren. Zwischenformen wie Mittelstadt- oder Vorstadtnetze wurden in @sec:eval-setup bewusst nicht aufgenommen. Quantitative Befunde wie die Faktoren der Suchraum-Reduktion (etwa 65 für Berlin, etwa 17 für Ireland) sind damit Eckpunkte, keine generalisierbare Funktion über alle Netzwerktypen hinweg.

Die zweite Limitierung ist die Beschränkung auf eine einzelne Abstraktionsebene. Boteas Originalentwurf @Botea:2004 sieht ausdrücklich mehrere Hierarchieebenen vor, bei denen der bereits abstrahierte Graph erneut clusterisiert wird. Für die Frage, wie sich Speedup, Pfadqualität und Vorberechnungskosten mit zunehmender Hierarchietiefe verhalten, liefert die Arbeit keine Aussage.

Die in @sec:eval-quality dokumentierte exakte Optimalität der HPA\*-Pfade ist eine direkte Folge zweier Designentscheidungen: alle Gate Nodes werden beibehalten, und die Verfeinerung erfolgt cluster-beschränkt ohne Glättungs-Heuristik. Beide Entscheidungen weichen von der Originalliteratur ab und schließen einen Vergleich mit der dort berichteten Near-Optimalität von 1 bis 2 % systematisch aus. Die Aussage „HPA\* findet optimale Pfade" gilt damit für diese Implementierung, nicht für HPA\* allgemein.

Die in @sec:eval-precomputation gemessenen Vorberechnungszeiten von bis zu 850 Sekunden fallen aktuell bei jedem Serverstart erneut an, weil der Build-Zustand nicht persistiert wird. Eine entsprechende Persistenz in der projektseitig vorhandenen PostgreSQL-Instanz ist in @sec:build-phase konzeptionell skizziert, aber nicht implementiert. Die Amortisationsschätzungen aus @sec:eval-summary setzen folglich den fortlaufenden Betrieb einer einzelnen Serverinstanz voraus.

Die in @sec:eval-search-space herangezogene Open-Set-Größe ist ein struktureller Indikator für den Spitzenspeicherbedarf, kein direkter Mobile-Benchmark. Die in @sec:motivation aufgemachte These einer besonderen Eignung des Verfahrens für ressourcenbeschränkte Endgeräte ist auf Basis der erhobenen Daten plausibel, aber nicht empirisch nachgewiesen.

Die als Strukturmetrik vorgesehene `transit_node_count` (siehe @tbl:map_metrics) lieferte für beide getesteten Radien den Wert 0; eine Validierung dieses Resultats war im Rahmen der Arbeit nicht mehr leistbar (siehe @tbl:datasets). Der Vergleich der Datensätze stützt sich daher auf den mittleren Knotengrad, die heuristische Genauigkeit und die `dimension` nach Sturtevant @Sturtevant:2012.

Schließlich repräsentieren die untersuchten Datensätze den Straßenzustand zu einem festen Zeitpunkt. Dynamische Effekte wie temporäre Sperrungen, Verkehrslast oder zeitabhängige Geschwindigkeiten werden nicht abgebildet. Diese Einschränkung wurde in @sec:abgrenzung explizit benannt, schließt aber praxisrelevante Routing-Szenarien aus dem Anwendungsbereich der Arbeit aus.

== Ausblick <sec:outlook>

Aus den oben benannten Limitierungen ergeben sich mehrere konkrete Anschlusspunkte für weiterführende Arbeiten.

Eine Übernahme der von Botea et al. @Botea:2004 beschriebenen Reduktion der Entrance Points auf wenige repräsentative Transition Points würde den abstrakten Graphen verkleinern und die abstrakte Suche beschleunigen. Der Effekt auf den hier beobachteten Speedup, insbesondere auf die Lage des Crossover-Punkts, ließe sich mit der bestehenden Benchmark-Infrastruktur unmittelbar messen. Ergänzend dazu würde ein nachgelagerter Glättungs-Schritt, der die Cluster-Übergänge an den Gate Nodes lokal optimiert, die Pfadqualität von „exakt optimal in der Hauptkonfiguration" zu „near-optimal in einer beschleunigten Konfiguration" verschieben und einen direkten Vergleich gegen die in der Originalliteratur berichteten Pfadfehler ermöglichen.

Die in dieser Arbeit beschriebene Voronoi-Partitionierung lässt sich rekursiv auf den abstrakten Graphen anwenden. Eine entsprechende Erweiterung zu einer Mehrebenen-Hierarchie würde die für sehr große Netzwerke, etwa Karten kontinentaler Größe, erwartbaren Skalierungsgrenzen einer Single-Layer-Hierarchie überwinden und ist eine logische Fortsetzung des hier ausgeführten Konzepts.

Die in @sec:build-phase konzipierte Speicherung des Build-Zustands in der projektseitig vorhandenen PostgreSQL-Instanz wäre eine vergleichsweise kleine Implementierungserweiterung mit substantieller Wirkung: Sobald der Build-Zustand serverübergreifend wiederverwendbar ist, verschiebt sich der relevante Bezugspunkt der Amortisation von „Anfragen pro Serverlebenszyklus" zu „Anfragen pro OSM-Auszug", was die in @sec:eval-summary dokumentierten Amortisationsschätzungen praxisnäher werden lässt.

Die Übertragung des Verfahrens auf dynamische Graphen ist ein eigenständiges Forschungsthema, das in der Literatur bereits unter Stichworten wie Customizable Route Planning behandelt wird @Delling:2011. Eine entsprechende Erweiterung wäre ein substantieller Folgeschritt, der die in @sec:motivation angedeuteten praxisrelevanten Szenarien direkt adressiert.

Eine empirische Validierung der vermuteten Mobile-Eignung erforderte schließlich einen Implementierungs-Port auf eine repräsentative mobile Laufzeitumgebung (Android oder iOS) und Messungen unter realistischen Speicher- und CPU-Beschränkungen. Ohne diese Messung bleibt die Mobilitäts-These aus @sec:motivation eine plausible, aber nicht überprüfte Vermutung.

== Schlussbemerkung

Die methodische Stärke der vorliegenden Arbeit liegt nicht in der absoluten Höhe des erzielten Speedups, sondern in der nachvollziehbaren Verbindung von Implementierung, Mechanismus-Analyse und quantitativer Evaluation auf realen Straßendaten. Die durchgängige Trennung zwischen Beobachtung und algorithmischer Erklärung soll auch nach den oben benannten Limitierungen als belastbarer Beitrag bestehen bleiben.
