'use strict';

const Promise = require('bluebird');
const fs = require('fs');
const respond = require('./helpers.js').respond;
const winston = require('winston');

module.exports = function (db) {
    return {
        auth: function (req, res, next) {
            if (!req.query.u) {
                respond(res, 401);
                return;
            }
            let User = db.collection('users');
            User.findOne({ alias: req.query.u })
            .then(function (result) {
                if (result) {
                    req.user = result;
                    next();
                } else {
                    respond(res, 401);
                }
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        },
        get: function (req, res) {
            let body = {
                firstName: null,
                lastName: null,
                profileImage: null
            };
            new Promise(function (resolve, reject) {
                if (req.params.alias === req.user.alias) {
                    body.firstName = req.user.info.firstName;
                    body.lastName = req.user.info.lastName;
                    resolve(req.user.images.profileImage);
                } else {
                    resolve(null);
                }
            })
            .then(function (profileImage) {
                let User = db.collection('users');
                return profileImage || User.findOne({ alias: req.params.alias })
                .then(function (user) {
                    if (user) {
                        body.firstName = user.info.firstName;
                        body.lastName = user.info.lastName;
                        return user.images.profileImage;
                    }
                    respond(res, 404);
                });
            })
            .then(function (profileImage) {
                if (profileImage) {
                    let Image = db.collection('images');
                    return Image.findOne({ _id: profileImage })
                    .then(function (image) {
                        if (image) {
                            body.profileImage = '/images/' + image._id + '.' + image.format;
                        }
                        respond(res, 200, body);
                    });
                }
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        },
        post: function (req, res) {

            // Validate request
            if (!req.body.alias || !req.body.profileImage.format || !req.body.profileImage.data) {
                respond(res, 400);
                return;
            }

            let User = db.collection('users');
            let Image = db.collection('images');

            Promise.all([
                // If user doesn't exist, create a new user
                User.findOne({ alias: req.body.alias })
                .then(function (user) {
                    if (user) {
                        return user;
                    } else {
                        return User.insertOne({
                            alias: req.body.alias,
                            info: {
                                firstName: null,
                                lastName: null
                            },
                            stats: {
                                drawPts: 0,
                                guessPts: 0,
                                users_revealed: []
                            },
                            images: {
                                profileImage: null,
                                imagesFor: [],
                                drawingsFor: []
                            },
                            internalFlags: {
                                drawingsQuizzed: {
                                    all: [],
                                    wrong: []
                                },
                                isAnonymous: true
                            }
                        })
                        .then(function (result) {
                            return result.ops[0];
                        });
                    }
                }),
                // Create image row
                Image.insertOne({
                    format: req.body.profileImage.format,
                    originalFileName: null,
                    forUser: null,
                    drawingsFor: []
                })
                .then(function (result) {
                    return result.ops[0];
                })
            ])
            .spread(function (user, image) {
                return Promise.all([
                    // Update user row
                    User.updateOne({
                        _id: user._id
                    }, {
                        $set: {
                            'images.profileImage': image._id,
                            'images.imagesFor': user.images.imagesFor.concat([image._id])
                        }
                    }),
                    // Update image row
                    Image.updateOne({
                        _id: image._id
                    }, {
                        $set: {
                            forUser: user._id
                        }
                    }),
                    // Save image file
                    new Promise.promisify(fs.writeFile)('./public/images/' + image._id + '.' + image.format, new Buffer(req.body.profileImage.data, 'base64'))
                ]);
            })
            .then(function (results) {
                respond(res, 200);
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        }
    };
};
