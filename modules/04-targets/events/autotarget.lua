--[[
  @Authors: Ben Dol (BeniS)
  @Details: Auto targeting event logic
]]

TargetsModule.AutoTarget = {}
AutoTarget = TargetsModule.AutoTarget

-- Variables

AutoTarget.creatureData = {}
AutoTarget.lootQueue = {}
AutoTarget.looting = false

-- Methods

function AutoTarget.getCreatureData()
  return AutoTarget.creatureData
end

function AutoTarget.isLooting()
  return AutoTarget.looting
end

function AutoTarget.scan()
  local targetList = {}
  for k,v in pairs(TargetsModule.getTargets()) do
    table.insert(targetList, v:getName())
  end

  local player = g_game.getLocalPlayer()
  local targets = player:getTargetsInArea(targetList, true)

  for k,target in pairs(targets) do
    if not target:isDead() and not target:isRemoved() then
      if not AutoTarget.isAlreadyStored(target) then
        AutoTarget.addCreature(target)
      end
    else
      AutoTarget.removeCreature(target)
    end
  end
end

function AutoTarget.isAlreadyStored(creature)
  for id,v in pairs(AutoTarget.creatureData) do
    if v and id == creature:getId() then
      return true
    end
  end
  return false
end

function AutoTarget.addCreature(creature)
  if creature then
    --connect(creature, { onHealthPercentChange = AutoTarget.onTargetHealthChange })
    connect(creature, { onDisappear = AutoTarget.removeCreature })
    connect(creature, { onDeath = AutoTarget.onTargetDeath })
    AutoTarget.creatureData[creature:getId()] = creature
  end
end

function AutoTarget.removeCreature(creature)
  if creature then
    --disconnect(creature, { onHealthPercentChange = AutoTarget.onTargetHealthChange })
    disconnect(creature, { onDisappear = AutoTarget.removeCreature })
    disconnect(creature, { onDeath = AutoTarget.onTargetDeath })

    AutoTarget.creatureData[creature:getId()] = nil
  end
end

function AutoTarget.onTargetHealthChange(creature)

end

function AutoTarget.onTargetDeath(creature)
  AutoTarget.lootQueue[creature:getId()] = {
    position = creature:getPosition(),
    looted = false
  }
end

function AutoTarget.removeLoot(creature)
  AutoTarget.lootQueue[creature:getId()] = nil
end

function AutoTarget.hasUncheckedLoot()
  for _,loot in pairs(AutoTarget.lootQueue) do
    if loot and not loot.looted then
      return true
    end
  end
  return false
end

function AutoTarget.startLooting()
  print("AutoTarget.startLooting")
  AutoTarget.looting = true

  local queue = Queue.new(function()
    -- Executed when the queue is finished
    print("Queue finished callback called")
    AutoTarget.stopLooting()
  end)

  for id,loot in pairs(AutoTarget.lootQueue) do
    if loot and not loot.looted then
      print("Added ".. tostring(id) .. " [" .. postostring(loot.position).. "]")
      queue:add(LootEvent.new(id, loot.position, function()
        print("Fired LootEvent Callback: " .. tostring(id))
        loot.looted = true
      end))
    end
  end
  queue:start()
end

function AutoTarget.stopLooting()
  print("AutoTarget.stopLooting")
  AutoTarget.looting = false

  -- Clean up loot data?
end

function AutoTarget.Event(event)
  -- Cannot continue if still attacking or looting
  if g_game.isAttacking() or AutoTarget.looting then
    EventHandler.rescheduleEvent(TargetsModule.getModuleId(), 
      event, Helper.safeDelay(1500, 4000))
    return
  end

  -- Scan the area to update creature data
  AutoTarget.scan()

  -- Find a valid target to attack
  for id,target in pairs(AutoTarget.creatureData) do
    if target then g_game.attack(target) break end
  end

  -- Try loot if not attacking still
  if not g_game.isAttacking() and AutoTarget.hasUncheckedLoot() then
    AutoTarget.startLooting()
  end

  -- Keep the event live
  EventHandler.rescheduleEvent(TargetsModule.getModuleId(), 
    event, Helper.safeDelay(800, 3000))
end