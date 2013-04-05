require!{should}
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

describe 'Test parseZHNumber', ->
    test 'Good input', ->
        for data in ZH_NUMBER_DATA
            util.parseZHNumber data.zh .should.eql data.int

describe 'Test toISOData', ->
    test 'Good input, single argument', ->
        for data in DATE_DATA
            util.toISODate data.zh .should.eql data.date
