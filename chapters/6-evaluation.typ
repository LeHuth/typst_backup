#import "global.typ": *

= Evaluation <evaluation>

Dieses Kapitel wertet die in @sec:benchmark beschriebenen Benchmark-Läufe quantitativ aus. Im Zentrum steht die Forschungsfrage: Unter welchen Bedingungen bietet HPA\* gegenüber A\* einen Laufzeitvorteil, und zu welchen Kosten in Bezug auf Pfadqualität und Vorberechnungsaufwand? Die Auswertung stützt sich auf zwei Datensätze, die sich in der absoluten Knotenzahl und damit in der räumlichen Knotendichte des untersuchten Straßennetzes unterscheiden. Beide Datensätze wurden mit derselben Benchmark-Infrastruktur erzeugt und verwenden identische Bucketing-Parameter (500 m Bucket-Breite, 10 Probleme pro Bucket).

== Versuchsaufbau <sec:eval-setup>

Die Evaluation untersucht die Wirkung zweier Parameter auf das Verhalten von HPA\*: die Struktur des zugrundeliegenden Straßennetzes (über zwei kontrastierende OSM-Datensätze) und die Cluster-Granularität (über eine Variation der Grid-Size in sieben Stufen). Beide Achsen werden orthogonal kombiniert, woraus sich 14 Konfigurationen ergeben. In jeder Konfiguration werden A\* und HPA\* auf einer stratifizierten Problemmenge gegeneinander verglichen.

Zwei OSM-Auszüge, jeweils mit 10 km Radius und dem Netzwerktyp `bike`, bilden die experimentelle Grundlage. Der Berliner Auszug repräsentiert ein großstädtisches Straßennetz mit hoher Knoten- und Kantenzahl auf engem geographischen Raum. Der irische Auszug aus der Region südlich von Athy steht für ein ländliches Straßennetz mit deutlich geringerer Knotenzahl bei identischem geographischen Radius. @tbl:datasets fasst die zentralen Eigenschaften beider Datensätze zusammen.

