__includes ["../../IODA_3_0.nls"]
extensions [ioda]

breed [characters character]
breed [apples apple]
breed [keys key]
breed [remotes remote]
breed [doors door]
breed [walls wall]
breed [halos halo]

globals [finished?]
doors-own [state clock ]
characters-own [ bag explored ]

to setup
  clear-all
  init-world
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices experiment " \t"
  ioda:setup
  ioda:set-metric "Moore"
  reset-ticks
end


to go
  ioda:go
  tick
  if (finished?) [stop]
end


to init-world
  set finished? false
  set-default-shape characters "person"
  set-default-shape apples "apple"
  set-default-shape keys "key"
  set-default-shape remotes "computer server"
  set-default-shape doors "door-locked"
  set-default-shape walls "tile brick"
  set-default-shape halos "thin square"
  ask patches with [(abs pxcor = max-pxcor) or (abs pycor = max-pycor) or (pycor = 0 and pxcor != 0)]
    [ sprout-walls 1 [ init-wall ]]
    ask patch 0 0 [ sprout-doors 1 [ init-door ]]
  ask one-of patches with [ (abs pxcor < max-pxcor) and (abs pycor < max-pycor) and (pycor > 0) ]
    [ sprout-apples 1 [ init-apple ]]
  ask one-of patches with [ (abs pxcor < max-pxcor) and (abs pycor < max-pycor) and (pycor < 0) ]
    [ sprout-keys 1 [ init-key ]]
  ask one-of patches with [ (abs pxcor < max-pxcor) and (abs pycor < max-pycor) and (pycor < 0) and (not any? turtles-here) ]
    [ sprout-remotes 1 [ init-remote ]]
  ask one-of patches with [ (abs pxcor < max-pxcor) and (abs pycor < max-pycor) and (pycor < 0) and (not any? turtles-here) ]
    [ sprout-characters 1 [ init-character ]]
end

to init-character
  set heading 0
  set bag []
  set explored no-patches
  set color cyan
end

to init-remote
  set heading 0
  set color gray
end

to init-key
  set heading 0
  set color orange
end

to init-apple
  set heading 0
  set color lime
end

to init-door
  set state ifelse-value (lock-door) ["locked"] ["closed"]
  set color white
  set heading 0
  set clock -1
  update-shape
  if (experiment = "matrix2.txt")
    [ hatch-halos 1
        [ set color red
          set size 2 * door-radius + 1]
    ]
end

to update-shape
  set shape (word "door-" state)
end

to init-wall
  set color red - 4
  set heading 0
end


to characters::wiggle
  ifelse (not any? other turtles-on patch-ahead 1)
    [ move-to patch-ahead 1
      set explored (patch-set explored patch-here)]
    [ let ex explored
      let p neighbors with [(not any? other turtles-here) and (not member? self ex)]
      ifelse (any? p)
        [ face one-of p ]
        [ right random 180 left random 180 ]
    ]
  set pcolor black + 1
end

to characters::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here neighbors)
end

to characters::put-in-bag
  output-show (word "I'm taking " ioda:my-target)
  set bag fput (word [breed] of ioda:my-target) bag
end

to apples::die
  ioda:die
end

to keys::die
  ioda:die
end

to remotes::die
  ioda:die
end

to-report characters::owns-food?
  report member? "apples" bag
end

to characters::eat-food
  output-show "I'm eating the apple"
  set bag remove "apples" bag
  set finished? true
end

to-report doors::locked?
;  output-show (word ioda:my-target " is testing if I am locked")
  report state = "locked"
end

to-report characters::owns-key?
  report member? "keys" bag
end

to doors::unlock
  output-show "I'm being unlocked !"
  set state "closed"
  update-shape
end

to-report doors::closed?
;  output-show (word ioda:my-target " is testing if I am closed")
  report state = "closed"
end

to doors::open
  output-show "I'm now open!"
  set state "open"
  update-shape
end

to-report doors::open?
;  output-show (word ioda:my-target " is testing if I am open")
  report state = "open"
end

