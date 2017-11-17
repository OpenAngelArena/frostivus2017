local Boss = class({})

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  local Boss = Boss()
  Boss:Init(thisEntity)
end

PhaseEnums = {
	[1] = 100,
	[2] = 75,
	[3] = 50,
	[4] = 25,
}

function Boss:Init(entity)
  -- thisEntity
  self.entity = entity
  self.abilityList = {}
  self.moonrain =  self.entity:FindAbilityByName("evil_wisp_moon_rain")
  table.insert(self.abilityList, self.moonrain)
  self.moonbeam = self.entity:FindAbilityByName("evil_wisp_moon_beam")
  table.insert(self.abilityList, self.moonbeam)
  self.omni = self.entity:FindAbilityByName("evil_wisp_omni_party")
  table.insert(self.abilityList, self.omni)
  self.egg = self.entity:FindAbilityByName("evil_wisp_egg")
  table.insert(self.abilityList, self.egg)

  self.phase = 1


  Timers:CreateTimer(1, function()
    return self:Think()
  end)
end

function Boss:Think()
  if self.entity:IsNull() or not self.entity:IsAlive() then
    return
  end
  if self.entity:GetHealthPercent() < PhaseEnums[self.phase + 1] and self.phase < 3 then
    self:GoToNextPhase()
  end
  if self.moonbeam:IsFullyCastable() then
    return self:MoonBeam()
  end
  if self.moonrain:IsFullyCastable() then
    return self:MoonRain()
  end
  -- if self.omni:IsFullyCastable() then
  --   return self:OmniParty()
  -- end
  if self.egg:IsFullyCastable() and self.phase >= 3 and self.entity:GetHealthPercent() < PhaseEnums[self.phase] then
    return self:Egg()
  end
  self:Wander()
  return 1
end

function Boss:GoToNextPhase()
	self.phase = self.phase + 1
	for _, ability in ipairs(self.abilityList) do
		ability:SetLevel(self.phase)
	end
end

function Boss:Wander()
  ExecuteOrderFromTable({
    UnitIndex = self.entity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = self.entity:GetAbsOrigin() + RandomVector(600),
    Queue = 0
  })
end

function Boss:MoonBeam()
  ExecuteOrderFromTable({
  UnitIndex = self.entity:entindex(),
  OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
  AbilityIndex = self.moonbeam:entindex()
  })
  return self.moonbeam:GetCastPoint() + 0.1
end

function Boss:MoonRain()
	local target = self:NearestEnemyHeroInRange( 9999 )
	if target then
		ExecuteOrderFromTable({
			UnitIndex = self.entity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			TargetIndex = target:entindex(),
			AbilityIndex = self.moonrain:entindex()
		})
	end
  return self.moonrain:GetCastPoint() + 0.1
end

function Boss:OmniParty()
  return self.omni:GetCastPoint() + 0.1
end

function Boss:Egg()
  ExecuteOrderFromTable({
  	UnitIndex = self.entity:entindex(),
  	OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
  	AbilityIndex = self.egg:entindex()
  })
  return self.egg:GetCastPoint() + 0.1
end

function Boss:NearestEnemyHeroInRange( range )
	local flags = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
	local enemies = FindUnitsInRadius( self.entity:GetTeamNumber(), self.entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )

	local minRange = range
	local target = nil

	for _,enemy in pairs(enemies) do
		local distanceToEnemy = (self.entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
		if enemy:IsAlive() and distanceToEnemy < minRange then
			minRange = distanceToEnemy
			target = enemy
		end
	end
	return target
end
