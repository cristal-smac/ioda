__includes ["../../IODA_3_0.nls"]

extensions [ioda]

breed [ azures azure ]
breed [ gules gule ]
breed [ silvers silver ]
breed [ golds gold ]

globals [ assignation-stack ]

to setup
  clear-all
  set assignation-stack []
  init-agents true
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices experiment " \t"
  ioda:setup
  reset-ticks
end


to filter-neighbors
  ioda:filter-neighbors-in-radius radius
end

to init-agents [exp-dependent?]
  ifelse exp-dependent? [
  ifelse (experiment = "spiral2.txt")
    [ set nb-white 25 ]
    [ ifelse (experiment = "emergent-drawing.txt") or (experiment = "emergent-drawing2.txt")
        or (experiment = "apoptotic.txt")
        [ set nb-white 25 set nb-blue 25 set nb-yellow 25 set nb-red 25 ]
        [ ifelse (experiment = "segregation.txt")
          [ set nb-white 75 set nb-blue 75 set nb-yellow 75 set nb-red 75 ]
          [ if (experiment = "DLA.txt")
              [ set nb-white 1 set nb-blue 250 set nb-yellow 0 set nb-red 0 ]]]]
  ] [ set nb-white 100 set nb-yellow 100 set nb-blue 100 set nb-red 100]
  set-default-shape turtles "circle"
  let x count patches
  while [ nb-blue + nb-red + nb-white + nb-yellow > x ]
    [ if (nb-blue > 0) [ set nb-blue nb-blue - 1]
      if (nb-red > 0) [ set nb-red nb-red - 1]
      if (nb-white > 0) [ set nb-white nb-white - 1]
      if (nb-yellow > 0) [ set nb-yellow nb-yellow - 1]
    ]
  (foreach (list nb-blue nb-red nb-white nb-yellow)
           (list azures gules silvers golds)
      [ [?1 ?2] ->
        ask n-of ?1 (patches with [not any? turtles-here])
        [ sprout 1 [ set breed ?2 run ioda:concrete-primitive self "init" ]]
      ])
end

to go
  ioda:set-metric metric
  ioda:go
  if (length ioda:performed-interactions = 0) [ stop ]
  tick
end

to-report empty-neighbor?
  report any? neighbors with [not any? turtles-here]
end

to infect
  if ioda:my-target != nobody [
    let b breed
    ask (turtle-set ioda:my-target)
    [ set breed b
      run ioda:concrete-primitive self "init" ]
  ]
end

to mimic-one
  let t ioda:my-target
  if (t != nobody) [
  let x ifelse-value (not is-list? t) [t] [one-of t]
  if (x != nobody)
    [ ask x [ioda:set-my-target myself infect]]
  ]
end

to become-blue
  set breed azures
  azures::init
end

to become-red
  set breed gules
  gules::init
end

to become-white
  set breed silvers
  silvers::init
end

to become-yellow
  set breed golds
  golds::init
end

to die-or-kill
  ifelse (random 2 = 0)
    [ ioda:die ]
    [ let t ioda:my-target
      if (t != nobody) [ ask (turtle-set t) [ ioda:die ]]
    ]
end

to move-to-neighbor
  let n neighbors with [not any? turtles-here]
  if any? n [ move-to one-of n ]
end

to clone-or-let-clone
  ifelse (random 2 = 0)
    [ run ioda:concrete-primitive self "clone"]
    [ let t ioda:my-target
      if (t != nobody)
        [ ask (turtle-set t) [ run ioda:concrete-primitive self "clone"]]
    ]
end

to clone
  let b breed
  let n (neighbors with [not any? turtles-here])
  if any? n
    [ ask one-of n
    [ sprout 1
        [ set breed b
          run ioda:concrete-primitive self "init"
          ioda:init-agent ] ]]
end

to reset-matrix
if user-yes-or-no? "Do you really want to clean the current matrix?"
  [ ioda:clear-matrices
    ioda:load-interactions "interactions.txt"
    clear-output
    set assignation-stack []
  ]
end


to-report interaction-names
  report map ioda:interaction-name ioda:get-interactions
end

