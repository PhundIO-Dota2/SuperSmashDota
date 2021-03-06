puck_special_top = class({})



function puck_special_top:IsHiddenAbilityCastable()
  return true
end

function puck_special_top:OnAbilityPhaseStart()
  if not self:GetCaster():CanCast(self) then return false end
  if not self:IsCooldownReady() then return false end
   
  return true
end

function puck_special_top:OnSpellStart()
  local caster = self:GetCaster()
  StoreSpecialKeyValues(self)
  local ability = self
  if not ability.orb then

    caster:EmitSound("Hero_Puck.Illusory_Orb")
    

    local projectileTable = 
    { 
      vDirection = ability.mouseVector,
      hCaster = caster,
      flSpeed = ability.projectile_speed,
      flRadius = ability.radius,
      flDuration = 1.25,
      sEffectName = "particles/puck/puck_illusory_orb.vpcf",
      PlatformBehavior = PROJECTILES_NOTHING,
      OnPlatformHit = function(projectile,unit)
      end,
      UnitBehavior = PROJECTILES_NOTHING,
      UnitTest = function(projectile, unit) return unit:GetUnitName() ~= "npc_dummy_unit" and unit:GetTeamNumber() ~= caster:GetTeamNumber() end,
      OnUnitHit = function(projectile,unit)
        local damageTable = {
          victim = unit,
          attacker = caster,
          damage =  ability.damage + RandomInt(0,ability.damage_offset),
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = ability,
        }
        ApplyDamage(damageTable)
      end,
      OnFinish = function(projectile)
        caster:StopSound("Hero_Puck.Illusory_Orb")
        
        ability:StartCooldown(ability:GetSpecialValueFor("cooldown"))
        CustomGameEventManager:Send_ServerToPlayer(ability:GetCaster():GetPlayerOwner(),"show_cooldown",{sAbilityName = ability:GetAbilityName(),ability = ability:entindex(), nCooldown = ability:GetCooldown(1)})
        --Timers:CreateTimer(1,function()
        -- ParticleManager:DestroyParticle(particle,false)
        -- ParticleManager:ReleaseParticleIndex(particle)
        --end)
        ability.orb = nil
      end,
      
    }
    ability.orb = Physics2D:CreateLinearProjectile(projectileTable)
  else
    if caster.jumps > 2 then return end
    caster.jumps = 3
    caster:StopSound("Hero_Puck.Illusory_Orb")
    caster:EmitSound("Hero_Puck.EtherealJaunt")
    caster:SetAbsOrigin(self.orb.location)

    local units = FindUnitsInRadius(caster:GetTeam(), self.orb.location, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
    units = FilterUnitsBasedOnHeight(units,self.orb.location,self.radius)
    for k,v in pairs(units) do
      local damageTable = {
        victim = v,
        attacker = caster,
        damage = (self.damage + RandomInt(0,selfdamage_offset))/2,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
      } 
      ApplyDamage(damageTable)
    end

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_illusory_orb_blink_out.vpcf", PATTACH_POINT, caster)
    ParticleManager:SetParticleControl(particle,0,self.orb.location)

    Timers:CreateTimer(self:GetCastPoint(),function()
      ParticleManager:DestroyParticle(particle,true)
      ParticleManager:ReleaseParticleIndex(particle)
    end)
    
    Physics2D:DestroyProjectile(ability.orb)
    self:StartCooldown(self:GetSpecialValueFor("cooldown"))


  --[[
    local projectile = {
      EffectName = "particles/puck/puck_illusory_orb.vpcf",
      vSpawnOrigin = caster:GetAbsOrigin(),
      fDistance = self:GetSpecialValueFor("distance"),
      fStartRadius = 200,
      fEndRadius = 200,
      Source = caster,
      fExpireTime = self:GetSpecialValueFor("duration"),
      vVelocity = self.mouseVector * (self:GetSpecialValueFor("distance")/self:GetSpecialValueFor("duration")), -- RandomVector(1000),
      UnitBehavior = PROJECTILES_NOTHING ,
      bMultipleHits = false,
      bIgnoreSource = true,
      WallBehavior = PROJECTILES_NOTHING,
      GroundBehavior = PROJECTILES_NOTHING,
      fGroundOffset = 0,
      nChangeMax = 1,
      bRecreateOnChange = true,
      bZCheck = true,
      bGroundLock = false,
      draw = IsInToolsMode(),--             draw = {alpha=1, color=Vector(200,0,0)},
      
      UnitTest = function(self, unit) return unit:GetUnitName() ~= "npc_dummy_unit" and unit:GetTeamNumber() ~= caster:GetTeamNumber() end,
      OnUnitHit = function(self, unit) 
        local damageTable = {
          victim = unit,
          attacker = caster,
          damage = caster:FindAbilityByName("puck_special_top"):GetSpecialValueFor("damage") + RandomInt(0,caster:FindAbilityByName("puck_special_top"):GetSpecialValueFor("damage_offset")),
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = caster:FindAbilityByName("puck_special_top"),
        }
      end,
      OnFinish = function(self,unit)
      caster:StopSound("Hero_Puck.Illusory_Orb")
        ability.orb = nil
        ability:StartCooldown(caster:FindAbilityByName("puck_special_top"):GetSpecialValueFor("cooldown"))
        CustomGameEventManager:Send_ServerToPlayer(ability:GetCaster():GetPlayerOwner(),"show_cooldown",{sAbilityName = ability:GetAbilityName(),ability = ability:entindex(), nCooldown = ability:GetCooldown(1)})
      end,
    }
    ability.orb = Projectiles:CreateProjectile(projectile)
  else
    caster:StopSound("Hero_Puck.Illusory_Orb")
    caster:EmitSound("Hero_Puck.EtherealJaunt")
    caster:SetAbsOrigin(self.orb:GetPosition())

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
    units = FilterUnitsBasedOnHeight(units,caster:GetAbsOrigin(),radius)
    for k,v in pairs(units) do
      local damageTable = {
        victim = v,
        attacker = caster,
        damage = self:GetSpecialValueFor("damage")/2 + RandomInt(0,self:GetSpecialValueFor("damage_offset"))/2,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
      } 
      ApplyDamage(damageTable)
    end

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_illusory_orb_blink_out.vpcf", PATTACH_POINT, caster)
    ParticleManager:SetParticleControl(particle,0,caster:GetAbsOrigin())

    Timers:CreateTimer(self:GetCastPoint(),function()
      ParticleManager:DestroyParticle(particle,true)
      ParticleManager:ReleaseParticleIndex(particle)
    end)
    
    ability.orb:Destroy()
    ability.orb = nil
    self:StartCooldown(self:GetSpecialValueFor("cooldown"))]] 
  end
end

puck_special_bottom = class({})

function puck_special_bottom:OnAbilityPhaseStart()
  if not self:GetCaster():CanCast(self) then return false end
  if not self:IsCooldownReady() then return false end 
  return true
end

function puck_special_bottom:IsHiddenAbilityCastable()
  return true
end
function puck_special_bottom:GetChannelTime()
  return self:GetSpecialValueFor("duration")
end

function puck_special_bottom:OnSpellStart()
  local caster = self:GetCaster()
  caster:EmitSound("Hero_Puck.Phase_Shift")
  caster:RemoveModifierByName("modifier_left")
  caster:RemoveModifierByName("modifier_right")
  caster:RemoveModifierByName("modifier_jump")
  caster:AddNewModifier(caster,self,"modifier_puck_phase_shift",{duration = self:GetChannelTime()})
  caster:AddNewModifier(caster,self,"modifier_smash_root",{duration = self:GetChannelTime()})
end
function puck_special_bottom:OnChannelFinish(bInterrupted)
  self.oldLoc =  self:GetCaster():GetAbsOrigin()
  self:GetCaster():RemoveModifierByName("modifier_puck_phase_shift")
  self:GetCaster():RemoveModifierByName("modifier_smash_root")
  self:GetCaster():SetAbsOrigin(self.oldLoc)
  self:GetCaster():InterruptChannel()
end

puck_special_side = class({})

function puck_special_side:IsHiddenAbilityCastable()
  return true
end
function puck_special_side:OnAbilityPhaseStart()
  if not self:GetCaster():CanCast(self) then return false end
  if not self:IsCooldownReady() then return false end 
  return true
end
function puck_special_side:OnSpellStart()
  local caster = self:GetCaster()

  caster:EmitSound("Hero_Puck.Waning_Rift")
  local radius = self:GetSpecialValueFor("radius")
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_waning_rift.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(particle,0,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+100))
    ParticleManager:SetParticleControl(particle,1,Vector(self:GetSpecialValueFor("radius") ,self:GetSpecialValueFor("radius"),self:GetSpecialValueFor("radius")))

    Timers:CreateTimer(self:GetCastPoint(),function()
      ParticleManager:DestroyParticle(particle,true)
      ParticleManager:ReleaseParticleIndex(particle)
    end)


  local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
  units = FilterUnitsBasedOnHeight(units,caster:GetAbsOrigin(),radius)
  for k,v in pairs(units) do
    v:AddNewModifier(caster,self,"modifier_smash_silence",{duration = self:GetSpecialValueFor("duration")})
    local damageTable = {
      victim = v,
      attacker = caster,
      damage = self:GetSpecialValueFor("damage") + RandomInt(0,self:GetSpecialValueFor("damage_offset")),
      damage_type = DAMAGE_TYPE_MAGICAL,
      ability = self
    } 
    ApplyDamage(damageTable)
  end
