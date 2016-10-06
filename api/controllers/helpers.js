'use strict';

let codeToStatus = {
    200: 'OK',
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    500: 'Internal Server Error'
};

module.exports = {
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
    }
};
