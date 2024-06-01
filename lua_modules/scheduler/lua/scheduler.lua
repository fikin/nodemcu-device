---@class scheduler
local scheduler = {}

---@alias scheduler_ready_fn fun(ticks:integer):boolean tests if the function is ready to be resumed

---@class scheduler_job
---@field priority integer of the thread
---@field args nil|any[] arguments passed to first coroutine.resume() call
---@field readyAfterTicks nil|integer test if the function is
-- ready to resume in current scheduler:pulse()
---@field readyAfterPredicate nil|fun():boolean if it returns true,
-- the function is ready to resume in current scheduler:pulse()
---@field readyAfterSignal nil|any ready to resume in current scheduler:pulse()
-- if signal with given id arrives

---@alias scheduler_pool table<thread,scheduler_job>

---@type scheduler_pool
local _pool = {}

---@param lhs scheduler_job
---@param rhs scheduler_job
---@return boolean
local function sortByPriority(lhs, rhs)
  return lhs.priority < rhs.priority
end

--- Traverse and wake the ready threads, one at a time.
--- Please note that if a higher priority thread will switch to
--- ready state as a side-effect of the following loop it won't
--- be called until the next [scheduler:pulse()] call.
---@param jobs scheduler_pool
local function resumeJobs(jobs)
  for thread, params in pairs(jobs) do
    local args = params.args or {}

    -- reset job's resume conditions
    params.args = nil
    params.readyAfterTicks = nil
    params.readyAfterPredicate = nil
    params.readyAfterSignal = nil

    local ok, err = coroutine.resume(thread, table.unpack(args))
    if not ok then
      require("log").error("core dump : %s : %s", thread, err)
      _pool[thread] = nil
    end
  end
end

--- Get rid of the not longer alive thread.
---@param jobs scheduler_pool
local function gc(jobs)
  for k, p in pairs(jobs) do
    p.args = nil
    p.readyAfterPredicate = nil
    _pool[k] = nil
  end
end

---@param ticks integer
---@param params scheduler_job
---@return boolean
local function isJobReadyToRun(ticks, params)
  if params.readyAfterTicks then
    -- First we need to update the [SLEEPING] threads' timers.
    params.readyAfterTicks = params.readyAfterTicks - ticks
    -- If the timer has elapsed we switch the thread in [READY] state.
    return params.readyAfterTicks <= 0
  elseif params.readyAfterPredicate then
    return params.readyAfterPredicate()
  else
    return false
  end
end

---Find dead jobs and ones ready to resume now
---@param ticks integer
---@param jobs scheduler_pool
---@return scheduler_pool
---@return scheduler_pool
local function findReadyJobs(ticks, jobs)
  local dead = {}
  local ready = {}
  for thread, params in pairs(jobs) do
    local status = coroutine.status(thread)
    if status == "dead" then
      -- Dead threads are detected and removed the from the table itself
      -- (and the garbage-collector will eventually handle them).
      dead[thread] = params
    elseif status == "suspended" then
      if isJobReadyToRun(ticks, params) then
        ready[thread] = params
      end
    else
      error(string.format("unexpected thread status : %s", status))
    end
  end
  return dead, ready
end

---@param id any
---@param ... any
---@return scheduler_pool
local function signalJobs(id, ...)
  local jobs = {}
  for thread, params in pairs(_pool) do
    if params.readyAfterSignal == id then
      params.args = table.pack(...)
      params.readyAfterTicks = 0
      params.readyAfterPredicate = nil
      params.readyAfterSignal = nil

      jobs[thread] = params
    end
  end
  return jobs
end

--- Suspends the calling thread execution. It will be resumed on the next
--- [scheduler:pulse()] call, according the its relative priority.
---@param ... any arguments passed to actual coroutine.yield()
---@return nil|any arguments returned by actual coroutine.resume()
function scheduler:yield(...)
  assert(self ~= nil)
  local thread = coroutine.running()

  local params = _pool[thread]
  params.args = nil
  params.readyAfterTicks = 0
  params.readyAfterPredicate = nil
  params.readyAfterSignal = nil

  return coroutine.yield(...)
end

--- Suspend the calling thread execution for a give amount of [ticks].
--- Once the timeout is elapsed, the thread will move to [READY] state
--- and will be scheduled in the following [scheduler:pulse()] call.
---@param ticks integer to wait before awakening the thread
---@param ... any arguments passed to actual coroutine.yield()
---@return any arguments returned by actual coroutine.resume()
function scheduler:sleep(ticks, ...)
  assert(self ~= nil)
  local thread = coroutine.running()

  local params = _pool[thread]
  params.args = nil
  params.readyAfterTicks = ticks
  params.readyAfterPredicate = nil
  params.readyAfterSignal = nil

  return coroutine.yield(...)
end

--- Suspend the calling thread execution until the given [predicate]
--- turns true. Once this happens, the thread will move to [READY] state
--- and will be scheduled in the following [scheduler:pulse()] call.
---@param predicate fun():boolean to check when is ready to resume the thread
---@param ... any arguments passed to actual coroutine.yield()
---@return any arguments returned by actual coroutine.resume()
function scheduler:check(predicate, ...)
  assert(self ~= nil)
  local thread = coroutine.running()

  local params = _pool[thread]
  params.args = nil
  params.readyAfterTicks = nil
  params.readyAfterPredicate = predicate
  params.readyAfterSignal = nil

  return coroutine.yield(...)
