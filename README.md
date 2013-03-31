# Introduction
This is the data for [laweasyread](https://github.com/g0v/laweasyread). Please
run `npm install` if you want to use any script in this project.

# Rawdata
The [rawdata directory](https://github.com/g0v/laweasyread-data/tree/master/rawdata)
contains all raw data for laweasyread. The description each directory are listed
as following:

* [lawstat](https://github.com/g0v/laweasyread-data/tree/master/rawdata/lawstat)
    * Raw data downloading from [立法院法律系統](http://lis.ly.gov.tw/lgcgi/lglaw)
* [utf8_lawstat](https://github.com/g0v/laweasyread-data/tree/master/rawdata/utf8_lawstat)
    * UTF-8 version of lawstat. This is created by
      [big5\_to\_utf8.sh](https://github.com/g0v/laweasyread-data/tree/master/rawdata/big5_to_utf8.sh)
      in rawdata directory

To download rawdata. Please see [twlaw](https://github.com/g0v/twlaw) project.

Use the following command to generate data from rawdata:

    ./node_modules/.bin/lsc parser.ls

# Data
The [data directory](https://github.com/g0v/laweasyread-data/tree/master/data)
contains json files for mongodb. The file name of each json is collection name
in mongodb. Use the following command to create database:

    ./node_modules/.bin/lsc import.ls

# Bugs
Please report any problem in [here](https://github.com/g0v/laweasyread-data/issues).

# Travis Build Status
[![Build Status](https://travis-ci.org/g0v/laweasyread-data.png)](https://travis-ci.org/g0v/laweasyread-data)
