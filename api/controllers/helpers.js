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
    }
};
