for u, v in self.graph.edges():
    seed_u = self.node_region.get(u)
    seed_v = self.node_region.get(v)
    if seed_u is None or seed_v is None or seed_u == seed_v:
        continue

    edge_len = min(e.get("length", 100.0)
                   for e in self.graph[u][v].values())

    for node in (u, v):
        if node not in self.abstract_graph:
            nd = self.graph.nodes[node]
            self.abstract_graph.add_node(node, x=nd["x"], y=nd["y"])

    self.abstract_graph.add_edge(u, v, weight=edge_len, inter=True)
    cluster_exits[seed_u].append(u)
    cluster_entries[seed_v].append(v)
