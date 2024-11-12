#!/bin/zsh
#
# Send a daily notification via ntfy about some topic you're interested in.
# With a timer to wait a random amount of second and receive the notification at an unpredetermined time.
#
# usage:
# Put your ntfy topic in the env variable NTFY_PHONE
#
# Then run:
# ./daily_fact_ntfy.sh X Y "Z" "W"
#   - X: an int, minimum number of second to wait
#   - Y: an int greater than X, maximum number of second to wait
#   - Z: the topic you're interested in
#   - W: (optional) custom arguments for the llm command (e.g. "-m gpt-4 -o temperature 0.7")

today=$(date)
seed=$(openssl rand -base64 20)
PROMPT="I want you to tell me an interesting fact about a topic. It needs to always be true. It can be something interesting, insightful, little known, intriguing, etc. To increase the 'randomness' of your answer, know that today's date is \"$today\" and here's a random seed to ignore: \"$seed\". The topic of today is"

phone_notif () {
    sender=$NTFY_PHONE
    title="$1"
    message="$2"
    curl -s -H "Title: $title" -d "$message" "ntfy.sh/$sender"
}

# sleep an arbitrary amount between first and second arg
min=$1
max=$2

# receive the topic and llm args as arguments
topic="$3"
llm_args="$4"

# check validity of args
if [[ -z "$NTFY_PHONE" ]]; then
    echo "You forgot to put your ntfy topic in the env variable NTFY_PHONE"
    exit 1
fi
if [[ -z "$topic" || -z "$min" || -z "$max" ]]; then
    echo "You must supply a topic as third argument, a min and max number of seconds as first and second argument."
    exit 1
elif [[ "$min" -ge "$max" ]]; then
    echo "The first argument must be an int lower than the second argument"
    exit 1
fi

# Split the llm_args string into an array if provided
if [[ -n "$llm_args" ]]; then
    llm_args=(${(s: :)llm_args})
fi

tosleep=$(echo $((RANDOM % ($max-$min+1) + $min)))

# echo "Sleeping $tosleep seconds"
sleep $tosleep

if [[ -n "$llm_args" ]]; then
    fact=$(llm "${llm_args[@]}" "$PROMPT $topic")
else
    fact=$(llm "$PROMPT $topic")
fi

cleaned=$(echo $fact | sed -z 's/<thinking>.*<\/thinking>\s\+//g')
cleaned=$(printf "Your daily fact on the topic of '%s':\n%s" "$topic" "$cleaned")

phone_notif "Daily Psychiatry Fact" "$cleaned"


