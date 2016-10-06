'use strict';

const Promise = require('bluebird');
const config = require('../config.js');
const respond = require('./helpers.js').respond;
const winston = require('winston');

function fixProfileImagePath(Image, user) {
    return Image.findOne({ _id: user.profileImage })
    .then(function (image) {
        user.profileImage = '/images/' + image._id + '.' + image.format;
        return user;
    });
}

module.exports = function (db) {
    return {
        get: function (req, res) {
            let body = {
                draw: null,
                guess: null,
                myRankings: {
                    draw: null,
                    guess: null
                }
            };

            let User = db.collection('users');
            let Image = db.collection('images');

            Promise.all([
                User.find().sort({ 'stats.drawPts': -1 }).limit(config.numLeadersToReturn).toArray()
                .then(function (users) {
                    return users.map((user) => {
                        return {
                            profileImage: user.images.profileImage,
                            alias: user.alias,
                            pts: user.stats.drawPts
                        };
                    });
                }),
                User.find().sort({ 'stats.guessPts': -1 }).limit(config.numLeadersToReturn).toArray()
                .then(function (users) {
                    return users.map((user) => {
                        return {
                            profileImage: user.images.profileImage,
                            alias: user.alias,
                            pts: user.stats.guessPts
                        };
                    });
                }),
                User.find({ 'stats.drawPts': { $gt: req.user.stats.drawPts } }).count()
                .then(function (result) {
                    body.myRankings.draw = result + 1;
                }),
                User.find({ 'stats.guessPts': { $gt: req.user.stats.guessPts } }).count()
                .then(function (result) {
                    body.myRankings.guess = result + 1;
                })
            ])
            .spread(function (drawLeaders, guessLeaders) {
                // Fix profile image paths
                return Promise.all([
                    Promise.all(drawLeaders.map(fixProfileImagePath.bind(this, Image))),
                    Promise.all(guessLeaders.map(fixProfileImagePath.bind(this, Image)))
                ]);
            })
            .spread(function (drawLeaders, guessLeaders) {
                body.draw = drawLeaders;
                body.guess = guessLeaders;
                respond(res, 200, body);
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        }
    };
}
