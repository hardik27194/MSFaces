'use strict';

module.exports = {
    collectionDefaultQueryLimit: 12,
    dbUrl: 'mongodb://localhost:27017/msfaces',
    maxDrawingTime: 60,
    numGuessChoices: 4,
    numLeadersToReturn: 3,
    port: process.env.PORT || 1337
}
