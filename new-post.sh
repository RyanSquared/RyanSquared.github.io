#!/bin/bash
filename="_posts/$(date '+%Y-%m-%d')-$(echo $@ | tr ' ' '-' | tr A-Z a-z | sed "s/[^a-z\\-]//g").md"

cat > $filename <<END
---
layout: post
title:  "$*"
date:   $(date '+%Y-%m-%d %H:%M:%S %z')
---
END

${EDITOR:-vim} "$filename"
