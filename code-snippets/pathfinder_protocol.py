@runtime_checkable
class PathfinderProtocol(Protocol):
    name: str

    def find_path(self, start: int, end: int) -> PathResult:
        ...
