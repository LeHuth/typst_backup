for neighbor in self.graph.neighbors(current):
    if node_allowlist is not None and neighbor not in node_allowlist:
        continue
    if neighbor in closed_set:
        continue
    ...
