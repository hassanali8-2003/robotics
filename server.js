// server.js
const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });
wss.on('connection', function connection(ws) {
    console.log('Client connected');

    ws.on('message', function incoming(message) {
        try {
            // 🔥 Convert Buffer → String
            const dataString = message.toString();

            // 🔥 Parse JSON
            const data = JSON.parse(dataString);

            console.log("Parsed Data:", data);

            // 🔥 Broadcast to all connected clients (Flutter)
            wss.clients.forEach(function each(client) {
                if (client.readyState === WebSocket.OPEN) {
                    client.send(JSON.stringify(data));
                }
            });

        } catch (err) {
            console.error("Error parsing message:", err);
        }
    });
});



console.log('WebSocket server running on ws://localhost:8080');
