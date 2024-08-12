__includes ["../../IODA_3_0.nls"]
extensions [ioda]

breed [missile-launchers missile-launcher]
breed [explorers explorer]
breed [bases base]
breed [obstacles obstacle]
breed [food-items food-item]
breed [missiles missile]
breed [halos halo]

globals [teams]
missile-launchers-own [team speed energy detection munitions last-missile destination]
explorers-own [team speed energy detection foraging-target bag]
bases-own [team energy detection food changed? memory ]
missiles-own [speed clock]

to setup
  clear-all
  init-world
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices "matrix.txt" " \t"
  ioda:setup
  reset-ticks
end

to init-world
  set-default-shape halos "thin ring"
  set-default-shape bases "target"
  set-default-shape missile-launchers "tank"
  set-default-shape explorers "heli"
  set-default-shape missiles "rocket"
  set-default-shape obstacles "tile stones"
  set-default-shape food-items "food"
  set teams [blue red yellow]
  (foreach teams (list (patch 0 22) (patch -16 -13) (patch 20 -11))
    [ [?1 ?2] -> create-bases 1
        [ move-to one-of patches with [distance ?2 < 6]
          init-base ?1 ] ])
  build-obstacles
  create-food-items nb-food [init-food]
end

to build-obstacles
  create-obstacles 20
    [ init-obstacle ]
  repeat nb-obstacles - 20
    [ let x obstacles with [any? neighbors4 with [not any? bases-here and not any? obstacles-here]]
      ask one-of x
        [ ask one-of neighbors4 with [not any? bases-here and not any? obstacles-here]
            [ sprout-obstacles 1 [ioda:init-agent set color gray]]
        ]
    ]
end

to init-obstacle
  ioda:init-agent
  move-to one-of patches with [not any? bases-here and not any? obstacles-here]
  set color gray
end

to init-food
  ioda:init-agent
  setxy random-xcor random-ycor
  while [any? obstacles-here]
    [ setxy random-xcor random-ycor ]
end

to init-base [ t ]
  ioda:init-agent
  set food 0
  set changed? true
  set memory []
  set size 2
  set energy 12000
  set detection 20
  set team t
  set color t
  let d detection
  hatch-halos 1 [create-link-with myself [hide-link tie] set size d * 2 + 1]
  hatch-explorers nb-explorers
    [ init-explorer t
      move-to one-of neighbors with [not any? obstacles-here]
      create-link-with myself [ set thickness 0.1 set color t hide-link ]]
  hatch-missile-launchers nb-missile-launchers
    [ init-missile-launcher t
      move-to one-of neighbors with [not any? obstacles-here]
      create-link-with myself [ set thickness 0.1 set color t hide-link ]]
end

to init-missile-launcher [ t ]
  ioda:init-agent
  set energy 4000
  set destination nobody
  set detection 8
  set speed 0.125
  set size 2
  set team t
  set color t
  set last-missile 0
  set munitions max-munitions
  let d detection
  hatch-halos 1 [create-link-with myself [hide-link tie] set size d * 2 + 1]
end

to init-missile
  ioda:init-agent
  set speed 1
  fd 0.5
  set size 0.8
  set clock 20
end

to init-explorer [ t ]
  ioda:init-agent
  set foraging-target nobody
  set bag 0
  set size 1.5
  set heading random 360
  set energy 1000
  set detection 13
  set speed 0.5
  set team t
  set color t
;  hatch-halos 1 [create-link-with myself [hide-link tie] set size 13]
end



to go
  ioda:go
  tick
  if (count bases <= 1) [stop]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report default::same-team?
  report team = [team] of ioda:my-target
end

to default::filter-neighbors
  ioda:filter-neighbors-in-radius detection
  ;ioda:set-my-neighbors remove-duplicates (sentence ioda:my-neighbors ([self] of link-neighbors))
  ioda:add-neighbors-on-links my-links
end

to default::advance
  if (can-move? speed) and (not any? obstacles-on patch-ahead speed)
    [ fd speed ]
end

to default::move-towards
  face ioda:my-target
  default::advance
end

to default::damage
  set energy energy - 1000
end

to-report default::fatal-energy-level?
  report energy <= 0
end

to-report default::danger?
  let t ioda:my-target
  if ([breed] of t = obstacles) [ report true ]
  ifelse (([breed] of t != missiles) and  ([team] of t = team))
    [ report false ]
    [ let d distance t
      if (d = 0) [ report true ]
      let ddx [dx] of t
      let ddy [dy] of t
      let x [xcor] of t
      let y [ycor] of t
      let cosinus (ddx * (xcor - x) + ddy * (ycor - y)) / d
      report cosinus > 0.9
    ]
end

to default::move-away
  face ioda:my-target
  right 180
  ifelse (random 2 = 0) [ left 10 + random 30 ] [ right 10 + random 30 ]
  default::advance
end





to explorers::filter-neighbors
  default::filter-neighbors
end

