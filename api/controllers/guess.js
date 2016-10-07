'use strict';

const BadRequestError = require('./helpers.js').BadRequestError;
const NotFoundError = require('./helpers.js').NotFoundError;
const ObjectID = require('mongodb').ObjectID;
const Promise = require('bluebird');
const config = require('../config.js');
const respond = require('./helpers.js').respond;
const shuffle = require('./helpers.js').shuffle;
const winston = require('winston');

module.exports = function (db) {
    return {
        get: function (req, res) {
            let User = db.collection('users');
            let Drawing = db.collection('drawings');
            let QuizSession = db.collection('quizSessions');

            let body = {
                sessionId: null,
                drawing: null,
                choices: []
            };

            // Try to avoid previously quizzed items
            new Promise(function (resolve, reject) {
                Drawing.aggregate([{ $match: { _id: { $nin: req.user.internalFlags.drawingsQuizzed.all }}}, { $sample: { size: 1 }}]).toArray(function (err, results) {
                    if (err) reject(err);
                    if (results.length === 0) {
                        // Used up inventory, try previously wronged quizzes
                        Drawing.aggregate([{ $match: { _id: { $in: req.user.internalFlags.drawingsQuizzed.wrong }}}, { $sample: { size: 1 }}]).toArray(function (err, results) {
                            if (err) reject(err);
                            if (results.length === 0) {
                                // No luck, just try something
                                Drawing.aggregate([{ $sample: { size: 1 }}]).toArray(function (err, results) {
                                    if (err) reject(err); else resolve(results);
                                });
                            } else {
                                resolve(results);
                            }
                        });
                    } else {
                        resolve(results);
                    }
                });
            })
            .then(function (results) {
                if (results.length === 0) {
                    throw new NotFoundError();
                } else {
                    return results[0];
                }
            })
            .then(function (drawing) {
                body.drawing = {
                    data: drawing.data,
                    faceType: drawing.faceType
                };
                return Promise.all([
                    User.findOne({ _id: drawing.forUser }),
                    User.aggregate([{ $match: { _id: { $ne: drawing.forUser }, 'internalFlags.isAnonymous': false }}, { $sample: { size: config.numGuessChoices - 1 }}]).toArray()
                ])
                .spread(function (rightUser, otherUsers) {
                    otherUsers.push(rightUser);
                    let allUsers = otherUsers;
                    allUsers = shuffle(allUsers);
                    body.choices = allUsers.map((user) => {
                        return {
                            alias: user.alias,
                            firstName: user.info.firstName,
                            lastName: user.info.lastName
                        };
                    });
                    let allUserIds = allUsers.map((user) => {
                        return user._id.toString();
                    });
                    let rightUserIndex = allUserIds.indexOf(rightUser._id.toString());
                    return QuizSession.insertOne({
                        player: req.user._id,
                        drawing: drawing._id,
                        choices: allUserIds.map((id) => { return ObjectID(id); }),
                        correctAnswer: rightUserIndex,
                        startTime: new Date(),
                        score: 0,
                        isCompleted: false
                    })
                    .then(function (quizSession) {
                        body.sessionId = quizSession.ops[0]._id;
                        return;
                    });
                });
            })
            .then(function (result) {
                respond(res, 200, body);
            })
            .catch(NotFoundError, function (error) {
                respond(res, 404);
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        },
        post: function (req, res) {

            // Validate request
            if (!req.params.sessionId || typeof req.body.choice !== 'number' || req.body.choice < 0) {
                respond(res, 400);
                return;
            }

            let body = {
                isRightAnswer: false,
                score: 0
            };

            let User = db.collection('users');
            let Drawing = db.collection('drawings');
            let QuizSession = db.collection('quizSessions');

            new Promise(function (resolve, reject) {
                QuizSession.findOne({ _id: ObjectID(req.params.sessionId) }, function (err, quizSession) {
                    if (err) reject(err); else resolve(quizSession);
                });
            })
            .then(function (quizSession) {
                if (!quizSession) {
                    throw new NotFoundError();
                } else if (quizSession.isCompleted || req.user._id.toString() !== quizSession.player.toString() || req.body.choice >= quizSession.choices.length) {
                    throw new BadRequestError();
                } else {
                    body.score += Math.floor(Math.max(0, (1 - (new Date() - quizSession.startTime) / 1000 / config.maxDrawingTime)) * 50);
                    if (req.body.choice === quizSession.correctAnswer) {
                        body.isRightAnswer = true;
                        body.score += 50;
                        // If the player doesn't have this face, add to collection
                        if (req.user.stats.usersRevealed.map((user) => { return user.id.toString(); }).indexOf(quizSession.choices[req.body.choice].toString()) === -1) {
                            req.user.stats.usersRevealed.push({
                                id: quizSession.choices[req.body.choice],
                                isNew: true
                            });
                        }
                        // Remove drawing from wronged list if part of it
                        req.user.internalFlags.drawingsQuizzed.wrong = req.user.internalFlags.drawingsQuizzed.wrong.filter((drawing) => {
                            return drawing.toString() !== quizSession.drawing.toString();
                        });
                    } else {
                        // Add drawing to wronged list if not part of it
                        if (req.user.internalFlags.drawingsQuizzed.wrong.map((drawing) => { return drawing.toString(); }).indexOf(quizSession.drawing.toString()) === -1) {
                            req.user.internalFlags.drawingsQuizzed.wrong.push(quizSession.drawing);
                        }
                    }
                    req.user.stats.guessPts += body.score;
                    // Add drawing to all quizzed list if not part of it
                    if (req.user.internalFlags.drawingsQuizzed.all.map((drawing) => { return drawing.toString(); }).indexOf(quizSession.drawing.toString()) === -1) {
                        req.user.internalFlags.drawingsQuizzed.all.push(quizSession.drawing);
                    }

                    return Promise.all([
                        User.updateOne({
                            _id: req.user._id
                        }, {
                            $set: {
                                'stats.guessPts': req.user.stats.guessPts,
                                'stats.usersRevealed': req.user.stats.usersRevealed,
                                'internalFlags.drawingsQuizzed': req.user.internalFlags.drawingsQuizzed
                            }
                        }),
                        QuizSession.updateOne({
                            _id: quizSession._id
                        }, {
                            $set: {
                                score: body.score,
                                isCompleted: true
                            }
                        })
                    ]);
                }
            })
            .then(function (results) {
                respond(res, 200, body);
            })
            .catch(BadRequestError, function (error) {
                respond(res, 400);
            })
            .catch(NotFoundError, function (error) {
                respond(res, 404);
            })
            .catch(function (error) {
                winston.log('error', error);
                respond(res, 500);
            });
        }
    };
};
