'use strict';

const Promise = require('bluebird');
const config = require('./config.js');
const db = require('./db.js');
const express = require('express');
const path = require('path');
const winston = require('winston');

let app = express();

// Serve static assets from the /public folder
app.use(express.static(path.join(__dirname, '/public')));

app.get('/ping', require('./endpoints/ping.js'));

// Wait for connection to DB
db.then(function (db) {
    // Start listening to requests
    app.listen(config.port, function () {
        winston.log('info', 'MSfaces API v1 is now up and listening for requests.', {
            port: config.port
        });
    });
});