to-report explorers::carrying?
  report bag > 0
end

to-report explorers::empty?
  report bag = 0
end

to-report explorers::full?
  report bag = max-bag
end

to-report explorers::same-team?
  report default::same-team?
end

to explorers::load
  set bag bag + 1
end

to explorers::unload
  set bag bag - 1
end

to explorers::move-towards
  if (foraging-target = nobody)
    [ set foraging-target ioda:my-target ]
  default::move-towards
end

to explorers::wiggle
  right random 45 left random 45
  default::advance
end

to explorers::damage
  default::damage
end

to-report explorers::fatal-energy-level?
  report default::fatal-energy-level?
end

to explorers::die
  ioda:die
end

to-report explorers::danger?
  report default::danger?
end

to explorers::move-away
  default::move-away
end




to bases::filter-neighbors
  default::filter-neighbors
end

to-report bases::ennemy-detected?
  report not empty? memory
end

to-report bases::same-team?
  report default::same-team?
end

to bases::send-position
  let t (turtle-set ioda:my-target)
  let tm length memory
  let tt count t
  ifelse (tm >= tt)
    [ set memory sublist memory 0 tt]
    [ while [ length memory < tt ]
        [ set memory (sentence memory sublist memory 0 min (list (tt - length memory) length memory ))]]
  foreach memory
    [ ?1 -> let p ?1
      let x min-one-of t [ioda:distance p]
      ask x [set destination p]
      set t t with [self != x]
    ]
  set memory []
end

to bases::memorize-positions
  set memory sort-by [ [?1 ?2] -> distance ?1 < distance ?2 ] (map [ ?1 -> [patch-here] of ?1 ] ioda:my-target)
end

to-report bases::ennemy?
  report [team] of ioda:my-target != team
end

to-report bases::changed?
  report changed?
end

to bases::load
  set food food + 1
  set changed? true
end

to bases::update-label
  set label food
  set changed? false
end

to bases::damage
  default::damage
end

to-report bases::fatal-energy-level?
  report default::fatal-energy-level?
end

to bases::die
  ask link-neighbors with [breed = halos] [die]
  ioda:die
end

to-report bases::available-munitions?
  report food > 5
end





to food-items::die
  ioda:die
end

to-report food-items::proximity
  report ifelse-value (self = [foraging-target] of ioda:my-target)
    [ 10000 ]
    [ 1000 - ioda:distance ioda:my-target ]
end





to missile-launchers::filter-neighbors
  default::filter-neighbors
end

to missile-launchers::wiggle
  right random 30 left random 30
  default::advance
end

to-report missile-launchers::ennemy?
  report ([breed] of ioda:my-target = obstacles) or (team != [color] of ioda:my-target)
end

to missile-launchers::damage
  default::damage
end

to missile-launchers::launch-missile
  face ioda:my-target
  set last-missile ticks
  set munitions munitions - 1
  hatch-missiles 1
    [ init-missile ]
end

to-report missile-launchers::fatal-energy-level?
  report default::fatal-energy-level?
end

to missile-launchers::die
  ask link-neighbors with [breed = halos] [die]
  ioda:die
end

to-report missile-launchers::ready-to-fire?
  report munitions > 0 and (ticks - last-missile > 3)
end

to-report missile-launchers::danger?
  report default::danger?
end

to missile-launchers::move-away
  default::move-away
end

to-report missile-launchers::high-munitions?
  report munitions >= max-munitions / 2
end

to-report missile-launchers::low-munitions?
  report munitions < 3
end


to missile-launchers::load-munitions
  ask ioda:my-target [ set food food - 1 ]
  set munitions munitions + 1
end

to missile-launchers::move-towards
  default::move-towards
end

to-report missile-launchers::has-a-destination?
  report destination != nobody
end

to missile-launchers::move-to-place
  ifelse (patch-here = destination)
    [ set destination nobody ]
    [ face destination
      default::advance
    ]
end






to missiles::filter-neighbors
  let p patch-ahead speed
  ioda:set-my-neighbors filter [ ?1 -> [patch-here] of ?1 = p ] ioda:my-neighbors
end

to-report missiles::timeout?
  report clock <= 0
end

to missiles::count-down
  set clock clock - 1
end

to missiles::die
  ioda:die
end

to missiles::damage
  ioda:die
end

to missiles::move-forward
  fd speed
end





to obstacles::damage
  ioda:die
end




@#$#@#$#@
GRAPHICS-WINDOW
482
10
1200
729
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-35
35
-35
35
1
1
1
ticks
60.0

BUTTON
14
19
80
52
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
88
19
151
52
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

SLIDER
297
140
469
173
nb-food
nb-food
0
1000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
21
70
251
103
nb-explorers
nb-explorers
0
10
6.0
1
1
per team
HORIZONTAL

SLIDER
21
120
249
153
nb-missile-launchers
nb-missile-launchers
0
5
4.0
1
1
per team
HORIZONTAL