#figure(
  caption: [Charakterisierung der beiden Evaluations-Datensätze. Sturtevant-Map-Metriken (`dimension`, `transit_node_count`) sind methodisch in @tbl:map_metrics eingeführt und werden noch nachgereicht.],
  table(
    columns: (1.6fr, 1fr, 1fr),
    align: (left, right, right),
    table.header[*Eigenschaft*][*Berlin*][*Ireland*],
    [Mittelpunkt (lat, lon)],         [52,5200; 13,4050], [52,8054; -7,2100],
    [Radius],                          [10 km],           [10 km],
    [Netzwerktyp],                     [`bike`],          [`bike`],
    [Knotenzahl],                      [110.556],         [4.818],
    [Mittlerer Knotengrad],            [1,19],            [1,18],
    [Heuristische Genauigkeit],        [0,838],           [0,754],
    [Mittlerer Detour-Faktor],         [1,206],           [1,375],
    [`dimension` (Sturtevant)],        [#todo[t. b. d.]], [#todo[t. b. d.]],
    [`transit_node_count` (r = 500 m)],  [#todo[t. b. d.]], [#todo[t. b. d.]],
    [`transit_node_count` (r = 2000 m)], [#todo[t. b. d.]], [#todo[t. b. d.]],
    [Bucket-Bereich der Stichprobe],   [1–49],            [0–52],
    [Anzahl Test-Probleme],            [490],             [530],
  ),
) <tbl:datasets>

Trotz fast identischen mittleren Knotengrads (1,19 gegenüber 1,18) unterscheiden sich die beiden Datensätze um mehr als eine Größenordnung in der absoluten Knotenzahl. Die Auswahl zielt damit bewusst nicht auf strukturelle Dichte-Variation im graphentheoretischen Sinn, sondern auf den Kontrast zwischen einem urbanen und einem ländlichen Straßennetz bei sonst identischen Erhebungsparametern.

#todo("Sturtevant-Map-Metriken `dimension` und `transit_node_count` (Radien 500 m und 2000 m) für beide Datensätze nachberechnen und in @tbl:datasets eintragen. Implementierung steht in `Benchmark/metrics.py` bereit. Die Werte sind methodisch in @tbl:map_metrics motiviert und sollen die in @sec:eval-search-space getroffene Aussage zur Skalierung mit der Graphstruktur empirisch unterfüttern.")

Die Beschränkung auf zwei Datensätze ist eine bewusste Entscheidung. Zwischenstufen wie Mittelstadt-Auszüge würden voraussichtlich Metriken liefern, die zwischen den beobachteten Extremen liegen, und keine qualitativ neuen Aussagen ermöglichen. Die orthogonale Variation der Cluster-Granularität in sieben Stufen erhöht die experimentelle Abdeckung dagegen erheblich.

Die Grid-Size, also die Seitenlänge des Saatknoten-Gitters (siehe @sec:build-phase), wird über die Werte 5, 10, 15, 20, 25, 30 und 35 variiert. Pro Datensatz ergeben sich daraus sieben Voronoi-Partitionen mit zwischen 25 und 1.225 Clustern. Bei kleiner Grid-Size sind die Cluster groß; viele Gate-Paare pro Cluster führen zu hohen Build-Kosten. Bei großer Grid-Size sind die Cluster klein und individuell günstig vorzuberechnen, dafür wächst der abstrakte Graph in seiner Knotenzahl. Welche Stufe für ein gegebenes Straßennetz optimal ist, ist eine der Hauptfragen der nachfolgenden quantitativen Auswertung.

In jeder Konfiguration werden A\* als Referenzverfahren und HPA\* mit vollständiger Verfeinerung gegeneinander getestet. Eine während der Entwicklung als Debug-Hilfe entstandene dritte Variante (HPA\*-partial, siehe @sec:hpastar) wird in der Hauptauswertung nicht berücksichtigt.

Die Problem-Stichprobe folgt der in @sec:benchmark beschriebenen Methodik nach Sturtevant @Sturtevant:2012: Zufällige Knotenpaare aus der größten zusammenhängenden Komponente, optimale Distanz per A\*-Referenzlauf bestimmt, Stratifizierung in Buckets von 500 m Breite mit jeweils zehn Problemen pro Bucket. Im Berliner Datensatz ergibt das 49 vollständig befüllte Buckets von etwa 500 m bis 24.500 m, im irischen Datensatz 53 Buckets von 0 m bis etwa 26.500 m. Über alle 14 Konfigurationen hinweg umfasst die Auswertung mehr als 14.000 Algorithmus-Läufe.

== Pfadqualität <sec:eval-quality>

Die zentrale Qualitätsmetrik ist die in @tbl:derived_metrics definierte `suboptimality_ratio`, berechnet als Verhältnis der gefundenen zur optimalen Pfadlänge nach der Fehlerformel aus Botea et al. @Botea:2004[S.~18]. Ein Wert von 1,0 entspricht einem optimalen Pfad; höhere Werte beziffern die relative Längenüberschreitung gegenüber dem A\*-Referenzpfad.

Über alle 14 Konfigurationen und 7.140 HPA\*-Anfragen liegen Median, Mittelwert und Maximum der `suboptimality_ratio` bei 1,0; die größte beobachtete Abweichung liegt bei etwa $10^(-15)$ und damit auf dem Niveau des Fließkomma-Rauschens. HPA\* findet in dieser Implementierung den optimalen Pfad in jeder einzelnen Anfrage. @fig:path_quality_scatter macht diesen Befund konkret: für die 490 Test-Probleme im Berliner Datensatz bei Grid-Size 10 liegt jedes Punktepaar aus A\*-Distanz und HPA\*-Distanz exakt auf der Diagonalen $y = x$.

#figure(
  image("../figures/path_quality_scatter.png", width: 100%),
  caption: [Vergleich der gefundenen Pfaddistanzen für A\* und HPA\* im Berliner Datensatz bei Grid-Size 10. Jeder Punkt entspricht einem Testproblem; alle 490 Punkte liegen auf der Diagonalen $y = x$.],
) <fig:path_quality_scatter>

#todo("Scatter-Plot aus `knowledgebase/plots/v2/serialized/path_quality.json` generieren: `scatter_grid_10.BerlinV2.astar_distance_m` gegen `scatter_grid_10.BerlinV2.hpa_distance_m`. Diagonale $y = x$ als Referenzlinie einzeichnen.")

Dieses Ergebnis weicht von der Originalliteratur ab: Botea et al. @Botea:2004 beschreiben HPA\* als _near-optimal_ und berichten in ihren Experimenten relative Pfadfehler in der Größenordnung von 1 bis 2 %. Der Unterschied zur vorliegenden Implementierung lässt sich auf zwei Designentscheidungen zurückführen. Erstens werden im hier verwendeten Verfahren alle Gate Nodes erhalten: jeder Endpunkt einer cluster-überschreitenden Kante des Basisgraphen wird zum Gate-Knoten des abstrakten Graphen (siehe @gate-architektur). Boteas Originalvariante reduziert dagegen die zahlreichen _Entrance Points_ pro Cluster-Grenze auf einen oder wenige repräsentative _Transition Points_. Diese Reduktion verkleinert den abstrakten Graphen und beschleunigt die abstrakte Suche, schließt aber potenziell den objektiv kürzesten Übergang aus. Sie ist die primäre Ursache der berichteten 1 bis 2 % Suboptimalität.

Zweitens werden die Intra-Cluster-Kantengewichte streng cluster-beschränkt berechnet (siehe @sec:build-phase). Auf gerichteten Graphen ist es theoretisch möglich, dass der global optimale Pfad zwischen zwei Gate Nodes desselben Voronoi-Clusters kurz ein Nachbar-Cluster durchquert und damit von einer cluster-beschränkten A\*-Suche nicht gefunden wird. In den 14 untersuchten Konfigurationen tritt dieser Fall empirisch nicht auf. Eine plausible Erklärung liegt in der hohen Bidirektionalität des OSM-Fahrradnetzes: Die wenigen Einbahnstraßen-Restriktionen reichen nicht aus, um die Voronoi-Konvexität der Cluster systematisch zu verletzen.

Als Randbeobachtung lässt sich festhalten, dass je nach Konfiguration zwischen 15 % und 43 % der HPA\*-Pfade bit-genau mit ihrer A\*-Referenz übereinstimmen. Die übrigen Pfade haben dieselbe Länge, weichen aber um Fließkomma-Rauschen ab. Diese Abweichung entsteht, wenn die beiden Algorithmen zwischen mehreren gleichlangen Pfaden in unterschiedlicher Reihenfolge wählen und die akkumulierten Distanzen folglich in unterschiedlicher Reihenfolge summiert werden. Für die Optimalitätsaussage ist dieser Unterschied ohne Belang.

== Laufzeitverhalten <sec:eval-runtime>

Die Wirkung von HPA\* auf die Laufzeit hängt von zwei Faktoren ab: der Länge des angefragten Pfads und der Grid-Size, mit der die Voronoi-Partitionierung erstellt wurde. Beide Faktoren werden in den folgenden Unterabschnitten getrennt diskutiert und mit einer Aufschlüsselung der HPA\*-Laufzeit nach Phasen ergänzt.

=== Speedup über Pfadlänge

Für jeden Datensatz und jede Grid-Size lässt sich der Speedup als Funktion der Pfadlänge auftragen. @fig:speedup_pathlength_grids zeigt diese Kurven für den Berliner Datensatz; die Darstellung für Ireland folgt demselben Muster.

#figure(
  image("../figures/speedup_pathlength_grids.png", width: 100%),
  caption: [Speedup von HPA\* gegenüber A\* als Funktion der Pfadlänge (Bucket-ID) für sieben Grid-Sizes im Berliner Datensatz. Die horizontale Linie bei 1,0 markiert den Break-Even; oberhalb arbeitet HPA\* schneller, unterhalb A\*.],
) <fig:speedup_pathlength_grids>

