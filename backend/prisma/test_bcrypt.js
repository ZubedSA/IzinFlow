const bcrypt = require('bcrypt');
console.log('--- DIAGNOSTIC START ---');
try {
  bcrypt.hash('student123', 10)
    .then(hash => {
      console.log('HASH SUCCESS:', hash);
      return bcrypt.compare('student123', hash);
    })
    .then(match => {
      console.log('COMPARE SUCCESS:', match);
      console.log('--- DIAGNOSTIC END (SUCCESS) ---');
      process.exit(0);
    })
    .catch(err => {
      console.error('BCRYPT ASYNC ERROR:', err);
      process.exit(1);
    });
} catch (err) {
  console.error('BCRYPT SYNC ERROR:', err);
  process.exit(1);
}
