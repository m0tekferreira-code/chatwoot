const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('--- BUSCANDO MARCADORES DE DEBUG [Instagram-Auth] ---');
  conn.exec(`journalctl -u chatwoot-web.1 -n 500 | grep "Instagram-Auth"`, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => conn.end()).on('data', (d) => console.log('DEBUG LOG:\n' + d));
  });

}).connect({
  host: '195.7.7.220', port: 22, username: 'root', password: 'Ap@lo20060'
});
