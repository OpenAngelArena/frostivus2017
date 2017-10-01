HordeDirector = HordeDirector or class({})

PHASE_BUILD_UP = 1
PHASE_PEAK = 2
PHASE_REST = 3
PHASE_WRAP = 4

local DesiredStressEvent = Event()
local WaveEvent = Event()

function HordeDirector:Init()
  DebugPrint('Init hero director')

  self.watchers = {}
  self.currentPhase = 0
  self.wave = 1
  self.timeInWave = 0

  Timers:CreateTimer(1, function()
    self.timeInWave = self.timeInWave + 1
    return 1
  end)

  PlayerResource:GetAllTeamPlayerIDs():each(function (playerID)
    DebugPrint('Initializing player watcher for player ' .. playerID)
    local watcher = PlayerWatcher()
    watcher:Init(playerID)
    table.insert(self.watchers, watcher)

    DesiredStressEvent.listen(function (ds)
      watcher.desiredStress = ds
    end)
    WaveEvent.listen(function (wave)
      watcher.wave = wave
    end)
  end)

  PeakStressEvent.listen(partial(HordeDirector.OnPeakStress, self))

  -- start horde director
  HordeSpawner:Init(self)
  self:EnterNextPhase()
end

function HordeDirector:OnPeakStress (watcher)
  DebugPrint('A player just entered peak stress!')
  if self:AllPlayersInPeakStress() then
    if self.currentPhase == PHASE_BUILD_UP then
      self:EnterNextPhase()
    end
  end
end

function HordeDirector:AllPlayersInPeakStress ()
  for _,watcher in ipairs(self.watchers) do
    if not watcher:IsPeakStress() then
      return false
    end
  end
  return true
end

function HordeDirector:EnterNextPhase()
  self.currentPhase = self.currentPhase + 1
  if self.currentPhase == PHASE_WRAP then
    self.currentPhase = PHASE_BUILD_UP
  end

  if self.currentPhase == PHASE_BUILD_UP then
    self:StartBuildUp()
  elseif self.currentPhase == PHASE_PEAK then
    self:StartPeak()
  elseif self.currentPhase == PHASE_REST then
    self:StartRest()
  end
end

function HordeDirector:StartBuildUp()
  DebugPrint('Entering start up phase')
  local desiredStress = 0
  Timers:CreateTimer(1, function()
    if self.currentPhase ~= PHASE_BUILD_UP then
      return
    end
    desiredStress = math.min(1, desiredStress + 0.01)
    DesiredStressEvent.broadcast(desiredStress)

    if self.timeInWave > MAX_WAVE_TIME then
      self:StartNextWave()
    end

    return 1
  end)
end

function HordeDirector:StartPeak()
  DebugPrint('Entering peak phase')
  DesiredStressEvent.broadcast(1.1) -- force impossible stress at peak
  Timers:CreateTimer(10, function()
    -- end peak on a timer
    self:EnterNextPhase()
  end)
end

function HordeDirector:StartRest()
  DesiredStressEvent.broadcast(-1)
  DebugPrint('Entering rest phase')
  if self.timeInWave > MIN_WAVE_TIME then
    self:StartNextWave()
  end

  Timers:CreateTimer(20, function()
    self:EnterNextPhase()
  end)
end

function HordeDirector:StartNextWave()
  DebugPrint('Starting next wave!')
  self.timeInWave = 0
  self.wave = self.wave + 1
  WaveEvent.broadcast(self.wave)
end
