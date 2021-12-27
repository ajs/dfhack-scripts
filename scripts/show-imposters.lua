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

local function usage()
    -----
    -- Print usage message

    print("Usage: show-imposters [-living] [-dead] [-vampire] [-inactive]")
    print("  -living - show only living imposters")
    print("  -dead - show only dead imposters")
    print("  -vampire - show only vampires")
    print("  -inactive - include inactive units")
end

local function print_alias_info(unit, alias)
    -----
    -- Given a unit and its alias, print the summary

    local alias_name = dfhack.TranslateName(alias.name)
    local race_name = titlecase(dfhack.units.getRaceName(unit))
    local real_name = dfhack.TranslateName(unit.name)
    local historical_name = dfhack.TranslateName(df.historical_figure.find(unit.hist_figure_id).name)
    local soul_name = dfhack.TranslateName(unit.status.current_soul.name)
    local nemesis = dfhack.units.getNemesis(unit)
    local hidden_curse = dfhack.units.isHidingCurse(unit)
    local crazed = dfhack.units.isHidingCurse(unit)
    local anti_life = dfhack.units.isOpposedToLife(unit)
    local active = dfhack.units.isActive(unit)
    local citizen = dfhack.units.isCitizen(unit)
    local age = round(dfhack.units.getAge(unit), 1)
    local real_age = round(dfhack.units.getAge(unit, true), 1)
    local alive = dfhack.units.isAlive(unit)
    local bloodsucker = dfhack.units.isBloodsucker(unit)
    local prefix = "   - * "  -- Output prefix for detail info

    print("** Imposter found! Current alias: "..alias_name.." ("..race_name..")")
    print("   - "..real_name.." is their real name.")
    if not historical_name == real_name and not historical_name == alias_name then
        print("   - "..historical_name.." is their historical name.")
    end
    if not soul_name == real_name and not soul_name == alias_name then
        print("   - "..soul_name.." is their soul name.")
    end
    print("   - Additionally:")
    if nemesis and not nemesis.unit_id == unit.id then
        local nemesis_unit = df.unit.find(nemesis.unit_id)
        local nemesis_name = dfhack.TranslateName(dfhack.units.getVisibleName(nemesis_unit))
        print(prefix.."has a nemesis: "..nemesis_name)
    end
    if hidden_curse then
        print(prefix.."hides the nature of their curse")
    end
    if crazed then
        print(prefix.."crazed")
    end
    if anti_life then
        print(prefix.."opposed to life")
    end
    if bloodsucker then
        print(prefix.."drinks blood")
    end
    if not active then
        print(prefix.."inactive")
    end
    if alive then
        print(prefix.."alive")
    else
        print(prefix.."dead ('your friend is only mostly dead')")
    end
    local citizen_status = "visitor"
    if citizen then
        citizen_status = "citizen"
    end
    print(prefix..citizen_status)
    local age_tag = "age"
    local age_value = age
    if not age == real_age then
        age_tag = "age (real)"
        age_value = age.." ("..real_age..")"
    end
    print(prefix..age_tag..": "..age_value)
    print(" ")
end

local function main(...)
    -----
    -- Main script body

    local utils = require 'utils'

    local valid_opts = utils.invert({"help", "living", "dead", "vampire", "inactive"})
    local args = utils.processArgs({...}, valid_opts)

    if args.help then
        usage()
        return
    end

    local only_living = args.living
    local only_dead = args.dead
    local only_vampire = args.vampire
    local include_inactive = args.inactive

    local imp_count = 0
    for _,unit in ipairs(df.global.world.units.all) do
        local alive = dfhack.units.isAlive(unit)
        local bloodsucker = dfhack.units.isBloodsucker(unit)
        local active = dfhack.units.isActive(unit)
        local alias = dfhack.units.getIdentity(unit)

        arg_restricted = (
            (only_living and not alive) or
            (only_dead and alive) or
            (only_vampire and not bloodsucker) or
            (not include_inactive and not active)
        )

        if alias and not arg_restricted then
            print_alias_info(unit, alias)
            imp_count = imp_count + 1
        end
    end

    if imp_count > 0 then
        print("Total imposters: "..imp_count)
    end
end

if not dfhack_flags.module then
  main(...)
end