to create-new-assignation
  let source one-of ["azures" "gules" "silvers" "golds"]
  let target one-of ["nobody" "azures" "gules" "silvers" "golds" "azures" "gules" "silvers" "golds"]
  let prio random 100
  let inter one-of interaction-names
  let tmp (list source inter prio)
  if (target != "nobody") [
    set tmp lput target tmp
    set tmp lput (0.5 + round (100 * random-float radius) / 100) tmp
    if (random 10 < 1) [
      let tsp one-of ["NUMBER:" "ALL"]
      if tsp = "NUMBER:"
        [ let card (list random 9 random 9)
          set tsp (word tsp min card "-" max card)
        ]
      set tmp lput tsp tmp
    ]
  ]
  output-print (word "Adding assignation:\n" tmp)
  set assignation-stack fput (ioda:assignation-from-list tmp) assignation-stack
  ioda:add-assignation ioda:get-interaction-matrix  first assignation-stack
end

to remove-randomly
  let a ioda:matrix-to-list ioda:get-interaction-matrix
  if (not empty? a)
    [ let choice one-of a
      output-print (word "Removing assignation\n" ioda:assignation-to-list choice)
      set assignation-stack remove choice assignation-stack
      ioda:remove-assignation ioda:get-interaction-matrix choice ]
end


to cancel-last
  if (not empty? assignation-stack)
    [ let choice first assignation-stack
      set assignation-stack but-first assignation-stack
      output-print (word "Removing assignation\n" ioda:assignation-to-list choice)
      ioda:remove-assignation ioda:get-interaction-matrix choice ]
end

to reset-agents
  ask turtles [die]
  clear-all-plots
  init-agents false
  ioda:load-interactions "interactions.txt"
  ioda:setup
  reset-ticks
end

to save-matrix
  ioda:save-matrices user-new-file true
end

to load-matrix
  ioda:clear-matrices
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices user-file " \t"
end

to read-matrix-from-input
  ioda:load-interactions "interactions.txt"
  carefully
    [ ioda:read-matrices "User input field" matrix-lines " \t" ]
    [ user-message error-message ]
end


to azures::init
  set color blue
end

to gules::init
  set color red
end

to silvers::init
  set color white
end

to golds::init
  set color yellow
end

to azures::clone
  clone
end

to gules::clone
  clone
end

to silvers::clone
  clone
end

to golds::clone
  clone
end

to-report azures::empty-neighbor?
  report empty-neighbor?
end

to-report gules::empty-neighbor?
  report empty-neighbor?
end

to-report silvers::empty-neighbor?
  report empty-neighbor?
end

to-report golds::empty-neighbor?
  report empty-neighbor?
end

to azures::move-to-neighbor
  move-to-neighbor
end

to gules::move-to-neighbor
  move-to-neighbor
end

to silvers::move-to-neighbor
  move-to-neighbor
end

to golds::move-to-neighbor
  move-to-neighbor
end

to azures::filter-neighbors
  filter-neighbors
end

to gules::filter-neighbors
  filter-neighbors
end

to silvers::filter-neighbors
  filter-neighbors
end

to golds::filter-neighbors
  filter-neighbors
end

to azures::infect
  infect
end

to gules::infect
 infect
end

to silvers::infect
  infect
end

to golds::infect
  infect
end

to azures::die
  ioda:die
end

to gules::die
 ioda:die
end

to silvers::die
  ioda:die
end

to golds::die
  ioda:die
end

to azures::mimic-one
  mimic-one
end

to gules::mimic-one
  mimic-one
end

to silvers::mimic-one
  mimic-one
end

to golds::mimic-one
  mimic-one
end

to golds::clone-or-let-clone
  clone-or-let-clone
end

to azures::clone-or-let-clone
  clone-or-let-clone
end

to gules::clone-or-let-clone
  clone-or-let-clone
end

to silvers::clone-or-let-clone
  clone-or-let-clone
end

to azures::die-or-kill
  die-or-kill
end

to silvers::die-or-kill
  die-or-kill
end

to golds::die-or-kill
  die-or-kill
end

to gules::die-or-kill
  die-or-kill
end

to golds::become-blue
  become-blue
end

