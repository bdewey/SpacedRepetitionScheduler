# SpacedRepetitionScheduler

This package provides a spaced repetition scheduler inspired by the implementation in the popular Anki spaced-repetition program.

This package implements an Anki-style spaced repetition scheduler for active recall items.

In a learning system that uses [active recall](https://en.wikipedia.org/wiki/Active_recall), learners are presented with a *prompt* and rate their ability to recall the corresponding information. `SpacedRepetitionScheduler` determines the optimum time for the learner to see a *prompt* again, given his/her history of recalling the information associated with this prompt and how well he/she did recalling the associated information this time.

A *prompt* can be either in a *learning* state or a *review* state.

- In the *learning* state, the learner must successfully recall the corresponding information a specific number of times, at which point the prompt graduates to the *review* state.
- In the *review* state, the amount of time between successive reviews of a prompt increases by a geometric progression with each successful recall.
