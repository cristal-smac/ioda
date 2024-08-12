__includes ["../../IODA_3_0.nls"]


extensions [ioda]

breed [ants ant]
breed [foods food]
breed [nests nest]
breed [pheromones pheromone]

globals [pile1 pile2 pile3 minwho]

ants-own [speed carrying? motivation quality]
pheromones-own [ strength]
nests-own [ stock quality carriers ]

foods-own [quality]

to setup
  clear-all
  init-agents
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices matrix-file " \t()"
  ioda:setup
  ask ants [ioda:set-alive false]
  reset-ticks
end

to go
  if  (ticks < count ants)
    [ ask one-of ants with [ not ioda:alive? ] [ioda:set-alive true ]]
  ioda:go
  tick
end

to init-agents
  set-default-shape ants "ant"
  set-default-shape foods "tile stones"
  set-default-shape nests "target"
  set-default-shape pheromones "dot"
  ask patches with [(distancexy (0.6 * max-pxcor) 0) <= 5] [set pcolor red - 4]
  ask patches with [(distancexy (-0.6 * max-pxcor) (-0.6 * max-pycor)) <= 5] [set pcolor orange - 4]
  ask patches with [(distancexy (-0.8 * max-pxcor) (0.8 * max-pycor)) <= 5] [set pcolor yellow - 4]
  create-nests 1 [ init-nest ]
  create-foods food-qty [init-food]
  create-ants nb-ants [ init-ant ]
  set pile1 sum [count foods-here] of patches with [shade-of? pcolor red]
  set pile2 sum [count foods-here] of patches with [shade-of? pcolor orange]
  set pile3 sum [count foods-here] of patches with [shade-of? pcolor yellow]
  set minwho min [who] of ants
end

to init-food
  while
    [ not (((distancexy (0.6 * max-pxcor) 0) < 5)
      or ((distancexy (-0.6 * max-pxcor) (-0.6 * max-pycor)) < 5)
      or ((distancexy (-0.8 * max-pxcor) (0.8 * max-pycor)) < 5)) or (pcolor = black)]
    [setxy random-xcor random-ycor]
  ifelse (any? other foods in-radius 2)
    [ set quality (mean [quality] of other foods in-radius 2) + (random 5) - (random 5) ]
    [ set quality random 100 ]
  set color scale-color blue quality 0 100
 end

to init-nest
  set color gray
  setxy 0 0
  set size 2
  set stock 0
  set quality []
  set carriers []
end


to init-ant
  setxy 0 0
  set color brown
  set size 2
  set speed 1
  set carrying? false
end

to ants::filter-neighbors
  ;ioda:filter-neighbors-in-radius 5
  ioda:filter-neighbors-in-radius 2
  ioda:add-neighbors-in-cone 5 60
end

to-report foods::quality
  report quality
end

to init-model
  output-print ioda:get-interaction-matrix
  output-print ioda:get-update-matrix
  output-print ioda:matrix-view ioda:get-interaction-matrix
  output-print ioda:matrix-view ioda:get-update-matrix
  if (ioda:check-consistency) [print "CONSISTENT MODEL"]
end

to-report ants::can-take-load?
  report not carrying?
end

to-report pheromones::can-take-load?
  report strength + [strength] of ioda:my-target < 5
end

to foods::decrease-strength
end

to-report pheromones::strength
  report strength
end

to pheromones::decrease-strength
  set strength strength * (100 - evaporation-rate) / 100
  update-view
end

to update-view
  set color scale-color cyan strength 0.01 5
  set size sqrt strength
end

to init-pheromone [s]
  set color cyan
  set strength s
end

to pheromones::filter-neighbors
  ioda:filter-neighbors-in-radius 2
end

to-report pheromones::too-weak?
  report strength < 0.01
end

to ants::turn-back
  right 180
end

to nests::update-label
  set label stock
  if (not empty? quality)
    [ set-current-plot "Quality of food"
      foreach quality [ [?1] -> plotxy ticks ?1 ]
      set quality []]
end

to ants::drop-load
  let q quality
  let w who - minwho
  ask ioda:my-target
    [ set stock stock + 1
      set quality fput q quality
      set carriers fput w carriers ]
  set carrying? false
  set color brown
