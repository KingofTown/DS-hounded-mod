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
        damageMult: how much damage it does compared to normal mob
        healthMult: how much health it has compared to its normal self
		dropMult: Modify the odds to drop something. This reduces every item in the drop table by this percent.
        
        TODO: Have health defined here? It's a bit much fighing one of these sometimes...multiple seems impossible
        
--]]

local MOB_LIST =
{
    [1]  = {enabled=true,prefab="hound",mobMult=1,timeMult=1},
    [2]  = {enabled=true,prefab="merm",brain="mermbrain",mobMult=1,timeMult=1},
    [3]  = {enabled=true,prefab="tallbird",brain="tallbirdbrain",mobMult=.75,timeMult=1.2},
    [4]  = {enabled=true,prefab="pigman",brain="pigbrain",mobMult=1,timeMult=1},
    [5]  = {enabled=true,prefab="spider",brain="spiderbrain",mobMult=1.7,timeMult=.5},
    [6]  = {enabled=true,prefab="killerbee",brain="killerbeebrain",mobMult=2.2,timeMult=.3,dropMult=.8},
    [7]  = {enabled=true,prefab="mosquito",brain="mosquitobrain",mobMult=2.75,timeMult=.13,damageMult=2.2,dropMult=.5},
    [8]  = {enabled=true,prefab="lightninggoat",brain="lightninggoatbrain",RoG=true,mobMult=.75,timeMult=1.25}, 
    [9]  = {enabled=true,prefab="beefalo",brain="beefalobrain",mobMult=.75,timeMult=1.5},
    [10] = {enabled=false,prefab="bat",brain="batbrain",CaveState="open",mobMult=1,timeMult=1}, -- TODO: Bats crash game when attacked by other things.
    [11] = {enabled=false,prefab="rook",brain="rookbrain",mobMult=1,timeMult=1}, -- These dudes don't work too well (mostly works, but they get lost)
    [12] = {enabled=true,prefab="knight",brain="knightbrain",mobMult=1,timeMult=1.5,dropMult=.4}, -- Only drop half of the time
    [13] = {enabled=false,prefab="mossling",brain="mosslingbrain",RoG=true,Season={SEASONS.SPRING},mobMult=1,timeMult=1}, -- Needs work. They wont get enraged. Also spawns moosegoose....so yeah
    [14] = {enabled=true,prefab="perd",brain="perdbrain",mobMult=2.5,timeMult=.25,dropMult=.4},
    [15] = {enabled=true,prefab="penguin",brain="penguinbrain",Season={SEASONS.WINTER},mobMult=2.5,timeMult=.35,damageMult=.5},
}

-- Lookup the table index by prefab name. Returns nil if not found
local function getIndexByName(name)
    for k,v in pairs(MOB_LIST) do
        if v.prefab == name then
            return k
        end
    end
