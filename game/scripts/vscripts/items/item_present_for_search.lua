LinkLuaModifier("modifier_item_present", "items/item_present_for_search.lua", LUA_MODIFIER_MOTION_NONE)
item_present_for_search = class(ItemBaseClass)

--------------------------------------------------------------------------------

function item_present_for_search:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	return behavior
end

function item_present_for_search:GetIntrinsicModifierName()
  return "modifier_item_present"
end


function item_present_for_search:GetCooldown(nLevel)
	return 0.5
end

function item_present_for_search:OnOwnerDied()
	local hCaster = self:GetCaster()
	local numberOfPresents = self:GetCurrentCharges()
	local pos = hCaster:GetAbsOrigin()
	for i  = 1,numberOfPresents do
		PhaseTwo:SpawnPresent(pos,100)
	end
	hCaster:RemoveItem(self)
end
--[[
function item_present_for_search:OnUnequip() --Does not seem to work
	local hCaster = self:GetCaster()
	local numberOfPresents = self:GetCurrentCharges()
	local pos = hCaster:GetAbsOrigin()
	for i  = 1,numberOfPresents do
		PhaseTwo:SpawnPresent(pos,100)
	end
	hCaster:RemoveItem(self)
end
]]
function item_present_for_search:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	local numberOfPresents = self:GetCurrentCharges()
	if hTarget:GetUnitLabel() == "santa_act_2_flying" then
		PhaseTwo:PresentsTurnedIn(numberOfPresents)
		hCaster:RemoveItem(self)
	end
end

modifier_item_present = class(ModifierBaseClass)
function modifier_item_present:OnCreated()
  self:SetStackCount(1)
  if IsServer() then self:StartIntervalThink(0.1) end
end

function modifier_item_present:OnIntervalThink()
  self:SetStackCount( self:GetAbility():GetCurrentCharges() )
end

function modifier_item_present:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }
  return funcs
end

function modifier_item_present:GetModifierMoveSpeedBonus_Percentage( params )
	return -5 * self:GetStackCount()
end