end

--[[puck_special_side = class({})

function puck_special_side:OnAbilityPhaseStart()
  if not self:GetCaster():CanCast(self) then return false end
  if not self:IsCooldownReady() then return false end 
  return true
end
function puck_special_side:OnSpellStart()
  local caster = self:GetCaster()
  caster:EmitSound("Hero_Puck.Attack")
    local projectile = {
      --EffectName = "particles/test_particle/ranged_tower_good.vpcf",
      EffectName = "particles/puck_side/puck_side.vpcf",
      --EffectName = "particles/units/heroes/hero_puck/puck_illusory_orb.vpcf",
      --EeffectName = "",
      --vSpawnOrigin = caster:GetAbsOrigin(),
      vSpawnOrigin = {unit=caster, attach="attach_attack1"},
      fDistance = self:GetSpecialValueFor("range"),
      fStartRadius = self:GetSpecialValueFor("radius"),
      fEndRadius = self:GetSpecialValueFor("radius"),
      Source = caster,
      fExpireTime = self:GetSpecialValueFor("range")/self:GetSpecialValueFor("projectile_speed"),
      vVelocity = self.mouseVector * self:GetSpecialValueFor("projectile_speed"), -- RandomVector(1000),
      UnitBehavior = PROJECTILES_DESTROY ,
      bMultipleHits = false,
      bIgnoreSource = true,
      TreeBehavior = PROJECTILES_NOTHING,
      bCutTrees = false,
      bTreeFullCollision = false,
      WallBehavior = PROJECTILES_BOUNCE,
      GroundBehavior = PROJECTILES_BOUNCE,
      fGroundOffset = 0,
      nChangeMax = 1,
      bRecreateOnChange = true,
      bZCheck = true,
      bGroundLock = false,
      bProvidesVision = true,
      iVisionRadius = self:GetSpecialValueFor("radius"),
      iVisionTeamNumber = caster:GetTeam(),
      bFlyingVision = false,
      fVisionTickTime = .1,
      fVisionLingerDuration = 1,
      draw = false,--             draw = {alpha=1, color=Vector(200,0,0)},
      --iPositionCP = 0,
      --iVelocityCP = 1,
      --ControlPoints = {[5]=Vector(100,0,0), [10]=Vector(0,0,1)},
      --ControlPointForwards = {[4]=hero:GetForwardVector() * -1},
      --ControlPointOrientations = {[1]={hero:GetForwardVector() * -1, hero:GetForwardVector() * -1, hero:GetForwardVector() * -1}},
      --[[ControlPointEntityAttaches = {[0]={
        unit = hero,
        pattach = PATTACH_ABSORIGIN_FOLLOW,
        attachPoint = "attach_attack1", -- nil
        origin = Vector(0,0,0)
      }},
      --fRehitDelay = .3,
      --fChangeDelay = 1,
      --fRadiusStep = 10,
      --bUseFindUnitsInRadius = false,

      UnitTest = function(self, unit) return unit:GetUnitName() ~= "npc_dummy_unit" and unit:GetTeamNumber() ~= caster:GetTeamNumber() end,
      OnUnitHit = function(self, unit)
        caster:EmitSound("Hero_Puck.ProjectileImpact")
        local damageTable = {
          victim = unit,
          attacker = caster,
          damage = caster:FindAbilityByName("puck_special_side"):GetSpecialValueFor("damage") + RandomInt(0,caster:FindAbilityByName("puck_special_side"):GetSpecialValueFor("damage_offset")),
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = caster:FindAbilityByName("puck_special_side"),
        }
        ApplyDamage(damageTable)
      end,
      OnGroundHit = function(self, unit)
        caster:EmitSound("Hero_Puck.ProjectileImpact")
      end,
    }
    Projectiles:CreateProjectile(projectile)

end]]