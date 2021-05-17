# Shared code for managing changes to the game's state.
#
# "Game state" refers to a few bytes in memory that control what the game is
# currently doing. The most important value (gameState) directly controls
# whether normal gameplay, a menu, or a cutscene is running. The next byte
# (gameState + 1) often determines what gameplay/menu/cutscene routine will run
# on the next frame, such as fading in/out, accepting player input for menus, or
# restarting a stage. This secondary byte is sometimes located elsewhere in
# memory.
#
# "Game mode" refers to whether the main game is being played or one of the
# extra modes (Time Attack, Endless Attack, replays, or challenges).
#
# The soft reset, exit, and retry codes (Select combo codes) are based on
# changing the game state. For example, writing 0x001a at gameState instantly
# goes back to the title screen.
#
# For the most part, the game has no problem with this. However, with MM9, there
# were some specific edge cases where changing gameState would crash. I'm
# assuming this is the same for MM10.
#
# To avoid these crashes, the safest thing to do seems to be to only change the
# game state in between screen transitions (e.g., the black screen in between
# gameplay and menus). This involves opening or closing menus as necessary in
# order to get to a safe game state where it can be changed.
#
# As a secondary goal, fade out the current screen if possible just to look
# more like as if the functionality was actually built into the game.
#
# Rather than duplicating this logic in each Select code, this single code
# handles that logic in order to reduce code size. The Select codes write to
# a certain address, then this code manages changing the game state.
#
# The Select codes write a word containing the desired gameState value (low
# halfword) and some conditional bits that determine which game modes or screens
# the state change can occur on.

.set version, 'E'

.set codeState,      0x81000002
.set stageSelectBit, 0b0000000000000001
.set otherStatesBit, 0b0000000000000010

.if version == 'E'
  .set gameState,           0x805336e8
  .set menuState,           0x80fb9000 + 0x10000
  .set currentRefightKills, 0x80510661
  .set objectSpawns,        0x805c6b4c
.endif

.set stageSelectState,    gameState + 0x1244
.set gameMode,            gameState + 0x22ff
.set initialRefightKills, gameState + 0x2425
.set weaponMenuState,     menuState + 0x0039 - 0x10000

# Registers:
# - r9: code state address (high halfword)
# - r10: code state word
# - r11: game state address (high halfword)
# - r12: game state high halfword
# - r5: game state low halfword

  lis r9, codeState@h                  # \ Read code state
  lwz r10, codeState@l (r9)            # /
  cmplwi r10, 0x0000                   # \ Do nothing if not activated
  beq end                              # /

  lis r3, gameMode@h
  lbz r3, gameMode@l (r3)
  cmplwi r3, 0x0005                    # \ Never change game state during TA replay
  beq deactivate                       # /

  lis r11, gameState@h                 # \ Read game state
  lhz r12, gameState@l (r11)           # |
  lhz r5, gameState@l+0x0002 (r11)     # /
  cmplwi r12, 0x0009                   # \ Deactivate if first stage fade in frame to cancel codes
  beq deactivate                       # / activated during main menu
  cmplwi r12, 0x000a                   # > Check if normal gameplay
  beq openWeaponMenu
  cmplwi r12, 0x000b                   # \ Force weapon menu to open if fading from gameplay to
  beq openWeaponMenu                   # | menu (avoid one frame of pause menu visible when game
                                       # / state can be changed)
  cmplwi r12, 0x000c                   # > Check if fade in gameplay from menu
  beq checkFadeInGameplayState
  cmplwi r12, 0x0100                   # > Check if initializing weapon menu
  beq activate
  cmplwi r12, 0x0101                   # > Check if in weapon menu
  beq closeWeaponMenu
  cmplwi r12, 0x0200                   # > Check if in stage select
  beq closeStageSelect
  cmplwi r12, 0x0a01                   # > Check if in challenge menu
  beq deactivate
  cmplwi r12, 0x0c00                   # \ Do nothing if initializing pause menu (initialization
  beq end                              # | has side effect that overwrites game state after this
                                       # / code runs)
  cmplwi r12, 0x0c01                   # > Check if in pause menu
  beq closePauseMenu
  cmplwi r12, 0x1001                   # > Check if in options menu
  beq deactivate

  andis. r0, r10, otherStatesBit       # \ Do nothing (wait for game to proceed) if not activating
  beq end                              # / during other game states
  cmplwi r12, 0x0401                   # > Check if boss intro cutscene
  beq endBossIntro
  cmplwi r12, 0x0601                   # > Check if get weapon cutscene
  beq endGetWeapon
  cmplwi r12, 0x0805                   # > Check if game/save/load menu
  beq checkGameMenus
  b activate

