class Osm:
    FILE_PATH = Path("data/graph.graphml")

    def __init__(self, latitude, longitude, distance, graph_type="bike"):
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.graph_type = graph_type
        self.graph = nx.MultiDiGraph()

    def get_graph(self):
        if self.load_graph():
            return self.graph
        self.graph = ox.graph.graph_from_point(
            center_point=(self.latitude, self.longitude),
            network_type=self.graph_type,
            dist=self.distance)
        self.save_osm_graph()
        return self.graph

    def load_graph(self):
        p = self.FILE_PATH
        if not p.exists() or p.stat().st_size == 0:
            return False
        try:
            self.graph = ox.load_graphml(str(p))
            return True
        except Exception:
            return False

    def save_osm_graph(self):
        self.FILE_PATH.parent.mkdir(parents=True, exist_ok=True)
        ox.save_graphml(self.graph, filepath=str(self.FILE_PATH))