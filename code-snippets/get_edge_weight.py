def get_edge_weight(self, u: int, v: int) -> float:
    try:
        edges = self.graph[u][v]
        if edges:
            return min(edge_data.get('length', 100.0)
                       for edge_data in edges.values())
        return 100.0
    except KeyError:
        return float('inf')