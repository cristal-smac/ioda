__includes ["../../IODA_3_0.nls"]
extensions [ioda]

breed [keys key]
breed [doors door]
breed [walls wall]
breed [knights knight]
breed [princesses princess]
;breed [halos halo]

globals [finished? comment available-knights-names available-princesses-names nb-keys]

patches-own [ dijkstra-dist ]
;turtles-own [ known? ]
doors-own [ state state-visible? ]
knights-own [ name bag explored unlocked goals thoughts new-info exploring?]
princesses-own [name]

to setup
  clear-all
  set available-knights-names ["Marcel" "Don Quichotte" "Arthur" "Perceval"]
  set available-princesses-names ["Albertine" "Dulcinea" "Guinevere" "Blanchefleur"]
  init-world
  ask knights [set goals (list one-of princesses) output-show (word name ": My most noble desire is to rescue princess " [name] of first goals) ]
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices "matrix.txt" " \t"
  ioda:setup
  ioda:set-metric "Von Neumann"
  ask knights [knights::update-map]
  set nb-keys count keys
  reset-ticks
end


to go
  ioda:go
  tick
  if (show-interactions?)
    [ ask knights
        [ output-print (word name " performs " ioda:interaction-name first ioda:decision) ]
    ]
  if (finished?) [stop]
end

to init-world
  set comment ""
  set finished? false
  set-default-shape knights "personh"
  set-default-shape princesses "personf"
  set-default-shape keys "key2"
  set-default-shape doors "door-locked"
  set-default-shape walls "tile brick"
;  set-default-shape halos "thin square"
  read-environment experiment
  ask patches [ set pcolor ifelse-value (vision = "omniscient") [ white - 2 ] [ black ]]
  ask patches [set dijkstra-dist -1]
end

to-report name-color [c]
  foreach ["gray" "red" "blue" "yellow" "green" "black" ]
    [ ?1 -> let n ?1
      if (shade-of? c (read-from-string n))
        [ report n]
    ]
  report "colored"
end

to read-environment [ filename ]
  file-open filename
  set comment file-read-line
  let s read-from-string file-read-line ; list with width and height
  resize-world 0 (first s - 1)  (1 - last s) 0
  let x 0 let y 0
  while [(y >= min-pycor) and (not file-at-end?)]
    [ set x 0
      set s file-read-line
      while [(x <= max-pxcor) and (x < length s)]
        [ ask patch x y [ create-agent (item x s) ]
          set x x + 1 ]
      set y y - 1 ]
  file-close
  if (vision = "partial")
    [ ask patches with [not any? neighbors with [any? knights-here]] [ask turtles-here [hide-turtle]]]
  ask knights [show-turtle]
end

; W wall K knight P princess r, g, b, y keys (red, green, blue, yellows) R G B Y doors D door (not locked)
to create-agent [ char ]
  ifelse (char = "W")
    [ sprout-walls 1 [ init-wall ] ]
    [ ifelse (char = "D")
      [ sprout-doors 1 [ init-door gray ]]
      [ ifelse (char = "K")
        [ sprout-knights 1 [ init-knight ]]
        [ ifelse (char = "P")
          [ sprout-princesses 1 [ init-princess ]]
          [ ifelse (char = "B") or (char = "R") or (char = "G") or (char = "Y")
            [ sprout-doors 1 [ init-door item (position char "RGBY") [red green blue yellow]]]
            [ ifelse (char = "b") or (char = "r") or (char = "g") or (char = "y")
              [ sprout-keys 1 [ init-key item (position char "rgby") [red green blue yellow]]]
              [ ;;;;;; other agents ?
              ]
            ]
          ]
        ]
      ]
    ]
end



to-report get-comments
  report comment
end


; dijkstra algorithm -> shortest path to specified agents (turtle procedure)
; the immediate? flag indicates if the path is computed from only accessible
; patches or with possible ways through doors in unknown state
to propagate-dist [ ag-or-pset mykeys immediate? ]
  ask patches with [ not any? walls-here ]
    [ set dijkstra-dist -1 set plabel "" ]
  let p ifelse-value (is-agentset? ag-or-pset) [ ag-or-pset ] [(patch-set [patch-here] of (ag-or-pset with [ ioda:alive? ]))]
  ask p
    [ set dijkstra-dist 0
      if show-dijkstra? [ set plabel 0 ]
    ]
  let s 0
  while [ any? p ]
    [ set s s + 1
      let pp patch-set ([neighbors4 with [ (not obstacle-here? mykeys immediate?) and ((dijkstra-dist < 0) or (dijkstra-dist > s)) ]] of p)
      ask pp
        [ set dijkstra-dist s
          if show-dijkstra?
          [ set plabel dijkstra-dist ]
        ]
      set p pp ]
