const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  conn.exec(`grep "FRONTEND_URL" /home/chatwoot/chatwoot/.env`, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => conn.end()).on('data', (data) => {
      console.log('RESULTADO: ' + data);
    });
  });
}).connect({
  host: '195.7.7.220', port: 22, username: 'root', password: 'Ap@lo20060'
});