end

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
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "The cavalry are coming!"
    elseif prefab == "perd" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Gobbles!!!"
    elseif prefab == "penguin" then
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Oh no...they think I took their eggs!"
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
                    pickThisMob = true
                elseif MOB_LIST[v].CaveState == "used" and caveUsed ~= nil and caveUsed == true then
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
        local pigPos = Vector3(v.Transform:GetWorldPosition())
        -- Strike lightning on pig (make it not burnable first)
        v:RemoveComponent("burnable")
        GLOBAL.GetSeasonManager():DoLightningStrike(pigPos)
        v:DoTaskInTime(1, function(inst) inst:AddComponent("burnable") end)
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
            mob:AddTag("hostile") -- seems natural to set this

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
                    -- TODO: Seeing what happens when this is gone.
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
                -- TODO: Testing this 
                if true then
                    return inst.components.combat:CanTarget(target)
                end
                -- This wont get hit. Was original code. TODO : if above is better, remove this.
                if target:HasTag("player") and inst.components.combat:CanTarget(target) then
                    return true
                else
                    return origCanTarget and origCanTarget(inst,target)
                end
            end
            mob.components.combat:SetKeepTargetFunction(keepTargetOverride)
            
            -- Let's try this out. Give the players a chance. Basically, the mobs will look for something 
            -- else to attack every once in a while...
            local function retargetfn(inst)
                thing =  GLOBAL.FindEntity(inst, 20, function(guy) 
                    return not guy:HasTag("wall") and not guy:HasTag("houndedKiller") and inst.components.combat:CanTarget(guy)
                    end)
                if thing then
                    return thing
                end
            end
            
            -- TODO: Get this to work
            --if not mob.components.teamattacker then
            --  mob.components.combat:SetRetargetFunction(3, retargetfn)
            --end
            
            -- Set the min attack period to something...higher
            local currentAttackPeriod = mob.components.combat.min_attack_period
            mob.components.combat:SetAttackPeriod(math.max(currentAttackPeriod,3))
            mob.components.combat:SuggestTarget(GLOBAL.GetPlayer())
            
            -- Tweak the damage output of this mob based on the table
            local index = getIndexByName(mob.prefab)
            if index and MOB_LIST[index].damageMult then
                local mult = MOB_LIST[index].damageMult
                mob.components.combat:SetDefaultDamage(mult*mob.components.combat.defaultdamage)
            end
            
            -- Tweak the health of this mob based on the table
            if index and MOB_LIST[index].healthMult then
                local mult = MOB_LIST[index].healthMult
                mob.components.health:SetMaxHealth(mult*mob.components.health.maxhealth)
            end
			
			-- Tweak the drop rates for the mobs
			if index and MOB_LIST[index].dropMult then
				local mult = MOB_LIST[index].dropMult
				if mob.components.lootdropper.loot then
					local current_loot = mob.components.lootdropper.loot
					mob.components.lootdropper:SetLoot(nil)
					-- Create a loot_table from this (chance would be 1)
					for k,v in pairs(current_loot) do
						mob.components.lootdropper:AddChanceLoot(v,mult)
					end			
				elseif mob.components.lootdropper.chanceloottable then
					local loot_table = GLOBAL.LootTables[mob.components.lootdropper.chanceloottable]
					if loot_table then
					mob.components.lootdropper:SetChanceLootTable(nil)
						for i,entry in pairs(loot_table) do
							local prefab = entry[1]
							local chance = entry[2]*mult
							mob.components.lootdropper:AddChanceLoot(prefab,chance)
						end
					end
				end
			end
            
            ------------------------------------------------------------------------------
        end
    end -- end AddMob fcn
    
    
    self.RemoveMob = function(self,mob)
        if mob and self.currentMobs[mob] then
            self.currentMobs[mob] = nil
            self.numMobsSpawned = self.numMobsSpawned - 1
        end
    end
    -----------------------------------------------------------------
    
    -- Create some quake effects
    local function stampedeShake(self, duration, speed, scale)
                             -- type,duration,speed,scale,maxdist
        GLOBAL.TheCamera:Shake("FULL", duration, speed, scale, 80)
        
        -- Increase the intensity for the next call (only start the sound once)
        if not self.quakeStarted then
            self.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "earthquake")
            self.quakeStarted = true
        end
        self.SoundEmitter:SetParameter("earthquake", "intensity", self.soundIntensity)
        
    end
    self.quakeMachine.WarnQuake = stampedeShake
    
    local function endStampedeShake(self)
        self.quakeStarted = false
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
                    if GLOBAL.GetSeasonManager():IsWinter() then
                        prefab = "icehound"
                    else
                        prefab = "firehound"
                    end
                end     
            end
            
			-- They spawn from lightning!
            if prefab == "lightninggoat" then
                GLOBAL.GetSeasonManager():DoMediumLightning()
            end
                        
			-- This was in the original hounded...though it seems unused
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
				
				-- TODO: Check player sanity. If insane, set a condition to change these monsters into
				--       shadow creatures!
				local transformToShadow = function(self)
					-- Only do this once we get close enough for dramatic effect	
					local currentPos = Vector3(self.Transform:GetWorldPosition())
					local playerPos = Vector3(GLOBAL.GetPlayer().Transform:GetWorldPosition())
					if currentPos ~= nil and playerPos ~= nil then
						local currentDist = GLOBAL.distsq(currentPos,playerPos)
						if currentDist <= 50 then
							-- Don't turn every single one into a shadow dude...
							local index = getIndexByName(theMob.prefab)
							local mult = MOB_LIST[index].mobMult or 1
							local meanOne = math.random() < (1/(mult*mult))+.15
							if meanOne then
								shadowDude = GLOBAL.SpawnPrefab("crawlinghorror")
								shadowDude.components.combat:SuggestTarget(GLOBAL.GetPlayer())
								shadowDude.Physics:Teleport(currentPos:Get())
							else
								shadowDude = GLOBAL.SpawnPrefab("shadowskittish")
								shadowDude.Transform:SetPosition(currentPos:Get())
							end
							
							shadowDude.previousPrefab = self.prefab
							self:Remove()
							
							-- TODO...should probably set a periodic task to turn them back
							-- when not insane :P
						else
							-- Check again (only if player is still crazy)
							if GLOBAL.GetPlayer().components.sanity:IsSane() then
								self.AnimState:SetMultColour(1,1,1,1)
								self.task:Cancel()
								self.task = nil
								
							else
								-- Flicker
								local black = math.max(.15,math.random()*.5)
								--self.AnimState:SetMultColour(black,black,black,math.random()*.5)
								self.AnimState:SetMultColour(0,0,0,math.max(.3,math.random()*.5))
							end
						end
					end
					
				end
				if GLOBAL.GetPlayer().components.sanity and GLOBAL.GetPlayer().components.sanity:IsCrazy() then
					theMob.task = theMob:DoPeriodicTask(.15,transformToShadow)
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
            end -- if theMob
        end -- spawn_pt
        
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

        self.houndstorelease = math.floor(self.houndstorelease*MOB_LIST[self.currentIndex].mobMult)
        print("Next Attack: " .. self.houndstorelease .. " " .. MOB_LIST[self.currentIndex].prefab)
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
            
        end
        
        -- If beefalo are coming, start the stampede effects
        if MOB_LIST[self.currentIndex].prefab == "beefalo" then
            if self.timetoattack < self.warnduration and self.timetoattack > 0 and not self.quakeMachine.quakeStarted then

                -- This is kind of hackey...but i want the quake to INCREASE over time, not decrease. 
                -- The camerashake only has functions that decrease...            
                local interval = self.timetoattack / 2

                --self.quakeMachine:DoTaskInTime(0, function(self) self:WarnQuake(interval*2, .015, .1) end)
                self.quakeMachine:WarnQuake(interval*2,.015,.1)
                -- Camera shake decreases in intensity as it goes on...but I want it to INCREASE!!
                self.quakeMachine:DoTaskInTime(1*interval, function(self) self:WarnQuake(interval*2, .02, .1) end)
                self.quakeMachine:DoTaskInTime(2*interval, function(self) self:WarnQuake(interval*2, .025, .1) end)
                self.quakeMachine.quakeStarted = true
                
                local interval = self.timetoattack/5
                for i=1, 5 do
                    self.quakeMachine:DoTaskInTime(i*interval, function(self) self:MakeStampedeLouder() end)
                end
                
                -- Schedule quake to end
                self.quakeMachine:DoTaskInTime(self.timetoattack+5, function(self) self:EndQuake() end)
            end
        -- If lightning goats are coming, start some weather effects
        elseif MOB_LIST[self.currentIndex].prefab == "lightninggoat" then
            if self.timetoattack < self.warnduration and self.timetoattack > 0 and not self.inst.overcastStarted then
                                
                -- We're in the warning interval. Lets make some clouds (only if it's day)
                self.inst.overcastStarted = true
                if GLOBAL.GetClock():IsDay() then
                    self.inst.startColor = GLOBAL.GetClock().currentColour
                    print(self.inst.startColor)
                    
                    -- Get the curent cloud cover
                    currentClouds = GLOBAL.GetSeasonManager():GetWeatherLightPercent()
                    
                    -- If there is more than 50% cloud cover...don't make it even darker!
                    if (1-currentClouds) < .5 then
                    
                        -- The clock uses the absolute day color already. Don't need to 
                        -- adjust to this. Just adjusting initially so we don't make it flash brighter, THEN
                        -- get darker. Instead, start at current cloud cover and add MORE!

                        -- Make some (more) clouds! These are supposed to be ominous!
                        self.inst.endColor = GLOBAL.Point(0,0,0)
                        self.inst.endColor.x = .5*currentClouds*self.inst.startColor.x
                        self.inst.endColor.y = .5*currentClouds*self.inst.startColor.y
                        self.inst.endColor.z = .5*currentClouds*self.inst.startColor.z

                        
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
                end
                
                -- Schedule some distant thunder sound fx
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
        else
            updateWarningString(self.currentIndex)
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
            if timeToAttack == nil then timeToAttack = 30 end
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