end

to-report obstacle-here? [mykeys immediate?]
  report (pcolor = black) or (any? walls-here) or (any? doors-here with
    [ ((state = "locked") and (state-visible?) and (not member? name-color color mykeys))
      or (immediate? and (not state-visible?)) ])
end

to-report known-agents-matching [ g ]
  report (turtles-on explored) with [ (breed != walls) and (basic-match self g)]
end

to-report path-to? [g mykeys immediate?]
  propagate-dist g mykeys immediate?
  let d [dijkstra-dist] of patch-here
  report any? neighbors4 with [ is-path? d mykeys immediate? ]
end

to-report is-path? [ threshold mykeys immediate? ]
  report (dijkstra-dist >= 0) and (dijkstra-dist < threshold) and (not any? walls-here) and
    (not any? doors-here with [((not state-visible?) and immediate?) or (state-visible? and (state = "locked") and (not member? name-color color mykeys))])
end

to-report direct-path-to? [ g mykeys ]
  report path-to? g mykeys true
end

to-report possible-path-to? [ g mykeys]
  report path-to? g mykeys false
end





to init-knight
  ifelse (empty? available-knights-names)
    [ set name [name] of one-of other knights ]
    [ set name first available-knights-names
      set available-knights-names but-first available-knights-names ]
  set exploring? false
  set heading 0
  set bag []
  set unlocked []
  set explored no-patches
  set new-info no-turtles
  set goals []
  set thoughts []
  set color blue
end

to init-princess
  ifelse (empty? available-princesses-names)
    [ set name [name] of one-of other princesses ]
    [ set name first available-princesses-names
      set available-princesses-names but-first available-princesses-names ]
  set heading 0
  set color pink
end

to init-key [ col ]
  set heading 0
  set color col
end

to init-door [ col ]
  set state ifelse-value (lock-doors? and col != gray) ["locked"] ["closed"]
  set state-visible? false
  set color col
  set heading 0
  doors::update-shape
end


to init-wall
  set color gray - 3
  set heading 0
end


to-report knights::target-nearby?
  report dijkstra-dist >= 0 and dijkstra-dist <= 4
end



to keys::die
  ioda:die
end

to-report keys::proximity
  let k (turtle-set ioda:my-target)
  let mykeys [bag] of ioda:my-target
  let x ifelse-value ([knights::optimistic?] of ioda:my-target)
    [ possible-path-to? k mykeys]
    [ direct-path-to? k mykeys]
;  ask ioda:my-target [propagate-dist (turtle-set myself) knights::pessimistic?]
  let m dijkstra-dist
  let n neighbors4 with [dijkstra-dist >= 0]
  if any? n
    [ set m min [dijkstra-dist] of n]
  if m < 0 [ report -10000]
  report (- m)
end

to-report keys::would-help-goal?
  let g [goals] of ioda:my-target
  if empty? g [ report false ]
  if (not is-agent? g)
    [ report false ]
  if ([breed] of g != doors)
    [ report false ]
  report [state-visible? and (color = [color] of myself)] of g
end



;to-report keys::goal-range
;  let g [goals] of ioda:my-target
;  report length g - position (list keys name-color color) g
;end



to-report doors::unknown-state?
  report not state-visible?
end

to doors::reveal-state
  ask ioda:my-target [ output-show (word "We shall have a look at " myself "...")]
  set state-visible? true
  output-show (word ioda:my-target " now knows my state: " state)
  ask ioda:my-target [ output-show (word "Now I know that this door is " [description] of myself ".")]
end

to doors::update-shape
  ifelse state-visible?
    [ set shape (word "door-" state) ]
    [ set shape "door-unknown" ]
end

to-report doors::locked?
;  output-show (word ioda:my-target " is testing if I am locked")
  report state = "locked"
end