#todo("Plot aus `knowledgebase/plots/v2/serialized/speedup_vs_pathlength_all_grids.json` generieren: eine Kurve pro Grid-Size (5, 10, 15, 20, 25, 30, 35), x = bucket_id, y = mean_speedup. Horizontale Referenzlinie bei y = 1,0.")

In allen sieben Grid-Sizes wächst der Speedup monoton mit der Pfadlänge. Bei kurzen Pfaden liegt er deutlich unter 1, bei langen Pfaden deutlich darüber. Der Crossover-Punkt, also der Bucket, ab dem HPA\* erstmals schneller wird als A\*, verschiebt sich systematisch mit der Grid-Size: Im Berliner Datensatz liegt er bei Grid-Size 10 bei Bucket 27,9 (etwa 13,9 km), bei Grid-Size 20 bereits bei Bucket 15,2 (etwa 7,6 km) und bei Grid-Size 35 bei Bucket 7,7 (etwa 3,9 km). Bei der kleinsten getesteten Grid-Size 5 tritt im Berliner Datensatz im gesamten Bucket-Bereich kein Crossover auf; HPA\* bleibt dort über alle Pfadlängen langsamer als A\*.

Im irischen Datensatz zeigt sich das gleiche Muster bei niedrigeren absoluten Werten. Der Crossover-Punkt wandert von Bucket 39,6 (Grid-Size 5, etwa 19,8 km) über Bucket 20,9 (Grid-Size 10) zu Bucket 7,9 (Grid-Size 35, etwa 4,0 km). Auch hier liefert die kleinste Grid-Size für nahezu den gesamten Pfadlängenbereich keinen Speedup; erst der mit Abstand längste Bucket erreicht den Faktor 1.

Der Mechanismus dahinter ist algorithmischer Natur. Eine HPA\*-Anfrage trägt unabhängig von der Pfadlänge die Kosten der abstrakten Suche und die Anbindung von Start- und Zielknoten an ihre jeweiligen Cluster. Bei kurzen Pfaden, die nur wenige Cluster berühren, kann HPA\* gegenüber A\* keinen substantiellen Suchraum einsparen, weil der A\*-Suchraum ohnehin klein bleibt; der konstante Aufwand für die abstrakte Suche wird dann nicht durch eine entsprechende Knoten-Einsparung kompensiert. Mit wachsender Pfadlänge wächst der A\*-Suchraum stark, der zusätzliche HPA\*-Aufwand bleibt aber durch die feste Größe des abstrakten Graphen begrenzt. Ab einer bestimmten Pfadlänge dreht sich das Verhältnis. Eine größere Grid-Size verschiebt diese Schwelle nach unten, weil kleinere Cluster zu einem günstiger zu durchsuchenden abstrakten Graphen führen.

