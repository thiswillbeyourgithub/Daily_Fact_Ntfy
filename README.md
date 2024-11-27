# Daily Ntfy Ai Fact

This project sends a daily notification with an AI-generated interesting fact about a specified topic using ntfy.sh.

## Description

Daily Ntfy Ai Fact is a shell script that:
1. Waits for a random amount of time within a specified range.
2. Generates `subtopic` about `topic`, then an interesting fact about `subtopic` in the context of `topic` using an AI language model.
3. Sends this fact as a notification to your phone via ntfy.sh.

## Prerequisites

- zsh shell
- curl
- An AI language model CLI tool ([llm](https://github.com/simonw/llm))
- An ntfy.sh topic

## Setup

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/daily-ntfy-ai-fact.git
   cd daily-ntfy-ai-fact
   ```

2. Make the script executable:
   ```
   chmod +x daily_ntfy_ai_fact.sh
   ```

3. Set up your ntfy.sh topic as an environment variable:
   ```
   export NTFY_PHONE=your_ntfy_topic
   ```
## Usage

Run the script with three required arguments and one optional argument:

```
./daily_ntfy_ai_fact.sh MIN_SECONDS MAX_SECONDS "TOPIC"
```

- MIN_SECONDS: Minimum number of seconds to wait before sending the notification
- MAX_SECONDS: Maximum number of seconds to wait before sending the notification
- TOPIC: The topic you're interested in receiving an AI-generated fact about

Example:
```
./daily_ntfy_ai_fact.sh 3600 7200 "Psychiatry"
```

This will wait between 1 to 2 hours before sending an AI-generated fact about psychiatry:

* > Did you know that the first comprehensive textbook on psychiatry was published in 1845 by Dr. Thomas Kirkbride? Titled "An Introduction to the Study of Insanity," this influential book laid the groundwork for modern psychiatric research and practice.`

Example with custom LLM arguments:
```
DAILYFACT_EXTRA_ARGS_2="-m gpt-4o -o temperature 1" ./daily_ntfy_ai_fact.sh 3600 7200 "Psychiatry"
```

This will use the specified LLM model (gpt-4) with a custom temperature setting.

## Custom LLM Arguments

You can customize the behavior of the AI language model by providing additional arguments. These arguments are passed directly to the `llm` command. Some examples include:

- Specifying a different model: `-m gpt-4`
- Adjusting the temperature: `-o temperature 0.7`
- Setting a maximum token limit: `-o max_tokens 100`

If no custom arguments are provided, the script will use default settings (temperature 1).
To specify those extra arguments to 'llm', put them as string in the env variable DAILYFACT_EXTRA_ARGS_1 for the llm call that creates a subtopic about topic and DAILYFACT_EXTRA_ARGS_2 for the llm call to create the daily fact about the subtopic.

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check issues page if you want to contribute.