to doors::unlock
  ask ioda:my-target [ output-show (word "I am unlocking " [description] of myself " with the " name-color [color] of myself " key.") ]
  output-show "Now I am unlocked !"
  set state "closed"
end

to-report doors::closed?
;  output-show (word ioda:my-target " is testing if I am closed")
  report state = "closed"
end

to doors::open
  ask ioda:my-target [ output-show (word "I am opening " [description] of myself ".")]
  output-show "Now I am open!"
  set state "open"
end

to-report doors::open?
;  output-show (word ioda:my-target " is testing if I am open")
  report state = "open"
end

to doors::lock
  output-show "Now I am locked..."
  set state "locked"
end

to doors::close
  output-show "Now I am closed..."
  set state "closed"
end

to-report doors::proximity
  let k (turtle-set ioda:my-target)
  let mykeys [bag] of ioda:my-target
  let x ifelse-value ([knights::optimistic?] of ioda:my-target)
    [ possible-path-to? k mykeys]
    [ direct-path-to? k mykeys]
;  ask ioda:my-target [propagate-dist (turtle-set myself) knights::pessimistic?]
  let m dijkstra-dist
  let n neighbors4 with [dijkstra-dist >= 0]
  if any? n
    [ set m min [dijkstra-dist] of n]
  if m < 0 [ report -10000]
  report (- m)
end

to-report doors::proximity-and-chances
  let exploration-bonus ifelse-value (any? neighbors4 with [pcolor = black]) [ 100 ] [ 0 ]
  report ifelse-value (state-visible? and
      (((state = "locked") and (member? name-color color [bag] of ioda:my-target)) or (state = "closed")))
    [ 1000 + doors::proximity + exploration-bonus ]
    [ ifelse-value (([knights::possible-path-to-goal?] of ioda:my-target) and (dijkstra-dist > 0))
        [ 1000 - dijkstra-dist ]
        [ doors::proximity + exploration-bonus ]
    ]
end

to-report doors::state-visible?
  report state-visible?
end

;to-report doors::goal-range
;  let g [goals] of ioda:my-target
;  report length g - position self g
;end

to doors::become-goal
  if (not state-visible?) or (state-visible? and state != "open")
  [ let d self
    ask ioda:my-target
    [ set goals fput d goals
      output-show (word "I shall try to open " [description] of d " " d "." )  ]
    if ((color != gray) and state-visible? and (not member? name-color color [bag] of ioda:my-target))
      [ let c color
        ask ioda:my-target
        [ set goals fput (list keys name-color c) goals
          output-show (word "Therefore I need the " name-color c " key.") ]
      ]
  ]
end

to doors::become-goal-if-rigid
  if (goals-ordering = "rigid") [ doors::become-goal ]
end

to keys::become-goal
  let c color
  ask ioda:my-target
    [ set goals fput (list keys name-color c) goals
      output-show (word "I think " [description] of myself " could be useful.") ]
 end



to knights::filter-neighbors
  if (vision = "partial")
    [ ioda:filter-neighbors-on-patches explored ]
end

to knights::put-in-bag
  output-show (word "I am taking " [description] of ioda:my-target ".")
;    ifelse-value (knights::target-matches-goal?) [" because I need it."] [ " because it might be useful."])
  set bag fput name-color [color] of ioda:my-target bag
end

to-report knights::target-matches-goal?
  if (empty? goals)
    [ report false ]
;  ifelse (goals-ordering = "rigid")
    ;[
      report basic-match ioda:my-target first goals
     ; ]
;    [ foreach goals
;        [ if basic-match ioda:my-target ?
;            [ report true ]
;        ]
;    report false
;    ]
end

; the specification of a goal can be either an agent, or a breed, or a list with the breed of the agent and its color
to-report basic-match [agent spec]
  ifelse is-agent? spec
    [ report agent = spec ]
    [ ifelse is-agentset? spec
        [ report member? agent spec ]
        [ report (member? agent first spec) and ([color] of agent = read-from-string last spec) ]
    ]
end

;to-report knights::no-path-to-target?
;  report not (knights::direct-path-to-target? or knights::possible-path-to-target?)
;end

;to-report knights::no-path-to-goal?
;  report not knights::path-to-goal?
;end

;to-report knights::near-target?
;  let t ioda:my-target
;  if t = nobody [ report false]
;  report any? neighbors4 with [ member? t turtles-here ]
;end

