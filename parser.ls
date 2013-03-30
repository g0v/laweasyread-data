require!{fs, mkdirp, moment, optimist, sprintf}

update_name = (name_array, new_name, date) ->
    for name in name_array
        if name.name == new_name
            if moment date .isBefore name.start_date
                name.start_date = date
            return
    name_array.push { name: new_name, start_date: date }

update_history = (all_history, history) ->
    for item, index in all_history
        if moment item.passed_date .isAfter history.passed_date
            all_history.slice 1, 0, history
            return
        else if item.passed_date == history.passed_date
            return
    all_history.push history

to_iso_date = (year, month, date) ->
    year = parseInt(year, 10)
    month = parseInt(month, 10)
    date = parseInt(date, 10)
    sprintf.sprintf '%04d-%02d-%02d', year + 1911, month, date

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

        var date
        var history

        for line in html / '\n'
            match line
            | /<title>法編號:(\d{5})\s+版本:(\d{3})(\d{2})(\d{2})\d{2}/
                # console.log "Match lyID, version"
                # 版本是 民國年(3) + 月(2) + 日(2) + 兩數字 組成
                # We use ISO-8601 format as statute version
                ret.statute.lyID = that.1
                date = to_iso_date that.2, that.3, that.4

            | /<FONT COLOR=blue SIZE=5>([^(（]+)/
                # console.log "Match name"
                update_name ret.statute.name, that.1, date

            | /<a href.*<font size=2>中華民國 (\d+) 年 (\d+) 月 (\d+) 日/
                # console.log "Match pass date"
                date = to_iso_date that.1, that.2, that.3
                if history
                    update_history ret.statute.history, history
                history =
                    passed_date: date

            | /<font size=2>中華民國 (\d+) 年 (\d+) 月 (\d+) 日(公布|施行)/
                #console.log "Match enactment / enforcement date"
                date = to_iso_date that.1, that.2, that.3

                match that.4
                | "公布" => history.enactment_date = date
                | "施行" => history.enforcement_date = date

        if history
            update_history ret.statute.history, history

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
        #console.log JSON.stringify data
main!
