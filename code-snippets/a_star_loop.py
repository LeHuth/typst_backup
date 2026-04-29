while open_set:
    current_f, current = heapq.heappop(open_set)
    heap_pops += 1

    if current in closed_set:
        continue
    closed_set.add(current)
    visited_nodes_count += 1

    yield {'type': 'visiting', 'node': current, ...}

    if current == end_node:
        path = self._reconstruct_path(came_from, current)
        yield {'type': 'complete', 'path': path,
               'distance': g_score[current], ...}
        return

    for neighbor in self.graph.neighbors(current):
        if neighbor in closed_set:
            continue

        edge_weight = self.get_edge_weight(current, neighbor)
        tentative_g = g_score[current] + edge_weight

        if neighbor not in g_score or tentative_g < g_score[neighbor]:
            came_from[neighbor] = current
            g_score[neighbor] = tentative_g
            h = self.haversine_distance(neighbor, end_node)
            f_score[neighbor] = tentative_g + h
            heapq.heappush(open_set, (f_score[neighbor], neighbor))
            heap_pushes += 1

            yield {'type': 'exploring', 'node': neighbor,
                   'from': current, ...}