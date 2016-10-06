'use strict';

const respond = require('./helpers.js').respond;
const winston = require('winston');

module.exports = function (db) {
    return {
        requireAuth: function (req, res, next) {
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
        getUser: function (req, res) {
            let body = {
                firstName: null,
                lastName: null,
                profileImage: null
            }
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
        }
    };
};