to silvers::become-blue
  become-blue
end

to gules::become-blue
  become-blue
end

to azures::become-blue
end

to golds::become-red
  become-red
end

to silvers::become-red
  become-red
end

to azures::become-red
  become-red
end

to gules::become-red
end

to golds::become-white
  become-white
end

to azures::become-white
  become-white
end

to gules::become-white
  become-white
end

to silvers::become-white
end

to gules::become-yellow
  become-yellow
end

to silvers::become-yellow
  become-yellow
end

to azures::become-yellow
  become-yellow
end

to golds::become-yellow
end
@#$#@#$#@
GRAPHICS-WINDOW
423
10
860
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
120.0

BUTTON
244
49
326
147
setup
setup\noutput-print ioda:print-interaction-matrix
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
335
49
416
147
go
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

CHOOSER
8
49
231
94
experiment
experiment
"emergent-drawing.txt" "emergent-drawing2.txt" "spiral.txt" "spiral2.txt" "segregation.txt" "struggle.txt" "DLA.txt" "apoptotic.txt"
7

SLIDER
62
150
234
183
nb-blue
nb-blue
0
200
25.0
1
1
NIL
HORIZONTAL

SLIDER
62
185
234
218
nb-red
nb-red
0
200
25.0
1
1
NIL
HORIZONTAL

SLIDER
62
220
234
253
nb-yellow
nb-yellow
0
200
25.0
1
1
NIL
HORIZONTAL

SLIDER
62
255
234
288
nb-white
nb-white
0
200
25.0
1
1
NIL
HORIZONTAL

PLOT
5
292
415
478
Nb of interactions per tick
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot length ioda:performed-interactions"

