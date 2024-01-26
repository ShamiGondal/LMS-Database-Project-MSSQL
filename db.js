const sql = require('mssql');

const config = {
  server: 'localhost',
  user: 'sa',
  password: 'shami345',
  database: 'lmsTrail2',
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
  options: {
    encrypt: true,
    trustServerCertificate: true,
    trustedConnection: true,
    connectionTimeout: 30000,
  },
};

const pool = new sql.ConnectionPool(config);

const connectToDatabase = async () => {
  try {
    await pool.connect();
    console.log('Connected to the database!');
    return pool;
  } catch (error) {
    console.error('Error connecting to the database:', error.message);
    throw error;
  }
};

module.exports = connectToDatabase;
