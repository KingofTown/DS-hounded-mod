STRINGS = GLOBAL.STRINGS

local defaultPhrase = STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "WTF WAS THAT!!"

local Vector3 = GLOBAL.Vector3



local MOB_LIST =
{
    "merm",
    "hound",
    "tallbird",
    "pigman", -- add tag "guard" to make guardian pigman
    "spider" -- add spider warriors and probably more
}

local function getRandomMob()
    -- pick a number from 0 to MOB_LIST.getn
    count = 0
    for k in pairs(MOB_LIST) do
        count = count + 1
    end
    
    mob = MOB_LIST[math.random(1,count-1)]

    return mob
end



local function updateWarningString(prefab)
    print("Updating warning strings for: " .. prefab)
    if prefab == nil then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = defaultPhrase
    elseif prefab == "merm" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Oh god, it smells like rotting fish..."
    elseif prefab == "spider" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Sounds like a million tiny legs"
    elseif prefab == "tallbird" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Sounds like a murder...of tall birds"
    elseif prefab == "pigman" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Was that an oink?"
    else
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = defaultPhrase
    end
    
end

--local currentPrefab = getRandomMob()
local currentPrefab = "pigman"
updateWarningString(currentPrefab)

local function transformThings(inst)

    print("Searching for pigs")
    local playPos = Vector3(GLOBAL.GetPlayer().Transform:GetWorldPosition())
    local naughtyPigs = TheSim:FindEntities(playPos.x,playPos.y,playPos.z, 80, {"SpecialPigman"})
    print("Found " .. #naughtyPigs .. " special pigs around me")
    for k,v in pairs(naughtyPigs) do 
        --print("Pushing event for " .. tostring(v))
        local pigPos = Vector3(v.Transform:GetWorldPosition())
        -- Get the pig's position
        
        -- Strike lightning on pig (make it not burnable first)
        v:RemoveComponent("burnable")
        GLOBAL.GetSeasonManager():DoLightningStrike(pigPos)
        -- If we add it too fast, they will be on fire but not showing fire...
        v:DoTaskInTime(1, function(inst) print("......") inst:AddComponent("burnable") end)
        
        --GLOBAL.GetSeasonManager():DoMediumLightning()
        -- tranform
        v:PushEvent("transform_special_pigs",{inst=v})
        
    end
    
end


local function releaseRandomMobs(self)

	local function ReleasePrefab(dt)
        
		local pt = Vector3(GLOBAL.GetPlayer().Transform:GetWorldPosition())
		local spawn_pt = self:GetSpawnPoint(pt)

        if currentPrefab == nil then
            -- Next wave hasn't been planned
            prefab = getRandomMob()
        else 
            prefab = currentPrefab
        end
        
        print("HERE COMES A " .. prefab)
		
		if spawn_pt then
            -- TODO: Add a counter to the different mob types to modify how many come
			self.houndstorelease = self.houndstorelease - 1
            
            -- Because I keep spawning them in the console...
            if self.houndstorelease <= 0 then 
                self.houndstorelease = 0
            end
            

			
			local day = GLOBAL.GetClock().numcycles
		
			local theMob = GLOBAL.SpawnPrefab(prefab)
			if theMob then
            
                -- If spiders...give a chance at warrior spiders
                if theMob == "spider" and math.random() < .5 then
                    theMob = "spider_warrior"
                end

                theMob:RemoveComponent("homeseeker") 
                
                -- Can't remove 'sleeper' tag as it causes the entity to throw errors. Just
                -- override the ShouldSleep functions
                if theMob.components.sleeper ~= nil then
                    local sleepFcn = function(self,inst)
                        -- Super hack! Just keep suggesting this mob attacks the player.
                        theMob.components.combat:SuggestTarget(GLOBAL.GetPlayer())
                        return false
                    end
                    local wakeFcn = function(self,inst)
                        return true
                    end
                    theMob.components.sleeper:SetSleepTest(sleepFcn)
                    theMob.components.sleeper:SetWakeTest(wakeFcn)
                end
                
                -- Pigs might transform!
                if theMob.components.werebeast ~= nil then
                    theMob:AddTag("SpecialPigman")
                end
                
                
				
				-- Override the default KeepTarget for this prefab so it never stops
								
				--local function keepTargetOverride(inst, target)
				--	return inst.components.combat:CanTarget(target)
				--end
				
				--theMob.components.combat:SetKeepTargetFunction(keepTargetOverride)
				
				theMob.Physics:Teleport(spawn_pt:Get())
				theMob:FacePoint(pt)
				theMob.components.combat:SuggestTarget(GLOBAL.GetPlayer())
                
                if self.houndstorelease == 0 and theMob:HasTag("SpecialPigman") then
                    self.inst:DoTaskInTime(5, function(inst) transformThings() end)
                end
			end
		end
		
	end
	self.ReleaseHound = ReleasePrefab
	

    local origPlanFunction = self.PlanNextHoundAttack
    local function planNextAttack()
        origPlanFunction(self)
        -- Set the next type of mob
        print("Planning next attack...")
        currentPrefab = getRandomMob()
        print("Picked " .. currentPrefab .. " as next mob")
        updateWarningString(currentPrefab)
    end
    
    self.PlanNextHoundAttack = planNextAttack
    
    self.PrintCurrentMob = function()
        if currentPrefab ~= nil then
            print(currentPrefab)
        else
            print("none")
        end
    end

end
AddComponentPostInit("hounded",releaseRandomMobs)


local function transformFcn(inst)
    if inst:HasTag("SpecialPigman") then
        inst.components.werebeast:SetWere()
        
        -- Don't transform back in the day or night. Were here to stay!
        -- inst:RemoveAllEventCallbacks() -- hmm...this will get rid of important ones...
        
        -- Don't sleep!
        inst.components.sleeper:SetSleepTest(sleepFcn)
        inst.components.sleeper:SetWakeTest(wakeFcn)
        
        -- Keep going for the player
        inst.components.combat:SuggestTarget(GLOBAL.GetPlayer())
    end
end

-------------------------------------------------
-- PIGMAN override to add listen event
-------------------------------------------------
local function AddPigmanTransformEvent(inst)
    inst:ListenForEvent("transform_special_pigs",transformFcn)
end

AddPrefabPostInit("pigman",AddPigmanTransformEvent)