;to-report knights::path-to-target?
;
;end

to-report knights::direct-path-to-target?
  report direct-path-to? (turtle-set ioda:my-target) bag
end

to-report knights::possible-path-to-target?
  report possible-path-to? (turtle-set ioda:my-target) bag
end

;to-report knights::path-to-goal?
;  if (empty? goals) [ report false ]
;  let g known-agents-matching first goals
;  report path-to? g knights::pessimistic?
;end


to-report knights::shortest-path-free?
  let mykeys bag
  let immediate? knights::pessimistic?
  let d [dijkstra-dist] of patch-here
  report any? (neighbors4 with [ (is-path? d mykeys immediate?) and is-free? ]) with-min [dijkstra-dist]
end

to-report is-free?
  report (not any? walls-here) and (not any? doors-here with [(not state-visible?) or (state = "locked") or (state = "closed")])
end


to knights::choose-shortest-path
  let mykeys bag
  let immediate? knights::pessimistic?
  let d [dijkstra-dist] of patch-here
  face one-of (neighbors4 with [ is-path? d mykeys immediate?]) with-min [dijkstra-dist]
  ;    ]
end

to knights::remember-path-to-target
    let x ifelse-value (knights::optimistic?)
      [ knights::possible-path-to-target? ]
      [ knights::direct-path-to-target? ]
end

to-report knights::target-on-shortest-path?
  let n neighbors4 with [ (dijkstra-dist >= 0) and (not any? walls-here) ]
  if not any? n
    [ report false ]
  let m min [dijkstra-dist] of n
  report [dijkstra-dist] of ioda:my-target = m
end

to-report knights::possible-path-to-goal?
  if (empty? goals) [ report false ]
  let g first goals
  let t turtles with [ (pcolor != black) and (basic-match self g) ]
  ifelse any? t
    [ report possible-path-to? t bag]
    [ report false ]
end

to-report knights::direct-path-to-goal?
  if (empty? goals) [ report false ]
  let g first goals
  let t turtles with [ (pcolor != black) and (basic-match self g) ]
  ifelse any? t
    [ report direct-path-to? t bag]
    [ report false ]
end

;to-report knights::no-path-to-goal?
;  report not knights::possible-path-to-goal?
;end





to knights::succeed
  output-show "YES! NOW THE PRINCESS IS UNDER THE PROTECTION OF MY MIGHTY SWORD!"
end

to knights::end-game
  set finished? true
  let unused filter [ ?1 -> not member? ?1 unlocked ] bag
  if (not empty? unused)
    [ foreach unused
        [ ?1 -> output-show (word "I did not use the " ?1 " key...") ]
    ]
end

to knights::move-one-step
  fd 1
end

to knights::fail
  output-show "ALAS! ALAS! RESCUE THE PRINCESS I CANNOT!"
end

to-report knights::no-goal?
  report empty? goals
end

to-report knights::opportunistic?
  report plan-execution = "opportunistic"
end

to-report knights::same-in-bag?
  report member? ([color] of ioda:my-target) bag
end

to-report knights::already-goal?
  if (empty? goals)
    [ report false ]
  foreach goals
    [ ?1 -> if basic-match ioda:my-target ?1
      [ report true ]
    ]
  report false
end

to knights::remove-goal
  let g goals
  set goals remove-goal ioda:my-target goals
  if ((not empty? goals)  and (g != goals))
    [ output-show (word "Now the next goal is " first goals ".") ]
end

to-report remove-goal [ag specs]
  if empty? specs
    [ report []]
  ifelse (basic-match ag first specs)
    [ output-show (word "I have reached my goal: " first specs ".")
      report but-first specs ]
    [ report sentence (list first specs) remove-goal ag but-first specs]
end

to-report knights::optimistic?
  report mood = "optimistic"
end

to-report knights::pessimistic?
  report mood = "pessimistic"
end

to-report knights::owns-key?
  report member? name-color [color] of ioda:my-target bag
end

to knights::flush-memory
  set new-info no-turtles
end

