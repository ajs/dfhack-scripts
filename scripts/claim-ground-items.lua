-----
-- Find any unattended items that have flags that prevent being picked up
-- OTHER THAN explicitly being forbidden and make them accessible.

local item_count = 0
for _,item in ipairs(df.global.world.items.all) do
    if item.flags.on_ground and not item.flags.forbid then
        local name = dfhack.items.getDescription(item, item:getType())
        local item_is = 0
        if item.flags.trader then
            print("Trader item: "..name)
            item_count = item_count + 1
            item.flags.trader = false
        else if item.flags.hostile then
            print("Hostile owned item: "..name)
            item_count = item_count + 1
            item.flags.hostile = false
        else if item.flags.hidden then
            print("Hidden item: "..name)
            item_count = item_count + 1
            item.flags.hidden = false
        else if item.flags.removed then
            print("Removed item: "..name)
            item_count = item_count + 1
            item.flags.removed = false
        end end end end
    end
end

if item_count > 0 then
    print("Total reclaimed items: "..item_count)
end

-- What follows is a script by PatrikLundell on the Dwarf Fortress forums.
local enemy_civs = {}

for i, diplomacy in ipairs (df.global.world.entities.all [df.global.ui.civ_id].relations.diplomacy) do
  if df.global.world.entities.all [diplomacy.group_id].type == df.historical_entity_type.Civilization and
     diplomacy.relation == 1 then  --  1 seems to be war, while 0 is peace for civs. Sites seem to use a different encoding.
    table.insert (enemy_civs, dfhack.TranslateName (df.global.world.entities.all [diplomacy.group_id].name, true))
  end
end

---------------------------

function Is_Enemy_Civ (civ)
  for i, enemy in ipairs (enemy_civs) do
    if dfhack.TranslateName (civ.name, true) == enemy then
      return true
    end
  end

  return false
end

---------------------------

function y ()
  local dumped = 0
  local dump_forbidden = 0
  local dump_foreign = 0
  local dump_trader = 0
  local melt = 0
  local trader_ground = 0
  for i, item in ipairs (df.global.world.items.all) do
    if item.flags.dump then
      dumped = dumped + 1

      if item.flags.forbid then
        dump_forbidden = dump_forbidden + 1
      end

      if item.flags.foreign then
        dump_foreign = dump_foreign + 1
      end

      if item.flags.trader then
        dump_trader = dump_trader + 1
      end
    end

    if item.flags.melt then
      melt = melt + 1
    end

    if item.flags.on_ground and
       item.flags.trader then
      trader_ground = trader_ground + 1
      if item.subtype.id == "ITEM_TOOL_SCROLL" then
        item.flags.trader = false
        dfhack.println ("Claiming scroll")

      else
        printall (item.subtype)
      end
    end
  end

  dfhack.println ("Dump designated: " .. tostring (dumped) .. ", Foreign: " .. tostring (dump_foreign) .. ", Trader: " .. tostring (dump_trader) .. ", Trader on the ground: " .. tostring (trader_ground) .. ", Melt designated: " .. tostring (melt))

  ---------------------------

  for i, unit in ipairs (df.global.world.units.all) do
    if (dfhack.TranslateName(dfhack.units.getVisibleName(unit), true) ~= dfhack.TranslateName (unit.name, true) or
        #unit.status.souls > 1) and
        not unit.flags2.killed then
      dfhack.println (dfhack.TranslateName(dfhack.units.getVisibleName(unit), true), dfhack.TranslateName (unit.name, true))
    end

    local hf = df.historical_figure.find (unit.hist_figure_id)

    if not unit.flags2.killed and
       hf and
       hf.info.reputation then
      if #hf.info.reputation.all_identities > 0 then
        dfhack.color (COLOR_LIGHTRED)
        dfhack.println ("Has false identities:", dfhack.TranslateName (unit.name, true), dfhack.TranslateName (unit.name, false), #hf.info.reputation.all_identities, hf.id)
        for k, identity_id in ipairs (hf.info.reputation.all_identities) do
          local identity = df.identity.find (identity_id)
          dfhack.println ("", dfhack.TranslateName (identity.name, true), dfhack.TranslateName (identity.name, false), identity.histfig_id, df.identity_type [identity.type])
        end
        dfhack.color (COLOR_RESET)
      end
    end
  end

  local trap_count = 0
  local spied_trap_count = 0
  local civ_observed_count = {}

  for i, building in ipairs (df.global.world.buildings.all) do
    if building._type == df.building_trapst and
       building.trap_type == df.trap_type.CageTrap then
      trap_count = trap_count + 1

      for k, observer in ipairs (building.observed_by_civs) do
        if civ_observed_count [observer] then
          civ_observed_count [observer] = civ_observed_count [observer] + 1

        else
          civ_observed_count [observer] = 1
        end
      end
    end
  end

  dfhack.println ("Trap Count: " .. tostring (trap_count))

  ---------------------------

  for i, count in pairs (civ_observed_count) do
    local civ = df.historical_entity.find (i)
    if civ.race == -1 then
--      dfhack.println ("  Traps observed by the " ..  df.historical_entity_type [civ.type] .. " "  .. dfhack.TranslateName (civ.name, true) .. ": " .. tostring (count))
    else
      if df.global.world.raws.creatures.all [civ.race].name [0] == "goblin" or
         Is_Enemy_Civ (civ) then
        dfhack.color (COLOR_LIGHTRED)
      dfhack.println ("  Traps observed by the " .. df.global.world.raws.creatures.all [civ.race].name [0] .. " " ..
                      df.historical_entity_type [civ.type] .. " " .. dfhack.TranslateName (civ.name, true) .. ": " .. tostring (count))
      end
--      dfhack.println ("  Traps observed by the " .. df.global.world.raws.creatures.all [civ.race].name [0] .. " " ..
--                      df.historical_entity_type [civ.type] .. " " .. dfhack.TranslateName (civ.name, true) .. ": " .. tostring (count))
      dfhack.color (COLOR_RESET)
    end
  end

  local goblin_found = false

  for i, unit in ipairs (df.global.world.units.active) do
    local civ = df.historical_entity.find (unit.civ_id)

    if civ and
       civ.race ~= -1 and
       (df.global.world.raws.creatures.all [civ.race].name [0] == "goblin" or
        Is_Enemy_Civ (civ)) and
       not unit.flags1.marauder and
       unit.flags2.visitor and
       dfhack.units.isAlive (unit) then
--       not unit.flags1.invader_origin and
--       not unit.flags1.invades and
--       not unit.flags2.visitor_uninvited
      if not goblin_found then
        goblin_found = true
        dfhack.println ()
        dfhack.println ("Enemy civ members present:")
      end

      dfhack.color (COLOR_LIGHTRED)
      dfhack.println (dfhack.TranslateName (unit.name, true), dfhack.TranslateName (unit.name, false), dfhack.TranslateName (civ.name, true))
      dfhack.color (COLOR_RESET)
    end
  end
end

y ()