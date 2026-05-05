end_extra: dict[int, float] = {}
for v in entries:
    _, cost = self._low_level.a_star(v, end_node, node_allowlist=end_allowlist)
    if not math.isinf(cost):
        end_extra[v] = cost

for gate_u in exits:
    _, cost = self._low_level.a_star(start_node, gate_u, node_allowlist=start_allowlist)
    if math.isinf(cost):
        continue
    g[gate_u] = cost
    h = self._node_haversine(gate_u, end_node)
    heapq.heappush(open_set, (cost + h, counter, gate_u, None))
