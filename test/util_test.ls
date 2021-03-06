require!<[fs should]>
util = require \../ .util
test = it

const ZH_NUMBER_DATA =
    * zh: \一
      int: 1
    * zh: \十
      int: 10
    * zh: \一二三四
      int: 1234
    * zh: \五千六百七十八
      int: 5678
    * zh: \一萬零五拾七
      int: 10057

const DATE_DATA =
    * zh: "中華民國 102 年 3 月 31 日"
      date: \2013-03-31
    * zh: "民國 一百零二 年 三 月 三十一 號"
      date: \2013-03-31

describe 'Test parseZHNumber', !->
    test 'Good input', !(done) ->
        for data in ZH_NUMBER_DATA
            util.parseZHNumber data.zh .should.eql data.int
        done!

describe 'Test toISOData', !->
    test 'Good input, single argument', !(done) ->
        for data in DATE_DATA
            util.toISODate data.zh .should.eql data.date
        done!

describe 'Test normalizePageCharset', !->
    utf8 = void
    big5 = void
    big5_no_quoted = void

    before !(done) ->
        utf8 := fs.readFileSync "#__dirname/data/utf8.html"
        big5 := fs.readFileSync "#__dirname/data/big5.html"
        big5_no_quoted := fs.readFileSync "#__dirname/data/big5_no_quoted.html"
        done!

    test 'Normalize big5 page, no quoted', !(done) ->
        util.normalizePageCharset big5 .should.eql utf8.toString!
        done!

    test 'Normalize big5 page, quoted', !(done) ->
        util.normalizePageCharset big5_no_quoted .should.eql utf8.toString!
        done!

    test 'Normalize utf-8 page', !(done) ->
        util.normalizePageCharset utf8 .should.eql utf8.toString!
        done!