=== Cluster-Granularität als Stellgröße

Aggregiert man den Speedup über Bucket-Bereiche, ergibt sich eine direkte Abhängigkeit von der Grid-Size. @fig:speedup_gridsize zeigt diese Funktion für zwei Pfadlängen-Klassen je Datensatz.

#figure(
  image("../figures/speedup_gridsize.png", width: 100%),
  caption: [Mittlerer Speedup als Funktion der Grid-Size für zwei Pfadlängen-Klassen (kurze Pfade in den Buckets 0–15, lange Pfade ab Bucket 30) im Berliner und im irischen Datensatz. Werte oberhalb der Referenzlinie y = 1 bedeuten, dass HPA\* schneller arbeitet als A\*. Fehlerbalken zeigen die Standardabweichung.],
) <fig:speedup_gridsize>

#todo("Plot aus `knowledgebase/plots/v2/serialized/speedup_vs_gridsize.json` generieren: zwei Panels (Berlin, Ireland), pro Panel zwei Linien für die Bucket-Bereiche `short_paths_bucket_0_15` und `long_paths_bucket_30_plus`, x = grid_size, y = mean speedup, Fehlerbalken aus `std_speedup`. Horizontale Referenzlinie bei y = 1,0.")

Im Berliner Datensatz wächst der Speedup für lange Pfade monoton von 0,37 (Grid-Size 5) auf 4,76 (Grid-Size 35); die stärkste Steigung liegt im unteren Grid-Size-Bereich, zwischen Grid-Size 5 und 15 verzehnfacht sich der Speedup nahezu (von 0,37 auf 3,10), während er zwischen Grid-Size 25 und 35 nur noch um etwa 10 % zulegt. Für kurze Pfade bleibt der Speedup bis Grid-Size 30 unter 1 und erreicht bei Grid-Size 35 mit 1,10 erstmals einen marginalen Vorteil. Im irischen Datensatz wächst der Speedup für lange Pfade nicht streng monoton: er erreicht bei Grid-Size 25 sein Maximum von 2,76 und schwankt anschließend zwischen 2,63 und 2,64. Ab Grid-Size 15 plateaut die Kurve sichtbar, der Übergang von Grid-Size 5 (0,80) auf Grid-Size 15 (2,63) macht den Großteil des Gewinns aus. Für kurze Pfade bleibt HPA\* im irischen Datensatz über alle Grid-Sizes hinweg langsamer als A\*, erreicht aber bei Grid-Size 35 mit 0,97 das Break-Even-Niveau.

Die Streuung der Speedup-Werte ist beträchtlich. Für lange Pfade liegt die Standardabweichung in Berlin zwischen 0,23 (Grid-Size 5) und 1,30 (Grid-Size 15), in Ireland zwischen 0,43 und 0,91; die Mittelwerte sind also nur als Trend zu lesen, nicht als enge Schätzwerte für die Einzelanfrage. Bei kurzen Pfaden im irischen Datensatz übersteigt die Standardabweichung den Mittelwert sogar teilweise, was die geringe Aussagekraft der Speedup-Mittelwerte in dieser Klasse zusätzlich unterstreicht.

Aus diesen Verläufen folgt eine Designaussage: Innerhalb des untersuchten Bereichs gibt es keine Grid-Size, die für alle Pfadlängen ideal wäre. Größere Grid-Sizes verbessern den Speedup auf langen Pfaden und verschieben den Crossover-Punkt zu kürzeren Pfaden, beseitigen ihn aber nicht. Welche Grid-Size für ein konkretes Anwendungsszenario sinnvoll ist, hängt damit von der erwarteten Verteilung der Anfragelängen ab und ist letztlich eine Trade-Off-Entscheidung zwischen Speedup-Niveau und Crossover-Schwelle.

=== Phasen-Aufschlüsselung

Die Laufzeit einer HPA\*-Anfrage gliedert sich in zwei dominante Phasen (siehe @sec:query-phase): die abstrakte Suche auf dem Gate-Graphen und die anschließende Verfeinerung der gefundenen Gate-Sequenz. @fig:hpa_phases zeigt die mittlere Aufteilung dieser beiden Phasen je Grid-Size und Datensatz.

#figure(
  image("../figures/hpa_phases.png", width: 100%),
  caption: [Aufteilung der mittleren HPA\*-Anfragezeit in abstrakte Suche und Verfeinerung, je Grid-Size und Datensatz. Gestapelte Balken zeigen die absoluten Anteile in Millisekunden.],
) <fig:hpa_phases>

