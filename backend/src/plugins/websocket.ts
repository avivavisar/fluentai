import fp from 'fastify-plugin';
import websocket from '@fastify/websocket';

// Registers WebSocket support. A connectivity-check endpoint lives at /ws/health.
// Real conversation streaming is added in Increment 1/2.
export default fp(async (app) => {
  await app.register(websocket);

  app.get('/ws/health', { websocket: true }, (connection) => {
    connection.socket.send(JSON.stringify({ type: 'connected' }));
    connection.socket.on('message', (raw: Buffer) => {
      connection.socket.send(JSON.stringify({ type: 'echo', data: raw.toString() }));
    });
  });
});
