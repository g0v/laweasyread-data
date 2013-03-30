require!{fs, mkdirp, optimist}

parseHTML = (path) ->
    ret =
        statute:
            name: []
        article: []

    for file in fs.readdirSync path
        if /\d+\.htm/ != file
            continue
        #console.log "Process #path/#file"

        html = fs.readFileSync "#path/#file"

        var ver

        for line in html / '\b'
            match line
            | /<title>法編號:(\d{5})\s+版本:(\d{3})(\d{2})(\d{2})\d{2}/
                # 版本是 民國年(3) + 月(2) + 日(2) + 兩數字 組成
                # We use ISO-8601 format as statute version
                ret.statute.lyID = that.1
                year = parseInt(that.2, 10) + 1911
                ver = "#year-#{that.3}-#{that.4}"
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
main!
