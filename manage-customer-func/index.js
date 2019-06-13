const express = require('express')
const app = express()
const bodyParser = require('body-parser')
const PORT = process.env.PORT || 8080
const pg = require('pg')

const connectionName =
  process.env.INSTANCE_CONNECTION_NAME || '<YOUR INSTANCE CONNECTION NAME>';
const dbUser = process.env.SQL_USER || '<YOUR DB USER>';
const dbPassword = process.env.SQL_PASSWORD || '<YOUR DB PASSWORD>';
const dbName = process.env.SQL_NAME || '<YOUR DB NAME>';

const pgConfig = {
  max: 1,
  user: dbUser,
  password: dbPassword,
  database: dbName,
};

if (process.env.NODE_ENV === 'production') {
  pgConfig.host = `/cloudsql/${connectionName}`;
}

let pgPool;

const createCustomerInSoR = async (customer) => {
  if (!pgPool) {
    pgPool = new pg.Pool(pgConfig);
  }

  let QUERY = `INSERT INTO CUSTOMERS (FIRSTNAME, LASTNAME, COMPANY, EMAIL)
               VALUES ($1, $2, $3, $4) RETURNING CUSTID`

  // Assume one or many????
  try {
    await pgPool.query(QUERY, [customer.firstname, customer.lastname, customer.company, ''])
  } catch(e) {
    console.error("Error occured while creating customer record", e)
  }

}

exports.sampleFunctionMain = async (req, res) => {

  res.set('Access-Control-Allow-Credentials', 'true')

  console.log("REQ RECEIVED BY FUNCTION", req)
  console.log('REQ HEADERS', req.headers)

  if (req.method === 'OPTIONS') {
    // Send response to OPTIONS requests
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Authorization');
    res.set('Access-Control-Max-Age', '3600');
    res.status(204).send('');
  } else if (req.method === 'POST') {
    console.log('Rquest body is', req.body)
    let customers = req.body.customers
    let action = req.body.action
    res.status(200).send('Done');
    // Invoke Cloud SQL action - CAN THIS BE AFTER res.send???
    await createCustomerInSoR(customers)
  } else {
    res.send('Hello World')
  }
}

//curl -v -k -H 'Content-Type: application/json' -H "Authorization: Bearer $(gcloud auth print-access-token)"-X POST -d '{"message": "true"}' https://us-central1-gcf-invoker-tests.txcloud.net/testInvokerDeployment
// Personal Account Function URL: https://us-central1-deliveroo-1540203586751.cloudfunctions.net/securefunction
//Personal account function service account JSON file: external-service-invoker-sa.json
//curl -v -k -H 'Content-Type: application/json' -H "Authorization: Bearer ${ACCESS}" -X GET https://us-central1-deliveroo-1540203586751.cloudfunctions.net/securefunction