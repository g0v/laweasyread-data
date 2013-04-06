require!<[async fs mkdirp optimist path url request]>
util = require \../ .util

getPortalLink = (callback) ->
    # FIXME: Get portal link automatic
    callback null, \http://lis.ly.gov.tw/lgcgi/lglaw?@22:1804289383:g:CN%3D0100*%20AND%20NO%3DA1%24%241__

getCategoryLink = (portalLink, callback) ->
    err, rsp, body <- request { url: portalLink, encoding: null }
    if err => return callback err
    body = util.normalizePageCharset body

    regex = /a href="([^"]+)">([^>]+)</ig
    ret = []

    while m = regex.exec body
        if not isNaN parseInt m.2
            ret.push \http://lis.ly.gov.tw/lgcgi/ + m.1

    callback null, ret

getLawLink = (categoryLink, callback) ->
    err, rsp, body <- request { url: categoryLink, encoding: null }
    if err => return callback err
    body = util.normalizePageCharset body

    regex = /a href="([^"]+)">([^>]+)</ig
    ret = []

    while m = regex.exec body
        if m.2.trim! == /\[全　　文\]|\[廢　　止\]|\[停止適用\]/
            ret.push \http://lis.ly.gov.tw/lgcgi/ + m.1

    callback null, ret

getLawAllVerLink = (lawLink, callback) ->
    err, rsp, body <- request { url: lawLink, encoding: null }
    if err => return callback err
    body = util.normalizePageCharset body

    regex = /a href=\/(lghtml\/lawstat\/version2\/[^\s]+)/ig
    ret = []

    while m = regex.exec body
        ret.push \http://lis.ly.gov.tw/ + m.1

    callback null, ret

downloadLawAllVer = (rawdata, link, callback) -->
    filepath = url.parse link .pathname - /\/lghtml\//
    filepath = rawdata + filepath

    mkdirp.sync path.dirname filepath

    # Don't run too fast
    <- setTimeout _, 1000ms

    err, rsp, body <- request { url: link, encoding: null }
    if err => return callback err
    body = util.normalizePageCharset body

    err <- fs.writeFile filepath, body
    if err => return callback err

    console.log "Download #filepath"
    callback null

main = ->
    callback = (err)-> if err => console.error err

    argv = optimist.default {
        output: "#__dirname/../rawdata/"
    } .argv

    err, portalLink <- getPortalLink
    if err => return callback err

    err, categoryLink <- getCategoryLink portalLink
    if err => return callback err

    err, lawLink <- async.concat categoryLink, getLawLink
    if err => return callback err

    err, lawAllVerLink <- async.concat lawLink, getLawAllVerLink
    if err => return callback err

    # Don't run too fast
    err <- async.eachLimit lawAllVerLink, 1, downloadLawAllVer argv.output
    if err => return callback err

    console.log \Done
    callback null

main!
