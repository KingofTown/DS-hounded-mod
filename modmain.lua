local Vector3 = GLOBAL.Vector3
local dlcEnabled = GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)
local SEASONS = GLOBAL.SEASONS

--[[ Table is as follows:
        enabled: is this a valid prefab to use (DLC restrictions or config file)
        prefab: prefab name
        brain: brain name. If a mob has this defined, will add a new PriorityNode to the brain to attack player.
               (leave this out if don't want to override brain function at all)
        RoG: Is this a Reign of Giants only mob? (Toggles enabled if DLC is not enabled). If not added, assumed to be false.
        CaveState: "open", "used", nil - This mob will only spawn when the cavestate condition is met. If not defined, ignore
        Season: restricts the season(s) this can come. If not defined...can come any season. 
        mobMult: multiplier compared to normal hound values (how many to release)
        timeMult: how fast these come out compared to normal hounds. 0.5 is twice as fast. 2 is half speed.
        
        TODO: Have health defined here? It's a bit much fighing one of these sometimes...multiple seems impossible
        
--]]

local MOB_LIST =
{
    [1]  = {enabled=true,prefab="hound",mobMult=1,timeMult=1},
    [2]  = {enabled=true,prefab="merm",brain="mermbrain",mobMult=1,timeMult=1},
    [3]  = {enabled=true,prefab="tallbird",brain="tallbirdbrain",mobMult=.75,timeMult=1.2},
    [4]  = {enabled=true,prefab="pigman",brain="pigbrain",mobMult=1,timeMult=1},
    [5]  = {enabled=true,prefab="spider",brain="spiderbrain",mobMult=1.7,timeMult=.5},
    [6]  = {enabled=true,prefab="killerbee",brain="killerbeebrain",mobMult=2.2,timeMult=.3},
    [7]  = {enabled=true,prefab="mosquito",brain="mosquitobrain",mobMult=2.5,timeMult=.15}, 
    [8]  = {enabled=true,prefab="lightninggoat",brain="lightninggoatbrain",RoG=true,mobMult=.75,timeMult=1.25}, 
    [9]  = {enabled=true,prefab="beefalo",brain="beefalobrain",mobMult=.75,timeMult=1.5},
    [10] = {enabled=true,prefab="bat",brain="batbrain",CaveState="open",mobMult=1,timeMult=1},
    [11] = {enabled=false,prefab="rook",brain="rookbrain",mobMult=1,timeMult=1}, -- These dudes don't work too well
    [12] = {enabled=true,prefab="knight",brain="knightbrain",mobMult=1,timeMult=1.5}, 
    [13] = {enabled=false,prefab="mossling",brain="mosslingbrain",RoG=true,Season={SEASONS.SPRING},mobMult=1,timeMult=1}, -- Needs work. They wont get enraged.
}

-- Check the config file and the DLC to disable some of the mobs
local function disableMobs()
    
    for k,v in pairs(MOB_LIST) do
        if not dlcEnabled and v.RoG then
            print("Disabling RoG mob: " .. v.prefab)
            MOB_LIST[k].enabled = false
        end
        -- Get the config data for it
        local enabled = GetModConfigData(v.prefab)
        if enabled ~= nil and enabled == "off" then
            print("Disabling " .. v.prefab .. " due to config setting")
            MOB_LIST[k].enabled = false
        end
        
    end
end
disableMobs()


--[[ -----------------------------------------------------
  Update strings for warnings. 
  TODO: Add updates for all characters
--]] -----------------------------------------------------
STRINGS = GLOBAL.STRINGS
local defaultPhrase = STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "WTF WAS THAT!!"

local warningCount = 1

-- Dumb function to get a dumb string for a dumb idea :P
local function getDumbString(num)
    if num == 1 then return "ONE!"
    elseif num == 2 then return "TWO!"
    elseif num == 3 then return "THREE!"
    elseif num == 4 then return "FOUR!"
    else return "TOO MANY!" end
end


-- This is called after each verbal warning. If new strings are wanted,
-- just check the warningCount.
local function updateWarningString(index)

    if GLOBAL.GetPlayer() == nil then
        return 
    end
    
    character = string.upper(GLOBAL.GetPlayer().prefab)
    if character == nil or character == "WILSON" then
        character = "GENERIC"
    end
    
    prefab = MOB_LIST[index].prefab
    if prefab == nil then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = defaultPhrase
    elseif prefab == "merm" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Oh god, it smells like rotting fish"
    elseif prefab == "spider" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Sounds like a million tiny legs"
    elseif prefab == "tallbird" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Sounds like a murder...of tall birds"
    elseif prefab == "pigman" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Was that an oink?"
    elseif prefab == "killerbee" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Beeeeeeeeeeeeeeeeees!"
    elseif prefab == "mosquito" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "I hear a million teeny tiny vampires"
    elseif prefab == "lightninggoat" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Those giant dark clouds look ominous"
    elseif prefab == "beefalo" then
        if warningCount == 1 then
            STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Earthquake?!?"
        else
            STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Wait, no...STAMPEDE!!!"
        end
    elseif prefab == "bat" then
        -- TODO: Increment the count each warning lol
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = getDumbString(warningCount) .. " Ah ah ah!"
    elseif prefab == "knight" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Incomming old people music...and horses?"
    else
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = defaultPhrase
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
        local pickThisMob = true
        if MOB_LIST[v].enabled then
            -- Check the various conditions
            if MOB_LIST[v].CaveState ~= nil then
                caveOpen = GLOBAL.ProfileStatsGet("cave_entrance_opened")
                caveUsed = GLOBAL.ProfileStatsGet("cave_entrance_used")
                if MOB_LIST[v].CaveState == "open" and caveOpen ~= nil and caveOpen == true then
                    print("Cave open. Returning " .. tostring(MOB_LIST[v].prefab))
                    pickThisMob = true
                elseif MOB_LIST[v].CaveState == "used" and caveUsed ~= nil and caveUsed == true then
                    print("Cave used. Returning " .. tostring(MOB_LIST[v].prefab))
                    pickThisMob = true
                else
                    print("Skipping " .. tostring(MOB_LIST[v].prefab) .. " as mob because cavestate not met")
                    if caveOpen ~= nil then
                        print("CaveOpen: " .. tostring(caveOpen))
                    end
                    if caveUsed ~= nil then
                        print("CaveUsed: " .. tostring(caveUsed))
                    end    
                    
                    pickThisMob = false
                end
            end
            
            -- Check for season restrictions
            if MOB_LIST[v].Season ~= nil then
                for key,season in pairs(MOB_LIST[v].Season) do
                    if GLOBAL.GetSeasonManager().current_season ~= season then
                        pickThisMob = false
                    else
                        pickThisMob = true
                        break
                    end
                end
                
                if not pickThisMob then
                    print("Skipping " .. tostring(MOB_LIST[v].prefab) .. " as mob because season not met")
                end
            end
			
			-- Don't do spiders if the player is a 'spiderwhisperer' (webber)
			-- Note, these spiders won't follow the spiderhat like normal ones.
			if MOB_LIST[v].prefab == "spider" then
				if GLOBAL.GetPlayer() and GLOBAL.GetPlayer():HasTag("spiderwhisperer") then
					print("Not picking spiders...the player is a spiderwhisperer!")
					pickThisMob = false
				end
			end
            
            -- If this is still true, return this selection 
            if pickThisMob then 
                return v 
            end
        end
    end

    -- If we are here...there is NOTHING in the list enabled and valid.
    -- This is strange. Just return hound I guess (even though
    -- hound is in the list and the user disabled it...)
    print("WARNING: No possible mobs to select from! Using Hound as default")
    return 1
end



local function transformThings(inst)
    local playPos = Vector3(GLOBAL.GetPlayer().Transform:GetWorldPosition())
    local naughtyPigs = TheSim:FindEntities(playPos.x,playPos.y,playPos.z, 80, {"SpecialPigman"})
    for k,v in pairs(naughtyPigs) do 
        --print("Pushing event for " .. tostring(v))
        local pigPos = Vector3(v.Transform:GetWorldPosition())
        -- Strike lightning on pig (make it not burnable first)
        v:RemoveComponent("burnable")
        GLOBAL.GetSeasonManager():DoLightningStrike(pigPos)
        -- If we add it too fast, they will be on fire but not showing fire...
        v:DoTaskInTime(1, function(inst) inst:AddComponent("burnable") end)
        
        --GLOBAL.GetSeasonManager():DoMediumLightning()
        -- tranform
        v:PushEvent("transform_special_pigs",{inst=v})
    end
end


local function releaseRandomMobs(self)
    self.quakeMachine = GLOBAL.CreateEntity()
    self.quakeMachine.persists = false
    self.quakeMachine.entity:AddSoundEmitter()
    self.quakeMachine.soundIntensity = 0.01
    self.currentIndex = nil
    
    -------------------------------------------------------------
    -- I guess we have to store these mobs that we can tag them onLoad
    self.currentMobs = {}
    self.numMobsSpawned = 0

    self.AddMob = function(self,mob)
        if self.currentMobs[mob] == nil and mob then
            self.currentMobs[mob] = true
            self.numMobsSpawned = self.numMobsSpawned + 1
            -- Listen for death events on these dudes
            mob.deathfn = function() self:RemoveMob(mob) end
            
            -- If the mob leaves, remove it from the list
            self.inst:ListenForEvent("death", mob.deathfn,mob)
            self.inst:ListenForEvent("onremove", mob.deathfn, mob )
            
            ---------------------------------------------------------------------------------
            --Add All of the stuff for this mob here so we can persist on save states----
            
            -- I've modified the mobs brains to be mindless killers with this tag
            mob:AddTag("houndedKiller")

            -- This mob has no home anymore. It's set to kill.
            if mob.components.homeseeker then
                mob:RemoveComponent("homeseeker")
            end
            
            -- Can't remove 'sleeper' tag as it causes the entity to throw errors. Just
            -- override the ShouldSleep functions
            if mob.components.sleeper ~= nil then
                local sleepFcn = function(self,inst)
                    --[[ Just keep suggesting this mob attacks the player. These are 
					     merciless killers after all.
					       "Should I sleep?"
					       "NO! Attack that guy!"
					       ...
						   "Should I sleep?"
						   "NO! Attack that guy!"
					--]]
                    mob.components.combat:SuggestTarget(GLOBAL.GetPlayer())
                    return false
                end
                local wakeFcn = function(self,inst)
                    return true
                end
                mob.components.sleeper:SetSleepTest(sleepFcn)
                mob.components.sleeper:SetWakeTest(wakeFcn)
                
            end
            
            -- Pigs might transform! Hmm, beardbunny dudes are werebeasts too
            if mob.components.werebeast ~= nil then
                mob:AddTag("SpecialPigman")
            end
            
            -- Quit trying to find a herd dumb mobs
               -- or not...some prefabs kind of assume this is set
            --if mob.components.herdmember then
            --    mob:RemoveComponent("herdmember")
            --end
            
            -- Quit trying to go home. Your home is the afterlife.
            if mob.components.knownlocations then
                mob.components.knownlocations:ForgetLocation("home")
            end
            
            -- Override the default KeepTarget for this mob.
            -- Basically, if it's currently targeting the player, continue to.
            -- If not, let it do whatever it's doing for now until it loses interest
            -- and comes back for the player.
            local origCanTarget = mob.components.combat.keeptargetfn
            local function keepTargetOverride(inst, target)
				-- TODO: Check distance of player?
                if target:HasTag("player") and inst.components.combat:CanTarget(target) then
                    return true
                else
                    return origCanTarget and origCanTarget(inst,target)
                end
            end
            mob.components.combat:SetKeepTargetFunction(keepTargetOverride)
            
            -- Set the min attack period to something...higher
            local currentAttackPeriod = mob.components.combat.min_attack_period
            mob.components.combat:SetAttackPeriod(math.max(currentAttackPeriod,3))
            mob.components.combat:SuggestTarget(GLOBAL.GetPlayer())
            
            ------------------------------------------------------------------------------
        end
    end
    
    
    self.RemoveMob = function(self,mob)
        if mob and self.currentMobs[mob] then
            self.currentMobs[mob] = nil
            self.numMobsSpawned = self.numMobsSpawned - 1
        end
    end
    -----------------------------------------------------------------
    
    -- Override the quake functions to only shake camera and play/stop the madness
    local function stampedeShake(self, duration, speed, scale)
                             -- type,duration,speed,scale,maxdist
        GLOBAL.TheCamera:Shake("FULL", duration, speed, scale, 80)
        
        -- Increase the intensity for the next call (only start the sound once)
        if not self.quakeStarted then
            self.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "earthquake")
        end
        self.SoundEmitter:SetParameter("earthquake", "intensity", self.soundIntensity)
        
    end
    self.quakeMachine.WarnQuake = stampedeShake
    
    local function endStampedeShake(self)
        self.quake = false
        self.emittingsound = false
        self.SoundEmitter:KillSound("earthquake")
        self.soundIntensity = 0.01
    end
    self.quakeMachine.EndQuake = endStampedeShake
    
    local function makeLouder(self)
        self.soundIntensity = self.soundIntensity + .04
        self.SoundEmitter:SetParameter("earthquake","intensity",self.soundIntensity)
    end
    self.quakeMachine.MakeStampedeLouder = makeLouder
    self.quakeStarted = false
    

	local function ReleasePrefab(dt)
		local pt = Vector3(GLOBAL.GetPlayer().Transform:GetWorldPosition())
		local spawn_pt = self:GetSpawnPoint(pt)

        if self.currentIndex == nil then
            -- Next wave hasn't been planned
            prefab,index = getRandomMob()
        else 
            prefab = MOB_LIST[self.currentIndex].prefab
        end
        
        --print("HERE COMES A " .. prefab)
		
		if spawn_pt then
            -- TODO: Add a counter to the different mob types to modify how many come
			self.houndstorelease = self.houndstorelease - 1
            
            -- Because I keep spawning them in the console...
            if self.houndstorelease <= 0 then 
                self.houndstorelease = 0
            end
			
			-- Increase chances of special mobs later on
			local specialMobChance = self:GetSpecialHoundChance()
            
            -- If spiders...give a chance at warrior spiders
            if prefab == "spider" and math.random() < specialMobChance then
                prefab = "spider_warrior"
            end
			

			
			-- If hounds...maybe have some fire or ice
			if prefab == "hound" then 
				if math.random() < specialMobChance then
					if GetSeasonManager():IsWinter() then
						prefab = "icehound"
					else
						prefab = "firehound"
					end
				end		
			end
			
            
            -- This is nearby lightning...not a bolt. Don't want to make
            -- them all charged (unless that would be fun...)
            if prefab == "lightninggoat" then
                GLOBAL.GetSeasonManager():DoMediumLightning()
            end
            			
			local day = GLOBAL.GetClock().numcycles
		            
			local theMob = GLOBAL.SpawnPrefab(prefab)
			if theMob then
                -- This fcn will add it to our list and put a bunch of stuff on it
                self:AddMob(theMob)

                -- This is stuff that happens when spawning (not onLoad). 

                -- Mosquitos should have a random fill rate instead of all being at 0
                if theMob:HasTag("mosquito") then
                    local fillUp = math.random(0,2)
                    for i=0,fillUp do
                        theMob:PushEvent("onattackother",{data=theMob})
                    end
                end
                
				
				-- If lightning goat...give it a chance to get struck by lightning
                local exciteGoat = function(self)
                    local goatPos = Vector3(self.Transform:GetWorldPosition())
                    GLOBAL.GetSeasonManager():DoLightningStrike(goatPos)
                end
                if theMob:HasTag("lightninggoat") and math.random() < (.9*specialMobChance) then
                    theMob:DoTaskInTime(math.max(5,10*math.random()),exciteGoat)
                end
                
				theMob.Physics:Teleport(spawn_pt:Get())
				theMob:FacePoint(pt)
                
                -- Stuff to do after all of the mobs are released
                if self.houndstorelease == 0 then
				
                    -- Transform the pigs to werepigs
                    if theMob:HasTag("SpecialPigman") and math.random() < (1.2*specialMobChance) then
                        self.inst:DoTaskInTime(5, function(inst) transformThings() end)
                    end
                    
                end
                
			end
		end
		
        self.calcNextReleaseTime = (self.houndstorelease > 0)
	end
	self.ReleaseHound = ReleasePrefab
	

    local origPlanFunction = self.PlanNextHoundAttack
    local function planNextAttack(self, prefabIndex)
        origPlanFunction(self)
        -- Set the next type of mob
        print("Planning next attack...")
        if prefabIndex and prefabIndex > 0 and prefabIndex <= #MOB_LIST then
            print("Prefab selection overwrite")
            self.currentIndex = prefabIndex
        else
            self.currentIndex = getRandomMob()
        end
        print("Picked " .. MOB_LIST[self.currentIndex].prefab .. " as next mob")
        self.houndstorelease = math.floor(self.houndstorelease*MOB_LIST[self.currentIndex].mobMult)
        print("Number scheduled to be released: " .. self.houndstorelease)
        updateWarningString(self.currentIndex)
        
        -- Reset the warning counter
        warningCount = 1
    end
    
    self.PlanNextHoundAttack = planNextAttack
    
    local origOnUpdate = self.OnUpdate
    local function newOnUpdate(self,dt)
        -- Stuff to do before calling hounded:OnUpdate
        local didWarnFirst = self.announcewarningsoundinterval
        --------------------------------------------------------
        origOnUpdate(self,dt)
        --------------------------------------------------------
        -- Stuff to do after calling hounded:OnUpdate
        local didWarnSecond = self.announcewarningsoundinterval
        -- Modify the next release time based on the current prefab
        if self.timetoattack <= 0 then
            if MOB_LIST[self.currentIndex].timeMult ~= 1 and self.calcNextReleaseTime then
                local orig = self.timetonexthound
                self.timetonexthound = self.timetonexthound * MOB_LIST[self.currentIndex].timeMult
                self.calcNextReleaseTime = false
            end
            
            if self.quakeStarted then
                self.quakeMachine:DoTaskInTime(5, function(self) self:EndQuake() end)
                self.quakeStarted = false
            end
        end
        
        -- If beefalo are coming, start the stampede effects
        if MOB_LIST[self.currentIndex].prefab == "beefalo" then
            if self.timetoattack < self.warnduration and self.timetoattack > 0 and not self.quakeStarted then

                -- This is kind of hackey...but i want the quake to INCREASE over time, not decrease. 
                -- The camerashake only has functions that decrease...
                local quakeTime = 4*(self.houndstorelease+1) + self.timetoattack                
                local interval = self.timetoattack / 2

                --self.quakeMachine:DoTaskInTime(0, function(self) self:WarnQuake(interval*2, .015, .1) end)
                self.quakeMachine:WarnQuake(interval*2,.015,.1)
                -- Camera shake decreases in intensity as it goes on...but I want it to INCREASE!!
                self.quakeMachine:DoTaskInTime(1*interval, function(self) self:WarnQuake(interval*2, .02, .1) end)
                self.quakeMachine:DoTaskInTime(2*interval, function(self) self:WarnQuake(interval*2, .025, .1) end)

                --self.quakeMachine:WarnQuake(quakeTime)
                self.quakeStarted = true
                
                -- Schedule volume increases. Want at least 10 of them
                local interval = self.timetoattack/10
                for i=1, 10 do
                    self.quakeMachine:DoTaskInTime(i*interval, function(self) self:MakeStampedeLouder() end)
                end
            end
        -- If lightning goats are coming, start some weather effects
        elseif MOB_LIST[self.currentIndex].prefab == "lightninggoat" then
            if self.timetoattack < self.warnduration and self.timetoattack > 0 and not self.inst.overcastStarted then
								
                -- We're in the warning interval. Lets make some clouds (only if it's day)
                self.inst.overcastStarted = true
                if GLOBAL.GetClock():IsDay() then
                    self.inst.startColor = GLOBAL.GetClock().currentColour
					print("Start/Clouds/End")
					print(self.inst.startColor)
					
					-- Get the curent cloud cover
					currentClouds = GLOBAL.GetSeasonManager():GetWeatherLightPercent()
					print("Current cloud cover percent: " .. currentClouds)
					
					-- The clock uses the absolute day color already. Don't need to 
					-- adjust to this. Just adjusting initially so we don't make it flash brighter, THEN
					-- get darker. Instead, start at current cloud cover and add MORE!

                    -- Make some (more) clouds! These are supposed to be ominous!
                    self.inst.endColor = GLOBAL.Point(0,0,0)
                    self.inst.endColor.x = .5*currentClouds*self.inst.startColor.x
                    self.inst.endColor.y = .5*currentClouds*self.inst.startColor.y
                    self.inst.endColor.z = .5*currentClouds*self.inst.startColor.z
					print(self.inst.endColor)
                    
                    -- Make it darker
                    GLOBAL.GetClock():LerpAmbientColour(self.inst.startColor, self.inst.endColor, self.timetoattack-8)
                    
                    local makeCloudsGoAway = function(self)
                        -- Don't fix the color if it went to dusk as that would break the color
                        if GLOBAL.GetClock():IsDay() then
                            GLOBAL.GetClock():LerpAmbientColour(self.endColor,self.startColor,3)
                        end
                        self.overcastStarted = false
                    end
                    -- When done...transition back to normal color
                    local cloudTime = 8*(self.houndstorelease+1) + self.timetoattack
                    self.inst:DoTaskInTime(cloudTime, makeCloudsGoAway)
                end
                
                -- Schedule some distant thunder
                local interval = self.timetoattack/6

                for i=1,5 do
                    self.inst:DoTaskInTime(i*interval*(math.random()+1), function(self) 
                            GLOBAL.GetPlayer().SoundEmitter:PlaySound("dontstarve/rain/thunder_far","far_thunder") 
                            GLOBAL.GetPlayer().SoundEmitter:SetParameter("far_thunder", "intensity", .02*i) end)
                            
                end
                
            end
        end
        
        -- In this case...hounded issued a verbal warning. Update the strings to next warning
        if didWarnFirst < didWarnSecond and self.timetoattack > 0 then
            warningCount = warningCount + 1
            updateWarningString(self.currentIndex)
        end
        
    end
    self.OnUpdate = newOnUpdate
    
    local origOnSave = self.OnSave
    local function newOnSave(self)
        data = origOnSave(self)
        -- If this is empty...then don't bother saving anything.
        if GLOBAL.next(data) ~= nil then
            data.currentIndex = self.currentIndex
            local mobs = {}
            for k,v in pairs(self.currentMobs) do
                saved = true
                table.insert(mobs, k.GUID)
            end
            data.mobs = mobs
            return data
        end
    end
    self.OnSave = newOnSave
    
    local origOnLoad = self.OnLoad
    local function newOnLoad(data, newEnts)
        origOnLoad(self,newEnts)
        local test = data.currentIndex
        self.currentIndex = newEnts.currentIndex or nil
        if self.currentIndex == nil then
            print("Could not load index. Planning next attack")
            self:PlanNextHoundAttack()
        end
    end
    self.OnLoad = newOnLoad
    
    self.LoadPostPass = function(self,newents,savedata)
        if savedata and savedata.mobs then
            for k,v in pairs(savedata.mobs) do
                local targ = newents[v]
                if targ then
                    self:AddMob(targ.entity)
                end
            end
        end
    end
    
    -- Helper function to start an attack.
    local function fn(self,timeToAttack)
        if self.timetoattack > 31 then
            -- Can Pass in the time if wanted...
            if timeToAttack == nil then timeToAttack = 18 end
            print("Starting hound attack in: " .. timeToAttack)
            self.timetoattack = timeToAttack
        end
    end
    self.StartAttack = fn