SLIDER
297
102
469
135
nb-obstacles
nb-obstacles
20
1000
32.0
1
1
NIL
HORIZONTAL

SLIDER
297
18
469
51
max-munitions
max-munitions
0
500
300.0
1
1
NIL
HORIZONTAL

BUTTON
160
19
268
52
toggle halos
ask halos [set hidden? not hidden?]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
297
61
469
94
max-bag
max-bag
0
50
10.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model provides basic agents and behaviors for the "Warbot" simulations, aimed at testing strategies in robot teams competitions. This version is freely inspired from the original Warbot game (http://www.warbot.fr) proposed by Jacques Ferber. It can be used to test and compare various AI techniques.

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

airplane 2
true
0
Polygon -7500403 true true 150 26 135 30 120 60 120 90 18 105 15 135 120 150 120 165 135 210 135 225 150 285 165 225 165 210 180 165 180 150 285 135 282 105 180 90 180 60 165 30
Line -7500403 false 120 30 180 30
Polygon -7500403 true true 105 255 120 240 180 240 195 255 180 270 120 270

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

food
false
0
Polygon -7500403 true true 30 105 45 255 105 255 120 105
Rectangle -7500403 true true 15 90 135 105
Polygon -7500403 true true 75 90 105 15 120 15 90 90
Polygon -7500403 true true 135 225 150 240 195 255 225 255 270 240 285 225 150 225
Polygon -7500403 true true 135 180 150 165 195 150 225 150 270 165 285 180 150 180
Rectangle -7500403 true true 135 195 285 210

heli
false
0
Polygon -7500403 true true 85 68 51 94 45 106 33 122 43 174 63 218 99 232 141 236 191 204 237 160 273 134 281 110 285 52 285 22 283 14 259 20 257 36 243 68 227 100 201 116 159 88 117 70
Polygon -11221820 true false 63 118 57 132 73 198 121 218 143 178 125 124 63 118
Polygon -1 true false 85 34 43 54 25 68 7 84 47 106 115 112 167 104 213 70 191 44 151 18 67 24 19 66 25 78
Polygon -1 true false 29 78 75 88
Polygon -1 true false 75 88 139 68
Rectangle -1 true false 21 60 57 70
Rectangle -1 true false 29 46 69 78
Rectangle -1 true false 61 38 83 44
Rectangle -1 true false 53 32 93 52
Rectangle -1 true false 25 68 37 74
Polygon -1 true false 67 24 31 44 11 82 45 82
Line -16777216 false 97 40 59 58
Line -16777216 false 49 70 67 84
Line -16777216 false 117 84 157 68
Line -16777216 false 129 42 147 52
Line -16777216 false 97 62 107 56
Line -16777216 false 105 66 117 60
Polygon -1 true false 271 28 251 44 243 56 247 72 267 90 287 72 291 54 291 36 271 28
Polygon -1 true false 271 82 283 80 291 70 291 56 277 50
Line -16777216 false 255 54 269 42
Line -16777216 false 271 72 281 62
Line -16777216 false 267 56 271 60
Line -16777216 false 259 62 267 66
Line -16777216 false 275 46 281 52

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

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

rocket
true
0
Polygon -7500403 true true 120 165 75 285 135 255 165 255 225 285 180 165
Polygon -1 true false 135 285 105 135 105 105 120 45 135 15 150 0 165 15 180 45 195 105 195 135 165 285
Rectangle -7500403 true true 147 176 153 288
Polygon -7500403 true true 120 45 180 45 165 15 150 0 135 15
Line -7500403 true 105 105 135 120
Line -7500403 true 135 120 165 120
Line -7500403 true 165 120 195 105
Line -7500403 true 105 135 135 150
Line -7500403 true 135 150 165 150
Line -7500403 true 165 150 195 135

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

tank
true
0
Rectangle -7500403 true true 144 0 159 105
Rectangle -6459832 true false 195 45 255 255
Rectangle -16777216 false false 195 45 255 255
Rectangle -6459832 true false 45 45 105 255
Rectangle -16777216 false false 45 45 105 255
Line -16777216 false 45 75 255 75
Line -16777216 false 45 105 255 105
Line -16777216 false 45 60 255 60
Line -16777216 false 45 240 255 240
Line -16777216 false 45 225 255 225
Line -16777216 false 45 195 255 195
Line -16777216 false 45 150 255 150
Polygon -7500403 true true 90 60 60 90 60 240 120 255 180 255 240 240 240 90 210 60
Rectangle -16777216 false false 135 105 165 120
Polygon -16777216 false false 135 120 105 135 101 181 120 225 149 234 180 225 199 182 195 135 165 120
Polygon -16777216 false false 240 90 210 60 211 246 240 240
Polygon -16777216 false false 60 90 90 60 89 246 60 240
Polygon -16777216 false false 89 247 116 254 183 255 211 246 211 237 89 236
Rectangle -16777216 false false 90 60 210 90
Rectangle -16777216 false false 143 0 158 105

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

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

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