end

--- Suspend the calling thread execution until the event with identifier
--- [id] is signalled. See [scheduler:signal()].
---@param id any used by scheduler:signal() to awaken the thread,
-- if id is not globally unique signal will awaken multiple threads
---@param ... any arguments passed to actual coroutine.yield()
---@return any arguments returned by actual coroutine.resume()
function scheduler:wait(id, ...)
  assert(self ~= nil)
  local thread = coroutine.running()

  local params = _pool[thread]
  params.args = nil
  params.readyAfterTicks = nil
  params.readyAfterPredicate = nil
  params.readyAfterSignal = id

  return coroutine.yield(...)
end

--- Suspend the calling thread execution until either of:
--- -the event with identifier [id] is signalled. See [scheduler:signal()].
--- -sleep timeout runs out. See [scheduler:sleep()].
--- In this case timeoutArgs will be passed to coroutine.resume() call.
---@param id any used by scheduler:signal() to awaken the thread,
-- if id is not globally unique signal will awaken multiple threads
---@param ticks integer to wait before awakening the thread
---@param timeoutArgs any[]|nil arguments to pass to coroutine.resume() in case timeout ran out.
---@param ... any arguments passed to actual coroutine.yield()
---@return any arguments returned by actual coroutine.resume()
function scheduler:waitOrTimeout(id, ticks, timeoutArgs, ...)
  assert(self ~= nil)
  local thread = coroutine.running()

  local params = _pool[thread]
  params.args = timeoutArgs
  params.readyAfterTicks = ticks
  params.readyAfterPredicate = nil
  params.readyAfterSignal = id

  return coroutine.yield(...)
end

--- Signals an event given it's identifier-string. The waiting threads are
--- marked as "ready" and will wake on the next [scheduler:pulse()] call.
---@param id any must be globally unique identifier, used by scheduler:wait() to awaken the thread
---@param ... any arguments passed to actual coroutine.resume()
function scheduler:signal(id, ...)
  assert(self ~= nil)
  -- Signalled threads are not resumed here, but marked as "ready"
  -- and awaken when calling [schedule.pulse()].
  -- This ensure that threads won't be start from within another
  -- thread body but only from a single dispatcher loop. That is,
  -- threads are suspended only from an explicit [sleep()] or
  -- [wait()] call, and not since they are waking up some other
  -- thread.
  -- Note that calling "coroutine.resume()" from a thread yields
  -- and start the called one.
  signalJobs(id, ...)
end

--- Signals an event given it's identifier-string. The waiting threads are resumed immediately.
--- ATTENTION: since the threads are started as part of this call, make sure there would not be any
--- side effects due to threads starting oher threads.
---@param id any must be globally unique identifier, used by scheduler:wait() to awaken the thread
---@param ... any arguments passed to actual coroutine.resume()
function scheduler:signalSync(id, ...)
  assert(self ~= nil)
  local jobs = signalJobs(id, ...)
  resumeJobs(jobs)
end

--- Creates a new thread bound to the passed function [procedure]. If passed
--- the [priority] argument indicates the thread priority (higher values
--- means lower priority), otherwise sets it to zero as a default.
--- The thread is initially suspended and will wake up on the next
--- [scheduler:pulse()] call.
---@param procedure fun() coroutine function
---@param priority nil|integer priority, the lower the value, the higher the priority
---@param ... nil|any arguments passed to first coroutine.resume() call
---@return thread coroutine newly created
function scheduler:spawn(procedure, priority, ...)
  assert(self ~= nil)
  local thread = coroutine.create(procedure)

  _pool[thread] = {
    priority = priority or 0, -- if not provided revert to highest
    args = table.pack(...),
    readyAfterTicks = 0,
    readyAfterPredicate = nil,
    readyAfterSignal = nil,
  }

  -- Naive priority queue implementation, by re-sorting the table every time
  -- we spawn a new thread. A smarter heap-based implementation, at the moment,
  -- it's not worth the effort.
  table.sort(_pool, sortByPriority)

  return thread
end

--- Update the thread list considering [ticks] units have passed. Any
--- sleeping thread whose timeout is elapsed will be woken up.
---@param ticks integer how many ticks passed since last call to scheduler:pulse()
function scheduler:pulse(ticks)
  assert(self ~= nil)
  local dead, ready = findReadyJobs(ticks, _pool)
  gc(dead)
  resumeJobs(ready)
end

---resumes given thread immediately
---@param th thread
function scheduler:resumeSync(th)
  assert(self ~= nil)
  local params = _pool[th]
  if params then
    local tbl = {}
    tbl[th] = params
    resumeJobs(tbl)
  end
end

---dump the content of the scheduler (thread and status)
---@return string
function scheduler:dump()
  assert(self ~= nil)
  local sjson = require("sjson")
  local arr = { "scheduler dump:" }
  local cnt = 0
  for thread, params in pairs(_pool) do
    cnt = cnt + 1
    local str = string.format("%d : %s : %s : %s", cnt, thread, coroutine.status(thread), sjson.encode(params))
    table.insert(arr, str)
  end
  return table.concat(arr, "\n")
end

return scheduler
