const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('--- DEPLOY COM AUDITORIA DE CAMPOS ---');
  
  const commands = [
    'cd /home/chatwoot/chatwoot && git stash && git pull custom develop',
    'systemctl restart chatwoot-web.1 chatwoot-worker.1'
  ];

  const executeCommand = (index) => {
    if (index >= commands.length) {
      console.log('--- VPS ATUALIZADA! O CÓDIGO AGORA VAI LOGAR AS CHAVES DA META. TESTE NOVAMENTE. ---');
      conn.end();
      return;
    }

    console.log(`Rodando: ${commands[index]}`);
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
