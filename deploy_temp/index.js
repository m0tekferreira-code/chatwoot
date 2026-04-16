const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('Consultando banco de dados diretamente...');
  
  // Usando bundle exec rails runner para imprimir o dono da conversa 2
  const rubyCode = `
    c = Conversation.find_by(id: 2)
    if c
      puts "CONVERSA_2_ACHADA:true"
      puts "ACCOUNT_ID:#{c.account_id}"
      puts "STATUS:#{c.status}"
    else
      puts "CONVERSA_2_ACHADA:false"
    end
  `;

  conn.exec(`cd /home/chatwoot/chatwoot && bash -l -c "RAILS_ENV=production bundle exec rails runner '${rubyCode}'"`, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => conn.end()).on('data', (data) => {
      console.log('RESULTADO: ' + data);
    });
  });

}).connect({
  host: '195.7.7.220', port: 22, username: 'root', password: 'Ap@lo20060'
});
