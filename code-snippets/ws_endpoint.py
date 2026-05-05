@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_json()
        start_node = pathfinder.find_nearest_node(data['start_lat'], data['start_lon'])
        end_node   = pathfinder.find_nearest_node(data['end_lat'],   data['end_lon'])
        delay_ms   = data.get('delay_ms', 50)

        for state in pathfinder.a_star_generator(start_node, end_node):
            await websocket.send_json(state)
            if delay_ms > 0:
                await asyncio.sleep(delay_ms / 1000.0)