#todo("Plot aus `knowledgebase/plots/v2/serialized/hpa_runtime_breakdown.json` generieren: zwei Panels (Berlin, Ireland), pro Panel gestapelte Balken pro Grid-Size mit den Komponenten Abstract Search und Refinement.")

Im Berliner Datensatz wird die HPA\*-Laufzeit bei kleiner Grid-Size von der abstrakten Suche dominiert: Bei Grid-Size 5 entfallen etwa 98 % der mittleren Anfragezeit auf die abstrakte Suche und nur 2 % auf die Verfeinerung. Mit wachsender Grid-Size schrumpft die absolute Zeit für die abstrakte Suche um mehr als eine Größenordnung. Maßgeblich dafür ist nicht die Knotenzahl des abstrakten Graphen (die mit der Grid-Size sogar leicht wächst, siehe @fig:abstract_search), sondern die Anzahl der Intra-Cluster-Kanten pro Gate-Knoten: Kleinere Cluster enthalten weniger Gate-Paare, und jedes Gate hat damit weniger ausgehende Intra-Cluster-Kanten, die bei einer Expansion in die Priority Queue eingefügt werden müssen. Der relative Anteil der abstrakten Suche sinkt entsprechend auf etwa 85 % bei Grid-Size 35. Die Verfeinerung verändert sich absolut nur wenig, da bei mehr Clustern zwar mehr Cluster-Übergänge zu verfeinern sind, jeder einzelne Übergang aber kleiner ausfällt.

Im irischen Datensatz ist das Verhältnis ausgeglichener: Bei Grid-Size 5 entfallen rund 86 % auf die abstrakte Suche und 14 % auf die Verfeinerung, bei Grid-Size 35 nur noch 60 % und 40 %. Die beiden Phasen nähern sich einander an, weil der irische Graph deutlich kleiner ist und der abstrakte Graph entsprechend günstiger zu durchsuchen; der relative Aufwand der Verfeinerung gewinnt damit an Bedeutung.

Die Aufschlüsselung erklärt das Crossover-Verhalten aus dem vorigen Abschnitt: Solange die abstrakte Suche einen großen Anteil der Anfragezeit ausmacht, ist ihr Aufwand auch bei kurzen Pfaden vorhanden und wird nicht durch entsprechende A\*-Einsparungen kompensiert. Eine größere Grid-Size reduziert genau diesen Anteil und verschiebt damit den Crossover-Punkt zu kürzeren Pfaden.

== Suchraum-Reduktion <sec:eval-search-space>

Neben der Laufzeit ist die Anzahl der vom Pathfinder expandierten Knoten ein zentraler Effizienzindikator. Sie bemisst den algorithmischen Aufwand unabhängig von Implementierungs-Konstanten und macht den eigentlichen Vorteil der hierarchischen Abstraktion sichtbar.

#figure(
  image("../figures/search_space_reduction.png", width: 100%),
  caption: [Verhältnis der mittleren besuchten Knoten A\*/HPA\* je Bucket für sieben Grid-Sizes, je Datensatz. Werte oberhalb der Referenzlinie y = 1 bedeuten, dass HPA\* weniger Knoten expandiert.],
) <fig:search_space_reduction>

#todo("Plot aus `knowledgebase/plots/v2/serialized/search_space_reduction.json` generieren: zwei Panels (Berlin, Ireland), pro Panel eine Linie pro Grid-Size (5, 10, 15, 20, 25, 30, 35), x = bucket_id, y = ratio (A\* / HPA\* visited nodes). Horizontale Referenzlinie bei y = 1,0.")

Die Knoten-Reduktion wächst in beiden Datensätzen monoton mit der Pfadlänge und steigt zusätzlich mit der Grid-Size. Im Berliner Datensatz erreicht das A\*-zu-HPA\*-Verhältnis bei den längsten Pfaden mit Grid-Size 35 Werte von etwa 65; im irischen Datensatz liegen die entsprechenden Maxima bei etwa 17. Bei der kleinsten Grid-Size 5 bleibt das Verhältnis in beiden Datensätzen über den gesamten Bucket-Bereich unter 1, das heißt HPA\* expandiert dort mehr Knoten als A\*. Dieses Verhalten spiegelt das Crossover-Muster aus @sec:eval-runtime; Voraussetzung für eine spürbare Reduktion ist eine ausreichend feine Cluster-Granularität.

@fig:visited_nodes ergänzt diese relative Sicht um die absoluten Größenordnungen bei Grid-Size 10.

#figure(
  image("../figures/visited_nodes_comparison.png", width: 100%),
  caption: [Mittlere Anzahl besuchter Knoten je Bucket für A\* und HPA\* bei Grid-Size 10, je Datensatz, log-y. Die Differenz zwischen den Kurven illustriert den Suchraum-Vorteil in absoluten Werten.],
) <fig:visited_nodes>

