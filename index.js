"use strict";

module.exports = process.env.LAWEASYREAD_DATA_COV
    ? require('./lib-cov/')
    : require('./lib/');
