def haversine_distance(self, node1_id: int, node2_id: int) -> float:
    node1 = self.graph.nodes[node1_id]
    node2 = self.graph.nodes[node2_id]

    lat1, lon1 = math.radians(node1['y']), math.radians(node1['x'])
    lat2, lon2 = math.radians(node2['y']), math.radians(node2['x'])

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))

    return 6371000 * c  # Erdradius in Meter