---------------------------------------------------------------------------
-- PIGMAN override to add listen event
---------------------------------------------------------------------------
local function AddPigmanTransformEvent(inst)
    inst:ListenForEvent("transform_special_pigs",transformFcn)
end

AddPrefabPostInit("pigman",AddPigmanTransformEvent)

---------------------------------------------------------------------------
-- Brain Modifications
---------------------------------------------------------------------------
local ipairs = GLOBAL.ipairs
local function MakeMobChasePlayer(brain)
    --[[ Make this the top of the priority node. Basically, if they have the 
         insane tag (we add it above), they will prioritize chasing and attempting 
         to kill the player before doing normal things.
         
         Update - maybe should make all mobs attack walls now since they are crazy
    --]]

    local function KillKillDieDie(inst)
        -- Chase for 60 seconds, target distance 60
        return GLOBAL.ChaseAndAttack(inst,60,60)
    end
    
    attackWall = GLOBAL.WhileNode(function() return brain.inst:HasTag("houndedKiller") end, "Get The Coward", GLOBAL.AttackWall(brain.inst) )
    chaseAndKill = GLOBAL.WhileNode(function() return brain.inst:HasTag("houndedKiller") end, "Kill Kill", KillKillDieDie(brain.inst))
    
    
    -- Find the root node. Insert this WhileNode at the top.
    -- Well, we'll put it after "OnFire" (if it exists) so it will still panic if on fire
    local fireindex = 0
    for i,node in ipairs(brain.bt.root.children) do
        if node.name == "Parallel" and node.children[1].name == "OnFire" then
            fireindex = i
        end
    end
       
    -- Tell the brain "Attack the player...unless there is a wall in the way, get that instead"
    table.insert(brain.bt.root.children, fireindex+1, chaseAndKill)
    table.insert(brain.bt.root.children, fireindex+1, attackWall)

    
    -- The plan was to give the players a small break by having the mobs stop for a snack...but they don't 
    -- ever seem to want to to id. TODO!
    -- Make the mobs have a snack every so often
    local function EatFoodAction(inst)
        if inst.components.eater then
            local target = GLOBAL.FindEntity(inst, 30, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() end)
            if target then
                return GLOBAL.BufferedAction(inst, target, GLOBAL.ACTIONS.EAT)
            end
        end
    end
    haveASnack = GLOBAL.DoAction(brain.inst, EatFoodAction, "Eat Food", true )
    
    -- If the brain already has this...don't add it again. Else, add it to the end
    local hasAction = false
    for i,node in ipairs(brain.bt.root.children) do
        if node.name == "Parallel" and node.children[1].name == "Eat Food" then
            -- Already eats...don't add it again
            hasAction = true
            break
        end
    end
    
    -- TODO: Fix snack code
    if false then
        if not hasAction then
            -- Just insert at end
            table.insert(brain.bt.root.children, haveASnack)
        end
    end
    
    -- Debug string to see that my KillKillDieDie was added
    --print("Brain for " .. tostring(brain.inst.name))
    --for i,node in ipairs(brain.bt.root.children) do
    --    print("\t"..node.name.." > "..(node.children and node.children[1].name or ""))
    --end
    --print("\n")
    
