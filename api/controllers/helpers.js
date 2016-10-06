'use strict';

let codeToStatus = {
    200: 'OK',
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    500: 'Internal Server Error'
};

function BadRequestError() {}
BadRequestError.prototype = Error.prototype;

function NotFoundError() {}
NotFoundError.prototype = Error.prototype;

module.exports = {
    BadRequestError: BadRequestError,
    NotFoundError: NotFoundError,
    respond: function (res, code, result, message) {
        let body = {
            status: codeToStatus[code],
            result: result || {},
        }
        if (message) { body[message] = message; }
        res.status(code).json(body);
    },
    fixProfileImagePath: function (Image, user) {
        return Image.findOne({ _id: user.profileImage })
        .then(function (image) {
            user.profileImage = '/images/' + image._id + '.' + image.format;
            return user;
        });
    },
    getRandomInt: function (min, max) {
        min = Math.ceil(min);
        max = Math.floor(max);
        return Math.floor(Math.random() * (max - min)) + min;
    },
    shuffle: function (array) {
        var currentIndex = array.length, temporaryValue, randomIndex;
        while (0 !== currentIndex) {
            randomIndex = Math.floor(Math.random() * currentIndex);
            currentIndex -= 1;
            temporaryValue = array[currentIndex];
            array[currentIndex] = array[randomIndex];
            array[randomIndex] = temporaryValue;
        }
        return array;
    }
};
