require!<[fs mkdirp moment optimist winston ../lib/util]>

updateName = (name_array, new_name, date) ->
    for name in name_array
        if name.name == new_name
            if moment date .isBefore name.start_date
                name.start_date = date
            return
    name_array.push { name: new_name, start_date: date }

updateHistory = (history, date, reason) ->
    if history[date] != void
        if history[date] != reason
            history[date] .= "\n#reason"
        return
    history[date] = reason

updateArticle = (all_article, article) ->
    for item, index in all_article
        if item.article == article.article && item.content == article.content
            if moment item.passed_date .isAfter article.passed_date
                item.passed_date = article.passed_date
            if article.title and not item.title
                item.title = article.title
            return
    all_article.push article

fixupData = (data, opts) ->
    if data.statute.lyID == \90077
        data.statute.name.push {
            name: \外交部特派員公署組織條例
            start_date: \1943-08-28
        }

    data.statute.PCode = opts.lookupPCode data.statute
    data

parseHTML = (path, opts) ->
    ret =
        statute:
            name: []
            history: {}
        article: []

    for file in fs.readdirSync path
        if /\d+\.htm/ != file
            continue
        winston.info "Process #path/#file"

        html = fs.readFileSync "#path/#file"

        var passed_date

        article_no = "1"
        var article
        articleStart = false

        var date
        var reason

        for line in html / '\n'
            match line
            | /<title>法編號:(\d{5})\s+版本:(\d{3})(\d{2})(\d{2})\d{2}/
                # 版本是 民國年(3) + 月(2) + 日(2) + 兩數字 組成
                # We use ISO-8601 format as statute version
                ret.statute.lyID = that.1
                passed_date = util.toISODate that.2, that.3, that.4

                winston.info "Match lyID #{ret.statute.lyID}, version #{passed_date}"

            | /<FONT COLOR=blue SIZE=5>([^(（]+)/
                name = that.1
                winston.info "Found name: #name"
                updateName ret.statute.name, that.1, passed_date

            | /<font size=2>(中華民國 \d+ 年 \d+ 月 \d+ 日)(.*)?<\/font/
                if date and reason
                    updateHistory ret.statute.history, date, reason
                    date = void
                    reason = void

                if date
                    winston.warn "Found orphan date: #date"
                date = util.toISODate that.1
                winston.info "Found date #date"

                if that.2
                    if reason
                        winston.warn "Found orphan reason: #reason"
                    reason = that
                    winston.info "Found reason #reason"

                    updateHistory ret.statute.history, date, reason

                    date = void
                    reason = void

            | /^<td valign=top><font size=2>(.+)<\/font/
                if reason
                    winston.warn "Found orphan reason: #reason"

                reason = that.1
                winston.info "Found reason: #reason"

                if not date
                    winston.warn "Found reason: #reason without date"

                updateHistory ret.statute.history, date, reason

                date = void
                reason = void

            | /^<td valign=top><font size=2>([^<]+)<br/
                content = that.1
                winston.info "Found start of partial reason: #content"
                if reason
                    winston.warn "Found orphan reason: #reason"

                reason = content

            # http://law.moj.gov.tw/LawClass/LawSearchNo.aspx?PC=A0030133&DF=&SNo=8,9
            #
            # Some articles does not start with \u3000\u3000, thus they look
            # identical to the partial reason. Because of this, we use
            # articleStart here to distinguish article content and partial
            # reason.
            | /^\u3000*([^<\u3000]+)<br>(.*)$/
                content = that.1
                tail = that.2
                if articleStart
                    winston.info "Match article content"
                    if article == void
                        article =
                            article: article_no
                            lyID: ret.statute.lyID
                            content: ""
                            passed_date: passed_date
                    article.content += content + "\n"
                    article_no = 1 + parseInt article_no, 10
                else
                    winston.info "Found partial reason: #content"
                    if not reason
                        winston.warn "Found partial reason without start: #content"

                    reason += '\n' + content

                    if tail
                        tail = tail.replace '<br>', '\n'
                        reason += tail

            | /^([^<\u3000]+)<\/font/
                content = that.1
                winston.info "Found end of partial reason: #content"
                if not reason
                    winston.warn "Found partial reason without start: #content"

                reason += '\n' + content

                updateHistory ret.statute.history, date, reason

                date = void
                reason = void

            | /<font color=blue size=4>民國\d+年\d+月\d+日/
                articleStart = true

            | /<font color=8000ff>第(.*)條(?:之(.*))?/
                if article
                    updateArticle ret.article, article

                article_no = util.parseZHNumber that.1 .toString!
                if that.3
                    article_no += "-" + util.parseZHNumber that.3 .toString!

                winston.info "Found article number #article_no"

                article =
                    article: article_no
                    lyID: ret.statute.lyID
                    content: ""
                    passed_date: passed_date

            | /^</
                if article and article.content != ""
                    updateArticle ret.article, article
                    article = void

            | /<font size=2>\(([^<]+)\)<\/font/
                article_title = that.1
                if article
                    winston.info "Found article title #article_title"
                    article.title = util.normalizePunctuations article_title
                else
                    winston.warn "Found partial article title without start: #article_title"

        if date or reason
            winston.warn "Found orphan date: #date or reason: #reason"

        if article
            updateArticle ret.article, article

    fixupData ret, opts

createPCodeMapping = (path, callback) ->
    err, data <- fs.readFile path
    if err => return callback err
    data = JSON.parse data
    ret = {}
    for index, item of data
        ret[item.name] = item.PCode
    callback null, ret

createLookupPCodeFunc = (path, callback) ->
    err, pcodeMapping <- createPCodeMapping path
    if err => return callback err
    callback null, (statute) ->
        for i, item of statute.name
            if pcodeMapping[item.name] != void => return pcodeMapping[item.name]
        switch statute.lyID
        | \04507 => fallthrough
        | \04509 => fallthrough
        | \04511 => fallthrough
        | \04513 => fallthrough
        | \04515 => \B0000001
        | \04311 => \A0020001
        | \04318 => \D0020053
        |_ => void

main = ->
    argv = optimist .default {
        rawdata: "#__dirname/../rawdata/utf8_lawstat/version2"
        data: "#__dirname/../data/law"
        pcode: "#__dirname/../data/pcode.json"
    } .boolean \verbose .alias \v, \verbose
        .argv

    if not argv.verbose
        winston
            .remove winston.transports.Console
            .add winston.transports.Console, { level: \warn }

    (err, lookupPCode) <- createLookupPCodeFunc argv.pcode
    if err => winston.warn err; lookupPCode = -> void

    for path in fs.readdirSync argv.rawdata
        indir = "#{argv.rawdata}/#path"
        m = path.match /([^/]+)\/?$/
        outdir = "#{argv.data}/#{m.1}"

        if not fs.statSync(indir).isDirectory() => continue

        winston.info "Process #indir"
        data = parseHTML indir, {
            lookupPCode: lookupPCode
        }

        mkdirp.sync outdir
        winston.info "Write #outdir/article.json"
        fs.writeFileSync "#outdir/article.json", JSON.stringify data.article, '', 2
        winston.info "Write #outdir/statute.json"
        fs.writeFileSync "#outdir/statute.json", JSON.stringify data.statute, '', 2

main!
