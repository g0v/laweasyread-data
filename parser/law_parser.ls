require!{fs, mkdirp, moment, optimist, \../lib/util}

updateName = (name_array, new_name, date) ->
    for name in name_array
        if name.name == new_name
            if moment date .isBefore name.start_date
                name.start_date = date
            return
    name_array.push { name: new_name, start_date: date }

updateHistory = (all_history, history) ->
    for item, index in all_history
        if moment item.passed_date .isAfter history.passed_date
            all_history.slice index, 0, history
            return
        else if item.passed_date == history.passed_date
            return
    all_history.push history

updateArticle = (all_article, article) ->
    for item, index in all_article
        if item.article == article.article && item.content == article.content
            if moment item.passed_date .isAfter article.passed_date
                item.passed_date = article.passed_date
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
            history: []
        article: []

    for file in fs.readdirSync path
        if /\d+\.htm/ != file
            continue
        #console.log "Process #path/#file"

        html = fs.readFileSync "#path/#file"

        var passed_date
        var unknown_date
        var history

        article_no = "1"
        var article

        for line in html / '\n'
            match line
            | /<title>法編號:(\d{5})\s+版本:(\d{3})(\d{2})(\d{2})\d{2}/
                # console.log "Match lyID, version"
                # 版本是 民國年(3) + 月(2) + 日(2) + 兩數字 組成
                # We use ISO-8601 format as statute version
                ret.statute.lyID = that.1
                passed_date = util.toISODate that.2, that.3, that.4

            | /<FONT COLOR=blue SIZE=5>([^(（]+)/
                # console.log "Match name"
                updateName ret.statute.name, that.1, passed_date

            | /<a href.*<font size=2>(中華民國 \d+ 年 \d+ 月 \d+ 日)/
                # console.log "Match pass date"
                date = util.toISODate that.1
                if history
                    updateHistory ret.statute.history, history
                history =
                    passed_date: date

            | /<font size=2>(中華民國 \d+ 年 \d+ 月 \d+ 日)(公布|施行)/
                #console.log "Match enactment / enforcement date"
                date = util.toISODate that.1

                match that.2
                | "公布"
                    if history.enactment_date == void
                        history.enactment_date = date
                    else
                        console.error "Found another enactment date in #path/#file"
                | "施行"
                    if history.enforcement_date == void
                        history.enforcement_date = date
                    else
                        console.error "Found another enforcement date in #path/#file"

            | /(中華民國 \d+ 年 \d+ 月 \d+ 日)/
                unknown_date = util.toISODate that.0

            | /<font size=2>立法院通過停止適用/ => fallthrough
            | /<font size=2>期滿當然廢止/ => fallthrough
            | /<font size=2>廢止.*條/
                if unknown_date
                    if history
                        updateHistory ret.statute.history, history
                    history =
                        discarded_date: unknown_date
                    unknown_date = void
                else
                    console.error "Found keyword without date in #path/#file"

            | /<font size=2>立法院通過暫停適用/ => fallthrough
            | /<font size=2>考試院令公告廢止/ => fallthrough
            | /<font size=2>國民政府明令暫緩施行/
                if unknown_date
                    if history
                        updateHistory ret.statute.history, history
                    history =
                        suspended: unknown_date
                    unknown_date = void
                else
                    console.error "Found keyword without date in #path/#file"


            | /<font color=8000ff>第(.*)條(?:之(.*))?/
                #console.log "Match article number"
                if article
                    updateArticle ret.article, article

                article_no = util.parseZHNumber that.1 .toString!
                if that.3
                    article_no += "-" + util.parseZHNumber that.3 .toString!

                article =
                    article: article_no
                    lyID: ret.statute.lyID
                    content: ""
                    passed_date: passed_date

            # http://law.moj.gov.tw/LawClass/LawSearchNo.aspx?PC=A0030133&DF=&SNo=8,9
            | /^　　(.*)<br>/
                #console.log "Match article content"
                if article == void
                    article =
                        article: article_no
                        lyID: ret.statute.lyID
                        content: ""
                        passed_date: passed_date
                article.content += that.1 + "\n"
                article_no = 1 + parseInt article_no, 10

            | /^[^　]/
                if article and article.content != ""
                    updateArticle ret.article, article
                article = void

        if history
            updateHistory ret.statute.history, history

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
        | \04515 => return \B0000001
        void

main = ->
    argv = optimist .default {
        rawdata: "#__dirname/../rawdata/utf8_lawstat/version2"
        output: "#__dirname/../data/law"
        pcode: "#__dirname/../data/pcode.json"
    } .argv

    (err, lookupPCode) <- createLookupPCodeFunc argv.pcode
    if err => console.error err; lookupPCode = -> void

    for path in fs.readdirSync argv.rawdata
        indir = "#{argv.rawdata}/#path"
        m = path.match /([^/]+)\/?$/
        outdir = "#{argv.output}/#{m.1}"

        if not fs.statSync(indir).isDirectory() => continue

        console.log "Process #indir"
        data = parseHTML indir, {
            lookupPCode: lookupPCode
        }

        mkdirp.sync outdir
        console.log "Write #outdir/article.json"
        fs.writeFileSync "#outdir/article.json", JSON.stringify data.article, '', 2
        console.log "Write #outdir/statute.json"
        fs.writeFileSync "#outdir/statute.json", JSON.stringify data.statute, '', 2

main!
