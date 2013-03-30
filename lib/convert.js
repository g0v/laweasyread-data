//need to be converted to livescript

var cnNum2ArabNum = function(cn){
    var arab, cnChars = '零一二三四五六七八九'
 
    if (!cn) {
        return 0
    }
 
    if (cn.indexOf('十') === 0){
        cn = '一' + cn
    }
    arab = cn.replace(/[零一二三四五六七八九]/g, function (a) {
            return '+' + cnChars.indexOf(a)
        }).replace(/(十|百|千)/g, function(a, b){
            return '*' + (
                b == '十' ? 1e1 :
                b == '百' ? 1e2 : 1e3
            )
        })
    return (new Function('return ' + arab))()
}

console.log(cnNum2ArabNum("一千一百零六"));
