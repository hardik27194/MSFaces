'use strict';

const Promise = require('bluebird');
const config = require('../config.js');
const respond = require('./helpers.js').respond;
const fixProfileImagePath = require('./helpers.js').fixProfileImagePath;
const winston = require('winston');

module.exports = function (db) {
    return {
        get: function (req, res) {
            let limit = parseInt(req.query.limit) || config.collectionDefaultQueryLimit;
            let offset = parseInt(req.query.offset) || 0;

            let User = db.collection('users');
            let Image = db.collection('images');

            let usersRevealedIds = req.user.stats.usersRevealed.map((user) => {
                return user.id;
            });
            let usersRevealedDict = {};
            req.user.stats.usersRevealed.forEach((user) => {
                usersRevealedDict[user.id] = user.isNew;
            });

            let body = {
                users: null,
                revealed: 0,
                total: 0
            };

            User.find({ _id: { $in: usersRevealedIds }, 'internalFlags.isAnonymous': false }).sort({ firstName: 1 }).skip(offset).limit(limit).toArray()
            .then(function (users) {
                limit -= users.length;
                return users.map((user) => {
                    return {
                        isNew: usersRevealedDict[user._id],
                        profileImage: user.images.profileImage,
                        firstName: user.info.firstName,
                        lastName: user.info.lastName,
                        alias: user.alias
                    };
                });
            })
            .then(function (users) {
                return Promise.all(users.map(fixProfileImagePath.bind(this, Image)));
            })
            .then(function (users) {
                if (limit === 0 ) return users;
                offset = Math.max(0, offset - req.user.stats.usersRevealed.length);
                return User.find({ _id: { $nin: usersRevealedIds.concat([req.user._id]) }, 'internalFlags.isAnonymous': false }).sort({ firstName: 1 }).skip(offset).limit(limit).toArray()
                .then(function (extraUsers) {
                    return extraUsers.map((user) => {
                        return {
                            isNew: false,
                            profileImage: '/unknown.png',
                            firstName: user.info.firstName.charAt(0) + '.',
                            lastName: user.info.lastName.charAt(0) + '.',
                            alias: '???'
                        };
                    });
                })
                .then(function (extraUsers) {
                    return users.concat(extraUsers);
                });
            })
            .then(function (users) {
                body.users = users;
                return Promise.all([
                    User.count({ _id: { $in: usersRevealedIds }, 'internalFlags.isAnonymous': false }),
                    User.count({ _id: { $ne: req.user._id }, 'internalFlags.isAnonymous': false })
                ])
                .spread(function (revealed, total) {
                    body.revealed = revealed;
                    body.total = total;
                    return;
                });
            })
            .then(function (result) {
                respond(res, 200, body);
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        },
        postSeen: function (req, res) {

            // Validate request
            if (!req.body.seen || !Array.isArray(req.body.seen)) {
                respond(res, 400);
                return;
            }

            let User = db.collection('users');
            User.find({ alias: { $in: req.body.seen }}).toArray()
            .then(function (users) {
                let userIds = users.map((user) => {
                    return user._id.toString();
                });
                req.user.stats.usersRevealed.forEach((user) => {
                    if (userIds.indexOf(user.id.toString()) !== -1) user.isNew = false;
                });
                return User.updateOne({
                    _id: req.user._id
                }, {
                    $set: {
                        'stats.usersRevealed': req.user.stats.usersRevealed
                    }
                });
            })
            .then(function (result) {
                respond(res, 200);
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        }
    };
};
