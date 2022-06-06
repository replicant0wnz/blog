#!/bin/bash

#ENTRY_DATE=$(ls -t1 $PWD/_posts | head -1 | awk -F- '{printf "%s-%s-%s", $1, $2, $3}')
ENTRY_TITLE=$(cat $PWD/_posts/`ls -t1 $PWD/_posts | head -1` | grep title | awk -F: '{print tolower($2)}')
echo $ENTRY_TITLE
