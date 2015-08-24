local Vector3 = GLOBAL.Vector3

-- Table is as follows
-- enabled: is this a valid prefab to use (DLC restrictions or config file)
-- RoG: Is this a Reign of Giants only mob? 
-- prefab: prefab name
-- mobMult: multiplier compared to normal hound values
-- timeMult: how fast these come out compared to normal hounds. 0.5 is twice as fast. 2 is half speed.
local MOB_LIST =
{
    [1] = {enabled=true,RoG=false,prefab="hound",mobMult=1,timeMult=1},
    [2] = {enabled=true,RoG=false,prefab="merm",mobMult=1,timeMult=1},
    [3] = {enabled=true,RoG=false,prefab="tallbird",mobMult=1,timeMult=1.2},
    [4] = {enabled=true,RoG=false,prefab="pigman",mobMult=1,timeMult=1},
    [5] = {enabled=true,RoG=false,prefab="spider",mobMult=2.5,timeMult=.5},
    [6] = {enabled=true,RoG=false,prefab="killerbee",mobMult=3,timeMult=.25},
    [7] = {enabled=true,RoG=false,prefab="mosquito",mobMult=3,timeMult=.25},
    [8] = {enabled=true,RoG=true,prefab="lightninggoat",mobMult=1,timeMult=1},
}

-- Check the config file and the DLC to disable some of the mobs
local function disableMobs()
    local dlcEnabled = GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)
    
    -- TODO: Add config file
    for k,v in pairs(MOB_LIST) do
        if not dlcEnabled and v.RoG then
            print("Disabling RoG mob: " .. v.prefab)
            MOB_LIST[k].enabled = false
        end
    end
end
disableMobs()
---------------------------------------------------------------------
-- Update strings
STRINGS = GLOBAL.STRINGS
local defaultPhrase = STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "WTF WAS THAT!!"
local function updateWarningString(index)
    prefab = MOB_LIST[index].prefab
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
    elseif prefab == "killerbee" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Buzzzzzzzz? Buzzzzzzzzzzzz!"
    else
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = defaultPhrase
    end
end
---------------------------------------------------------------------

local function getRandomMob()
    -- Generate a shuffled list from 1 to #MOB_LIST
    local t={}
    for i=1,#MOB_LIST do
        t[i]=i
    end
    
    for i = 1, #MOB_LIST do
        local j=math.random(i,#MOB_LIST)
        t[i],t[j]=t[j],t[i]
    end
    
    -- Return the first one that is enabled
    for k,v in pairs(t) do
        if MOB_LIST[v].enabled then
            return MOB_LIST[v].prefab, v
        end
    end

    -- If we are here...there is NOTHING in the list enabled.
    -- This is strange. Just return hound I guess (even though
    -- hound is in the list and the user disabled it...)
    return MOB_LIST[1].prefab,1

    --local index = math.random(1,#MOB_LIST)
    --mob = MOB_LIST[index]  
    --return mob.prefab, index
end





--local currentPrefab = getRandomMob()
local currentPrefab = "pigman"
local currentIndex = 4
updateWarningString(currentIndex)

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

        if currentIndex == nil then
            -- Next wave hasn't been planned
            prefab,index = getRandomMob()
        else 
            prefab = MOB_LIST[currentIndex].prefab
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
        currentPrefab, currentIndex = getRandomMob()
        print("Picked " .. currentPrefab .. " as next mob")
        self.houndstorelease = math.floor(self.houndstorelease*MOB_LIST[currentIndex].mobMult)
        print("Number scheduled to be released: " .. self.houndstorelease)
        updateWarningString(currentIndex)
    end
    
    self.PlanNextHoundAttack = planNextAttack
    
    local origOnUpdate = self.OnUpdate
    local function newOnUpdate(self,dt)
        origOnUpdate(self,dt)
        -- Modify the next release time based on the current prefab
        if self.timetoattack <= 0 then
            if MOB_LIST[currentIndex].timeMult ~= 1 then
                local orig = self.timetonexthound
                self.timetonexthound = self.timetonexthound * MOB_LIST[currentIndex].timeMult
            end
        end
    end
    self.OnUpdate = newOnUpdate

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