BUTTON
245
150
326
183
add one
without-interruption [\n  let p (patches with [not any? turtles-here])\n  if (any? p) \n    [ ask one-of p \n      [ sprout-azures 1 [ azures::init ioda:init-agent ]\n      ]\n]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
245
185
326
218
add one
without-interruption [\n  let p (patches with [not any? turtles-here])\n  if (any? p) \n    [ ask one-of p \n      [ sprout-gules 1 [ gules::init ioda:init-agent ]\n      ]\n]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
245
220
326
253
add one
without-interruption [\n  let p (patches with [not any? turtles-here])\n  if (any? p) \n    [ ask one-of p \n      [ sprout-golds 1 [ golds::init ioda:init-agent ]\n      ]\n]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
245
255
326
288
add one
without-interruption [\n  let p (patches with [not any? turtles-here])\n  if (any? p) \n    [ ask one-of p \n      [ sprout-silvers 1 [ silvers::init ioda:init-agent ]\n      ]\n]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
8
102
232
147
metric
metric
"Euclidean" "Moore" "Von Neumann"
0

SLIDER
16
149
49
287
radius
radius
1
5
2.0
1
1
NIL
VERTICAL

BUTTON
334
150
417
183
kill all
ask azures [ioda:die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
334
185
416
218
kill all
ask gules [ioda:die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
335
221
415
254
kill all
ask golds [ioda:die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
335
256
415
289
kill all
ask silvers [ioda:die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
6
481
415
667
Populations
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
"Azure" 1.0 0 -13345367 true "" "plot count azures"
"Gules" 1.0 0 -2674135 true "" "plot count gules"
"Silver" 1.0 0 -7500403 true "" "plot count silvers"
"Gold" 1.0 0 -1184463 true "" "plot count golds"

OUTPUT
867
10
1312
472
12

BUTTON
549
550
685
583
view interaction matrix
output-print ioda:print-interaction-matrix
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
549
590
657
623
view-interactions
output-print ioda:print-interactions
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
672
589
756
622
clear output
clear-output
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
426
512
534
545
RESET MATRIX
reset-matrix
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
548
512
648
545
ADD RANDOM
create-new-assignation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
493
481
846
515
CUSTOM SIMULATION GENERATOR
18
15.0
1

BUTTON
427
628
657
666
RESET AGENTS
reset-agents
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
672
626
864
665
GO
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

BUTTON
761
550
864
583
save matrix
save-matrix
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
760
512
864
545
REMOVE ONE
remove-randomly
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
761
589
863
622
load matrix
load-matrix
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
87
10
402
54
PREDEFINED EXPERIMENTS
18
105.0
1

BUTTON
689
550
756
583
view last
foreach assignation-stack\n  [ [?1] -> output-print ?1 ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
656
512
755
545
CANCEL LAST
cancel-last 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
867
477
1312
665
matrix-lines
azures  CloneSource  10\nazures  ChangeToGold  20  azures  1 NUMBER:6-\nazures  KillTarget   15  gules  1  ALL\nazures  KillTarget   15  silvers  1  ALL\n
1
1
String

BUTTON
426
550
544
624
READ FROM INPUT
read-matrix-from-input\noutput-print ioda:print-interaction-matrix
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

@#$#@#$#@
## WHAT IS IT?

This model consists in generic entities, identified by their color, which can do exactly the same actions. They are endowed with "generic" interactions, such as `CloneSource`, `Wander`, `KillTarget`, etc.   
Though very abstract, this collection of entities and interactions is sufficient to produce interesting collective behaviors, such as spiral formation or segregation phenomena. Several interaction matrices are provided so as to demonstrate the great versatility of such a toolkit. It is a quite interesting playground to explore the basics of the Interaction-Oriented approach.

Besides, since version 2.3 this model also provides a "custom simulation generator" which relies upon the reflection capabilities of IODA models. In this generator, interactions can be randomly assigned to pairs of agents. Most of the time such random assignations do not provide any interesting behaviors, yet sometimes it leads suprising things. You can also remove assignations from the interaction matrix. In addition, you can manually add or remove lines in the interaction matrix so as to design your own experiments.

## HOW IT WORKS

Four kinds of agents (breeds) are defined in this model, named after the heraldic tinctures (blue=azure, red=gules, yellow=gold and white=silver). Their primitives are exactly the same: in practice, each concrete primitive (e.g. `gold::clone`) calls a "shared" procedure (e.g. `clone`). There is only one agent per patch. Generic behaviors are described through the "interactions.txt" file, such as moving, cloning the source or target agent, killing the source or target agent, replacing the target by a copy of the source ("infect"), etc.  
You can also use one of the three metrics defined in IODA NetLogo ("Euclidean", "Moore", or "Von Neumann").  
Several interaction matrices have been written, in order to show that such a simple setup is sufficient to produce interesting collective behaviors.

## HOW TO USE IT

### PREDEFINED EXPERIMENTS

First choose an experiment (see the "Table of contents") and click on **`setup`**. Some experiments automatically determine the number of agents, otherwise you can also change the amount of each color with the sliders. The **`add one`** buttons allow you to put new agents in the environment during the simulation, while the **`kill all`** removes all agents of the speficied color (the "go" button must be clicked once or already down). Additionnally, you can specify the metric you want to use and the perception radius of the agents (according to this metric).   
When you are ready, click on **`go`** and watch the result. The plot shows how many interactions are performed during one tick. The simulations stops when no interactions occur.

### CUSTOM SIMULATION GENERATOR

First resets the existing interaction matrix through the **`RESET MATRIX`** button (leads to a confirmation pop-up). Then you can click several times the **`ADD RANDOM`** button in order to add random assignations to the matrix. To test them, click **`RESET AGENTS`** then **`GO`**.
You can remove assignations either randomly (by clicking **`REMOVE ONE`**) or one by one in reversere addition order (**`CANCEL LAST`**): indeed, the system keeps each added assignation into a history so as to allow you to cancel each step.

You can also view the content of the interaction matrix, of the assignation history and the list of available interactions through the corresponding buttons.

At any time you can also save the matrix that you have built (for instance, but not necessarily, in the `user-defined` folder) or load another one.

Another way to modify the interactions matrix consists in using the input field (top right), where you can put matrix lines (fields separated by spaces or tabs), and then read them by clicking the **`READ FROM INPUT`** button (please note that this does not clear the existing matrix: lines are added or removed). You may start lines wy "`-`" in order to **remove assignations** e.g. from a randomly generated matrix.

Such an ability to generate simulations by combining agents and interactions can be used within an evolutionary algorithm, in order to "explore" the space of possible simulations, such as explained in the following publication:

  * F. GAILLARD, Y. KUBERA, P. MATHIEU, S. PICAULT (2009), "A reverse engineering form for Multi Agent Systems", in: A. Artikis, G. Picard and L. Vercouter (eds.), _Post-proceedings of the 9th International Workshop Engineering Societies in the Agents World (ESAW'08)_, revised selected papers. Lecture Notes in Computer Science vol.&nbsp;5485, p.&nbsp;137-153, Springer.


## PREDEFINED EXPERIMENTS: TABLE OF CONTENTS

  * Emergent drawing 1 & 2: Nice patterns appear, as the result of the cloning activity of the agents.  
  * Spiral 1 & 2: After a growing phase, agents gradually self-organize to form moving spirals, like in the Belousov-Zhabotinsky reaction (Belousov, 1959; Zhabotinsky, 1964) or excitable media. In the 2nd experiment, silver agents are used as destructive obstacles, so as to demonstrate the robustness of the spirals. Nevertheless, from time to time it happens that one color is completely destroyed, which breaks the spiral.  
  * Segregation: Agents decide to move if they dislike their neighbors. This leads to an emerging spatial clustering as demonstrated by Schelling (1978).  
  * Struggle: This is a kind of ecological competition where two species compete: on the one hand, the blue/white agents, and on the other hand the yellow/red agents. Silver and Gold agents are "aggressive", since they kill agents of the other species, and agents similar to them as well. On the contrary, Azure and Gules agents are "peaceful", but they cannot live if they are surrounded by two many Azure or Gules agents. The patterns that are obtained are more or less stable depending on the metric.   
  * DLA: a Diffusion Limited Aggregation model with one white seed, which aggregates blue agents.  
  * Apoptotic: In this model, Azure agents act like a nutritive substrate for other agents. They clone Silver agents, which themselves destroy Azure agents; they also clone Gules agents. Silver agents are not mobile, and cannot live with a too high density: thus agents surrounded by 8 neighbors die. Gules agents can be seen as "destroyers" which kill Silver agents, while Gold agents can be interpreted as "protectors" since they infect Silver agents and regulate their own population by killing one the other. This leads to hollow and growing white structures, in which yellow agents circulate, and which can be damaged when encountering a pack of red cells: when this occurs, there is a sudden growth of yellow cells which seems to "hunt" and destroy red cells. If blue agents are still present, they grow to occupy the empty space and build again the white structure. Very nice results with the Moore metric.  

## EXTENDING THE MODEL

The great diversity of phenomena that can be produced through this very simple set of agents and interactions is by itself interesting. Try to find out new emergent structures based on those replication/competition/creation/destruction mechanisms!

## THINGS TO NOTICE

The execution may take some time though the number of interactions actually performed is rather small: indeed, what takes time in the simulation is the evaluation, by each active agent, of the ability to perform interactions on perceived neighbors: thus, it grows with the density of agents, the number of interactions by breed, and the diversity of targets for each breed.

## IODA NETLOGO FEATURES

As a programming example, this model makes use of several items you may need:  

  * the number of interactions performed during each time step is the length of the list contained in the ioda:performed-interactions variable  
  * the specification of a metric through `ioda:set-metric`
  * the execution of a breed-dependent command through e.g. 


    run ioda:concrete-primitive self "init"

  * some IODA commands introduced since v. 2.3, such as `ioda:save-matrices`, `ioda:add-assignation`, `ioda:remove-assignation`

## RELATED MODELS

  * The Segregation model in the NetLogo Library.  
  * The B-Z Reaction model in the NetLogo Library.  
  * The Diffusion Limited Aggregation models in the NetLogo Library.

## CREDITS AND REFERENCES

  * Belousov, B.P. (1959). A periodic reaction and its mechanism. _Compilation of Abstracts on Radiation Medicine_, 147:145.  
  * Zhabotinsky, A.M. (1964). Periodic processes of malonic acid oxidation in a liquid phase. _Biofizika_ 9:306-311.  
  * Schelling, T. (1978). _Micromotives and Macrobehavior_. New York: Norton.

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
