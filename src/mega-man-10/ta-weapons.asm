# Inject at:
# - WRXE: 0x80049994
#
# Fun fact: The function that initializes all weapons (0x80075fb8) was written with
# multiple characters in mind; it handles the fact that Bass doesn't have
# a weapon in the Jet slot when unlocking all weapons for Time Attack.

.set route, 1  # 1-4

.set buster,         0b0000000000000001
.set tripleBlade,    0b0000000000000010
.set waterShield,    0b0000000000000100
.set commandoBomb,   0b0000000000001000
.set chillSpike,     0b0000000000010000
.set thunderWool,    0b0000000000100000
.set reboundStriker, 0b0000000001000000
.set wheelCutter,    0b0000000010000000
.set solarBlaze,     0b0000000100000000
.set coil,           0b0000001000000000
.set jet,            0b0000010000000000
.set dlcWeapons,     0b0011100000000000

# Define stage weapons based on Mega Man, no DLC weapons. Jet is added/removed
# based on character automatically. DLC weapons unlocked by the original game
# code are maintained.
.if route == 1
  # Pump 1st
  .set pump,     buster | coil
  .set solar,    pump | waterShield
  .set chill,    solar | solarBlaze
  .set nitro,    chill | chillSpike
  .set commando, nitro | wheelCutter | jet
  .set blade,    commando | commandoBomb
  .set strike,   blade | tripleBlade
  .set sheep,    strike | reboundStriker
.elseif route == 2
  # Chill 1st, Pump 3rd
  .set chill,    buster | coil
  .set nitro,    chill | chillSpike
  .set pump,     nitro | wheelCutter
  .set solar,    pump | waterShield
  .set commando, solar | solarBlaze | jet
  .set blade,    commando | commandoBomb
  .set strike,   blade | tripleBlade
  .set sheep,    strike | reboundStriker
.elseif route == 3
  # Chill 1st, Pump 7th
  .set chill,    buster | coil
  .set nitro,    chill | chillSpike
  .set commando, nitro | wheelCutter
  .set blade,    commando | commandoBomb
  .set strike,   blade | tripleBlade | jet
  .set sheep,    strike | reboundStriker
  .set pump,     sheep | thunderWool
  .set solar,    pump | waterShield
.elseif route == 4
  # Commando 1st
  .set commando, buster | coil
  .set blade,    commando | commandoBomb
  .set chill,    blade | tripleBlade
  .set nitro,    chill | chillSpike
  .set strike,   nitro | wheelCutter | jet
  .set sheep,    strike | reboundStriker
  .set pump,     sheep | thunderWool
  .set solar,    pump | waterShield
.endif

.set protoMan, 0x0002
.set bass,     0x0003

.set characterIDOffset,  0x0001
.set stageIDOffset,     -0x2995
.set weaponsOffset,      0x0020

# Registers:
# - r3: address of character data structure
# - r6: unlocked weapon bits (initially all unlocked for current character)
# - r29: high halfword of stage ID + 1

  lbz r5, stageIDOffset (r29)          # > Read stage ID
  cmplwi r5, 0x0008                    # \ Do nothing if not a Robot Master stage
  bge end                              # /

  mflr r0                              # \ Table of weapons indexed by stage ID
  bl endTable                          # | (preserve original LR, put address of table in r7)
  .short blade, pump, commando, chill  # |
  .short sheep, strike, nitro, solar   # |
endTable:                              # |
  mflr r7                              # |
  mtlr r0                              # /

  andi. r6, r6, dlcWeapons@l           # > Lock all non-DLC weapons
  slwi r5, r5, 1                       # > Double stage ID to index halfwords in table
  lhzx r0, r5, r7                      # > Read unlocked weapons from table
  or r6, r6, r0                        # > Unlock non-DLC weapons

  lbz r4, characterIDOffset (r3)       # > Read character ID
  cmplwi r4, protoMan                  # \ Add Rush Jet if Proto Man
  bne checkBass                        # |
  ori r6, r6, jet                      # /
checkBass:
  cmplwi r4, bass                      # \ Remove Rush Jet if Bass
  bne writeWeapons                     # |
  andi. r6, r6, ~jet@l                 # /
writeWeapons:
  stw r6, weaponsOffset (r3)           # > Write unlocked weapons

end:
  lbz r0, 0x0002 (r31)                 # > Injected instruction