to knights::update-map
  let mykeys bag
  let n (patch-set patch-here neighbors)
  if [not obstacle-here? mykeys true] of patch-ahead 1
    [ set n (patch-set n patch-ahead 2)]
  let known turtles-on explored
  set explored (patch-set explored  n)
  ask n [ set pcolor white - 2 ]
  ask turtles-on n [show-turtle]
  let current-new-info (other turtles-on n) with [ (breed != walls) and (not member? self known) ]
  set new-info (turtle-set new-info current-new-info)
  foreach [self] of current-new-info [ ?1 ->
    let ag ?1
    output-show (word "Look at this: " [description] of ag " " ag )
    if ([breed] of ag = doors) and ([not state-visible?] of ag) and (knights::pessimistic?)
      [ output-show (word "I am afraid " [description] of ag " is quite difficult to open.") ]
  ]

end

to knights::move-on-target
  move-to ioda:my-target
end

to-report knights::partial-vision?
  report vision = "partial"
end

to-report knights::omniscient?
  report vision = "omniscient"
end

to-report knights::exploration-path?
  let ex explored
  ask (patch-set ex [neighbors] of ex) [set dijkstra-dist -1]
  let p patches with [(pcolor = black  or not member? self ex) and
    any? neighbors4 with [ (member? self ex) and (not any? walls-here) ]]
  if (any? p)
;    [ propagate-dist p knights::pessimistic? ]
;  report any? neighbors4 with [dijkstra-dist >= 0]
    [ report direct-path-to? p bag]
  report false
end

to-report knights::no-exploration-nearby?
  if not knights::exploration-path?
    [ report true ]
  report dijkstra-dist > 1
end


to-report knights::no-more-exploration?
  report not knights::exploration-path?
end

to knights::remember-exploration-path
  let x knights::exploration-path?
  if (not exploring?)
    [ set exploring? true
      output-show "I have to dive into those dark abysses..."
    ]
end


to knights::sleep
  output-show "I have no quest before me..."
end

to-report knights::new-information?
  report any? new-info
end

to-report knights::flexible-goals?
  report goals-ordering = "flexible"
end

;to knights::add-new-goals
;  let k new-info with [breed = keys]
;  if any? k and knights::opportunistic?
;    [ set goals sentence [(list keys name-color color)] of k goals ]
;end

to knights::reorder-goals
  let gl goals
  foreach goals
    [ ?1 -> let g ?1
      if ((any? new-info with [basic-match self g])
        or ((is-agent? g) and ([breed] of g = doors) and ([state-visible? and state = "locked"] of g) and (member? name-color [color] of g bag)))
        [ set gl sublist gl (position g gl) (length gl)
          if (is-agent? g) and ([breed] of g = doors) and ([state-visible? and state = "locked"] of g) and (not member? name-color [color] of g bag)
            [ set gl fput (list keys name-color [color] of g) gl ]
        ]
    ]
  set goals gl
end

to knights::remember-key
  set unlocked fput (name-color [color] of ioda:my-target) unlocked
end


to-report description
  ifelse (breed = knights)
    [ report (word "Knight " name) ]
    [ ifelse (breed = princesses)
      [ report (word "Princess " name) ]
      [ ifelse (breed = keys)
        [ report (word "the " name-color color " key")]
        [ ifelse (breed = doors)
          [ report (word ifelse-value (state-visible? ) [ (word "the " state " " name-color color " ")] ["a "] "door")]
          [ report (word breed)]
        ]
      ]
    ]
end

to knights::exploration-finished
  if exploring?
    [ set exploring? false
      output-show "For now the shadow is defeated!"
    ]
end

to-report knights::no-exploration-path?
  report not knights::exploration-path?
end

to knights::forget-new-info
  set new-info no-turtles
end


to knights::update-info
  set new-info (turtle-set new-info ioda:my-target)
end
@#$#@#$#@
GRAPHICS-WINDOW
566
10
1309
544
-1
-1
35.0
1
10
1
1
1
0
0
0
1
0
20
-14
0
1
1
1
ticks
5.0

BUTTON
302
88
368
121
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
472
89
555
122
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
12
625
1309
852
12

CHOOSER
301
35
494
80
experiment
experiment
"map1.txt" "map2.txt" "map3.txt" "map4.txt" "map5.txt" "map6.txt" "map7.txt" "map8.txt" "map9.txt" "map10.txt" "map11.txt" "map101.txt" "map102.txt" "map103.txt" "map104.txt" "map105.txt" "map106.txt" "map107.txt" "map108.txt" "map109.txt" "map110.txt" "map111.txt" "map-dedalus.txt"
0