end

to ants::move-to-home
  face patch 0 0
  fd speed
end

to ants::drop-pheromone
  let m motivation
  hatch-pheromones 1 [ init-pheromone m ]
  set motivation motivation * 0.95
end

to pheromones::take-target
  set strength strength + [strength] of ioda:my-target
  update-view
end

to ants::steal-load
  let t ioda:my-target
  ask t [ set carrying? false set color brown ]
  set carrying? true set color green
  set quality [quality] of t
  right 180 fd 1
end

to ants::take-target
  set motivation 1
  set carrying? true
  set color red
  set quality [quality] of ioda:my-target
end

to-report ants::foraging?
  report not carrying?
end

to-report ants::carrying-food?
  report carrying?
end

to ants::follow-target
  face ioda:my-target
  fd speed
end


to foods::die
  let p [pcolor] of patch-here
  ifelse (shade-of? p red)  [ set pile1 pile1 - 1 ]
    [ ifelse (shade-of? p orange) [set pile2 pile2 - 1]
      [ if (shade-of? p yellow) [set pile3 pile3 - 1]]]
  ioda:die
end

to pheromones::die
  ioda:die
end

to ants::wiggle
  if (random 3 = 0) [ left random 45 right random 45 ]
  fd speed
end

to pheromones::wiggle
  set heading random 360
  fd diffusion-speed
end
@#$#@#$#@
GRAPHICS-WINDOW
366
10
871
516
-1
-1
7.0
1
10
1
1
1
0
1
1
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
170
17
236
50
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
268
17
331
50
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
7
112
177
145
evaporation-rate
evaporation-rate
0
20
5.0
1
1
%
HORIZONTAL

SLIDER
184
112
356
145
diffusion-speed
diffusion-speed
0
0.5
0.1
0.01
1
NIL
HORIZONTAL

PLOT
882
10
1378
262
Agents
ticks
nb
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"nest" 1.0 0 -7500403 true "" "plot sum [stock] of nests"
"pile1" 1.0 0 -2674135 true "" "plot pile1"
"pile2" 1.0 0 -955883 true "" "plot pile2"
"pile3" 1.0 0 -1184463 true "" "plot pile3"
"nb-pheromones" 1.0 0 -11221820 true "" "plot count pheromones"

SLIDER
6
72
178
105
nb-ants
nb-ants
0
300
100.0
1
1
NIL
HORIZONTAL

SLIDER
184
72
356
105
food-qty
food-qty
0
1000
500.0
1
1
NIL
HORIZONTAL

PLOT
7
149
357
328
Headings
angle/10
nb
0.0
36.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [round (heading / 10)] of ants"

PLOT
7
331
357
538
Quality of food
time
quality
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""

PLOT
882
266
1377
537
DropFood
who
# DropFood
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [carriers] of one-of nests"

CHOOSER
10
12
148
57
matrix-file
matrix-file
"matrix.txt" "matrix2.txt"
0

@#$#@#$#@
## WHAT IS IT?

This model is a IODA adaptation of the classical NetLogo "Ants" model. It demonstrates how to use pheromones as true agents (instead of defining a patch variable). This is the implementation of Section 6 of the [IODA NetLogo Tutorial](file:../../doc/IODA-NetLogo-Tutorial.html).

## HOW IT WORKS

The general behaviors of agents is described in the interaction matrix ("matrix.txt").   
When ants find food, they take one piece (with the highest quality if possible) and bring it back to the nest; meanwhile they deposit pheromones (which are agents). To return to food, they follow the pheromones with the highest strength. Pheromones can also interact one with another, especially they can merge, move and disappear.

## HOW TO USE IT

Just run **`setup`** and **`go`**. You also can change parameters to observe how the behaviors are affected.   
Several plots are provided :  

  * an histogram with the headings (/ 10) of the ants: when foraging paths are built, it can be easily observed on the histogram  
  * the quality of food over time  
  * the number of agents  
  * the histogram showing how many times each ant drops a piece of food in the nest: this diagram is used to compare the initial behaviors ("matrix.txt") with the extended behaviors ("matrix2.txt") - see "Things to try" below.

