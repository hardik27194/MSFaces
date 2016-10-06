'use strict';

const Promise = require('bluebird');
const csv = require('csv-parser');
const dataPath = require('process').argv[2];
const db = require('../db.js');
const fs = require('fs');
const winston = require('winston');

const getFileExtension = /(?:\.([^.]+))?$/;

function cleanDirectorySync(directoryPath) {
    let filesToRemove = fs.readdirSync(directoryPath);
    filesToRemove.forEach(function (fileName) {
        if (fileName !== '.gitignore') {
            fs.unlinkSync(directoryPath + fileName);
        }
    });
}

db.then(function (db) {

    // Cleanup files
    cleanDirectorySync('./public/images/');
    winston.log('info', 'Files cleanup completed.');

    // Collections to operate on
    let Drawing = db.collection('drawings');
    let Image = db.collection('images');
    let QuizSession = db.collection('quizSessions');
    let User = db.collection('users');

    Promise.all([
        // Cleanup collections
        Drawing.drop(),
        Image.drop(),
        QuizSession.drop(),
        User.drop()
    ])
    .catch(function (error) {
        // Ignore ns not found error
        if (error.code === 26) {
            return;
        }
    })
    .then(function (results) {
        winston.log('info', 'DB cleanup completed.');
        return Promise.all([
            // Read user data from csv
            new Promise(function (resolve, reject) {
                let data = [];
                fs.createReadStream(dataPath + '/users.csv')
                .pipe(csv(['alias', 'firstName', 'lastName']))
                .on('data', function (row) {
                    data.push(row);
                })
                .on('end', function () {
                    winston.log('info', 'User data read from CSV.', {
                        numUsers: data.length
                    });
                    resolve(data);
                });
            }),
            // Read image files
            Promise.promisify(fs.readdir)(dataPath + '/pics')
            // Create rows for image files in DB
            .then(function (imageFiles) {
                winston.log('info', 'User image files read.');
                return Image.insert(imageFiles.map(function (imageFile) {
                    return {
                        format: getFileExtension.exec(imageFile)[1],
                        originalFileName: imageFile,
                        forUser: null,
                        drawingsFor: []
                    };
                }))
                .then(function (results) {
                    winston.log('info', 'User image file rows created.');
                    return results;
                });
            })
        ]);
    })
    .spread(function (csvData, imageRows) {
        let imageDict = {};
        imageRows.ops.forEach(function (row) {
            imageDict[row.originalFileName.split('.')[0]] = row._id;
        });
        return Promise.all([
            // Create rows for users
            User.insert(csvData.map(function (row) {
                return {
                    alias: row.alias,
                    info: {
                        firstName: row.firstName,
                        lastName: row.lastName
                    },
                    stats: {
                        drawPts: 0,
                        guessPts: 0,
                        usersRevealed: []
                    },
                    images: {
                        profileImage: imageDict[row.alias],
                        imagesFor: [imageDict[row.alias]],
                        drawingsFor: []
                    },
                    internalFlags: {
                        drawingsQuizzed: {
                            all: [],
                            wrong: []
                        },
                        isAnonymous: false
                    }
                };
            }))
            // Update rows for images
            .then(function (userRows) {
                winston.log('info', 'User rows created.');
                return Promise.all(userRows.ops.map(function (row) {
                    return Image.updateOne({
                        _id: row.images.profileImage
                    }, {
                        $set: {
                            forUser: row._id
                        }
                    });
                }))
                .then(function (results) {
                    winston.log('info', 'Image rows updated.');
                    return results;
                });
            }),
            // Copy image files
            Promise.all(imageRows.ops.map(function (row) {
                return new Promise(function (resolve, reject) {
                    fs.createReadStream(dataPath + '/pics/' + row.originalFileName)
                    .on('end', function () { resolve(); })
                    .pipe(fs.createWriteStream('./public/images/' + row._id + '.' + row.format));
                });
            }))
            .then(function (results) {
                winston.log('info', 'Image files copied to public directory.');
                return results;
            })
        ]);
    })
    // Create indices for better query performance
    .then(function () {
        return Promise.all([
            User.createIndex({ 'alias': 1 }),
            User.createIndex({ 'firstName': 1, '_id': 1 }),
            User.createIndex({ 'stats.drawPts': -1 }),
            User.createIndex({ 'stats.guessPts': -1 })
        ]);
    })
    .then(function () {
        winston.log('info', 'DB indices created.');
        winston.log('info', 'Data initialization complete!');
        db.close();
    })
});