to characters::cross-target
  let x [xcor] of ioda:my-target
  let y [ycor] of ioda:my-target
  setxy (2 * x - xcor) (2 * y - ycor)
  output-show "I'm crossing the door !"
  set explored (patch-set explored ioda:patch-here-of ioda:my-target patch-here)
end

to-report characters::not-already-explored?
  report not member? (ioda:patch-here-of ioda:my-target) explored
end


to-report characters::owns-remote?
  report member? "remotes" bag
end

to-report doors::timeout?
  report clock = 0
end

to-report doors::timeleft?
  report clock > 0
end

to doors::filter-neighbors
  ioda:filter-neighbors-in-radius door-radius
end

to doors::startTimer
  set clock ifelse-value (state = "open") [ 20 ] [ 2 ]
end

to doors::lock
  output-show "Now I'm locked..."
  set state "locked"
  update-shape
end

to doors::close
  output-show "Now I'm closed..."
  set state "closed"
  update-shape
end

to doors::decrease-time
  set clock clock - 1
end

to-report keys::interesting?
  report experiment = "matrix.txt"
end

to-report remotes::interesting?
  report experiment = "matrix2.txt"
end

to-report apples::interesting?
  report true
end

to-report doors::interesting?
  report (state = "closed") or
    ((state = "locked") and
    ([(characters::owns-key? and experiment = "matrix.txt")
        or (characters::owns-remote? and experiment = "matrix2.txt")] of ioda:my-target))
end

