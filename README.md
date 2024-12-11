# Daily Ntfy AI Fact

This project sends notifications with AI-generated interesting facts about specified topics using ntfy.sh.

## Description

Daily Ntfy AI Fact is a shell script that:
1. Generates a subtopic about your chosen topic
2. Creates an interesting fact about that subtopic in the context of your topic using an AI language model
3. Optionally waits a random amount of time within a specified range
4. Sends this fact as a notification via ntfy.sh

## Prerequisites

- zsh shell
- curl
- [uv](https://github.com/astral-sh/uv) (for [ShellArgParser](https://github.com/thiswillbeyourgithub/ShellArgParser))
- [llm](https://github.com/simonw/llm) (an AI language model CLI tool)
- An [ntfy.sh](https://ntfy.sh) topic

## Setup

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/daily-ntfy-ai-fact
   cd daily-ntfy-ai-fact
   ```

2. Make the script executable:
   ```
   chmod +x daily_ntfy_ai_fact.sh
   ```
## Usage

Basic usage:

```bash
./daily_ntfy_ai_fact.sh --topic TOPIC --ntfy_topic TOPIC_NAME [options]
```

Required arguments:
- `--topic TOPIC`: Main topic to generate facts about
- `--ntfy_topic TOPIC_NAME`: Ntfy.sh topic name for notifications

Optional arguments:
- `--min_t MIN`: Minimum seconds to wait (default: 0)
- `--max_t MAX`: Maximum seconds to wait (default: 1)
- `--topic_extra_args ARGS`: Additional arguments for topic LLM call
- `--subtopic_extra_args ARGS`: Additional arguments for subtopic LLM call
- `--topic_extra_rules RULES`: Additional rules for topic generation
- `--subtopic_extra_rules RULES`: Additional rules for subtopic generation
- `--verbose`: Enable verbose logging
- `--strip-thinking`: Remove <thinking>...</thinking> tags from output

Example:
```bash
./daily_ntfy_ai_fact.sh --topic "Psychiatry" --ntfy_topic "my-notifications" --min_t 3600 --max_t 7200
```

This will:
1. Generate a subtopic about psychiatry (say 'simulating depression in mice')
2. Create an interesting fact about that subtopic (the explanation about the subtopic)
3. Wait between 1 to 2 hours (to be surprised by the notification on your phone)
4. Send the fact as a notification via ntfy.sh

## Custom LLM Arguments

You can customize the behavior of the AI language model by providing additional arguments through `--topic_extra_args` or `--subtopic_extra_args`. These are passed directly to the `llm` command. For example:

```bash
./daily_ntfy_ai_fact.sh --topic "Psychiatry" --ntfy_topic "my-notifications" --topic_extra_args "-m gpt-4 -o temperature 0.7"
```

More advanced example using Claude, custom rules, and thinking tags:
```bash
./daily_ntfy_ai_fact.sh --ntfy_topic "my-notifications" \
  --topic "Psychiatry research" \
  --min_t 0 --max_t 5 \
  --subtopic_extra_args "-m claude -o temperature 2" \
  --topic_extra_args "-m claude -o temperature 1.5" \
  --topic_extra_rules "Answer in simple spanish. Start your answer by your internal thoughts in <thinking> tags then answer directly." \
  --verbose --strip-thinking
```

This will:
1. Use Claude instead of the default model
2. Generate facts in Spanish
3. Remove the model's thinking process from the output
4. Send the notification almost immediately (0-5 seconds delay)

Note: Default temperatures are:
- 2.0 for subtopic generation
- 1.5 for fact generation

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check issues page if you want to contribute.