SWITCH
187
130
319
163
lock-doors?
lock-doors?
0
1
-1000

CHOOSER
9
33
147
78
mood
mood
"optimistic" "pessimistic"
0

CHOOSER
9
82
147
127
vision
vision
"omniscient" "partial"
1

CHOOSER
154
34
292
79
goals-ordering
goals-ordering
"rigid" "flexible"
1

CHOOSER
154
83
292
128
plan-execution
plan-execution
"utilitarian" "opportunistic"
0

MONITOR
173
573
1310
618
comment on the environment
get-comments
0
1
11

MONITOR
10
475
559
520
goals of the knight
[goals] of one-of knights
0
1
11

TEXTBOX
14
589
164
607
Viewpoint of the agents
13
0.0
1

SWITCH
324
130
472
163
show-dijkstra?
show-dijkstra?
0
1
-1000

MONITOR
10
423
276
468
keys of the knight
[bag] of one-of knights
0
1
11

BUTTON
378
89
463
122
go-once
go
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
23
10
173
28
KNIGHT PROFILE
13
0.0
1

MONITOR
285
423
559
468
new informations
sort-on [who] ([new-info] of one-of knights)
0
1
11

SWITCH
8
130
183
163
show-interactions?
show-interactions?
1
1
-1000

TEXTBOX
305
10
455
28
MAP
13
0.0
1

PLOT
8
168
560
417
Stats
time
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"% unexplored" 1.0 0 -16777216 true "" "plot 100 * (1 - (count [explored] of one-of knights) / count patches)"
"% agents" 1.0 0 -2674135 true "" "plot 100 * (count (turtles-on [explored] of one-of knights)  with [breed != walls]) / (count turtles with [breed != walls])"
"% door states" 1.0 0 -13345367 true "" "plot 100 * (count doors with [state-visible?] / count doors)"
"% collected keys" 1.0 0 -10899396 true "" "if nb-keys > 0 [plot 100 * (length [bag] of one-of knights) / nb-keys]"

@#$#@#$#@
## WHAT IS IT?

This model demonstrates goal-driven behaviors. The character (knight) can perform several interactions which are hierarchized so as to make it search and reach its goals.
Basically the main goal of the knight is to rescue the princess which is somewhere in the maze. The knight can either have an exhaustive view (or "omniscient") of the maze, or on the contrary only see a small part and what has been explored. The state of the doors is not known before the knights explicitly checks wether they are locked, closed or open. When a door is locked, the appropriate key (i.e. with the matching color) is required. The knight uses a stack of goals so as to execute the appropriate actions.

The knight is also endowed with **personality traits** which influences the interactions that are chosen in a given situation and thus introduces diversity in the outcome of the simulation. The first one is the **mood**: an optimistic knight considers that doors which are still in an unknown state are easy to open, thus he takes them into account to compute the shortest path to his target. On the contrary, a pessimistic knight avoids doors with an unknown state as much as possible. The second personality trait is the **ordering of goals**. A rigid (psychotic ?) knight uses  the stack of goals in a strict order, and must fulfill the first goal before it can take into account the other ones. On the contrary, a flexible use of the stack of goals allows to remove obsolete goals when a higher level target is reached (e.g. why matter opening all the doors when the princess is before you?). The last personality trait is the way to **execute the plan**.
When an opportunistic knight finds a key, he takes it, be it useful or not, while an utilitarian knight takes only the keys that are needed to unlock doors.
Besides, we provide several maps that illustrate the differences between the resulting behaviors.

## HOW TO USE IT

  * Choose the the personality traits, the vision of the knight and a map of the maze, then click on **`setup`**.  
  * Click on **`go`** (or **`go-once`** for step-by-step execution) and observe the behavior of the knight. The thoughts and decisions of the knight are shown in the output area at the bottom of the window; the monitors also show the keys own by the knight, the other agents that are discovered at each exploration step, and the stack of goals (new goals appear at the beginning of the list)
  * You can toggle the logging of performed interactions, decide whether doors are locked at startup or only closed, and toggle the patch labels that show the number of steps to the goal of the knight (Dijkstra algorithm). The plot shows the proportions of unexplored patches, of agents that have been discovered by the knight, of doors that have been checked and of collected keys.

