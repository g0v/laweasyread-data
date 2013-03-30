require!{should, \../lib/util}

const ZH_NUMBER_DATA =
    * zh: \一
      int: 1
    * zh: \一二三四
      int: 1234
    * zh: \五千六百七十八
      int: 5678
    * zh: \一萬零五拾七
      int: 10057

for data in ZH_NUMBER_DATA
    util.parseZHNumber data.zh .should.equal data.int
