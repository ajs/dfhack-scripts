# dfhack-scripts
Some scripts I've written for dfhack

## Installation

Install Dwarf Fortress and dfhack directly or via a package like the
[Lazy Newb Pack](https://dwarffortresswiki.org/index.php/Utility:Lazy_Newb_Pack).
After unpacking, visit the top-level dwarf fortress directory and you
should find under it this tree:

```
hack
  scripts
```

In that scripts directory, you should place all of the files found under the `scripts`
directory in this repository.

## Scripts

### `claim-ground-items`

Find any unattended items that have flags that prevent being picked up
*other than* explicitly being forbidden and make them accessible.

This script tries its best, but there are some reasons that things
are inaccessible that it cannot yet detect or control.

### `show-imposters`

Search all units for those that are hiding their identities, then
report on all anomolies with as much detail as seems pertinent.

Usage:

```
show-imposters [-living] [-dead] [-vampire] [-inactive]
    -living - show only living imposters
    -dead - show only dead imposters
    -vampire - show only vampires
    -inactive - include inactive units
```

Sample output:

```
[DFHack]# show-imposters
** Imposter found! Current alias: Rashcog (Dwarf)
  - Oddomled Stelidshasar is their real name.
  - Additionally:
  - * hides the nature of their curse
  - * crazed
  - * drinks blood
  - * active
  - * dead ('your friend is only mostly dead')
  - * citizen
  - * age: 195.9

** Imposter found! Current alias: Tun Athelzatam (Human)
  - Idla Jolbithar is their real name.
  - Additionally:
  - * dead ('your friend is only mostly dead')
  - * visitor
  - * age: 62.2

** Imposter found! Current alias: Anir Adegom (Human)
  - Sudem Struslotehil is their real name.
  - Additionally:
  - * active
  - * alive
  - * visitor
  - * age: 73.9
```

### `show-military-unit`

A work-in-progress. I'm attempting to come up with a way to quickly navigate from the military
"positions" screen to the view-unit screen...