## THINGS TO NOTICE

The behavior of the knight is not completely deterministic, since several goals or paths may be equivalent in terms of Dijkstra distance.
Yet, most of the maps are designed to demonstrate the differences between personality traits.

You can also draw you own maps in a text file. The first line is a comment or title, the second line is a list with the dimensions ([width height]) of the map, then each line encodes a line of the map: **W** for walls, ' ' for empty space, **K** for the knight, **P** for the princess, **B** (resp. **R**, **Y**, **G**) for the blue (resp. red, yellow, green) door, **b** (resp. **r**, **y**, **g**) for the blue (resp. red, yellow, green) key,  **D** for closed (unlockable) doors.

## IODA NETLOGO FEATURES

This model makes an intensive use of one of the new features introduced in IODA 2.2: the ability to specify easily alternatives in the triggers or conditions of the interactions. For instance, please consider the "MoveTowards" interaction, which incites the knight to move in the direction of its goal when possible:

    parallel interaction MoveTowards
      trigger target-matches-goal? 
      condition  direct-path-to-target? shortest-path-free?
      condition  possible-path-to-target? optimistic? shortest-path-free?
      actions    remember-path-to-target choose-shortest-path move-one-step
    end

The trigger simply verifies that the target of the interaction is the first goal of the knight. Yet, there are two possible conditions depending on the mood of the agent. In any case, the knight can perform MoveTowards if there is a free path (without obstacles) to the target. But, if the knight is optimistic, he will also try to move towards its goals if there is a "possible" path, i.e. through doors even in an unknown state. 
The interaction is realizable if 1) the trigger is fulfilled and 2) at least ONE of the conditions is verified. 


## THINGS TO TRY

You can extend this model at will by introducing new personality traits and new characters. For instance, you can first try to use several knights and princesses (with the ability of being cooperative or not)! Or add a nasty dragon which can defeated only by brave knight (while cowards just flee). Have fun !

## HOW TO CITE

  * The original "Princess" model was designed by Jean-Christophe Routier and Philippe
Mathieu to illustrate cognitive behaviors. The corresponding applet can be found there:
http://cristal.univ-lille.fr/SMAC/projects/cocoa/princesse.html
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
15
Polygon -6459832 true false 0 60 60 15 150 0 240 15 300 60 300 300 0 300
Rectangle -7500403 true false 285 60 315 315
Circle -1 true true 240 150 30
Rectangle -1 true true 15 60 30 105
Rectangle -1 true true 15 255 30 300
Rectangle -1 true true 15 150 30 210
Rectangle -7500403 true false 0 60 15 300
Rectangle -16777216 false false 0 60 15 300
Rectangle -16777216 false false 15 60 30 105
Rectangle -16777216 false false 15 150 30 210
Rectangle -16777216 false false 15 255 30 300
Circle -16777216 false false 240 150 30
Rectangle -16777216 false false 285 60 300 300

door-locked
false
15
Polygon -6459832 true false 0 60 60 15 150 0 240 15 300 60 300 300 0 300
Rectangle -7500403 true false 0 60 15 300
Rectangle -7500403 true false 285 60 315 315
Circle -1 true true 240 150 30
Rectangle -1 true true 15 60 30 105
Rectangle -1 true true 15 255 30 300
Rectangle -1 true true 15 150 30 210
Circle -1 true true 90 15 120
Circle -6459832 true false 120 45 58
Circle -1 true true 63 108 175
Circle -16777216 true false 116 131 67
Rectangle -16777216 true false 135 195 165 240
Rectangle -16777216 false false 0 60 15 300
Rectangle -16777216 false false 15 60 30 105
Rectangle -16777216 false false 15 150 30 210
Rectangle -16777216 false false 15 255 30 300
Rectangle -16777216 false false 285 60 315 300
Circle -16777216 false false 240 150 30

