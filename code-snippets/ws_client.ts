wsAstar = new WebSocket(`${WS_BASE}/ws`)

wsAstar.onopen = () => {
  wsAstar!.send(JSON.stringify({
    start_lat: startCoord.value![0],
    start_lon: startCoord.value![1],
    end_lat:   endCoord.value![0],
    end_lon:   endCoord.value![1],
    realtime, delay_ms: delayMs,
  }))
}

wsAstar.onmessage = (evt) => {
  const msg: WsMessage = JSON.parse(evt.data)
  if (msg.stats) astarStats.value = msg.stats

  if (msg.type === 'visiting') {
    const [lat, lon] = msg.coords
    L.circleMarker([lat, lon], { radius: 3, color: '#e74c3c' })
      .addTo(astarVisitedLayer.value)
  } else if (msg.type === 'exploring') {
    const [lat, lon] = msg.coords
    L.circleMarker([lat, lon], { radius: 5, color: '#de04ff' })
      .addTo(astarExploringLayer.value)
  } else if (msg.type === 'complete') {
    astarStatus.value = 'complete'
    L.polyline(msg.coords, { color: '#3b82f6', weight: 5 })
      .addTo(astarPathLayer.value)
  }
}
