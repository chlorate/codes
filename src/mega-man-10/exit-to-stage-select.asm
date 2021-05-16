.set codeState,    0x81000000
.set pressedBit,   0b00010000
.set activatedBit, 0b00100000
.set buttonCombo,  0b0001000000100000  # Select + Y

# WRXE addresses:
.set input,     0x804534ea
.set gameState, 0x805336e8
.set menuState, 0x80fb9000

.set stageSelectState, gameState + 0x1244
.set gameMode,         gameState + 0x22ff
.set weaponMenuState,  menuState + 0x0039

# Registers:
# - r9: code state address (high halfword)
# - r10: code state value
# - r11: game state address (high halfword)
# - r12: game state value (high halfword)
# - r13: game state value (low halfword)
# - r14: menu state address (high halfword)

  lis r11, gameState@h                     # \ Read game mode
  lbz r3, gameMode@l (r3)                  # /
  cmplwi r3, 0x0000                        # \ if not playing main game:
  bne end                                  # /   Do nothing

  lis r9, codeState@h                      # \ Read code state
  lbz r10, codeState@l (r9)                # /

  lis r3, input@h                          # \ Read Classic Controller input
  lhz r3, input@l (r3)                     # /
  cmplwi r3, buttonCombo                   # \ if Select + Y is not pressed:
  beq pressed                              # |   Clear pressed bit
  andi. r10, r10, ~pressedBit@l            # |
  b activation                             # /
pressed:
  andi. r0, r10, pressedBit                # \ if Select + Y is pressed
  bgt activation                           # | and pressed bit is cleared:
  ori r10, r10, pressedBit | activatedBit  # /   Set pressed and activated bits

activation:
  andi. r0, r10, activatedBit              # \ if not activated:
  beq writeCodeState                       # /   Do nothing
  lis r14, menuState@h+0x10000
  lhz r12, gameState@l (r11)               # \ Read game state
  lhz r13, gameState@l+0x0002 (r11)        # /
  cmplwi r12, 0x000a                       # \ if normal gameplay:
  beq openWeaponMenu                       # /   Open weapon menu
  cmplwi r12, 0x000b                       # \ if fade out gameplay to menu:
  beq openWeaponMenu                       # |   Force weapon menu to open (avoid seeing
                                           # /   one frame of pause menu fade in)
  cmplwi r12, 0x000c                       # \ if fade in gameplay from menu:
  beq checkFadeState                       # /   Need to check low halfword of game state
  cmplwi r12, 0x0101                       # \ if weapon menu:
  beq closeWeaponMenu                      # /   Close weapon menu
  cmplwi r12, 0x0200                       # \ if stage select:
  beq deactivate                           # /   Deactivate
  cmplwi r12, 0x0401                       # \ if boss intro cutscene:
  beq endBossIntro                         # /   End cutscene
  cmplwi r12, 0x0601                       # \ if get weapon cutscene:
  beq endGetWeapon                         # /   End cutscene
  cmplwi r12, 0x0805                       # \ if game/save/load menu:
  beq checkGameMenus                       # /   Need to check low halfword of game state
  cmplwi r12, 0x0a01                       # \ if in challenge menu:
  beq deactivate                           # /   Deactivate
  cmplwi r12, 0x0c00                       # \ if initializing pause menu:
  beq writeCodeState                       # |   Do nothing (triggering now would go to
                                           # /   stage select instead)
  cmplwi r12, 0x0c01                       # \ if pause menu:
  beq closePauseMenu                       # /   Close pause menu
  cmplwi r12, 0x1001                       # \ if options menu:
  beq deactivate                           # /   Deactivate
  b exitToStageSelect

checkFadeState:
  andi. r0, r13, 0x00ff                    # \ if first black frame after closing menu:
  beq exitToStageSelect                    # /   Exit to stage select
  b openWeaponMenu

checkGameMenus:
  li r5, 0x000c                            # \ if game menu via game over:
  li r7, 0x000b                            # |   Try closing game menu
  cmplwi r13, 0x0000                       # |
  beq closeGameMenu                        # /
  li r5, 0x000a                            # \ if game menu via stage select:
  li r7, 0x000a                            # |   Try closing game menu
  cmplwi r13, 0x0100                       # |
  beq closeGameMenu                        # /
  cmplwi r13, 0x0401                       # \ if load menu:
  beq deactivate                           # /   Deactivate
  cmplwi r13, 0x0601                       # \ if save menu:
  beq deactivate                           # /   Deactivate
  b writeCodeState

openWeaponMenu:
  li r12, 0x000b                           # \ Open weapon menu or switch to weapon menu
  andi. r13, r13, 0x00ff                   # / if any menu is currently opening
  b writeGameState

closeWeaponMenu:
  lbz r3, weaponMenuState@l-0x10000 (r14)
  cmplwi r3, 0x0002                        # \ if weapon menu not closing:
  beq writeCodeState                       # |   Close the menu
  li r3, 0x0200                            # |
  sth r3, weaponMenuState@l-0x10000 (r14)  # /
  b writeCodeState

closePauseMenu:
  li r13, 0x0400
  b writeGameState

closeGameMenu:
  # r5 = menu fade out state value
  # r7 = menu state value for closing the menu
  lbz r3, menuState@l-0x10000 (r14)
  cmplwi r3, 0x0000                        # \ if game menu is initializing:
  beq writeCodeState                       # /   Do nothing (goes to stage select otherwise)
  cmplw r3, r5                             # \ if fading out:
  beq writeCodeState                       # /   Do nothing (freezes game over menu otherwise)
  stb r7, menuState@l-0x10000 (r14)        # > Close game menu
  b writeCodeState

endBossIntro:
  li r13, 0x0900
  b writeGameState

endGetWeapon:
  li r13, 0x0600
  b writeGameState

exitToStageSelect:
  li r12, 0x0001                           # > Set game state to stage select

deactivate:
  andi. r10, r10, ~activatedBit@l          # > Clear activated bit

writeGameState:
  sth r12, gameState@l (r11)               # \ Write new game state
  sth r13, gameState@l+0x0002 (r11)        # /

writeCodeState:
  stb r10, codeState@l (r9)                # > Write new code state

end:
  blr
