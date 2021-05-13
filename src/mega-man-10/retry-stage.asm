.set state,        0x81000000
.set pressedBit,   0b01000000
.set activatedBit, 0b10000000
.set buttonCombo,  0b0001000000001000  # Select + X

# WRXE addresses:
.set input,               0x804534ea
.set gameMode,            0x805336e8
.set weaponMenuMode,      0x80fb9039
.set currentRefightKills, 0x80510661
.set initialRefightKills, 0x80535b0d
.set objectSpawns,        0x805c6b4c

# Registers:
# - r9: state address (high halfword)
# - r10: state value
# - r11: game mode address (high halfword)
# - r12: game mode value (high halfword)
# - r13: game mode value (low halfword)

  lis r9, state@h                          # \ Read code state
  lbz r10, state@l (r9)                    # /

# Input check: Activate when the button combo is pressed and then don't activate
# again until the button combo is released. This avoids rapidly activating when
# the button combo is held.

  lis r3, input@h                          # \ Read Classic Controller input
  lhz r3, input@l (r3)                     # /
  cmplwi r3, buttonCombo                   # \ if Select + X is not pressed:
  beq pressed                              # |   Clear pressed bit
  andi. r10, r10, ~pressedBit@l            # |
  b activation                             # /
pressed:
  andi. r0, r10, pressedBit                # \ if Select + X is pressed
  bgt activation                           # | and pressed bit is cleared:
  ori r10, r10, pressedBit | activatedBit  # /   Set pressed and activated bits

# Activation: When the activated bit is set, a respawn will be triggered when it
# is safe to do so.
#
# There is one main "game mode" value in memory that controls the execution of
# normal gameplay, menus, or other functions, including respawning. There are
# some secondary values that represent the current state of certain menus.
#
# The game allows respawning any time after starting a new game (e.g., during
# stage select or boss intros). With MM9, there were some edge cases where
# respawning crashes the game. I'm assuming this is the same for MM10. The
# safest spots to respawn are the black screens when transitioning between
# gameplay and menus. This code opens and closes menus as necessary.

activation:
  andi. r0, r10, activatedBit              # \ if not activated:
  beq end                                  # /   Do nothing
  lis r11, gameMode@h                      # \ Read game mode
  lhz r12, gameMode@l (r11)                # |
  lhz r13, gameMode@l+0x0002 (r11)         # /
  cmplwi r12, 0x0009                       # \ if first stage fade-in frame:
  beq deactivate                           # /   Deactivate
  cmplwi r12, 0x000a                       # \ if normal gameplay:
  beq openWeaponMenu                       # /   Open weapon menu
  cmplwi r12, 0x000b                       # \ if fade out gameplay to menu:
  beq forceWeaponMenu                      # /   Force weapon menu to open
  cmplwi r12, 0x000c                       # \ if fade in gameplay from menu:
  beq checkFadeMode                        # /   Need to check low halfword of game mode
  cmplwi r12, 0x0100                       # \ if fade in weapon menu from gameplay:
  beq respawn                              # /   Respawn
  cmplwi r12, 0x0101                       # \ if in weapon menu:
  beq checkWeaponMenuMode                  # /   Need to check weapon menu mode
  cmplwi r12, 0x0a01                       # \ if in challenge menu:
  beq deactivate                           # /   Deactivate
  cmplwi r12, 0x0c01                       # \ if in pause menu:
  beq checkPauseMenuMode                   # /   Need to check low halfword of game mode
  cmplwi r12, 0x1001                       # \ if in option menu:
  beq deactivate                           # /   Deactivate
  b end

checkFadeMode:
  andi. r0, r13, 0x00ff                    # \ if first black frame after closing menu:
  beq respawn                              # /   Respawn
  b end

checkPauseMenuMode:
  cmplwi r13, 0x0300                       # \ if pause menu active:
  beq closePauseMenu                       # /   Close pause menu
  cmplwi r13, 0x0303                       # \ if retry/exit confirmation active:
  beq closePauseMenu                       # /   Close pause menu
  b end
closePauseMenu:
  li r13, 0x0400                           # > Set game mode to close pause menu
  b writeGameMode

checkWeaponMenuMode:
  lis r3, weaponMenuMode@h+0x10000         # \ Read weapon menu mode
  lhz r5, weaponMenuMode@l-0x10000 (r3)    # / (optimization: one less instruction)
  cmplwi r5, 0x0101                        # \ if weapon menu active:
  bne end                                  # |   Set weapon menu mode to close
  li r5, 0x0200                            # |   the menu
  sth r5, weaponMenuMode@l-0x10000 (r3)    # /
  b end

# There is some weirdness with the pause menu where triggering a respawn on
# a specific frame (second frame when r12 == 0x0c00) causes the game to go to
# the stage select instead. It's because Gecko codes run in the middle of
# a pause menu routine for some reason, and the rest of the routine sets one
# byte of the game mode, changing it from 0x0008 to 0x0001 which is the stage
# select mode. The weapon menu doesn't have this problem.

forceWeaponMenu:
  cmplwi r13, 0x0101                       # \ if middle of fade from gameplay to pause menu:
  bne end                                  # |   Set mode to open weapon menu instead
  li r13, 0x0001                           # /
  b writeGameMode

openWeaponMenu:
  li r12, 0x000b                           # > Set game mode to open weapon menu
  b writeGameMode

respawn:
  li r12, 0x0007                           # > Set game mode to respawn at beginning of stage

deactivate:
  andi. r10, r10, ~activatedBit@l          # > Clear activated bit

writeGameMode:
  sth r12, gameMode@l (r11)                # \ Write new game mode
  sth r13, gameMode@l+0x0002 (r11)         # /

end:
  stb r10, state@l (r9)                    # > Write new code state
  blr
