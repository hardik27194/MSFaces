'use strict';

const Promise = require('bluebird');
const bodyParser = require('body-parser');
const config = require('./config.js');
const db = require('./db.js');
const express = require('express');
const path = require('path');
const winston = require('winston');

let app = express();

// Serve static assets from the /public folder
app.use(express.static(path.join(__dirname, '/public')));

// We only accept JSON input
app.use(bodyParser.json());

app.get('/ping', require('./controllers/ping.js'));

// Wait for connection to DB
db.then(function (db) {

    // Initialize controllers
    let userController = require('./controllers/user.js')(db);
    let leaderboardController = require('./controllers/leaderboard.js')(db);

    // Setup endpoints
    app.get('/users/:alias', userController.auth, userController.get);
    app.post('/users', userController.post);
    app.get('/leaderboard', userController.auth, leaderboardController.get);

    // Start listening to requests
    app.listen(config.port, function () {
        winston.log('info', 'MSfaces API v1 is now up and listening for requests.', {
            port: config.port
        });
    });

});
