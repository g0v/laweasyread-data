#!/bin/sh

find lawstat -type f -exec sh -c 'mkdir -p `dirname utf8_{}`; iconv -f big5 -t utf-8 {} | sed s/charset=big5/charset=utf8/ > utf8_{}' \;
