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
    [8]  = {enabled=true,RoG=true,prefab="lightninggoat",brain="lightninggoatbrain",mobMult=.75,timeMult=1.25}, 
    [9]  = {enabled=true,prefab="beefalo",brain="beefalobrain",mobMult=.75,timeMult=1.5},
    [10] = {enabled=true,prefab="bat",CaveState="open",brain="batbrain",mobMult=1,timeMult=1},
    [11] = {enabled=true,prefab="rook",brain="rookbrain",mobMult=1,timeMult=1}, 
    [12] = {enabled=true,prefab="knight",brain="knightbrain",mobMult=1,timeMult=1}, 
}

-- This is for debugging. Set to random when launching the game.
--local currentIndex = 9

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
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Sounds like a million tiny legs getting closer and closer"
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
        STRINGS.CHARACTERS[character].ANNOUNCE_HOUNDS = "Earthquake? It's getting louder..."
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
        end
    end
    
    
    self.RemoveMob = function(self,mob)
        if mob and self.currentMobs[mob] then
            print("Removing " .. tostring(mob.prefab) .. " from mob list")
            self.currentMobs[mob] = nil
            self.numMobsSpawned = self.numMobsSpawned - 1
        end
    end
    -----------------------------------------------------------------
    
    -- Override the quake functions to only shake camera and play/stop the madness
    local function stampedeShake(self, duration, speed, scale)
                             -- type,duration,speed,maxshake,maxdist
        GLOBAL.TheCamera:Shake("FULL", duration, speed, scale, 80)
        -- Increase the intensity for the next call
        self.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "earthquake")
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
            
            -- If spiders...give a chance at warrior spiders
            if prefab == "spider" and math.random() < .25 then
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

                
                -- TODO: Decrease health?
 
 
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
                
                -- Mosquitos should have a random fill rate instead of all being at 0
                if theMob:HasTag("mosquito") then
                    local fillUp = math.random(0,2)
                    for i=0,fillUp do
                        theMob:PushEvent("onattackother",{data=theMob})
                    end
                end
                
                -- Pigs might transform! Hmm, beardbunny dudes are werebeasts too
                if theMob.components.werebeast ~= nil then
                    theMob:AddTag("SpecialPigman")
                end
                
                -- Quit trying to find a herd dumb mobs
                if theMob.components.herdmember then
                    theMob:RemoveComponent("herdmember")
                end
                
                -- Quit trying to go home. Your home is the afterlife.
                if theMob.components.knownlocations then
                    theMob.components.knownlocations:ForgetLocation("home")
                end
                
				
				-- Override the default KeepTarget for this mob.
                -- Basically, if it's currently targeting the player, continue to.
                -- If not, let it do whatever it's doing for now until it loses interest
                -- and comes back for the player.
				local origCanTarget = theMob.components.combat.keeptargetfn
				local function keepTargetOverride(inst, target)
                    if target:HasTag("player") and inst.components.combat:CanTarget(target) then
                        return true
                    else
                        return origCanTarget and origCanTarget(inst,target)
                    end
                end
				theMob.components.combat:SetKeepTargetFunction(keepTargetOverride)
                
                -- If the player is alive...go kill them
                --local function retargetOverride(inst)
                --    target = GLOBAL.GetPlayer()
                --    if inst.components.combat:CanTarget(target) then
                --        return target
                --    end
                --end
                --theMob.components.combat:SetRetargetFunction(3, retargetOverride)
				
				theMob.Physics:Teleport(spawn_pt:Get())
				theMob:FacePoint(pt)
                
                -- Set the min attack period to something...higher
                local currentAttackPeriod = theMob.components.combat.min_attack_period
                print("Mob current attack period: " .. currentAttackPeriod)
                theMob.components.combat:SetAttackPeriod(math.max(currentAttackPeriod,3))

				theMob.components.combat:SuggestTarget(GLOBAL.GetPlayer())
                --theMob.components.combat:SetTarget(GLOBAL.GetPlayer())
                
                -- Stuff to do after all of the mobs are released
                if self.houndstorelease == 0 then
                    -- Transform the pigs to werepigs
                    if theMob:HasTag("SpecialPigman") then
                        self.inst:DoTaskInTime(5, function(inst) transformThings() end)
                    end
                    
                end
                
                -- Start tracking this mob!
                self:AddMob(theMob)
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
            print("Prefab overwrite")
            self.currentIndex = prefabIndex
        else
            self.currentIndex = getRandomMob()
        end
        print("Picked " .. MOB_LIST[self.currentIndex].prefab .. " as next mob")
        self.houndstorelease = math.floor(self.houndstorelease*MOB_LIST[self.currentIndex].mobMult)
        print("Number scheduled to be released: " .. self.houndstorelease)
        updateWarningString(self.currentIndex)
    end
    
    self.PlanNextHoundAttack = planNextAttack
    
    local origOnUpdate = self.OnUpdate
    local function newOnUpdate(self,dt)
        origOnUpdate(self,dt)
        -- Modify the next release time based on the current prefab
        if self.timetoattack <= 0 then
            if MOB_LIST[self.currentIndex].timeMult ~= 1 and self.calcNextReleaseTime then
                local orig = self.timetonexthound
                self.timetonexthound = self.timetonexthound * MOB_LIST[self.currentIndex].timeMult
                self.calcNextReleaseTime = false
            end
            
            if self.quakeStarted then
                self.quakeMachine:DoTaskInTime(5, function(self) self:EndQuake() end)
                --self.quakeMachine:EndQuake()
                self.quakeStarted = false
            end
        end
        
        -- If beefalo are coming, start the stampede effects
        if MOB_LIST[self.currentIndex].prefab == "beefalo" then
            if self.timetoattack < self.warnduration and self.timetoattack > 0 and not self.quakeStarted then

                local quakeTime = 4*(self.houndstorelease+1) + self.timetoattack
                print("Starting quake for " .. tostring(quakeTime) .. " seconds")
                
                local interval = self.timetoattack / 2

                self.quakeMachine:DoTaskInTime(0, function(self) self:WarnQuake(interval*2, .015, .1) end)
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
        end
        
    end
    self.OnUpdate = newOnUpdate
    
    local origOnSave = self.OnSave
    local function newOnSave(self)
        data = origOnSave(self)
        -- If this is empty...hounded knew about
        -- something....so leave it empty.
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
                    -- Add this mob back to our counter
                    self:AddMob(targ.entity)
                    
                    -- Add the tags back to this mob
                    targ.entity:AddTag("houndedKiller")
                    
                    -- Our pigs are special...they know this
                    if targ.entity.components.werebeast then
                        targ.entity:AddTag("SpecialPigman")
                    end
                end
            end
        end
    end
    
    -- Helper function to start an attack.
    local function fn(self, prefabIndex)
        if self.timetoattack > 31 then
            print("Starting hound attack")
            self.timetoattack = 18
        end
    end
    self.StartAttackNow = fn

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
        ret = GLOBAL.ChaseAndAttack(inst,100,80)
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

