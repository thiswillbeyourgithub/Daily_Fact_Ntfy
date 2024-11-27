#!/bin/zsh
#
# Send a daily notification via ntfy about some topic you're interested in.
# With a timer to wait a random amount of second and receive the notification at an unpredetermined time.
# As increasing the temperature was not enough to avoid the LLM sending the same facts over and over again, a seed, date and subtopic prompt is used.
#
# usage:
# - Put your ntfy topic in the env variable NTFY_PHONE
# - To add extra arguments to 'llm', put them as string in the env variable DAILYFACT_EXTRA_ARGS_1 for the subtopic and DAILYFACT_EXTRA_ARGS_2 for the topic.
#
# - Then run:
#     ./daily_fact_ntfy.sh X Y "Z" "W"
#       - X: an int, minimum number of second to wait
#       - Y: an int greater than X, maximum number of second to wait
#       - Z: the topic you're interested in

phone_notif () {
    sender=$NTFY_PHONE
    title="$1"
    message="$2"
    curl -s -H "Title: $title" -d "$message" "ntfy.sh/$sender"
}

today=$(date)
seed=$(openssl rand -base64 20)
RAND_PROMPT="To increase the 'randomness' of your answer, know that today's date is \"$today\" and here's a random seed to ignore: \"$seed\"."

# parse args
min=$1
max=$2
topic="$3"
subtopic_extra_args="$DAILYFACT_EXTRA_ARGS_1"
topic_extra_args="$DAILYFACT_EXTRA_ARGS_2"

# Split the extra_args string into an array if provided
if [[ -n "$subtopic_extra_args" ]]; then
    subtopic_extra_args=(${(s: :)subtopic_extra_args})
fi
if [[ -n "$topic_extra_args" ]]; then
    topic_extra_args=(${(s: :)topic_extra_args})
fi


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

TOPIC_PROMPT="I want you to tell me an interesting fact about a topic. It needs to always be true. It can be something interesting, insightful, little known, intriguing, etc. $RAND_PROMPT The topic of today is "

SUBTOPIC_PROMPT="I want you to give me any subtopic on the topic \"$topic\". $RAND_PROMPT"
SUBTOPIC_SYSPROMPT="You answer only a single line containing a single concept. Don't include any explanation or details."

# generate subtopic
subtopic=$(llm "$SUBTOPIC_PROMPT" -s "$SUBTOPIC_SYSPROMPT" -o temperature 2)

if [[ -n "$subtopic_extra_args" ]]; then
    subtopic=$(llm "${subtopic_extra_args[@]}" "$SUBTOPIC_PROMPT" -s "$SUBTOPIC_SYSPROMPT")
else
    subtopic=$(llm "$SUBTOPIC_PROMPT" -s "$SUBTOPIC_SYSPROMPT" -o temperature 2)
fi

# sleep an arbitrary amount between first and second arg
tosleep=$(echo $((RANDOM % ($max-$min+1) + $min)))
# echo "Sleeping $tosleep seconds"
sleep $tosleep

if [[ -n "$topic_extra_args" ]]; then
    fact=$(llm "${topic_extra_args[@]}" "$TOPIC_PROMPT $subtopic in the context of \"$topic\"")
else
    fact=$(llm "$TOPIC_PROMPT $subtopic in the context of \"$topic\"")
fi

cleaned=$(echo $fact | sed -z 's/<thinking>.*<\/thinking>\s\+//g')
cleaned=$(printf "Your daily fact on the topic of '%s':\n%s" "$topic" "$cleaned")

# echo "$topic"
# echo "$subtopic"
# echo "$cleaned"
phone_notif "Daily Psychiatry Fact" "$cleaned"


