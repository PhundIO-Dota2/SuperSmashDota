-- Originally created by Perry

--[[
    Lua tracking projectile.

    Requires a param with AT LEAST:
    - hTarget = the unit handle the projectile should fly to.
    - hCaster = the unit handle the projectile originates from.
    - hAbility = the ability handle the projectile belongs to
    - iMoveSpeed = the speed of the projectile
    - EffectName = the path to the particle
    - SoundName = The sound when the projectile hits
    - flRadius = the radius the projectile has

    - OnProjectileHitUnit = The function called when projectile hits
    - OnProjectileDestroy = The function called when the projectile gets destroyed when it didn't hit a unit

    Optional
    - bDodgeable = Does the projectile disjoint?
    - bDestroyOnDodge = Does the projectile destroy it self on disjoint?
    - flVisionRadius = the vision the projectile gives
    - flExpireTime = Time when the projectile destroys itself
    - bDestroyOnGroundHit = Destroy this when it hits ground (Very unlikely to be used)
    - flAcceleration = The rate the projectile speed changes per second
    - fMaxDistance = The maximum distance the particle is allowed to go from a projectile
    - DestructionEffectName =  The effect when destroyed
    
    These take priority over each other (Still optional, not using this looks bad)
    - vSpawnOrigin = caster:GetAbsOrigin()
    - iSourceAttachment = the attachment the projectile originates from 

    Functions:

    (projectileID = ) TrackingProjectiles:Projectile(table)
    TrackingProjectiles:DestroyProjectile(projectileID)
    TrackingProjectiles:ChangeTarget(projectileID,hTarget)
    TrackingProjectiles:ChangeSpeed(projectileID,flSpeed)
    TrackingProjectiles:ChangeAcceleration(projectileID,flAcceleration)
    TrackingProjectiles:GetProjectilePosition(projectileID)


    -- An example

    local table =
    {
        hTarget = target,
        hCaster = caster,
        hAbility = ability,
        iMoveSpeed = ability:GetSpecialValueFor("projectile_speed") or 1000,
        EffectName = "particles/units/heroes/hero_tinker/tinker_missile.vpcf",
        SoundName = "Hero_Tinker.Heat-Seeking_Missile.Impact",
        flRadius = ability:GetSpecialValueFor("radius") or 200
        OnProjectileHitUnit = function(params, projectileID) 
          local damageTable = {
            victim = params.hTarget,
            attacker = params.hCaster,
            damage =  hAbility:GetSpecialValueFor("damage"),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = hAbility,
          }
          ApplyDamage(damageTable)
        end,
        OnProjectileDestroy = function(params, projectileID) 
            local particle = ParticleManager:CreateParticle(params.DestructionEffectName, PATTACH_ABSORIGIN_FOLLOW, params.hTarget) 
            ParticleManager:SetParticleControlEnt(particle, 1, params.hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", projectileID.projectile, true)
        end,

        -- Optional, can be omitted
        bDodgeable = true,
        bDestroyOnDodge = false,
        flVisionRadius = ability:GetSpecialValueFor("radius") or 200,
        flExpireTime = ability:GetSpecialValueFor("expire_time") or 5,
        flAcceleration = 1.1
    
        -- These take priority over each other (Still optional)
        vSpawnOrigin = caster:GetAbsOrigin() or Vector(0,0,0),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
        
        
        
    }
    local projectile = TrackingProjectiles:Projectile(table)
]]



TrackingProjectiles = TrackingProjectiles or class({})
    

function TrackingProjectiles:Projectile( params )
    --PrintTable(params)
    local target = params.hTarget
    local caster = params.hCaster
    local speed = params.iMoveSpeed

    -- Reset target dodge state
    target.dodged = false

    --Set creation time in the parameters
    params.creation_time = GameRules:GetGameTime()
    
    --Fetch initial projectile location
    local projectile
    if params.vSpawnOrigin then
        projectile = params.vSpawnOrigin
    elseif params.iSourceAttachment then
        projectile = caster:GetAttachmentOrigin( params.iSourceAttachment )
    else
        projectile = caster:GetAbsOrigin()
    end
    --Make the particle
    local particle = ParticleManager:CreateParticle( params.EffectName, PATTACH_CUSTOMORIGIN, caster)
    --Source CP
    ParticleManager:SetParticleControl( particle, 0, projectile )
    --TargetCP
    ParticleManager:SetParticleControlEnt( particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true )
    --Speed CP
    ParticleManager:SetParticleControl( particle, 2, Vector( speed, 0, 0 ) )

    -- Creating a projectileID so it can be referred to later
    params.bProjectileDodged = false
    local projectileID = {projectile=projectile,particle=particle}
    TrackingProjectiles:Think(params,projectileID)
    return projectileID
end

function TrackingProjectiles:Think(params,projectileID)
    local target = params.hTarget
    local caster = params.hCaster
    local speed = params.iMoveSpeed
    local projectile = projectileID.projectile
    local particle = projectileID.particle
    local visionRadius = params.flVisionRadius or 0
    local acceleration = params.flAcceleration or 1
    acceleration = math.pow(acceleration,1/32) -- Converting it to 1/32th second
    

    Timers:CreateTimer(function()
        -- Check if the destroy function has been called
        if projectileID.destroy then
            ParticleManager:DestroyParticle( particle, false )
            ParticleManager:ReleaseParticleIndex(particle)
            return nil
        end
        -- Check if this projectile has been dodged and if it should be destroyed because of that
        if params.bDestroyOnDodge and params.bDodgeable and target.dodged then
            ParticleManager:DestroyParticle( particle, false )
            ParticleManager:ReleaseParticleIndex(particle)
            return nil
        end
        -- Check if the particle has been dodged to prevent it from firing on hit effects
        if params.bDodgeable and target.dodged then
            params.bProjectileDodged = true
        end
        -- Check if the timer for the projectile has ran out
        if params.flExpireTime and GameRules:GetGameTime() - params.creation_time > params.flExpireTime then
            ParticleManager:DestroyParticle( particle, false )
            ParticleManager:ReleaseParticleIndex(particle)
            pcall(params.OnProjectileDestroy, params, projectileID)
            return nil
        end
        -- If there is a new speed, store that
        if projectileID.newSpeed then
            speed = projectileID.flSpeed
            projectileID.flSpeed = nil
        end
        -- If there is a new acceleration, store that
        if projectileID.Acceleration then
            acceleration = projectileID.flAcceleration
            projectileID.flAcceleration = nil
        end
        -- If there is a new target, store that
        if projectileID.hTarget then
            target = projectileID.hTarget
            projectileID.hTarget = nil
        end



        --Get the target location
        local target_location = target:GetAbsOrigin()

        -- Multiply speed by acceleration
        speed = speed * acceleration

        --Move the projectile towards the target and update the position
        projectile = projectile + ( target_location - projectile ):Normalized() * speed * 1/32
        projectileID.position = projectile
        -- Add vision
        if visionRadius then
            AddFOWViewer(caster:GetTeam(),projectile,visionRadius,2/32,true)
        end

        -- Check if projectile has hit a platform
        if params.bDestroyOnGroundHit and GetGroundPosition(projectile,nil).z - 50 > projectile.z then
            -- Platform hit
            ParticleManager:DestroyParticle( particle, false )
            ParticleManager:ReleaseParticleIndex(particle)
            pcall(params.OnProjectileDestroy, params, projectileID)
            return nil
        end

        -- Check if projectile has hit a wall
        if params.bDestroyOnWallHit and Gridnav:IsWall(projectiles) then
            -- Platform hit
            ParticleManager:DestroyParticle( particle, false )
            ParticleManager:ReleaseParticleIndex(particle)
            pcall(params.OnProjectileDestroy, params, projectileID)
            return nil
        end

        --Check the distance to the target
        if ( target_location - projectile ):Length()- params.flRadius < speed * 1/32 then -- Length2D() / Length()!
            --Target has reached destination!
            TrackingProjectiles:OnProjectileHitUnit( params,projectileID )
            ParticleManager:DestroyParticle( particle, false )
            ParticleManager:ReleaseParticleIndex(particle)
            return nil
        -- Check if the target is too far
        elseif params.flMaxDistance and (target_location - projectile):Length() > params.flMaxDistance then
                ParticleManager:DestroyParticle( particle, false )
                ParticleManager:ReleaseParticleIndex(particle)
                pcall(params.OnProjectileDestroy, params, projectileID)
                return nil
        else
            return 1/32
        end
    end)
end


function TrackingProjectiles:GetProjectilePosition(projectileID)
    return projectileID.position
end

-- Use this to destroy the particle at any time you want it to
function TrackingProjectiles:DestroyProjectile(projectileID)
    projectileID.destroy = true
end

-- Function to redirect to a new target
function TrackingProjectiles:ChangeTarget(projectileID,hTarget)
    projectileID.hTarget = hTarget
end
-- Function to update the speed
function TrackingProjectiles:ChangeSpeed(projectileID,flSpeed)
    projectileID.flSpeed = flSpeed
end
-- Function to update the acceleration
function TrackingProjectiles:ChangeAcceleration(projectileID,flAcceleration)
    projectileID.flAcceleration = flAcceleration
end
--Called when the projectile hits the target, params contains the params of the projectile plus a creation_time field.
function TrackingProjectiles:OnProjectileHitUnit( params,projectileID )
    --[[print( params.hCaster:GetUnitName() .. '\'s particle hit ' .. params.hTarget:GetUnitName() .. ' after ' ..
        ( GameRules:GetGameTime() - params.creation_time ) .. ' seconds.' )]]
    if not params.bProjectileDodged then
        pcall(params.OnProjectileHitUnit, params, projectileID)
    else
        pcall(params.OnProjectileDodge, params, projectileID)
    end
end

-- Based on the hooking done in statcollection.
-- This makes sure that when a projectile is dodgeable and the ProjectileManager.ProjectileDodge function gets called you dodge the projectile.
-- Not sure if this makes these projectiles dodgeable with the default spells
function TrackingProjectiles:hookFunctions()
    local this = self
    
    -- ProjectileManager:ProjectileDodge(hUnit)
    local oldProjectileDodge = ProjectileManager.ProjectileDodge
    ProjectileManager.ProjectileDodge = function(projectileManager,unit)
        -- Set the unit do be dodging
        if unit then
            unit.dodged = true
        end
        -- Run the real function for other projectiles
        oldProjectileDodge(projectileManager,unit)
    end
end
    
function TrackingProjectiles:init()
    self:hookFunctions()    
end

TrackingProjectiles:init()