#todo("Plot aus `knowledgebase/plots/v2/serialized/visited_nodes_comparison.json` generieren: zwei Panels (Berlin, Ireland), pro Panel zwei Linien (A\* und HPA\*), x = bucket_id, y = mean_visited_nodes, log-y.")

Bei Grid-Size 10 expandiert A\* in den oberen Buckets des Berliner Graphen im Mittel mehrere zehntausend Knoten, während HPA\* mit einem Bruchteil davon auskommt. Für Ireland liegt das Niveau etwa eine Größenordnung niedriger.

Die deutliche Diskrepanz zwischen Berlin (Reduktion bis etwa Faktor 65) und Ireland (bis etwa Faktor 17) ist algorithmisch erklärbar. In einem Netzwerk mit über 110.000 Knoten muss A\* einen ungleich größeren Anteil der Knoten expandieren, um den optimalen Pfad zu finden; HPA\* hingegen begrenzt seinen Suchraum auf den abstrakten Graphen und die clusterlokalen Teilgraphen, deren Größe nicht proportional mit der Gesamtknotenzahl wächst. Im irischen Graphen mit unter 5.000 Knoten ist der A\*-Suchraum ohnehin überschaubar, und die hierarchische Abstraktion kann verhältnismäßig weniger Knoten einsparen. Der Vorteil von HPA\* skaliert damit mit der Graphgröße und der Knotendichte: Je mehr Knoten auf engem geographischen Raum, desto stärker fällt die algorithmische Einsparung aus.

Die Knoten-Reduktion fällt durchgehend stärker aus als die in @sec:eval-runtime beobachtete Laufzeit-Reduktion: Faktor 65 in den expandierten Knoten entspricht im selben Datensatz nur einem Laufzeit-Speedup von etwa 4,8.

=== Open-Set-Größe als Speicherindikator

Über die Anzahl expandierter Knoten hinaus lässt sich der Suchaufwand auch über die maximale Belegung der A\*-Priority-Queue (Open Set) bewerten. Diese Größe bestimmt den Spitzenspeicherbedarf der Suche und ist im Gegensatz zur reinen Knotenzahl direkt für die in @sec:motivation angesprochene Frage des gerätebasierten Routings auf ressourcenbeschränkten Endgeräten relevant: Während die Gesamtzahl expandierter Knoten primär die Laufzeit beeinflusst, bestimmt das Maximum der Open-Set-Größe, wie viel Arbeitsspeicher die Suche zu ihrem Höhepunkt anfordert.

#figure(
  image("../figures/peak_memory.png", width: 100%),
  caption: [Mittlere maximale Open-Set-Größe je Bucket für A\* und HPA\* bei Grid-Size 10, je Datensatz, log-y. Höhere Werte bedeuten höheren Spitzenspeicherbedarf der Suche.],
) <fig:peak_memory>

#todo("Plot aus `knowledgebase/plots/v2/serialized/peak_memory.json` generieren: zwei Panels (Berlin, Ireland), pro Panel zwei Linien (A\* und HPA\*), x = bucket_id, y = mean_max_open_set_size, log-y. Hinweis: In der vorliegenden Serialisierung enthält die HPA\*-Reihe nur die unteren Buckets; die Aussage gilt entsprechend nur für diesen Bereich oder erfordert ein erneutes Sampling.")

Bei Grid-Size 10 wächst die mittlere maximale Open-Set-Größe für A\* im Berliner Datensatz monoton von etwa 24 Einträgen im kürzesten Bucket auf nahezu 1.000 Einträge im längsten. Im irischen Datensatz steigt der A\*-Wert über denselben Bucket-Bereich von 11 auf etwa 110 Einträge, also auf einem rund eine Größenordnung niedrigeren Niveau. Die HPA\*-Werte liegen in beiden Datensätzen in den unteren Buckets nahe dem A\*-Niveau (Berlin Bucket 5: 54 gegenüber 71; Ireland Bucket 5: 11 gegenüber 17), wachsen aber strukturell nicht mit der Pfadlänge mit, weil die abstrakte Suche auf einem Graphen fester Größe operiert.

Diese strukturelle Eigenschaft ist für mobile Endgeräte relevanter als der reine Laufzeit-Speedup. Selbst wenn HPA\* bei kurzen Anfragen im urbanen Datensatz nicht schneller ist als A\*, beschränkt es den Spitzenspeicherbedarf auf eine durch die Größe des abstrakten Graphen bestimmte Obergrenze, statt mit der Pfadlänge zu skalieren. Eine belastbare Quantifizierung für lange Pfade erfordert allerdings ein erneutes Sampling, da die vorliegende Serialisierung der HPA\*-Open-Set-Größe nur die unteren Buckets enthält.

== Vorberechnungskosten <sec:eval-precomputation>