checkFadeInGameplayState:
  andi. r0, r5, 0x00ff                 # > Check if first frame of black screen
  beq activate
  b openWeaponMenu

checkGameMenus:
  li r11, 0x000b
  li r12, 0x000c
  cmplwi r5, 0x0000                    # > Check if game menu via game over
  beq closeGameMenu
  li r11, 0x000a
  li r12, 0x000a
  cmplwi r5, 0x0100                    # > Check if game menu opened via stage select
  beq closeGameMenu
  cmplwi r5, 0x0401                    # > Check if load menu
  beq deactivate
  cmplwi r5, 0x0601                    # > Check if save menu
  beq deactivate
  b end

closeGameMenu:
  # r11 = menu state byte that will close the menu
  # r12 = menu state byte indicating that the menu is fading out
  lis r3, menuState@h
  lbz r5, menuState@l (r3)
  cmplwi r5, 0x0000                    # \ Do nothing if menu is initializing
  beq end                              # / (causes delayed fade out otherwise)
  cmplwi r5, r12                       # \ Do nothing if menu is fading out
  beq end                              # / (freezes game over menu otherwise)
  stb r11, menuState@l (r3)
  b end

closePauseMenu:
  li r5, 0x0400
  b writeGameStateWord

openWeaponMenu:
  li r12, 0x000b                       # \ Open weapon menu (oris) or switch to weapon menu (andi.)
  andi. r5, r5, 0x00ff                 # | if any menu is currently opening
  b writeGameStateWord                 # /

closeWeaponMenu:
  lis r3, menuState@h
  lhz r5, weaponMenuState@l (r3)
  andi. r5, r5, 0xff00                 # \ Do nothing if weapon menu is already closing
  cmplwi r5, 0x0200                    # |
  beq end                              # /
  li r5, 0x0200
  sth r5, weaponMenuState@l (r3)
  b end

closeStageSelect:
  andis. r0, r10, stageSelectBit       # \ Ignore if stage select condition bit is cleared
  beq deactivate                       # /
  li r3, 0x000a
  stb r3, stageSelectState@l (r11)
  b end

endBossIntro:
  li r5, 0x0900
  b writeGameStateWord

endGetWeapon:
  li r5, 0x0600
  b writeGameStateWord

writeGameStateWord:
  sth r5, gameState@l+0x0002 (r11)

writeGameStateHalf:
  sth r12, gameState@l (r11)
  b end

activate:
  sth r10, gameState@l (r11)           # > Write game state according to code state

  cmplwi r10, 0x0008                   # > Check if retrying checkpoint
  bne deactivate
  li r0, -0x0001                       # \ Set all stage object spawn bits
  lis r3, objectSpawns@h               # | (respawn energy pickups and destructible objects)
  ori r3, r3, objectSpawns@l           # |
  li r5, 0x007c                        # |
loopRespawnObjects:                    # |
  stwx r0, r3, r5                      # |
  subic. r5, r5, 0x0004                # |
  bge loopRespawnObjects               # /
  lis r3, currentRefightKills@h        # \ Save current boss refight kills so killed bosses don't
  lbz r3, currentRefightKills@l (r3)   # | respawn when retrying from checkpoint
  stb r3, initialRefightKills@l (r11)  # /

deactivate:
  lis r10, 0x0000                      # > Clear code state

writeCodeState:
  stw r10, codeState@l (r9)            # > Write new code state

end:
  blr
