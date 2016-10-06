'use strict';

const ObjectID = require('mongodb').ObjectID;
const Promise = require('bluebird');
const getRandomInt = require('./helpers.js').getRandomInt;
const respond = require('./helpers.js').respond;
const winston = require('winston');

module.exports = function (db) {
    return {
        get: function (req, res) {
            let Image = db.collection('images');

            Image.aggregate([{ $sample: { size: 1 }}]).toArray()
            .then(function (results) {
                return results[0];
            })
            .then(function (image) {
                respond(res, 200, {
                    id: image._id,
                    path: '/images/' + image._id + '.' + image.format
                });
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        },
        post: function (req, res) {

            // Validate request
            if (!req.params.imageId || !req.body.data) {
                respond(res, 400);
                return;
            }

            let body = {
                score: 0
            };

            let User = db.collection('users');
            let Image = db.collection('images');
            let Drawing = db.collection('drawings');

            Image.findOne({ _id: ObjectID(req.params.imageId) })
            .then(function (image) {
                if (!image) {
                    respond(res, 404);
                    return;
                }
                return Promise.all([
                    image,
                    User.findOne({ _id: image.forUser }),
                    Drawing.insertOne({
                        data: req.body.data,
                        score: getRandomInt(50, 100),
                        createdBy: req.user._id,
                        forUser: image.forUser,
                        forImage: image._id
                    })
                ])
                .spread(function (image, user, drawing) {
                    drawing = drawing.ops[0];
                    image.drawingsFor.push(drawing._id);
                    user.stats.drawPts += drawing.score;
                    body.score = drawing.score;
                    user.images.drawingsFor.push(drawing._id);
                    return Promise.all([
                        Image.updateOne({
                            _id: image._id
                        }, {
                            $set: {
                                drawingsFor: image.drawingsFor
                            }
                        }),
                        User.updateOne({
                            _id: user._id
                        }, {
                            $set: {
                                'stats.drawPts': user.stats.drawPts,
                                'images.drawingsFor': user.images.drawingsFor
                            }
                        })
                    ]);
                });
            })
            .then(function (results) {
                respond(res, 200, body);
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        }
    };
};
