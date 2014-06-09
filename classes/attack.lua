--[[
  @Authors: Ben Dol (BeniS)
  @Details: Attack class for auto attack logic.
]]

Attack = newclass("Attack")

Attack.create = function(type, words, item, ticks)
  local atk = Attack.internalCreate()

  atk.type = type
  atk.words = words or ''
  atk.item = item or 0
  atk.ticks = ticks or 100

  return atk
end

-- gets/sets

function Attack:getType()
  return self.type
end

function Attack:setType(type)
  self.type = type
end

function Attack:getWords()
  return self.words
end

function Attack:setWords(words)
  self.words = words
end

function Attack:getItem()
  return self.item
end

function Attack:setItem(item)
  self.item = item
end

function Attack:getTicks()
  return self.ticks
end

function Attack:setTicks(ticks)
  self.ticks = ticks
end

-- methods
