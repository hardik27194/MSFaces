'use strict';

let codeToStatus = {
    200: 'OK',
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    500: 'Internal Server Error'
};

function BadRequestError(message) {
    this.message = message;
    this.name = 'BadRequestError';
    Error.captureStackTrace(this, BadRequestError);
}
BadRequestError.prototype = Object.create(Error.prototype);
BadRequestError.prototype.constructor = BadRequestError;

function NotFoundError(message) {
    this.message = message;
    this.name = 'NotFoundError';
    Error.captureStackTrace(this, NotFoundError);
}
NotFoundError.prototype = Object.create(Error.prototype);
NotFoundError.prototype.constructor = NotFoundError;

module.exports = {
    BadRequestError: BadRequestError,
    NotFoundError: NotFoundError,
    respond: function (res, code, result, message) {
        let body = {
            status: codeToStatus[code],
            result: result || {},
        }
        if (message) body[message] = message;
        res.status(code).json(body);
    },
    fixProfileImagePath: function (Image, user) {
        return user.profileImage !== '/unknown.png' ? Image.findOne({ _id: user.profileImage })
        .then(function (image) {
            user.profileImage = '/images/' + image._id + '.' + image.format;
            return user;
        }) : user;
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
