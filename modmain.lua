local Vector3 = GLOBAL.Vector3
local dlcEnabled = GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)

--[[ Table is as follows:
        enabled: is this a valid prefab to use (DLC restrictions or config file)
        RoG: Is this a Reign of Giants only mob? (Toggles enabled if DLC is not enabled). If not added, assumed to be false.
        CaveState: "open", "used", nil - This mob will only spawn when the cavestate condition is met. If not defined, ignore
        prefab: prefab name
        brain: brain name. If a mob has this defined, will add a new PriorityNode to the brain to attack player.
               (leave this out if don't want to override brain function at all)
        mobMult: multiplier compared to normal hound values (how many to release)
        timeMult: how fast these come out compared to normal hounds. 0.5 is twice as fast. 2 is half speed.
        
        TODO: 
        What else to add? Could put the string in the table, but then each character would be forced to have the same one.
        
        
--]]

local MOB_LIST =
{
    [1]  = {enabled=true,prefab="hound",mobMult=1,timeMult=1},
    [2]  = {enabled=true,prefab="merm",brain="mermbrain",mobMult=1,timeMult=1},
    [3]  = {enabled=true,prefab="tallbird",brain="tallbirdbrain",mobMult=1,timeMult=1.2},
    [4]  = {enabled=true,prefab="pigman",brain="pigbrain",mobMult=1,timeMult=1},
    [5]  = {enabled=true,prefab="spider",brain="spiderbrain",mobMult=2.5,timeMult=.5},
    [6]  = {enabled=true,prefab="killerbee",brain="killerbeebrain",mobMult=3,timeMult=.4},
    [7]  = {enabled=true,prefab="mosquito",brain="mosquitobrain",mobMult=3,timeMult=.4}, 
    [8]  = {enabled=true,RoG=true,prefab="lightninggoat",brain="lightninggoatbrain",mobMult=1,timeMult=1}, 
    [9]  = {enabled=true,prefab="beefalo",brain="beefalobrain",mobMult=1,timeMult=1},
    [10] = {enabled=false,prefab="bat",CaveState="open",brain="batbrain",mobMult=1,timeMult=1}, --TODO, they don't seem to want to attack...
    [11] = {enabled=false,prefab="rook",brain="rookbrain",mobMult=1,timeMult=1}, --TODO, what is with these dudes...
    [12] = {enabled=false,prefab="knight",brain="knightbrain",mobMult=1,timeMult=1}, -- they don't want to keep on target :(
}

-- This is for debugging. Set to random when launching the game.
local currentIndex = 9

-- Check the config file and the DLC to disable some of the mobs
local function disableMobs()
    
    -- TODO: Add config file
    for k,v in pairs(MOB_LIST) do
        if not dlcEnabled and v.RoG then
            print("Disabling RoG mob: " .. v.prefab)
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
local function updateWarningString(index)
    prefab = MOB_LIST[index].prefab
    print("Updating warning strings for: " .. prefab)
    if prefab == nil then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = defaultPhrase
    elseif prefab == "merm" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Oh god, it smells like rotting fish"
    elseif prefab == "spider" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Sounds like a million tiny legs getting closer and closer"
    elseif prefab == "tallbird" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Sounds like a murder...of tall birds"
    elseif prefab == "pigman" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Was that an oink?"
    elseif prefab == "killerbee" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Beeeeeeeeeeeeeeeeees!"
    elseif prefab == "mosquito" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "I hear a million teeny tiny vampires"
    elseif prefab == "lightninggoat" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Those giant dark clouds look ominous"
    elseif prefab == "beefalo" then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HOUNDS = "Earthquake?!"
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
    -- TODO: Make this more flexible for more spawn restrictions so it doesn't get super messy
    for k,v in pairs(t) do
        if MOB_LIST[v].enabled then
            -- Check the various conditions
            if MOB_LIST[v].CaveState ~= nil then
                caveOpen = GLOBAL.ProfileStatsGet("cave_entrance_opened")
                caveUsed = GLOBAL.ProfileStatsGet("cave_entrance_used")
                if MOB_LIST[v].CaveState == "open" and caveOpen ~= nil and caveOpen == true then
                    print("Cave open. Returning " .. tostring(MOB_LIST[v].prefab))
                    return v
                elseif MOB_LIST[v].CaveState == "used" and caveUsed ~= nil and caveUsed == true then
                    print("Cave used. Returning " .. tostring(MOB_LIST[v].prefab))
                    return v
                else
                    print("Skipping " .. tostring(MOB_LIST[v].prefab) .. " as mob because cavestate not met")
                    if caveOpen ~= nil then
                        print("CaveOpen: " .. tostring(caveOpen))
                    end
                    if caveUsed ~= nil then
                        print("CaveUsed: " .. tostring(caveUsed))
                    end    
                       
                end
            else
                return v
            end
            
        end
    end

    -- If we are here...there is NOTHING in the list enabled.
    -- This is strange. Just return hound I guess (even though
    -- hound is in the list and the user disabled it...)
    return 1

    --local index = math.random(1,#MOB_LIST)
    --mob = MOB_LIST[index]  
    --return mob.prefab, index
end




updateWarningString(currentIndex)

--
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

    -- Hounded is a quaker now! muahaha
    self.quakeMachine = GLOBAL.CreateEntity()
    self.quakeMachine.persists = true
    self.quakeMachine:AddComponent("quaker")
    self.quakeMachine.entity:AddSoundEmitter()
    self.quakeMachine.components.quaker.soundIntensity = 0.01
    
    -- Override the quake functions to only shake camera and play/stop the madness
    local function stampedeShake(self, duration)
        self.emittingsound = true
                             -- type,duration,speed,maxshake,maxdist
        GLOBAL.TheCamera:Shake("FULL", duration, 0.02, .1, 40)
        self.inst.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "earthquake")
        self.inst.SoundEmitter:SetParameter("earthquake", "intensity", self.soundIntensity)
        
    end
    self.quakeMachine.components.quaker.WarnQuake = stampedeShake
    
    local function endStampedeShake(self)
        self.quake = false
        self.emittingsound = false
        self.inst.SoundEmitter:KillSound("earthquake")
        self.soundIntensity = 0.01
    end
    self.quakeMachine.components.quaker.EndQuake = endStampedeShake
    
    local function makeLouder(self)
        print("makeLouder")
        self.soundIntensity = self.soundIntensity + .04
        self.inst.SoundEmitter:SetParameter("earthquake","intensity",self.soundIntensity)
    end
    self.quakeMachine.components.quaker.MakeStampedeLouder = makeLouder
    
    self.quakeStarted = false
    

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
            
            -- If spiders...give a chance at warrior spiders
            if prefab == "spider" and math.random() < .5 then
                prefab = "spider_warrior"
            end
            
            -- This is nearby lightning...not a bolt. Don't want to make
            -- them all charged (unless that would be fun...)
            if prefab == "lightninggoat" then
                GLOBAL.GetSeasonManager():DoMediumLightning()
            end
            			
			local day = GLOBAL.GetClock().numcycles
		            
			local theMob = GLOBAL.SpawnPrefab(prefab)
			if theMob then
                -- I've modified the mobs brains to be mindless killers with this tag
                theMob:AddTag("houndedKiller")
 
 
                -- This mob has no home anymore. It's set to kill.
                if theMob.components.homeseeker then
                    theMob:RemoveComponent("homeseeker")
                end
                
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
                
                -- Pigs might transform! Hmm, beardbunny dudes are werebeasts too
                if theMob.components.werebeast ~= nil then
                    theMob:AddTag("SpecialPigman")
                end
                
                -- TODO: Make some lighting when lightninggoats are the attackers. Maybe just one...
                
                if theMob.components.herdmember then
                    print("Making this thing no longer a member of a herd")
                    theMob:RemoveComponent("herdmember")
                end
                
                if theMob.components.knownlocations then
                    print("Removing home from known locations")
                    theMob.components.knownlocations:ForgetLocation("home")
                end
                
				
				-- Override the default KeepTarget for this prefab so it never stops
								
				--local function keepTargetOverride(inst, target)
				--	return inst.components.combat:CanTarget(target)
				--end
				
				--theMob.components.combat:SetKeepTargetFunction(keepTargetOverride)
                -- If the player is alive...go kill them
                local function retargetOverride(inst)
                    target = GLOBAL.GetPlayer()
                    if inst.components.combat:CanTarget(target) then
                        return target
                    end
                end
                theMob.components.combat:SetRetargetFunction(3, retargetOverride)
				
				theMob.Physics:Teleport(spawn_pt:Get())
				theMob:FacePoint(pt)
				--theMob.components.combat:SuggestTarget(GLOBAL.GetPlayer())
                theMob.components.combat:SetTarget(GLOBAL.GetPlayer())
                
                -- Stuff to do after all of the mobs are released
                if self.houndstorelease == 0 then
                    -- Transform the pigs to werepigs
                    if theMob:HasTag("SpecialPigman") then
                        self.inst:DoTaskInTime(5, function(inst) transformThings() end)
                    end
                    
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
        currentIndex = getRandomMob()
        print("Picked " .. MOB_LIST[currentIndex].prefab .. " as next mob")
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
            
            if self.quakeStarted then
                print("Ending quake")
                self.quakeMachine.components.quaker:EndQuake()
                self.quakeStarted = false
            end
        end
        
        -- If beefalo are coming, start the stampede effects
        if MOB_LIST[currentIndex].prefab == "beefalo" then
            if self.timetoattack < self.warnduration and self.timetoattack > 0 and not self.quakeStarted then
                print("Starting quake")
                self.quakeMachine.components.quaker:WarnQuake(self.timetoattack + 3, 0.08)
                self.quakeStarted = true
                
                -- Schedule volume increases. Want at least 5 of them
                local interval = self.timetoattack/6
                for i=1, 6 do
                    print("Scheduling louder in " .. tostring(i*interval) .. " seconds")
                    self.quakeMachine:DoTaskInTime(i*interval, function(self) print("LOUDER!") self.components.quaker:MakeStampedeLouder() end)
                end
            end
        end
        
    end
    self.OnUpdate = newOnUpdate
    
    local function fn(self)
        self.timetoattack = 31
    end
    self.StartAttackNow = fn

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

--------------------------------------------------
-- Brain Modifications

local ipairs = GLOBAL.ipairs
local function MakeMobChasePlayer(brain)
    -- Make this the top of the priority node. Basically, if they have the insane tag (we add it above), they will
    -- prioritize chasing and attempting to kill the player before doing normal things.
    
    -- Made this a function so I can add more things to it if wanted. For now, just chase and attack.
    local function KillKillDieDie(inst)
        return GLOBAL.ChaseAndAttack(inst,100)
    end
    
    --for i,node in ipairs(brain.bt.root.children) do
    --    print("\t"..node.name.." > "..(node.children and node.children[1].name or ""))
    --end
    
    chaseAndKill = GLOBAL.WhileNode(function() return brain.inst:HasTag("houndedKiller") end, "Kill Kill", KillKillDieDie(brain.inst))
    --chaseAndKill = WhileNode(function() return self.inst:HasTag("houndedKiller") end , "Kill Kill", ChaseAndAttack(self.inst, 100))
    
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

-- TODO: Automate this add based on the MOB_LIST. Either add a brain= to it or 
--       assume the brain is simply [MOB_LIST[i].prefab .. "brain"]
--[[
if dlcEnabled then
    AddBrainPostInit("lightninggoatbrain",MakeMobChasePlayer)
end
AddBrainPostInit("pigbrain",MakeMobChasePlayer)
AddBrainPostInit("mermbrain",MakeMobChasePlayer)
AddBrainPostInit("tallbirdbrain",MakeMobChasePlayer)
AddBrainPostInit("mosquitobrain",MakeMobChasePlayer)
AddBrainPostInit("killerbeebrain",MakeMobChasePlayer)
AddBrainPostInit("spiderbrain",MakeMobChasePlayer)
AddBrainPostInit("beefalobrain",MakeMobChasePlayer)
--]]