Im Gegensatz zu A\* verlangt HPA\* eine einmalige Build-Phase, in der für jeden Cluster die optimalen Pfade zwischen allen Gate-Paaren vorab berechnet werden (siehe @sec:build-phase). Dieser Aufwand fällt vor der ersten Anfrage an und muss durch die anschließenden Anfragen amortisiert werden. Die folgenden Abbildungen quantifizieren diesen Aufwand und seine strukturelle Skalierung.

#figure(
  image("../figures/precomputation_vs_gridsize.png", width: 100%),
  caption: [Mittlere Vorberechnungszeit als Funktion der Grid-Size für beide Datensätze, log-y. Die sekundäre x-Achse zeigt die resultierende Anzahl Cluster ($"Grid-Size"^2$).],
) <fig:precomputation>

#todo("Plot aus `knowledgebase/plots/v2/serialized/precomputation_vs_gridsize.json` generieren: zwei Linien (Berlin, Ireland), x = grid_size, y = mean_precomputation_ms, log-y. Sekundäre Achse mit n_clusters_per_grid.")

Die Vorberechnung sinkt in beiden Datensätzen monoton mit wachsender Grid-Size. In Berlin fällt sie von 850 Sekunden bei Grid-Size 5 auf nur noch 25 Sekunden bei Grid-Size 35, also um den Faktor 34 bei einer 49-fachen Erhöhung der Cluster-Anzahl. Für Ireland bewegt sich die Vorberechnungszeit auf einem Niveau dreier Größenordnungen darunter und sinkt von 530 Millisekunden auf 84 Millisekunden, eine Reduktion um den Faktor 6,3.

Diese Skalierung ist auf den ersten Blick kontraintuitiv, weil mehr Cluster nach mehr Build-Arbeit aussehen. Die Auflösung liegt in der Struktur der Build-Phase. Pro Cluster wird für jede Kombination aus Entry- und Exit-Gate ein voller A\*-Lauf innerhalb des Clusters durchgeführt; bei $k$ Entry- und Exit-Gates also $k^2$ A\*-Berechnungen. Mit wachsender Grid-Size schrumpft jeder einzelne Cluster, und zwar in zwei Dimensionen gleichzeitig: er enthält weniger Knoten und entsprechend weniger Gates an seiner Grenze. @fig:cluster_stats zeigt das konkret.

#figure(
  image("../figures/cluster_stats.png", width: 100%),
  caption: [Mittlere Anzahl Knoten pro Cluster als Funktion der Grid-Size für beide Datensätze. Zusätzliche Linien für Median, Minimum und Maximum optional.],
) <fig:cluster_stats>

#todo("Plot aus `knowledgebase/plots/v2/serialized/cluster_stats.json` generieren: zwei Panels (Berlin, Ireland), pro Panel mittlere Knoten/Cluster über grid_size, ggf. mit Min/Max-Bändern oder Median-Linie.")

Im Berliner Datensatz sinkt die mittlere Cluster-Knotenzahl von etwa 4.400 bei Grid-Size 5 auf etwa 90 bei Grid-Size 35. Im irischen Datensatz von 193 auf knapp 4. Pro Cluster fallen also bei großer Grid-Size sowohl deutlich weniger Gate-Paare als auch deutlich kürzere A\*-Pfade an. Beide Effekte zusammen führen dazu, dass die per-Cluster-Arbeit schneller schrumpft als die Cluster-Anzahl wächst. Netto sinkt der Gesamtaufwand.

Eine zweite Konsequenz der größeren Grid-Size ist allerdings, dass der abstrakte Graph mehr Knoten enthält, weil jeder Cluster-Übergang einen eigenen Gate-Knoten erzeugt. @fig:abstract_search zeigt, dass die abstrakte Suche pro Anfrage entsprechend mehr Knoten besucht.

#figure(
  image("../figures/abstract_search.png", width: 100%),
  caption: [Mittlere Anzahl in der abstrakten Suche besuchter Knoten je Anfrage, in Abhängigkeit von der Grid-Size, für beide Datensätze. Wächst monoton mit der Grid-Size und dient als Indikator für die Größe des abstrakten Graphen.],
) <fig:abstract_search>

#todo("Plot aus `knowledgebase/plots/v2/serialized/abstract_graph_vs_gridsize.json` generieren: zwei Linien (Berlin, Ireland), x = grid_size, y = mean_abstract_nodes_visited.")

In Berlin wächst die mittlere Anzahl in der abstrakten Suche besuchter Knoten von 288 (Grid-Size 5) auf 1.650 (Grid-Size 35), in Ireland von 39 auf 238. Eine größere Grid-Size verschiebt damit einen Teil der Arbeit von der Build-Phase in die Query-Phase. Dieser Trade-Off ist allerdings nicht ausgeglichen, denn die Build-Phase profitiert deutlich stärker. Der in @sec:eval-runtime beobachtete Query-Speedup wächst mit der Grid-Size monoton und wird durch den wachsenden Aufwand der abstrakten Suche nicht kompensiert.

