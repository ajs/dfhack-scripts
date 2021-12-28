-----
-- Search all units for those that are hiding their identities, then
-- report on all anomalies with as much detail as seems pertinent.
--
-- Sample output:
--
-- [DFHack]# show-imposters
-- ** Imposter found! Current alias: Rashcog (Dwarf)
--   - Oddomled Stelidshasar is their real name.
--   - Additionally:
--   - * hides the nature of their curse
--   - * crazed
--   - * drinks blood
--   - * active
--   - * dead ('your friend is only mostly dead')
--   - * citizen
--   - * age: 195.9
--
--** Imposter found! Current alias: Tun Athelzatam (Human)
--   - Idla Jolbithar is their real name.
--   - Additionally:
--   - * dead ('your friend is only mostly dead')
--   - * visitor
--   - * age: 62.2
--
--** Imposter found! Current alias: Anir Adegom (Human)
--   - Sudem Struslotehil is their real name.
--   - Additionally:
--   - * alive
--   - * visitor
--   - * age: 73.9

local function round(n, precision)
    -----
    -- Round a number (n) to a given precision
    -- (precision defaults to 0)
    local pfactor
    if precision then
        pfactor = 10 ^ precision
        n = n * pfactor
    end
    n = n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
    if precision then
        n = n / pfactor
    end

    return n
end

local function titlecase(str)
    -----
    -- Upcase first letter of words in str
    return str:gsub("(%a)(%a+)", function(a, b) return string.upper(a) .. string.lower(b) end)
end

local function get_race(unit)
    ----
    -- Like dfhack.units.getRaceName, but that function does not work
    -- well on procedurally generated race names at this time.
    -- If there is a bug-fix in the future, just swap which line is
    -- commented.

    -- return dfhack.units.getRaceName(unit)
    return df.creature_raw.find(unit.race).name[0]
end

local function summarize_unit(unit)
    ----
    -- Return an object that gets some of the mess of unit interaction out of the way

    local hist_figure = df.historical_figure.find(unit.hist_figure_id) or {name = nil}
    local historical_name = nil
    if hist_figure and hist_figure.name then
        historical_name = dfhack.TranslateName(hist_figure.name)
    end

    local alias = dfhack.units.getIdentity(unit)
    local alias_name = nil
    if alias then
        alias_name = dfhack.TranslateName(alias.name)
    end

    return {
        unit = unit,
        unit = unit.id,
        alias = alias,
        alias_name = alias_name,
        active = dfhack.units.isActive(unit),
        age = round(dfhack.units.getAge(unit), 1),
        alive = dfhack.units.isAlive(unit),
        anti_life = dfhack.units.isOpposedToLife(unit),
        bloodsucker = dfhack.units.isBloodsucker(unit),
        citizen = dfhack.units.isCitizen(unit),
        crazed = dfhack.units.isHidingCurse(unit),
        hidden_curse = dfhack.units.isHidingCurse(unit),
        historical_name = historical_name,
        nemesis = dfhack.units.getNemesis(unit),
        race_name = titlecase(get_race(unit)),
        real_age = round(dfhack.units.getAge(unit, true), 1),
        real_name = dfhack.TranslateName(unit.name),
        soul_name = dfhack.TranslateName(unit.status.current_soul.name),
    }

end

local function usage()
    -----
    -- Print usage message

    print("Usage: show-imposters [-living] [-dead] [-vampire] [-inactive]")
    print("  Checks selected unit or all units if none selected.")
    print("  -living - show only living imposters")
    print("  -dead - show only dead imposters")
    print("  -vampire - show only vampires")
    print("  -inactive - include inactive units")
end

local function print_alias_info(unit)
    -----
    -- Given an imposter unit summary, format the info for the user

    local prefix = "   - * "  -- Output prefix for detail info

    print("** Imposter found! Current alias: "..unit.alias_name.." ("..unit.race_name..")")
    print("   - "..unit.real_name.." is their real name.")
    print("   - Additionally:")
    if unit.historical_name and unit.historical_name ~= unit.real_name and unit.historical_name ~= unit.alias_name then
        print(prefix..unit.historical_name.." is their historical name.")
    end
    if unit.soul_name and unit.soul_name ~= unit.real_name and unit.soul_name ~= unit.alias_name then
        print(prefix..unit.soul_name.." is their soul name.")
    end
    if unit.nemesis and unit.nemesis.unit_id ~= unit.id then
        local nemesis_unit = df.unit.find(unit.nemesis.unit_id)
        local nemesis_name = dfhack.TranslateName(dfhack.units.getVisibleName(nemesis_unit))
        print(prefix.."has a nemesis: "..nemesis_name)
    end
    if unit.hidden_curse then
        print(prefix.."hides the nature of their curse")
    end
    if unit.crazed then
        print(prefix.."crazed")
    end
    if unit.anti_life then
        print(prefix.."opposed to life")
    end
    if unit.bloodsucker then
        print(prefix.."drinks blood")
    end
    if not unit.active then
        print(prefix.."inactive")
    end
    if unit.alive then
        print(prefix.."alive")
    else
        print(prefix.."dead ('your friend is only mostly dead')")
    end
    local citizen_status = "visitor"
    if unit.citizen then
        citizen_status = "citizen"
    end
    print(prefix..citizen_status)
    local age_tag = "age"
    local age_value = unit.age
    if not unit.age == unit.real_age then
        age_tag = "age (real)"
        age_value = unit.age.." ("..unit.real_age..")"
    end
    print(prefix..age_tag..": "..age_value)
    print(" ")
end

local function main(...)
    -----
    -- Main script body

    local utils = require 'utils'

    local valid_opts = utils.invert({"help", "living", "dead", "vampire", "inactive", "citizen"})
    local args
    local invocation = {...}
    local status, result = pcall(function () return utils.processArgs(invocation, valid_opts) end)
    if status then
        args = result
    else
        print(result)
        args = {help = true}
    end

    if args.help then
        usage()
        return
    end

    local imp_count = 0

    local selected_unit = dfhack.gui.getSelectedUnit(true)
    local units

    if selected_unit then
        units = {selected_unit}
        selected_name = dfhack.TranslateName(dfhack.units.getVisibleName(selected_unit))
        print("Info for selected unit, "..selected_name.."...")
    else
        units = df.global.world.units.all
    end

    for _,unit in ipairs(units) do

        local summary = summarize_unit(unit)

        if summary.alias then
            -- All of the command-line argument filters applied:
            arg_restricted = (
                (args.living and not summary.alive) or
                (args.dead and summary.alive) or
                (args.vampire and not summary.bloodsucker) or
                (args.citizen and not summary.citizen) or
                (not args.inactive and not summary.active)
            )

            if not arg_restricted then
                print_alias_info(summary)
                imp_count = imp_count + 1
            end
        end
    end

    if imp_count > 0 then
        print("Total imposters: "..imp_count)
    else if selected_unit then
        print("Not an imposter.")
    else
        print("No imposters.")
    end end
end

if not dfhack_flags.module then
  main(...)
end
