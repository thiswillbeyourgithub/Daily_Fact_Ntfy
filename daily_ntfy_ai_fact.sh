#!/bin/zsh
#
# Send a daily notification via ntfy about some topic you're interested in.
# With a timer to wait a random amount of second and receive the notification at an unpredetermined time.
# As increasing the temperature was not enough to avoid the LLM sending the same facts over and over again, a seed, date and subtopic prompt is used.
#
# usage:
#   (make sure you have 'uv' installed, as it's used to call ShellArgParser)
#  ./daily_fact_ntfy.sh --topic "T" --ntfy_topic "N" --min_T X --max_T Y --topic_extra_args "V1" --subtopic_extra_args "V2" --topic_extra_rules "W1" --subtopic_extra_rules "W2" --verbose --strip-thinking
#
#  With as args:
#    - T: the topic you're interested in, required.
#    - N: the ntfy topic, appended to 'ntfy.sh/', required.
#    - X: an int, minimum number of second to wait, default to 0.
#    - Y: an int greater than X, maximum number of second to wait, default to 1.
#    - V: any extra argument you want to add to the 'llm' command. Be careful to specify the temperature using '-o temperature x' as the default is 2 for the subtopic generation and 1.5 for the fact generation. Note that you can't specify an llm template using -t because it's incompatible with specifying a system prompt, use the extra_rules args instead. V1 applies to the llm call to generate a subtopic and V2 applies to the llm call to generate the faily fact, optional.
#    - W: any extra rules to tell the LLM. W1 for the subtopic generation and W2 for the fact generation. They will be appended to 'Here are extra rules you need to follow:'. For example 'you must answer in simple spanish', optional.
#    - --verbose: optional
#    - --strip-thinking: if set, removes any <thinking>.*</thinking> text. Useful if your llm template makes use of that.

# parse args
eval $(uvx --quiet ShellArgParser@latest $@)

function log() {
    if [[ $ARGS_VERBOSE -eq 1 ]]; then
        echo "\n\n# $1"
    fi
}

# check args
if [[ -z "$ARGS_NTFY_TOPIC" ]]; then
    echo "Missing argument --ntfy_topic"
    exit 1
fi
if [[ -z "$ARGS_TOPIC" ]]; then
    echo "Missing argument --topic"
    exit 1
fi
if [[ -z "$ARGS_MIN_T" ]]; then
    ARGS_MIN_T=0
fi
if [[ -z "$ARGS_MAX_T" ]]; then
    ARGS_MAX_T=1
fi
if [[ ! "$ARGS_MIN_T" -le "$ARGS_MAX_T" ]]; then
    echo "The --min_t argument must be an int lower than --max_t"
    exit 1
fi
if [[ -n "$ARGS_TOPIC_EXTRA_RULES" ]]; then
    ARGS_TOPIC_EXTRA_RULES="\nHere are extra rules you need to follow: \"$ARGS_TOPIC_EXTRA_RULES\""
fi
if [[ -n "$ARGS_SUBTOPIC_EXTRA_RULES" ]]; then
    ARGS_SUBTOPIC_EXTRA_RULES="\nHere are extra rules you need to follow: \"$ARGS_SUBTOPIC_EXTRA_RULES\""
fi
log "Arguments are valid"

# generate a subtopic
SUBTOPIC_PROMPT="I want you to give me any subtopic on the topic \"$ARGS_TOPIC\".
To increase the 'randomness' of your answer, know that today's date is \"$(date)\" and here's a random seed to ignore: \"$(openssl rand -base64 20)\"."
SUBTOPIC_SYSPROMPT="You answer only a single line containing a single, specific, concept. Don't include any explanation or details. For example 'Technology of swords before the Xth century' or 'Nucleic acid replication in E. Coli'.$ARGS_SUBTOPIC_EXTRA_RULES"
log "subtopic prompt: $SUBTOPIC_PROMPT"
log "subtopic sysprompt: $SUBTOPIC_SYSPROMPT"
if [[ -n "$ARGS_SUBTOPIC_EXTRA_ARGS" ]]; then
    # Split the extra_args string into an array if provided
    ARGS_SUBTOPIC_EXTRA_ARGS=(${(s: :)ARGS_SUBTOPIC_EXTRA_ARGS})
    log "subtopic extra arguments: \"$ARGS_SUBTOPIC_EXTRA_ARGS\""
    subtopic=$(llm "${ARGS_SUBTOPIC_EXTRA_ARGS[@]}" "$SUBTOPIC_PROMPT" -s "$SUBTOPIC_SYSPROMPT")
