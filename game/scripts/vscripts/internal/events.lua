GameEvents = GameEvents or {}

function CreateGameEvent (name) --luacheck: ignore CreateGameEvent
  local event = Event()

  GameEvents[name] = (function (self, fn)
    return event.listen(fn)
  end)

  return event.broadcast
end

-- The overall game state has changed
local OnAllPlayersLoadedEvent = CreateGameEvent('OnAllPlayersLoaded')
function GameMode:_OnGameRulesStateChange(keys)
  if GameMode._reentrantCheck then
    return
  end

  local newState = GameRules:State_Get()
  CustomGameEventManager:Send_ServerToAllClients( 'oaa_state_change', {
    newState = newState
  })

  if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
    self.bSeenWaitForPlayers = true
  elseif newState == DOTA_GAMERULES_STATE_INIT then
    --Timers:RemoveTimer("alljointimer")
  elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
    GameMode:PostLoadPrecache()
    GameMode:OnAllPlayersLoaded()
    OnAllPlayersLoadedEvent({})

    if USE_CUSTOM_TEAM_COLORS_FOR_PLAYERS then
      for i=0,19 do
        if PlayerResource:IsValidPlayer(i) then
          local color = TEAM_COLORS[PlayerResource:GetTeam(i)]
          PlayerResource:SetCustomPlayerColor(i, color[1], color[2], color[3])
        end
      end
    end


  elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameMode:OnGameInProgress()
  end

  GameMode._reentrantCheck = true
  GameMode:OnGameRulesStateChange(keys)
  GameMode._reentrantCheck = false
end

local OnHeroInGameEvent = CreateGameEvent('OnHeroInGame')
local OnAllHeroesInGameEvent = CreateGameEvent('OnAllHeroesInGame')
-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:_OnNPCSpawned(keys)
  if GameMode._reentrantCheck then
    return
  end

  local npc = EntIndexToHScript(keys.entindex)

  if npc:IsRealHero() and npc.bFirstSpawned == nil then
    npc.bFirstSpawned = true
    OnHeroInGameEvent(npc)
    GameMode:OnHeroInGame(npc)

    if not GameMode._haveAllHeroesSpawned then
      local allPlayers = {}
      local function addToList (list, id)
        list[id] = true
      end
      GameMode._haveAllHeroesSpawned = true

      for _,playerId in ipairs(totable(PlayerResource:GetAllTeamPlayerIDs())) do
        local hero = PlayerResource:GetSelectedHeroEntity(playerId)
        if npc:GetPlayerID() == playerId then
          hero = npc
        end
        if not hero then
          GameMode._haveAllHeroesSpawned = false
        end
      end
      if GameMode._haveAllHeroesSpawned then
        Timers:CreateTimer(1, function()
          GameMode:OnAllHeroesInGame()
          OnAllHeroesInGameEvent({})
        end)
      end
    end
  end

  GameMode._reentrantCheck = true
  GameMode:OnNPCSpawned(keys)
  GameMode._reentrantCheck = false
end

-- An entity died
function GameMode:_OnEntityKilled( keys )
  if GameMode._reentrantCheck then
    return
  end

  -- The Unit that was Killed
  local killedUnit = EntIndexToHScript( keys.entindex_killed )
  -- The Killing entity
  local killerEntity = nil

  if keys.entindex_attacker ~= nil then
    killerEntity = EntIndexToHScript( keys.entindex_attacker )
  end

  if killedUnit:IsRealHero() then
    local killerTeam = killerEntity:GetTeam()
    DebugPrint("KILLED, KILLER: " .. killedUnit:GetName() .. " -- " .. killerEntity:GetName())
    if END_GAME_ON_KILLS and GetTeamHeroKills(killerTeam) >= KILLS_TO_END_GAME_FOR_TEAM then
      GameRules:SetSafeToLeave( true )
      GameRules:SetGameWinner( killerTeam )
    end

    --PlayerResource:GetTeamKills
    if SHOW_KILLS_ON_TOPBAR then
      GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, GetTeamHeroKills(DOTA_TEAM_BADGUYS) )
      GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, GetTeamHeroKills(DOTA_TEAM_GOODGUYS) )
    end

    -- if not Duels.currentDuel and killedUnit:GetRespawnsDisabled() then
    --   killedUnit:SetRespawnsDisabled(false)
    --   if not killedUnit:IsReincarnating() then
    --     killedUnit:SetTimeUntilRespawn(5)
    --   end
    -- end

    if killerTeam ~= DOTA_TEAM_BADGUYS and killerTeam ~= DOTA_TEAM_GOODGUYS and not killedUnit:IsReincarnating() then
      -- killedUnit:SetTimeUntilRespawn(10)
    else
      keys.killer = killerEntity
      keys.killed = killedUnit
      GameMode:OnHeroKilled(keys)
    end
  end

  GameMode._reentrantCheck = true
  GameMode:OnEntityKilled( keys )
  GameMode._reentrantCheck = false
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:_OnConnectFull(keys)
  if GameMode._reentrantCheck then
    return
  end

  GameMode:_CaptureGameMode()

  local entIndex = keys.index+1
  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)

  local userID = keys.userid

  self.vUserIds = self.vUserIds or {}
  self.vUserIds[userID] = ply

  GameMode._reentrantCheck = true
  GameMode:OnConnectFull( keys )
  GameMode._reentrantCheck = false
end
