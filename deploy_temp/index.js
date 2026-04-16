const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('Aplicando fix Meta Unified na VPS...');
  
  const commands = [
    'cd /home/chatwoot/chatwoot && git stash && git pull custom develop',
    'systemctl restart chatwoot-web.1 chatwoot-worker.1'
  ];

  const executeCommand = (index) => {
    if (index >= commands.length) {
      console.log('REINICIADO NA API META v21.0! TENTE O INSTAGRAM AGORA.');
      conn.end();
      return;
    }

    console.log(`Executando: ${commands[index]}`);
    conn.exec(commands[index], (err, stream) => {
      if (err) throw err;
      stream.on('close', () => executeCommand(index + 1))
            .on('data', (d) => console.log('LOG: ' + d));
    });
  };

  executeCommand(0);

}).connect({
  host: '195.7.7.220', port: 22, username: 'root', password: 'Ap@lo20060'
});
