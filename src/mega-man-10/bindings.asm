# Rebinding of the game's "virtual" controller. Instead of controller inputs
# being read directly from the controller, the game normalizes the hardware inputs
# to a virtual set of inputs:
#
# - Up, down, left, right
# - Shoot (Y/A or B/X depending on control type)
# - Jump (B/X or Y/A depending on control type)
# - Start, select, home
# - L, R (weapon swap and paging in weapons menu)
#
# There is a table in memory that maps hardware buttons to virtual buttons which
# allows the controls to be fully customized. Multiple hardware buttons can be
# mapped to a virtual button, as is the case normally with Y/A and B/X.
#
# The only issue is the weapon swap buttons are also used in the weapons menu to
# change pages. It makes changing pages awkward when binding weapon swaps to
# other buttons. To avoid this, the custom bindings are only applied during
# normal gameplay and the original bindings are restored elsewhere.
#
# Custom bindings are also applied during fade-in from either menu because
# otherwise the original bindings are triggered in addition to the custom ones
# (e.g., Weapon Swap L to X would trigger both jump and swap when buffering).

.set mode, 0x805336e8

.set bindings, 0x802e7754
.set downIndex, 0x0006
.set shootIndex, 0x0012  # Assuming control type 2: shoot is on Y and A
.set jumpIndex, 0x0016   # Assuming control type 2: jump is on B and X
.set rIndex, 0x0026
.set lIndex, 0x002a

.set a, 0x0010
.set x, 0x0008
.set l, 0x2000
.set r, 0x0200
.set zl, 0x0080
.set zr, 0x0004

# Unbind Weapon Swap L
  lis r5, bindings@h              # \ Read Weapon Swap L bindings
  lhz r0, bindings@l+lIndex (r5)  # /
  lis r7, mode@h                  # \ if game mode is not normal gameplay nor fade-in from menu:
  lhz r7, mode@l (r7)             # |
  cmpwi r7, 0x000a                # |
  beq unbind                      # |
  cmpwi r7, 0x000c                # |
  beq unbind                      # |
  ori r0, r0, l                   # | > Bind Weapon Swap L to L
  b end                           # /
unbind:                           # \ else:
  andi. r0, r0, ~l@l              # /   Unbind Weapon Swap L from L
end:
  sth r0, bindings@l+lIndex (r5)  # > Write Weapon Swap L bindings
  blr

# Unbind Weapon Swap R
  lis r5, bindings@h              # \ Read Weapon Swap R bindings
  lhz r0, bindings@l+rIndex (r5)  # /
  lis r7, mode@h                  # \ if game mode is not normal gameplay nor fade-in from menu:
  lhz r7, mode@l (r7)             # |
  cmpwi r7, 0x000a                # |
  beq unbind                      # |
  cmpwi r7, 0x000c                # |
  beq unbind                      # |
  ori r0, r0, r                   # | > Bind Weapon Swap R to R
  b end                           # /
unbind:                           # \ else:
  andi. r0, r0, ~r@l              # /   Unbind Weapon Swap R from R
end:
  sth r0, bindings@l+rIndex (r5)  # > Write Weapon Swap R bindings
  blr

# Bind Weapon Swap L to X
  lis r5, bindings@h                  # \ Read Weapon Swap L and Jump bindings
  lhz r0, bindings@l+lIndex (r5)      # |
  lhz r3, bindings@l+jumpIndex (r5)   # /
  lis r7, mode@h                      # \ if game mode is not normal gameplay nor fade-in from menu:
  lhz r7, mode@l (r7)                 # |
  cmpwi r7, 0x000a                    # |
  beq bind                            # |
  cmpwi r7, 0x000c                    # |
  beq bind                            # |
  ori r0, r0, l                       # | > Bind Weapon Swap L to L
  andi. r0, r0, ~x@l                  # | > Unbind Weapon Swap L from X
  ori r3, r3, x                       # | > Bind Jump to X
  b end                               # /
bind:                                 # \ else:
  andi. r0, r0, ~l@l                  # | > Unbind Weapon Swap L from L
  ori r0, r0, x                       # | > Bind Weapon Swap L to X
  andi. r3, r3, ~x@l                  # / > Unbind Jump from X
end:
  sth r0, bindings@l+lIndex (r5)      # \ Write Weapon Swap L and Jump bindings
  sth r3, bindings@l+jumpIndex (r5)   # /
  blr

# Bind Weapon Swap L to A
  lis r5, bindings@h                  # \ Read Weapon Swap L and Shoot bindings
  lhz r0, bindings@l+lIndex (r5)      # |
  lhz r3, bindings@l+shootIndex (r5)  # /
  lis r7, mode@h                      # \ if game mode is not normal gameplay nor fade-in from menu:
  lhz r7, mode@l (r7)                 # |
  cmpwi r7, 0x000a                    # |
  beq bind                            # |
  cmpwi r7, 0x000c                    # |
  beq bind                            # |
  ori r0, r0, l                       # | > Bind Weapon Swap L to L
  andi. r0, r0, ~a@l                  # | > Unbind Weapon Swap L from A
  ori r3, r3, a                       # | > Bind Shoot to A
  b end                               # /