to characters::move-towards
  let t ioda:my-target
  let p neighbors with [not any? other turtles-here]
  if (any? p)
    [ move-to min-one-of p [ioda:distance t]
      set explored (patch-set explored patch-here)
      set pcolor black + 1
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
482
10
915
444
-1
-1
25.0
1
10
1
1
1
0
0
0
1
-8
8
-8
8
1
1
1
ticks
5.0

BUTTON
155
26
221
59
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
234
27
297
60
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

OUTPUT
23
87
464
468
12

CHOOSER
3
10
141
55
experiment
experiment
"matrix.txt" "matrix2.txt"
0

SLIDER
332
47
458
80
door-radius
door-radius
0
5
2.0
1
1
NIL
HORIZONTAL

SWITCH
340
10
459
43
lock-door
lock-door
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model shows simple "arcade games"-like behaviors. The character is endowed to simple interactions which are hierarchized so as to make it search and eat the apple. Two experiments are provided: in the first one, the character has to unlock the door with a key; in the second one, the door unlocks and opens automatically when the character owns the remote. This transformation does not require much changes in the code, since the door is already considered as an "agent" in the first simulation, and not as a mere "object".

## HOW TO USE IT

  * Choose the experiment, then click on **`setup`**.  
  * Click on **`go`** and observe the behavior of the character.   
  * You can start either with a closed or a locked door, depending on the switch position.

## THINGS TO NOTICE

Depending on the experiment, the character may need different items to cross the door. Thus, it has to move towards required items (resp. the key in "matrix.txt" and the remote in "matrix2.txt") to take them. However, it has also been endowed with an "opportunistic" behavior: thus, in experiment "matrix.txt" for instance, if the character finds the remote, it will take it though this item is not required (just in case !).   
You can also try to change the initial state of the door from "locked" to "closed": thus, the character does not need the key or the remote any more, so it is likely to go straight to the door, unless it finds an item on the way.

## IODA NETLOGO FEATURES

The door is a true agent in both experiments, though it could be seen as a mere "artifact" or "resource" or "inanimate object" in the first experiment. This illustrates the interest of an homogeneous representation of all entities involved in the simulation, which is one of the main recommendations of the IODA methodology. Thus, the ability for an entity to perform or undergo actions or state changes only depends on the interaction matrix.

## HOW TO CITE

  * The **IODA methodology and simulation algorithms** (i.e. what is actually in use in this NetLogo extension):  
Y. KUBERA, P. MATHIEU and S. PICAULT (2011), "IODA: an interaction-oriented approach for multi-agent based simulations", in: _Journal of Autonomous Agents and Multi-Agent Systems (JAAMAS)_, vol. 23 (3), p. 303-343, Springer DOI: 10.1007/s10458-010-9164-z.  
  * The **key ideas** of the IODA methodology:  
P. MATHIEU and S. PICAULT (2005), "Towards an interaction-based design of behaviors", in: M.-P. Gleizes (ed.), _Proceedings of the The Third European Workshop on Multi-Agent Systems (EUMAS'2005)_.  
  * Do not forget to cite also **NetLogo** itself when you refer to the IODA NetLogo extension:  
U. WILENSKY (1999), NetLogo. http://ccl.northwestern.edu/netlogo Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## COPYRIGHT NOTICE

All contents &copy; 2008-2024 Sébastien PICAULT and Philippe MATHIEU  
Centre de Recherche en Informatique, Signal et Automatique de Lille (CRIStAL)
UMR CNRS 9189 -- Université de Lille (Sciences et Technologies)
Cité Scientifique, F-59655 Villeneuve d'Ascq Cedex, FRANCE.  
https://github.com/cristal-smac/ioda

![SMAC team](file:../../doc/images/small-smac.png) &nbsp;&nbsp;&nbsp;  ![CRIStAL](file:../../doc/images/small-cristal.png) &nbsp;&nbsp;&nbsp; ![CNRS](file:../../doc/images/small-cnrs.png) &nbsp;&nbsp;&nbsp;  ![Université de Lille](file:../../doc/images/small-UL.png)

The IODA NetLogo extension is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

IODA NetLogo extension is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with the IODA NetLogo extension. If not, see http://www.gnu.org/licenses.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

apple
false
0
Polygon -7500403 true true 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

computer server
false
0
Rectangle -7500403 true true 75 30 225 270
Line -16777216 false 210 30 210 195
Line -16777216 false 90 30 90 195
Line -16777216 false 90 195 210 195
Rectangle -10899396 true false 184 34 200 40
Rectangle -10899396 true false 184 47 200 53
Rectangle -10899396 true false 184 63 200 69
Line -16777216 false 90 210 90 255
Line -16777216 false 105 210 105 255
Line -16777216 false 120 210 120 255
Line -16777216 false 135 210 135 255
Line -16777216 false 165 210 165 255
Line -16777216 false 180 210 180 255
Line -16777216 false 195 210 195 255
Line -16777216 false 210 210 210 255
Rectangle -7500403 true true 84 232 219 236
Rectangle -16777216 false false 101 172 112 184

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

door-closed
false
0
Rectangle -7500403 true true 0 135 255 165
Circle -7500403 true true 234 129 42
Rectangle -7500403 true true 255 135 300 165
Circle -7500403 true true -21 129 42

door-locked
false
0
Rectangle -7500403 true true 0 135 255 165
Circle -7500403 true true 234 129 42
Rectangle -7500403 true true 255 135 300 165
Circle -7500403 true true -21 129 42
Rectangle -2674135 true false 195 135 300 165

door-open
false
0
Circle -7500403 true true 234 129 42
Rectangle -7500403 true true 255 135 300 165
Circle -7500403 true true -21 129 42
Polygon -7500403 true true 15 165 150 15 135 0 0 135 15 165

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

key
false
0
Rectangle -7500403 true true 90 120 285 150
Rectangle -7500403 true true 255 135 285 195
Rectangle -7500403 true true 180 135 210 195
Circle -7500403 true true 0 60 150
Circle -16777216 true false 30 90 90

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

thin ring
true
0
Circle -7500403 false true -1 -1 301

thin square
false
0
Rectangle -7500403 false true 0 0 300 300

tile brick
false
0
Rectangle -1 true false 0 0 300 300
Rectangle -7500403 true true 15 225 150 285
Rectangle -7500403 true true 165 225 300 285
Rectangle -7500403 true true 75 150 210 210
Rectangle -7500403 true true 0 150 60 210
Rectangle -7500403 true true 225 150 300 210
Rectangle -7500403 true true 165 75 300 135
Rectangle -7500403 true true 15 75 150 135
Rectangle -7500403 true true 0 0 60 60
Rectangle -7500403 true true 225 0 300 60
Rectangle -7500403 true true 75 0 210 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
