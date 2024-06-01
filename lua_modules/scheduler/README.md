Inspired by source: https://mode13h.dev/coroutines-scheduler-in-lua/

Scheduler is simple list of coroutines, with ability to resume them based on:

- delay of time (ticks)
- sending an event (numeric identifier)
- providing a callback to determine if thread is ready to resume

All code must use `require("scheduler"):<method>` instead of stock lua `coroutine.<method>`.

One can run it in background using scheduler-start and timer.

One can use coroutines in parallel, but those would not be subject to scheduling.
