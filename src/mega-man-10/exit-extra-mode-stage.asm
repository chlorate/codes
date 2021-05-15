.set state,        0x81000000
.set pressedBit,   0b00000100
.set activatedBit, 0b00001000
.set buttonCombo,  0b0011011000000000  # L + R + Start + Select

# WRXE addresses:
.set input,          0x804534ea
.set gameMode,       0x805336e8
.set gameType,       0x805359e7
.set weaponMenuMode, 0x80fb9039

# Registers:
# - r9: state address (high halfword)
# - r10: state value
# - r11: game mode address (high halfword)
# - r12: game mode value (high halfword)
# - r13: game mode value (low halfword)

  lis r3, gameType@h                       # \ Read game type
  lbz r3, gameType@l (r3)                  # /
  cmplwi r3, 0x0002                        # \ if playing main game:
  blt end                                  # /   Do nothing

  lis r9, state@h                          # \ Read code state
  lbz r10, state@l (r9)                    # /

  lis r3, input@h                          # \ Read Classic Controller input
  lhz r3, input@l (r3)                     # /
  cmplwi r3, buttonCombo                   # \ if L + R + Start + Select is not pressed:
  beq pressed                              # |   Clear pressed bit
  andi. r10, r10, ~pressedBit@l            # |
  b activation                             # /
pressed:
  andi. r0, r10, pressedBit                # \ if L + R + Start + Select is pressed
  bgt activation                           # | and pressed bit is cleared:
  ori r10, r10, pressedBit | activatedBit  # /   Set pressed and activated bits

activation:
  andi. r0, r10, activatedBit              # \ if not activated:
  beq writeState                           # /   Do nothing
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
  beq exit                                 # /   Exit to menu
  cmplwi r12, 0x0101                       # \ if in weapon menu:
  beq checkWeaponMenuMode                  # /   Need to check weapon menu mode
  cmplwi r12, 0x0a01                       # \ if in challenge menu:
  beq deactivate                           # /   Deactivate
  cmplwi r12, 0x0c01                       # \ if in pause menu:
  beq checkPauseMenuMode                   # /   Need to check low halfword of game mode
  cmplwi r12, 0x1001                       # \ if in option menu:
  beq deactivate                           # /   Deactivate
  b writeState

checkFadeMode:
  andi. r0, r13, 0x00ff                    # \ if first black frame after closing menu:
  beq exit                                 # /   Exit to menu
  b writeState

checkPauseMenuMode:
  cmplwi r13, 0x0300                       # \ if pause menu active:
  beq closePauseMenu                       # /   Close pause menu
  cmplwi r13, 0x0303                       # \ if retry/exit confirmation active:
  beq closePauseMenu                       # /   Close pause menu
  b writeState
closePauseMenu:
  li r13, 0x0400                           # > Set game mode to close pause menu
  b writeGameMode

checkWeaponMenuMode:
  lis r3, weaponMenuMode@h+0x10000         # \ Read weapon menu mode
  lhz r5, weaponMenuMode@l-0x10000 (r3)    # / (optimization: one less instruction)
  cmplwi r5, 0x0101                        # \ if weapon menu active:
  bne writeState                           # |   Set weapon menu mode to close
  li r5, 0x0200                            # |   the menu
  sth r5, weaponMenuMode@l-0x10000 (r3)    # /
  b writeState

forceWeaponMenu:
  cmplwi r13, 0x0101                       # \ if middle of fade from gameplay to pause menu:
  bne writeState                           # |   Set mode to open weapon menu instead
  li r13, 0x0001                           # /
  b writeGameMode

openWeaponMenu:
  li r12, 0x000b                           # > Set game mode to open weapon menu
  b writeGameMode

exit:
  li r12, 0x000e                           # > Set game mode to exit current mode

deactivate:
  andi. r10, r10, ~activatedBit@l          # > Clear activated bit

writeGameMode:
  sth r12, gameMode@l (r11)                # \ Write new game mode
  sth r13, gameMode@l+0x0002 (r11)         # /

writeState:
  stb r10, state@l (r9)                    # > Write new code state

end:
  blr
