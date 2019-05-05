# Time Attack weapons (Galaxy 3rd, Splash 7th)
.set concrete, 0x0201  # Buster, RC
.set magma,    0x0301  # Buster, CS, RC
.set galaxy,   0x0303  # Buster, MB, CS, RC
.set hornet,   0x030b  # Buster, MB, BHB, CS, RC
.set jewel,    0x030f  # Buster, MB, HC, BHB, CS, RC
.set plug,     0x071f  # Buster, MB, HC, BHB, JS, CS, RC, RJ
.set splash,   0x079f  # Buster, MB, HC, BHB, JS, PB, CS, RC, RJ
.set tornado,  0x07df  # Buster, MB, HC, BHB, JS, LT, PB, CS, RC, RJ

# Time Attack weapons (Galaxy 4th, Splash last)
.set concrete, 0x0201  # Buster, RC
.set magma,    0x0301  # Buster, CS, RC
.set hornet,   0x0303  # Buster, MB, CS, RC
.set galaxy,   0x0307  # Buster, MB, HC, CS, RC
.set jewel,    0x030f  # Buster, MB, HC, BHB, CS, RC
.set plug,     0x071f  # Buster, MB, HC, BHB, JS, CS, RC, RJ
.set tornado,  0x079f  # Buster, MB, HC, BHB, JS, PB, CS, RC, RJ
.set splash,   0x07bf  # Buster, MB, HC, BHB, JS, TB, PB, CS, RC, RJ

# Time Attack weapons (common code; use one of the sets of data above)
  li r0, magma          # \ if selected stage == Magma Man:
  lbz r4, 0x0002 (r31)  # |   Unlock certain weapons
  cmpwi r4, 0x0001      # |
  beq end               # /
  li r0, hornet         # \ if selected stage == Hornet Man:
  cmpwi r4, 0x0002      # |   Unlock certain weapons
  beq end               # /
  li r0, galaxy         # \ if selected stage == Galaxy Man:
  cmpwi r4, 0x0003      # |   Unlock certain weapons
  beq end               # /
  li r0, tornado        # \ if selected stage == Tornado Man:
  cmpwi r4, 0x0004      # |   Unlock certain weapons
  beq end               # /
  li r0, jewel          # \ if selected stage == Jewel Man:
  cmpwi r4, 0x0005      # |   Unlock certain weapons
  beq end               # /
  li r0, splash         # \ if selected stage == Splash Woman:
  cmpwi r4, 0x0006      # |   Unlock certain weapons
  beq end               # /
  li r0, plug           # \ if selected stage == Plug Man:
  cmpwi r4, 0x0007      # |   Unlock certain weapons
  beq end               # /
  li r0, concrete       # \ if selected stage == Concrete Man:
  cmpwi r4, 0x0008      # |   Unlock certain weapons
  beq end               # /
  li r0, 0x07ff         # > else: Unlock all weapons
end:
