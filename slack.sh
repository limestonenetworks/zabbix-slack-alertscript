#!/bin/bash

# Load /etc/environment in case proxy settings are needed
while read -r env; do export "$env"; done < <(cat /etc/environment)

export SCRIPT_PATH=$(dirname $(readlink -f "$0"))

if [[ -f "${SCRIPT_PATH}/slack.env" ]]; then
    . "${SCRIPT_PATH}/slack.env"
fi

# Slack incoming web-hook URL and user name
url='CHANGEME'		# example: https://hooks.slack.com/services/QW3R7Y/D34DC0D3/BCADFGabcDEF123
username='Zabbix'

## Values received by this script:
# To = $1 (Slack channel or user to send the message to, specified in the Zabbix web interface; "@username" or "#channel")
# Subject = $2 (usually either PROBLEM or RECOVERY/OK)
# Message = $3 (whatever message the Zabbix action sends, preferably something like "Zabbix server is unreachable for 5 minutes - Zabbix server (127.0.0.1)")

# Get the Slack channel or user ($1) and Zabbix subject ($2 - hopefully either PROBLEM or RECOVERY/OK)
to="$1"
subject="$2"

# Change message emoji depending on the subject - smile (RECOVERY/OK), frowning (PROBLEM), or ghost (for everything else)
recoversub='^RECOVER(Y|ED)?$'
if [[ "$subject" =~ ${recoversub} ]]; then
	color='#00ff00'
elif [ "$subject" == 'OK' ]; then
	color='#00ff00'
elif [ "$subject" == 'PROBLEM' ]; then
	color='#ff0000'
else
	color='#0000ff'
fi

# The message that we want to send to Slack is the "subject" value ($2 / $subject - that we got earlier)
#  followed by the message that Zabbix actually sent us ($3)
message="${subject}: $3"

# Build our JSON payload and send it as a POST request to the Slack incoming web-hook URL
payload="payload={\"channel\": \"${to//\"/\\\"}\", \"username\": \"${username//\"/\\\"}\", \"attachments\": [{\"color\": \"${color}\", \"text\": \"${message//\"/\\\"}\"}]}"
curl -m 5 --data-urlencode "${payload}" ${SLACK_WEBHOOK_URL:-$url} -A 'zabbix-slack-alertscript / https://github.com/ericoc/zabbix-slack-alertscript'
