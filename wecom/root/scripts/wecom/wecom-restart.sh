#!/bin/bash

/scripts/wecom/wecom-stop.sh
sleep 2
nohup /scripts/wecom/wecom-start.sh >/tmp/wecom-start.log 2>&1 &