end

-- Insert this brain for each mob that has it defined in MOB_LIST (if DLC allows)
for k,v in pairs(MOB_LIST) do
    local skip
    if v.brain and (not dlcEnabled and v.RoG) then
        skip = true
    end
    if v.brain and not skip then
        AddBrainPostInit(v.brain,MakeMobChasePlayer)
    end
end

---------------------------------------------------------------------------
-- Generate a new special hound effect if this has never been loaded before
---------------------------------------------------------------------------
local function firstTimeLoad()

	-- Don't load anything if in a cave
	if not GLOBAL.GetWorld():IsCave() then
		if GLOBAL.GetWorld().components.hounded.currentIndex == nil then
			print("First time loading this mod. Generating new hound attack.")   
			GLOBAL.GetWorld().components.hounded:PlanNextHoundAttack()
		else
			print("Current Mob Planned: " .. MOB_LIST[GLOBAL.GetWorld().components.hounded.currentIndex].prefab)
		end
	end
end
AddSimPostInit(function() firstTimeLoad() end)

---------------------------------------------------------------------------
-- Don't increase naughtyness for killing these things
---------------------------------------------------------------------------
local removedNaughty = function(self)
    local origFcn = self.onkilledother
    local newKillFcn = function(self,victim)
        if not victim:HasTag("houndedKiller") then
            origFcn(self,victim)
        end
    end
	self.onkilledother = newKillFcn
 end
 AddComponentPostInit("kramped",removedNaughty)

