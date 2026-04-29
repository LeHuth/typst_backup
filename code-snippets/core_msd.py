for seed in seeds:
    if seed in ug:
        dist[seed] = 0.0
        region[seed] = seed
        heapq.heappush(heap, (0.0, seed, seed))

while heap:
    d, node, seed_node = heapq.heappop(heap)
    if dist.get(node, float("inf")) < d:
        continue

    for neighbor in ug.neighbors(node):
        edges = ug[node][neighbor]
        edge_len = min(e.get(weight, 1.0) for e in edges.values())
        new_d = d + edge_len
        if new_d < dist.get(neighbor, float("inf")):
            dist[neighbor] = new_d
            region[neighbor] = seed_node
            heapq.heappush(heap, (new_d, neighbor, seed_node))