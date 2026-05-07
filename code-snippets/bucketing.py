while done < n_samples:
    start, end = random.sample(node_list, 2)
    result = self._reference.find_path(start, end)
    done += 1

    if not result.found or math.isinf(result.distance_m):
        continue

    bucket_id = int(result.distance_m // bucket_width_m)
    bucket = buckets.setdefault(bucket_id, [])
    if len(bucket) < max_per_bucket:
        bucket.append(Problem(start=start, end=end,
                              optimal_m=result.distance_m,
                              straight_line_m=self._haversine(start, end),
                              bucket_id=bucket_id))
