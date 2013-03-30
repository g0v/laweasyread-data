require!{sprintf}

parseZHNumber = ->
    throw Error "not implemented"

toISODate = ->
    var year
    var month
    var date
    if arguments.length == 1
        m = /(中華)?民國\s*(\S+)\s*年\s*(\S+)\s*月\s*(\S+)\s*日/.exec arguments.0
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
