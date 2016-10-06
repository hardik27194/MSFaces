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
    let drawController = require('./controllers/draw.js')(db);
    let guessController = require('./controllers/guess.js')(db);
    let leaderboardController = require('./controllers/leaderboard.js')(db);
    let collectionController = require('./controllers/collection.js')(db);

    // Setup endpoints
    app.post('/users', userController.post);
    app.get('/users/:alias', userController.auth, userController.get);
    app.get('/draw', userController.auth, drawController.get);
    app.post('/draw/:imageId', userController.auth, drawController.post);
    app.get('/guess', userController.auth, guessController.get);
    app.post('/guess/:sessionId', userController.auth, guessController.post);
    app.get('/leaderboard', userController.auth, leaderboardController.get);
    app.get('/collection', userController.auth, collectionController.get);
    app.post('/collection/seen', userController.auth, collectionController.postSeen);

    // Start listening to requests
    app.listen(config.port, function () {
        winston.log('info', 'MSfaces API v1 is now up and listening for requests.', {
            port: config.port
        });
    });

});
