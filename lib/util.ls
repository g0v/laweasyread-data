require!{sprintf}

const ZH_DIGIT =
    零: 0
    壹: 1
    貳: 2
    參: 3
    肆: 4
    伍: 5
    陸: 6
    柒: 7
    捌: 8
    玖: 9
    〇: 0
    一: 1
    二: 2
    三: 3
    四: 4
    五: 5
    六: 6
    七: 7
    八: 8
    九: 9

const ZH_SUBUNIT =
    拾: 10
    十: 10
    佰: 100
    百: 100
    千: 1000
    仟: 1000

const ZH_UNIT =
    萬: 1_0000

parseZHNumber = ->
    digit = void
    subtotal = 0
    total = 0

    for zh in it
        #console.log "#zh, #digit, #subtotal, #total"
        if ZH_DIGIT[zh] != void
            if digit != void
                digit *= 10
                digit += ZH_DIGIT[zh]
            else
                digit = ZH_DIGIT[zh]

        else if ZH_SUBUNIT[zh] != void
            if digit == void
                digit = 1
            subtotal += digit * ZH_SUBUNIT[zh]
            digit = void

        else if ZH_UNIT[zh] != void
            total += subtotal * ZH_UNIT[zh]
            if digit != void
                total += digit * ZH_UNIT[zh]
            digit = void
            subtotal = 0

        else
            return NaN
        #console.log "#digit, #subtotal, #total"

    if digit != void
        total += digit
    total += subtotal
    total

toISODate = ->
    var year
    var month
    var date
    if arguments.length == 1
        m = /(中華)?民國\s*(\S+)\s*年\s*(\S+)\s*月\s*(\S+)\s*(日|號)/.exec arguments.0
        if not m
            return ""
        year = m.2
        month = m.3
        date = m.4
    else if arguments.length == 3
        year = arguments.0
        month = arguments.1
        date = arguments.2
    else
        return ""

    year = if year == /\d+/ => parseInt year, 10 else parseZHNumber year
    month = if month == /\d+/ => parseInt month, 10 else parseZHNumber month
    date = if date == /\d+/ => parseInt date, 10 else parseZHNumber date

    sprintf.sprintf '%04d-%02d-%02d', year + 1911, month, date

module.exports = { parseZHNumber, toISODate }
