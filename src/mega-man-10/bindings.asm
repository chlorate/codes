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

.set mode, 0x805336e8

.set bindings, 0x802e7754
.set downIndex, 0x0006
.set yIndex, 0x0012
.set bIndex, 0x0016
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
  lis r7, mode@h                  # \ if game mode is normal gameplay:
  lhz r7, mode@l (r7)             # |   Unbind Weapon Swap L from L
  cmpwi r7, 0x000a                # |
  bne bind                        # |
  andi. r0, r0, ~l@l              # |
  b end                           # /
bind:                             # \ else:
  ori r0, r0, l                   # /   Bind Weapon Swap L to L
end:
  sth r0, bindings@l+lIndex (r5)  # > Write Weapon Swap L bindings
  blr

# Unbind Weapon Swap R
  lis r5, bindings@h              # \ Read Weapon Swap R bindings
  lhz r0, bindings@l+rIndex (r5)  # /
  lis r7, mode@h                  # \ if game mode is normal gameplay:
  lhz r7, mode@l (r7)             # |   Unbind Weapon Swap R from R
  cmpwi r7, 0x000a                # |
  bne bind                        # |
  andi. r0, r0, ~r@l              # |
  b end                           # /
bind:                             # \ else:
  ori r0, r0, r                   # /   Bind Weapon Swap R to R
end:
  sth r0, bindings@l+rIndex (r5)  # > Write Weapon Swap R bindings
  blr

# Bind Weapon Swap L to X
lis r3, bindings@h
lhz r0, bindings@l+lIndex (r3)     # \
andi. r0, r0, ~l@l                 # | Unbind from L
ori r0, r0, x                      # | Bind to X
sth r0, bindings@l+lIndex (r3)     # /
lhz r0, bindings@l+bIndex (r3)     # \
andi. r0, r0, ~x@l                 # | Unbind X mirroring B
sth r0, bindings@l+bIndex (r3)     # /
blr

# Bind Weapon Swap L to A
lis r3, bindings@h
lhz r0, bindings@l+lIndex (r3)     # \
andi. r0, r0, ~l@l                 # | Unbind from L
ori r0, r0, a                      # | Bind to A
sth r0, bindings@l+lIndex (r3)     # /
lhz r0, bindings@l+yIndex (r3)     # \
andi. r0, r0, ~a@l                 # | Unbind A mirroring Y
sth r0, bindings@l+yIndex (r3)     # /
blr

# Bind Weapon Swap L to ZL
lis r3, bindings@h
lhz r0, bindings@l+lIndex (r3)     # \
andi. r0, r0, ~l@l                 # | Unbind from L
ori r0, r0, zl                     # | Bind to ZL
sth r0, bindings@l+lIndex (r3)     # /
blr

# Bind Weapon Swap R to X
lis r3, bindings@h
lhz r0, bindings@l+rIndex (r3)     # \
andi. r0, r0, ~r@l                 # | Unbind from R
ori r0, r0, x                      # | Bind to X
sth r0, bindings@l+rIndex (r3)     # /
lhz r0, bindings@l+bIndex (r3)     # \
andi. r0, r0, ~x@l                 # | Unbind X mirroring B
sth r0, bindings@l+bIndex (r3)     # /
blr

# Bind Weapon Swap R to A
lis r3, bindings@h
lhz r0, bindings@l+rIndex (r3)     # \
andi. r0, r0, ~r@l                 # | Unbind from R
ori r0, r0, a                      # | Bind to A
sth r0, bindings@l+rIndex (r3)     # /
lhz r0, bindings@l+yIndex (r3)     # \
andi. r0, r0, ~a@l                 # | Unbind A mirroring Y
sth r0, bindings@l+yIndex (r3)     # /
blr

# Bind Weapon Swap R to ZR
lis r3, bindings@h
lhz r0, bindings@l+rIndex (r3)     # \
andi. r0, r0, ~r@l                 # | Unbind from R
ori r0, r0, zr                     # | Bind to ZR
sth r0, bindings@l+rIndex (r3)     # /
blr