end
AddComponentPostInit("hounded",releaseRandomMobs)


local function transformFcn(inst)
    if inst:HasTag("SpecialPigman") then
        inst.components.werebeast:SetWere()
        
        -- Don't sleep!
        inst.components.sleeper:SetSleepTest(sleepFcn)
        inst.components.sleeper:SetWakeTest(wakeFcn)
        
        -- Keep going for the player after transform
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

--------------------------------------------------
-- Brain Modifications
--------------------------------------------------

local ipairs = GLOBAL.ipairs
local function MakeMobChasePlayer(brain)
    --[[ Make this the top of the priority node. Basically, if they have the 
         insane tag (we add it above), they will prioritize chasing and attempting 
         to kill the player before doing normal things.
    --]]

    local function KillKillDieDie(inst)
		-- Chase for 80 seconds, target distance 60
        ret = GLOBAL.ChaseAndAttack(inst,80,60)
        return ret
    end
    
    chaseAndKill = GLOBAL.WhileNode(function() return brain.inst:HasTag("houndedKiller") end, "Kill Kill", KillKillDieDie(brain.inst))
    
    -- Find the root node. Insert this WhileNode at the top.
    -- Well, we'll put it after "OnFire" (if it exists) so it will still panic if on fire
    local fireindex = 0
    for i,node in ipairs(brain.bt.root.children) do
        if node.name == "Parallel" and node.children[1].name == "OnFire" then
            fireindex = i
            break
        end
    end
       
    -- If it wasn't found, it will be 0. Thus, inserting at 1 will be the first thing
    table.insert(brain.bt.root.children, fireindex+1, chaseAndKill)
    
    -- Debug string to see that my KillKillDieDie was added
    
    --for i,node in ipairs(brain.bt.root.children) do
    --    print("\t"..node.name.." > "..(node.children and node.children[1].name or ""))
    --end
    --print("\n")
    
end

-- Insert this brain for each mob that has it defined in MOB_LIST (if DLC allows)
for k,v in pairs(MOB_LIST) do
    local skip
    if v.brain and (not dlcEnabled and v.RoG) then
        print("Skipping insert of " .. tostring(v.brain) .. " because DLC is not enabled")
        skip = true
    end
    if v.brain and not skip then
        print("Adding modified brain to " .. tostring(v.brain))
        AddBrainPostInit(v.brain,MakeMobChasePlayer)
    end
end

---------------------------------------------------------------------------
-- Generate a new special hound effect if this has never been loaded before
---------------------------------------------------------------------------
local function firstTimeLoad()
    if GLOBAL.GetWorld().components.hounded.currentIndex == nil then
        print("First time loading this mod. Generating new hound attack")   
        GLOBAL.GetWorld().components.hounded:PlanNextHoundAttack()
    else
        print("currentIndex: " .. GLOBAL.GetWorld().components.hounded.currentIndex)
    end
end
AddSimPostInit(function() firstTimeLoad() end)