else
    subtopic=$(llm "$SUBTOPIC_PROMPT" -s "$SUBTOPIC_SYSPROMPT" -o temperature 2)
fi
log "Generated subtopic: \"$subtopic\""

if [[ -z "$subtopic" || $subtopic =~ "^Error:.*" ]]; then
    curl -s -H "Title: Error - Daily AI Fact" -d "Apparently an error happened when generating a subtopic. $subtopic" "ntfy.sh/$ARGS_NTFY_TOPIC"
    exit 1
fi

# generate a fact about subtopic in the context of topic
TOPIC_PROMPT="To increase the 'randomness' of your answer, know that today's date is \"$(date)\" and here's a random seed to ignore: \"$(openssl rand -base64 20)\".
The topic of of today is \"$subtopic\", which fits broadly in the context \"$ARGS_TOPIC\""
TOPIC_SYSPROMPT="You tell one interesting fact about a specific topic. You don't lie. You don't hallucinate.
Answer only true facts or, if you're unsure about something, make your doubts explicit. For example it can be something interesting, insightful, little known, intriguing, etc.$ARGS_TOPIC_EXTRA_RULES"
log "topic prompt: $TOPIC_PROMPT"
log "topic sysprompt: $TOPIC_SYSPROMPT"
if [[ -n "$ARGS_TOPIC_EXTRA_ARGS" ]]; then
    # Split the extra_args string into an array if provided
    ARGS_TOPIC_EXTRA_ARGS=(${(s: :)ARGS_TOPIC_EXTRA_ARGS})
    log "topic extra arguments: \"$ARGS_SUBTOPIC_EXTRA_ARGS\""
    fact=$(llm "${ARGS_TOPIC_EXTRA_ARGS[@]}" "$TOPIC_PROMPT" -s "$TOPIC_SYSPROMPT")
else
    fact=$(llm "$TOPIC_PROMPT" -s "$TOPIC_SYSPROMPT" -o temperature 1.5)
fi
if [[ -z "$fact" || $fact =~ "^Error:.*" ]]; then
    curl -s -H "Title: Error - Daily AI Fact" -d "Apparently an error happened when generating a fact. $fact" "ntfy.sh/$ARGS_NTFY_TOPIC"
    exit 1
fi

log "Full llm fact output: \"$fact\""
if [[ "$ARGS_STRIP_THINKING" -eq 1 ]]; then
    log "Removing thinking tags"
    cleaned=$(echo $fact | sed -z 's/<thinking>.*<\/thinking>\s\+//g')
fi
cleaned=$(printf "Your daily fact on the topic of '%s':\n%s" "$ARGS_TOPIC" "$cleaned")
log "Answer: \"$cleaned\""

# sleep an arbitrary amount between first and second arg
tosleep=$(echo $((RANDOM % ($ARGS_MAX_T-$ARGS_MIN_T+1) + $ARGS_MIN_T)))
# echo "Sleeping $tosleep seconds"
log "Sleeping for $tosleep seconds"
sleep $tosleep

echo "$cleaned"
log "Sending answer to ntfy at topic \"$ARGS_NTFY_TOPIC\""
# curl -s -H "Title: Daily AI Fact" -d "$cleaned" "ntfy.sh/$ARGS_NTFY_TOPIC"
