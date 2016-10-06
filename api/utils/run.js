'use strict';

const process = require('process');

const moduleName = process.argv[2];
const functionName = process.argv[3];
const args = process.argv.slice(4);

require('./' + moduleName + '.js')[functionName].apply(this, args);
