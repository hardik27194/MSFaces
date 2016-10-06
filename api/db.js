'use strict';

const Promise = require('bluebird');
const config = require('./config.js');
const winston = require('winston');

let MongoClient = require('mongodb').MongoClient;

module.exports = new Promise(function (resolve, reject) {
    // Use connect method to connect to the Server
    MongoClient.connect(config.dbUrl)
    .then(function (db) {
        resolve(db);
        winston.log('info', 'Connected to DB server.', {
            dbUrl: config.dbUrl
        });
    })
    .catch(function (err) {
        reject(err);
        winston.log('error', 'Failed to connect to DB server.', {
            dbUrl: config.dbUrl,
            error: err
        });
    });
});