## THINGS TO TRY

You probably noticed that two interaction matrices are provided: in addition to the matrix described in the tutorial, you can try "matrix2.txt", which allows ants to steal food from other ants, instead of searching by themselves. This behavior induces an emergent task allocation, since ants which begin to steal food are more likely to steal food again because they encounter ants coming back from the food source, and conversely ants which find food and carry it to the nest are stolen by the others and go back to the food source.   
This strategy was described for autonomous foraging robots in:  
A. Drogoul and J. Ferber (1992). "From Tom Thumb to the Dockers: Some Experiments with Foraging Robots". In: J.-A. Meyer, H. Roitblat and S. Wilson (eds), _From Animals To Animats: Second Conference on Simulation of Adaptive Behavior (SAB 92)_, MIT Press.

## IODA NETLOGO FEATURES

  * the use of Target Selection Policies in order to make the ants take food pieces with the highest quality, or to follow pheromones with the highest strength  
  * the use of the `ioda:alive?` and `ioda:set-alive` primitives in the `go` procedure so as to "wake up" the ants one by one (like in the original "Ants" NetLogo model)

## RELATED MODELS

The "Ants" model in the NetLogo Library. See also the "pheromones" model of the IODA NetLogo Tutorial (previous section) for explanations about the Target Selection Policies.

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

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

sheep 2
false
0
Polygon -7500403 true true 209 183 194 198 179 198 164 183 164 174 149 183 89 183 74 168 59 198 44 198 29 185 43 151 28 121 44 91 59 80 89 80 164 95 194 80 254 65 269 80 284 125 269 140 239 125 224 153 209 168
Rectangle -7500403 true true 180 195 195 225
Rectangle -7500403 true true 45 195 60 225
Rectangle -16777216 true false 180 225 195 240
Rectangle -16777216 true false 45 225 60 240
Polygon -7500403 true true 245 60 250 72 240 78 225 63 230 51
Polygon -7500403 true true 25 72 40 80 42 98 22 91
Line -16777216 false 270 137 251 122
Line -16777216 false 266 90 254 90

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

wolf
false
0
Polygon -7500403 true true 75 225 97 249 112 252 122 252 114 242 102 241 89 224 94 181 64 113 46 119 31 150 32 164 61 204 57 242 85 266 91 271 101 271 96 257 89 257 70 242
Polygon -7500403 true true 216 73 219 56 229 42 237 66 226 71
Polygon -7500403 true true 181 106 213 69 226 62 257 70 260 89 285 110 272 124 234 116 218 134 209 150 204 163 192 178 169 185 154 189 129 189 89 180 69 166 63 113 124 110 160 111 170 104
Polygon -6459832 true true 252 143 242 141
Polygon -6459832 true true 254 136 232 137
Line -16777216 false 75 224 89 179
Line -16777216 false 80 159 89 179
Polygon -6459832 true true 262 138 234 149
Polygon -7500403 true true 50 121 36 119 24 123 14 128 6 143 8 165 8 181 7 197 4 233 23 201 28 184 30 169 28 153 48 145
Polygon -7500403 true true 171 181 178 263 187 277 197 273 202 267 187 260 186 236 194 167
Polygon -7500403 true true 187 163 195 240 214 260 222 256 222 248 212 245 205 230 205 155
Polygon -7500403 true true 223 75 226 58 245 44 244 68 233 73
Line -16777216 false 89 181 112 185
Line -16777216 false 31 150 47 118
Polygon -16777216 true false 235 90 250 91 255 99 248 98 244 92
Line -16777216 false 236 112 246 119
Polygon -16777216 true false 278 119 282 116 274 113
Line -16777216 false 189 201 203 161
Line -16777216 false 90 262 94 272
Line -16777216 false 110 246 119 252
Line -16777216 false 190 266 194 274
Line -16777216 false 218 251 219 257
Polygon -16777216 true false 230 67 228 54 222 62 224 72
Line -16777216 false 246 67 234 64
Line -16777216 false 229 45 235 68
Line -16777216 false 30 150 30 165

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
