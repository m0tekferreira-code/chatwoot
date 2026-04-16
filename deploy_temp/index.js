const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('Buscando erro de troca de token no Rails...');
  
  // journalctl buscando por erros no CallbacksController do Instagram
  conn.exec(`journalctl -u chatwoot-web.1 -n 500 | grep "Instagram Channel creation Error"`, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => conn.end()).on('data', (d) => console.log('LOG: ' + d));
  });

}).connect({
  host: '195.7.7.220', port: 22, username: 'root', password: 'Ap@lo20060'
});
