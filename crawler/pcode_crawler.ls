require!{async, fs, optimist, request}

const URL = \http://law.moj.gov.tw/LawClass/LawClassList.aspx

fetch_index_file = (output, callback) ->
    filename = "#output/index.html"

    (err, rsp, body) <- request URL
    if err => callback err; return

    (err) <- fs.writeFile filename, body
    if err => callback err; return

    callback null, filename

parse_index_file = (filename, callback) ->
    (err, data) <- fs.readFile filename
    if err => callback err; return

    regex = /LawClassList.aspx\?TY=([A-Z0-9]+)" id="[A-Z0-9]+">([^<]+)/g
    data = data.toString!
    ret = []

    while m = regex.exec data
        ret.push {
            TY: m.1
            name: m.2
        }

    callback null, ret

fetch_category_file = (output, ty, callback) ->
    filename = "#output/#ty.html"

    (err, rsp, body) <- request "#URL?TY=#ty"
    if err => callback err; return

    (err) <- fs.writeFile filename, body
    if err => callback err; return

    callback null, filename

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
        output: "#__dirname/../rawdata/LawClassList"
    } .argv

    console.log "Fetching index file"
    (err, filename) <- fetch_index_file argv.output
    if err => console.error err; return

    console.log "Parsing index file"
    (err, index) <- parse_index_file filename
    if err => console.error err; return

    console.log "Fetching category file"
    (err, filelist) <- async.map index, (item, callback) ->
        (err, filename) <- fetch_category_file argv.output, item.TY
        if err => callback err; return
        callback null, filename
    if err => console.error err; return

    console.log "Done"

main!
