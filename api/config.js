'use strict';

module.exports = {
    dbUrl: 'mongodb://localhost:27017/msfaces',
    collectionDefaultQueryLimit: 12,
    numLeadersToReturn: 3,
    port: process.env.PORT || 1337
}