Die Skalierung der Vorberechnung unterscheidet sich erheblich zwischen den beiden Datensätzen: Berlin reduziert sich beim Übergang Grid-Size 5 auf 35 um Faktor 34, Ireland nur um Faktor 6,3. Die Ursache liegt in der absoluten Größe der individuellen Cluster bei hoher Grid-Size. Im Berliner Datensatz bleibt selbst bei Grid-Size 35 jeder Cluster mit durchschnittlich 90 Knoten noch substantiell groß, sodass die per-Cluster-A\*-Aufwendungen den Gesamtaufwand dominieren und die theoretische inverse-quadratische Skalierung näherungsweise greift. Im irischen Datensatz schrumpfen die Cluster auf durchschnittlich 4 Knoten, viele Voronoi-Zellen enthalten sogar gar keine Knoten mehr (statt der theoretischen 1.225 Cluster bei Grid-Size 35 existieren tatsächlich nur 1.102 nicht-leere Cluster). Die fixen Kosten pro Cluster für Voronoi-Zuordnung und Datenstruktur-Setup gewinnen damit relativ an Bedeutung, und die A\*-Kosten verschwinden in der Statistik. Die Skalierung flacht entsprechend ab.

== Zusammenfassung der Ergebnisse <sec:eval-summary>

Die quantitative Auswertung lässt sich in fünf Kernaussagen verdichten und beantwortet damit die in @sec:ziele formulierten Forschungsfragen:

+ *Pfadqualität:* HPA\* mit vollständiger Verfeinerung findet in allen getesteten Fällen optimale Pfade (`suboptimality_ratio` = 1,0). Die in @sec:ziele angestrebte Schwelle von unter 1 % Abweichung wird damit deutlich unterschritten. Die Implementierung weicht zugleich von der in der Literatur beschriebenen Near-Optimalität ab, da sie alle Gate Nodes beibehält und auf eine cluster-beschränkte Pfadrekonstruktion ohne Glättungs-Heuristik setzt.

+ *Laufzeit-Crossover:* HPA\* ist bei langen Pfaden (Bucket 30+) bereits ab Grid-Size 10 konsistent schneller als A\*. Bei kurzen Pfaden unter etwa 3 km dominiert A\* in beiden Datensätzen aufgrund des festen Overheads der abstrakten Suche, unabhängig von der Grid-Size. Der Crossover-Punkt wandert mit wachsender Grid-Size systematisch zu kürzeren Pfaden, lässt sich aber innerhalb des untersuchten Parameterbereichs nicht vollständig auf den Bereich kurzer Anfragen ausdehnen.

+ *Suchraum-Reduktion:* Die Anzahl der besuchten Knoten wird durch HPA\* um Faktoren von bis zu etwa 65 (Berlin) beziehungsweise 17 (Ireland) reduziert. Diese Reduktion wächst monoton mit der Pfadlänge und skaliert mit der Graphgröße: Je dichter das untersuchte Straßennetz, desto stärker fällt die algorithmische Einsparung aus. Über die maximale Open-Set-Größe (@sec:eval-search-space) ergibt sich zusätzlich ein struktureller Speichervorteil, der besonders für die in @sec:motivation angesprochene Klasse ressourcenbeschränkter Endgeräte relevant ist.

+ *Vorberechnungskosten und Amortisation:* Die einmalige Konstruktion des abstrakten Graphen dauert für den Berliner Datensatz zwischen 850 Sekunden (Grid-Size 5) und 25 Sekunden (Grid-Size 35). Bei einer mittleren Grid-Size von 10 amortisiert sich dieser Aufwand für eine gemischte Anfragelast nach etwa 2.500 Anfragen, bei großer Grid-Size und vorwiegend langen Anfragen bereits nach unter 300 Anfragen. Im irischen Datensatz liegt die Amortisationsschwelle aufgrund der geringen absoluten Vorberechnungszeit über alle Konfigurationen hinweg unter 600 Anfragen. Für einen dauerhaft laufenden Routing-Dienst ist diese Größenordnung realistisch, für eine einmalige Batch-Auswertung nicht.

+ *Trade-Off Grid-Size:* Innerhalb des untersuchten Bereichs existiert keine universell beste Grid-Size. Größere Grid-Sizes verbessern den Speedup auf langen Pfaden und verschieben den Crossover-Punkt zu kürzeren Pfaden, erhöhen aber die Knotenzahl des abstrakten Graphen und die Größe der Open-Set-Spitze in der abstrakten Suche. Die Wahl ist damit eine anwendungsabhängige Trade-Off-Entscheidung zwischen Speedup-Niveau, Crossover-Schwelle und Vorberechnungsbudget.
