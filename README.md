# SpacedRepetitionScheduler

Implements an Anki-style spaced repetition scheduler for active recall prompts.

## Overview

In a learning system that uses [active recall](https://en.wikipedia.org/wiki/Active_recall), 
learners are presented with a *prompt* and rate their ability to recall the corresponding information. 
`SpacedRepetitionScheduler` recommends a time interval to wait before showing a learner the same *prompt* again, given 
his/her history of recalling the information associated with this prompt and how well he/she did 
recalling the associated information this time. The recommended time intervals for a given prompt will increase the more frequently
the learner recalls the information associated with a prompt.

`SpacedRepetitionScheduler` considers a prompt to be in one of two modes when making time interval recommendations: *learning* or *review*.

- In the *learning* mode, the learner must successfully recall the corresponding information a specific number of times with specific time intervals between recall attempts. After successfully recalling the associated information the specified number of times, the prompt graduates to the *review* state.
- In the *review* mode, the amount of time between successive reviews of a prompt increases by a geometric progression with each successful recall.


## Where to start in the code

### Representing prompts

- `PromptSchedulingMetadata` -- Information needed to determine the recommended time to review a prompt again.
- `PromptSchedulingMode` -- Whether the prompt is in *learning* or *review* mode.

### Scheduling parameters

- `RecallEase` -- Rating for how easy it is to recall the information associated with a prompt.
- `SchedulingParameters` -- Holds parameters used to determine the recommended time to schedule the next review of a prompt.
