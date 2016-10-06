'use strict';

const Promise = require('bluebird');
const fs = require('fs');

let Tools = {};

Tools.encodeFileBase64 = function (filePath) {
    return Promise.promisify(fs.readFile)(filePath)
    .then((data) => {
        return Promise.promisify(fs.writeFile)(filePath + '_b64.txt', data.toString('base64'));
    });
}

Tools.decodeFileBase64 = function (filePath) {
    return Promise.promisify(fs.readFile)(filePath)
    .then((data) => {
        return Promise.promisify(fs.writeFile)(filePath + '.bin', new Buffer(data.toString('ascii'), 'base64'));
    });
}

module.exports = Tools;
