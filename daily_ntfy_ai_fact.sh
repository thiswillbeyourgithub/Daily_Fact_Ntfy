#!/bin/zsh
#
# Send a daily notification via ntfy about some topic you're interested in.
# With a timer to wait a random amount of second and receive the notification at an unpredetermined time.
# As increasing the temperature was not enough to avoid the LLM sending the same facts over and over again, a seed, date and subtopic prompt is used.
#
# Usage: (requires 'uv' for ShellArgParser)
#   ./daily_ntfy_ai_fact.sh --topic TOPIC --ntfy_topic TOPIC_NAME [options]
#
# Required arguments:
#   --topic TOPIC          Topic to generate facts about
#   --ntfy_topic NAME      Ntfy.sh topic name for notifications
#
# Optional arguments:
#   --min_t MIN           Minimum wait time in seconds (default: 0)
#   --max_t MAX          Maximum wait time in seconds (default: 1)
#   --topic_extra_args ARGS      Additional arguments for topic LLM call
#   --subtopic_extra_args ARGS   Additional arguments for subtopic LLM call
#   --topic_extra_rules RULES    Additional rules for topic generation
#   --subtopic_extra_rules RULES Additional rules for subtopic generation
#   --verbose            Enable verbose logging
#   --strip-thinking    Remove <thinking>...</thinking> tags from output
#
# Note: For LLM calls, default temperature is 2.0 for subtopic and 1.5 for fact generation.
#       Use -o temperature X in extra_args to override these values.

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