bind:                                 # \ else:
  andi. r0, r0, ~l@l                  # | > Unbind Weapon Swap L from L
  ori r0, r0, a                       # | > Bind Weapon Swap L to A
  andi. r3, r3, ~a@l                  # / > Unbind Shoot from A
end:
  sth r0, bindings@l+lIndex (r5)      # \ Write Weapon Swap L and Shoot bindings
  sth r3, bindings@l+shootIndex (r5)  # /
  blr

# Bind Weapon Swap L to ZL
  lis r5, bindings@h                  # \ Read Weapon Swap L bindings
  lhz r0, bindings@l+lIndex (r5)      # /
  lis r7, mode@h                      # \ if game mode is not normal gameplay nor fade-in from menu:
  lhz r7, mode@l (r7)                 # |
  cmpwi r7, 0x000a                    # |
  beq bind                            # |
  cmpwi r7, 0x000c                    # |
  beq bind                            # |
  ori r0, r0, l                       # | > Bind Weapon Swap L to L
  andi. r0, r0, ~zl@l                 # | > Unbind Weapon Swap L from ZL
  b end                               # /
bind:                                 # \ else:
  andi. r0, r0, ~l@l                  # | > Unbind Weapon Swap L from L
  ori r0, r0, zl                      # / > Bind Weapon Swap L to ZL
end:
  sth r0, bindings@l+lIndex (r5)      # > Write Weapon Swap L bindings
  blr

# Bind Weapon Swap R to X
  lis r5, bindings@h                  # \ Read Weapon Swap R and Jump bindings
  lhz r0, bindings@l+rIndex (r5)      # |
  lhz r3, bindings@l+jumpIndex (r5)   # /
  lis r7, mode@h                      # \ if game mode is not normal gameplay nor fade-in from menu:
  lhz r7, mode@l (r7)                 # |
  cmpwi r7, 0x000a                    # |
  beq bind                            # |
  cmpwi r7, 0x000c                    # |
  beq bind                            # |
  ori r0, r0, r                       # | > Bind Weapon Swap R to R
  andi. r0, r0, ~x@l                  # | > Unbind Weapon Swap R from X
  ori r3, r3, x                       # | > Bind Jump to X
  b end                               # /
bind:                                 # \ else:
  andi. r0, r0, ~r@l                  # | > Unbind Weapon Swap R from R
  ori r0, r0, x                       # | > Bind Weapon Swap R to X
  andi. r3, r3, ~x@l                  # / > Unbind Jump from X
end:
  sth r0, bindings@l+rIndex (r5)      # \ Write Weapon Swap R and Jump bindings
  sth r3, bindings@l+jumpIndex (r5)   # /
  blr

# Bind Weapon Swap R to A
  lis r5, bindings@h                  # \ Read Weapon Swap R and Shoot bindings
  lhz r0, bindings@l+rIndex (r5)      # |
  lhz r3, bindings@l+shootIndex (r5)  # /
  lis r7, mode@h                      # \ if game mode is not normal gameplay nor fade-in from menu:
  lhz r7, mode@l (r7)                 # |
  cmpwi r7, 0x000a                    # |
  beq bind                            # |
  cmpwi r7, 0x000c                    # |
  beq bind                            # |
  ori r0, r0, r                       # | > Bind Weapon Swap R to R
  andi. r0, r0, ~a@l                  # | > Unbind Weapon Swap R from A
  ori r3, r3, a                       # | > Bind Shoot to A
  b end                               # /
bind:                                 # \ else:
  andi. r0, r0, ~r@l                  # | > Unbind Weapon Swap R from R
  ori r0, r0, a                       # | > Bind Weapon Swap R to A
  andi. r3, r3, ~a@l                  # / > Unbind Shoot from A
end:
  sth r0, bindings@l+rIndex (r5)      # \ Write Weapon Swap R and Shoot bindings
  sth r3, bindings@l+shootIndex (r5)  # /
  blr

# Bind Weapon Swap R to ZR
  lis r5, bindings@h                  # \ Read Weapon Swap R bindings
  lhz r0, bindings@l+rIndex (r5)      # /
  lis r7, mode@h                      # \ if game mode is not normal gameplay nor fade-in from menu:
  lhz r7, mode@l (r7)                 # |
  cmpwi r7, 0x000a                    # |
  beq bind                            # |
  cmpwi r7, 0x000c                    # |
  beq bind                            # |
  ori r0, r0, r                       # | > Bind Weapon Swap R to R
  andi. r0, r0, ~zr@l                 # | > Unbind Weapon Swap R from ZR
  b end                               # /
bind:                                 # \ else:
  andi. r0, r0, ~r@l                  # | > Unbind Weapon Swap R from R
  ori r0, r0, zr                      # / > Bind Weapon Swap R to ZR
end:
  sth r0, bindings@l+rIndex (r5)      # > Write Weapon Swap R bindings
  blr