door-open
false
15
Polygon -7500403 true false 0 60 60 15 150 0 240 15 300 60 300 300 0 300
Rectangle -7500403 true false 0 60 15 300
Polygon -6459832 true false 15 60 120 15 120 255 15 300
Rectangle -1 true true 15 60 30 105
Rectangle -1 true true 15 150 30 210
Circle -1 true true 75 120 30
Rectangle -16777216 false false 0 60 15 300
Rectangle -16777216 false false 15 60 30 105
Rectangle -16777216 false false 15 150 30 210
Circle -16777216 false false 75 120 30
Polygon -16777216 false false 15 60 120 15 120 255 15 300
Rectangle -1 true true 15 255 30 300
Rectangle -16777216 false false 15 255 30 300
Rectangle -16777216 false false 285 60 300 300

door-unknown
false
13
Polygon -6459832 true false 0 60 60 15 150 0 240 15 300 60 300 300 0 300
Rectangle -7500403 true false 0 60 15 300
Rectangle -7500403 true false 285 60 315 315
Circle -7500403 true false 240 150 30
Rectangle -7500403 true false 15 60 30 105
Rectangle -7500403 true false 15 255 30 300
Rectangle -7500403 true false 15 150 30 210
Circle -16777216 true false 69 24 162
Circle -6459832 true false 96 51 108
Circle -16777216 true false 120 255 30
Circle -1 false false 96 51 108
Circle -1 false false 69 24 162
Rectangle -6459832 true false 60 105 150 195
Rectangle -16777216 true false 120 165 150 240
Rectangle -1 false false 120 165 150 240
Circle -1 false false 120 255 30
Rectangle -16777216 false false 0 60 15 300
Rectangle -16777216 false false 15 60 30 105
Rectangle -16777216 false false 15 150 30 210
Rectangle -16777216 false false 15 255 30 300
Rectangle -16777216 false false 285 60 315 300
Circle -16777216 false false 240 150 30

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

key2
false
0
Rectangle -16777216 false false 255 90 285 210
Rectangle -16777216 false false 195 90 225 210
Rectangle -16777216 false false 105 90 285 120
Rectangle -7500403 true true 255 120 285 210
Rectangle -7500403 true true 195 120 225 210
Circle -7500403 true true 15 75 120
Circle -16777216 false false 11 71 127
Rectangle -7500403 true true 90 90 285 120

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

personf
false
0
Circle -7500403 true true 110 20 80
Polygon -7500403 true true 105 105 120 210 90 300 105 315 135 315 150 240 165 315 195 315 210 300 180 210 195 105
Rectangle -7500403 true true 127 94 172 109
Polygon -7500403 true true 195 105 240 165 225 195 165 120
Polygon -7500403 true true 105 105 60 165 75 195 135 120
Polygon -7500403 true true 120 180 30 300 270 300 180 180
Polygon -1184463 true false 105 30 195 30 195 0 180 15 165 0 150 15 135 0 120 15 105 0

personh
false
8
Circle -11221820 true true 125 35 80
Polygon -11221820 true true 120 120 135 210 105 285 120 300 150 300 165 225 180 300 210 300 225 285 195 210 210 120
Rectangle -11221820 true true 142 109 187 124
Polygon -11221820 true true 210 120 255 180 240 210 180 135
Polygon -11221820 true true 120 120 75 180 90 210 150 135
Polygon -6459832 true false 240 210 225 210 255 225 270 180 255 180
Polygon -6459832 true false 240 165 285 165 285 210 270 180 255 180
Polygon -7500403 true false 270 165 300 45 300 0 255 165
Polygon -7500403 true false 135 105 120 105 120 30 135 15 165 0 195 15 210 30 210 105 195 105 195 90 195 45 180 45 165 75 150 45 135 45
Polygon -1184463 true false 195 195 135 195 135 210 195 210
Polygon -1 false false 270 165 300 45 300 0 255 165
Polygon -1 false false 195 105 210 105 210 30 195 15 165 0 135 15 120 30 120 105 135 105 135 45 150 45 165 75 180 45 195 45
Polygon -16777216 false false 0 150 0 255 45 285 75 285 120 255 120 105 0 105
Polygon -13791810 true false 0 105 0 255 45 285 60 285 60 105
Polygon -1184463 true false 60 105 120 105 120 255 75 285 60 285
Rectangle -1184463 true false 15 135 60 150
Rectangle -1184463 true false 15 180 60 195
Rectangle -1184463 true false 15 225 60 240
Rectangle -13791810 true false 60 135 105 150
Rectangle -13791810 true false 60 180 105 195
Rectangle -13791810 true false 60 225 105 240

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
