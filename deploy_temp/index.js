const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('Validando alteração no .env...');
  conn.exec(`grep "INSTAGRAM_VERIFY_TOKEN" /home/chatwoot/chatwoot/.env`, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => conn.end()).on('data', (data) => {
      console.log('ATUALIZADO: ' + data);
    });
  });
}).connect({
  host: '195.7.7.220', port: 22, username: 'root', password: 'Ap@lo20060'
});
