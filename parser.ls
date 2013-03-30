require!{fs, mkdirp, moment, optimist, \./lib/util}

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

parseHTML = (path) ->
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
        var history

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
                | "公布" => history.enactment_date = date
                | "施行" => history.enforcement_date = date

            | /<font color=8000ff>第(.*)條(?:之(.*))?/
                #console.log "Match article number"
                if article
                    updateArticle ret.article, article

                article_no = util.parseZHNumber that.1 .toString!
                if that.3
                    article_no += "-" + util.parseZHNumber that.3 .toString!

                article =
                    article: article_no
                    content: ""
                    passed_date: passed_date

            # http://law.moj.gov.tw/LawClass/LawSearchNo.aspx?PC=A0030133&DF=&SNo=8,9
            | /^　　(.*)<br>/
                #console.log "Match article content"
                article.content += that.1 + "\n"

        if history
            updateHistory ret.statute.history, history

        if article
            updateArticle ret.article, article

    ret

writeJSON = (path, json) ->
    console.log "Write #path"
    fs.writeFileSync path, JSON.stringify json, '', 4

main = ->
    argv = optimist .default {
        input: "#__dirname/rawdata/utf8_lawstat/version2"
        output: "#__dirname/data"
    } .argv

    for path in fs.readdirSync argv.input
        indir = "#{argv.input}/#path"
        m = path.match /([^/]+)\/?$/
        outdir = "#{argv.output}/#{m.1}"

        if not fs.statSync(indir).isDirectory() => continue

        #console.log "Process #indir"
        data = parseHTML indir
        #console.log JSON.stringify data, '', 2
main!
