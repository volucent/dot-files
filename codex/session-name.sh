#!/bin/bash
# Generate a deterministic cute two-word name from a session ID.
# Usage: echo "session_id" | bash session-name.sh

SESSION_ID="${1:-$(cat)}"
[ -z "$SESSION_ID" ] && echo "unnamed" && exit 0

ADJECTIVES=(
  fuzzy cozy snowy breezy sunny gentle mellow velvet golden silky
  happy lucky bubbly swift nimble tiny mighty brave calm clever
  sparkly dreamy jolly dizzy wiggly bouncy sleepy peppy zesty cosmic
)

ANIMALS=(
  penguin otter panda fox owl bunny kitten puppy dolphin koala
  hedgehog raccoon sloth flamingo narwhal quokka axolotl capybara wombat gecko
  puffin badger ferret lemur chinchilla toucan starling finch heron osprey
)

HASH=$(echo -n "$SESSION_ID" | md5sum | tr -dc '0-9' | head -c10)
ADJ_IDX=$(( ${HASH:0:5} % ${#ADJECTIVES[@]} ))
ANI_IDX=$(( ${HASH:5:5} % ${#ANIMALS[@]} ))

echo "${ADJECTIVES[$ADJ_IDX]}-${ANIMALS[$ANI_IDX]}"
