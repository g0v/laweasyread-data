require!{async, fs, \fs-tools, optimist, request}

const URL = \http://law.moj.gov.tw/LawClass/LawClassList.aspx

parse_category_file = (filename, callback) ->
    (err, data) <- fs.readFile filename
    if err => callback err; return

    regex = /AddHotLaw.ashx\?PCode=([A-Z0-9]+)" title="([^"]+)"/g
    data = data.toString!
    ret = []

    while m = regex.exec data
        ret.push {
            PCode: m.1
            name: m.2
        }

    callback null, ret

main = ->
    argv = optimist.default {
        rawdata: "#__dirname/../rawdata/LawClassList"
        output: "#__dirname/../data/pcode.json"
    } .argv

    filelist = []

    (err) <- fsTools.walk argv.rawdata, /[A-Z0-9]+\.html/, (path, stats, callback) ->
        filelist.push path
        callback null;
    if err => console.error err; return

    console.log "Parsing category page"
    (err, pcode_map_array) <- async.map filelist, (filename, callback) ->
        (err, pcode_map) <- parse_category_file filename
        if err => callback err; return
        callback null, pcode_map
    if err => console.error err; return

    pcode_map = []
    for index, item of pcode_map_array
        pcode_map = pcode_map.concat item

    console.log "Writing result to #{argv.output}"
    (err) <- fs.writeFile argv.output, JSON.stringify pcode_map, null, 2
    if err => console.error err; return

    console.log "Done"

main!
