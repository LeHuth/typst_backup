seed_xs, seed_ys = [], []
for i in range(grid_size):
    for j in range(grid_size):
        seed_xs.append(x_min + (i + 0.5) * (x_max - x_min) / grid_size)
        seed_ys.append(y_min + (j + 0.5) * (y_max - y_min) / grid_size)

node_ids = ox.distance.nearest_nodes(projected, seed_xs, seed_ys)
return list(dict.fromkeys(node_ids))