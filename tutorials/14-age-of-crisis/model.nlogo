__includes ["../../IODA_3_0.nls"]
extensions [ioda]

breed [ mines mine ]
breed [ trees tree ]
breed [ animals animal ]

breed [ farms farm ]
breed [ harbors harbor ]
breed [ agoras agora ]
breed [ houses house ]
breed [ barracks barrack ]
breed [ walls wall ]
breed [ peasants peasant ]
breed [ soldiers soldier ]
breed [ boats boat ]
breed [ fishes fish  ]
breed [ flags flag ]
breed [ fires fire ]

undirected-link-breed [ workforce worker ]
undirected-link-breed [ army hoplite ]

globals [ teams levels ]

turtles-own [ life speed quantity resource-type grown? attacked? ]

agoras-own [ food wood stone gold target-workforce target-army changed-view? needs level places ]
peasants-own [ basket basket-type last-place ]
soldiers-own [ trained? last-place skills ]
boats-own [ basket basket-type last-place ]
farms-own [ripe?]
flags-own [ strength  ]

to setup
  clear-all
  init-world
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices "matrix.txt" " \t,()"
  ioda:setup
  reset-ticks
end

to go
  ioda:go
  plot-statistics
  tick
end

to plot-statistics
  set-current-plot "World summary"
  foreach teams
    [ [?1] ->
      let col ?1
      set-current-plot-pen (word "team " col)
      plot ((count peasants with [color = col]) + (count soldiers with [color = col]))]
end


to init-world
  set-default-shape mines "cloud"
  set-default-shape trees "tree" ; "logs"
  set-default-shape animals "rabbit"
  set-default-shape fishes "fish"
  set-default-shape farms "plant small"
  set-default-shape harbors "harbor"
  set-default-shape agoras "building store"
  set-default-shape houses "house"
  set-default-shape barracks "pentagon"
  set-default-shape walls "tile stones"
  set-default-shape flags "flag"
  set-default-shape peasants "farmer"
  set-default-shape soldiers "soldier"
  set-default-shape boats "boat"
  set-default-shape fires "fire"
  set teams (list red blue yellow cyan magenta)
  set-current-plot "World summary"
  foreach teams
    [ [?1] ->
      create-temporary-plot-pen (word "team " ?1) set-plot-pen-color ?1]
  set levels [[1000 500 100 100 8 0] [2000 1000 500 500 16 8] [4000 2000 1000 1000 32 16] [10000 5000 5000 5000 32 32]]
  place-sea
  place-agoras
  ask agoras
    [ place-mines ]
  place-trees
  place-fish
  place-animals
end

to place-sea
  let p []
  ask patch 0 0 [set pcolor turquoise]
  repeat 3 [ask one-of patches with [abs pxcor + abs pycor < 6]
      [ set pcolor turquoise ]]
  let n sea-area - 4
  while [ n > 0]
    [ set p [neighbors4 with [pcolor = black]] of patches with [pcolor = turquoise]
      while [ (n > 0) and (not empty? p) ]
        [ let x one-of p
          set p remove x p
          ask x [ set pcolor turquoise ]
          set n n - 1
        ]
    ]
end

to place-fish
  ask n-of 10 patches with [pcolor = turquoise]
    [ sprout-fishes 1 [ init-fish set heading random 360 fd 0.1 + random-float 0.3 ]]
end

to place-agoras
  create-ordered-agoras length teams
    [ fd max-pxcor * 2 / 3
      init-agora (item who teams) 250 0 0 0
    ]
end

to init-agora [col f w s g]
  set level starting-level
  set attacked? false
  set life 100
  set grown? true
  set places []
  set size 2 set color col
  set label-color color
  set changed-view? true
  set food f set wood w set stone s set gold g
  let l item level levels
  set target-workforce item 4 l
  set target-army item 5 l
  set needs ["food" "wood"]
  set pcolor col - 4
  ask neighbors [ set pcolor col - 4 ]
  agoras::update-view
end


to place-mines
  repeat nb-gold-mines
    [ hatch-mines 1
        [ init-mine "gold" 1000 orange
          set heading random 360 fd (3 + random-float 10)
        ]
    ]
  repeat nb-stone-mines
    [ hatch-mines 1
        [ init-mine "stone" 1000 white
          set heading random 360 fd (3 + random-float 10)
        ]
    ]
  let t mines with [ (pcolor = turquoise) or (any? neighbors with [ pcolor = turquoise ])  or (any? agoras in-radius 3)]
  while [any? t]
    [ ask t [ right random 30 left random 30 fd 0.5 ]
      set t mines with [ (pcolor = turquoise) or (any? neighbors with [ pcolor = turquoise ]) or (any? agoras in-radius 3)]
    ]
end



to-report no-building-here?
  report (not any? mines-here) and (not any? houses-here) and (not any? agoras-here)
  and (not any? farms-here) and (not any? harbors-here) and (not any? barracks-here)
end


to init-mine [ n q c ]
  set size 1.5 set label ""
  set resource-type n set quantity q set color c set life 1
end

to place-trees
  ask agoras [ hatch-trees 10 [ init-tree fd 2 + random-float 10 ]]
  ask n-of 5 patches with [pcolor = turquoise] [ sprout-trees 1 [ init-tree fd 2 + random-float 10 ]]
  let q nb-trees - count trees
  repeat q
    [ ask one-of (patches with [count trees-on neighbors >= 1 and count trees-on neighbors < 7])
        [ sprout-trees 1 [ init-tree set heading random 360 fd 0.5 + random-float 1 ]]
    ]
  let t trees with [ (pcolor = turquoise) or (any? neighbors with [ pcolor = turquoise ]) or (any? agoras in-radius 3) or (any? mines in-radius 1) ]
  while [any? t]
    [ ask t [ right random 30 left random 30 fd 0.5 ]
      set t trees with [ (pcolor = turquoise) or (any? neighbors with [ pcolor = turquoise ]) or (any? agoras in-radius 3)  or (any? mines in-radius 1) ]
    ]
end

to init-tree
  set size 1 set label ""
  set quantity 100 set color green + (random 3) - (random 3)
  set life 25
  set resource-type "wood"
end

to place-animals
  create-animals nb-animals
    [ init-animal
      move-to one-of patches with [(not any? agoras-here) and (not any? trees-here) and (pcolor != turquoise)]
      set heading random 360
      fd random-float 0.5 ]
end

to init-animal
  ifelse (random 5 = 0)
    [ set color white set shape "cow" set size 1.5 set quantity 500 set life 20 set speed 0.1 ]
    [ set color brown   set quantity 100 set life 5 set speed 0.2 ]
  set attacked? false
  set resource-type "food"
  set grown? true
end

to init-fish
  set color red + 3 set size 1 set quantity 500 set life 20 set speed 0
  set resource-type "food"
  set attacked? false
  set grown? true
end

to init-peasant
  ioda:init-agent
  set label "" set size 1
  set attacked? false
  set life 100
  set speed 0.5
  set basket 0
  set basket-type ""
  set last-place []
end

to init-soldier
  ioda:init-agent
  set label "" set size 1
  set attacked? false
  set life 500
  set size 0.8
  set speed 1
  set skills 0
  set trained?  false
  set last-place []
end

to init-boat
  ioda:init-agent
  set label "" set size 1
  set attacked? false
  set life 100
  set speed 0.1
  set size 1.5
  set basket 0
  set basket-type ""
  set last-place []
end

to-report trees::decomposed?
  report quantity <= 0
end

to trees::clear
  ioda:die
end

to-report trees::fire?
  report any? fires-on patch-here
end

to trees::deteriorate
  set quantity quantity - 1
  set life life - 1
end

to-report trees::dead?
  report life <= 0
end

to trees::die
  set shape "logs"
  set color brown
end

to-report trees::effort
  report 500 - quantity
end



to-report mines::decomposed?
  report quantity <= 0
end

to-report mines::dead?
  report true
end

to mines::clear
  ioda:die
end

to-report mines::quantity
  report quantity
end





to fishes::wiggle
  if (random 100 = 0)
    [ let p neighbors with [ pcolor = turquoise ]
      if any? p
        [ move-to one-of p
          set heading random 360
          fd random-float 0.4 ]
    ]
end

;to-report fishes::not-decomposed?
;  report grown? and quantity > 0
;end

to-report fishes::decomposed?
  report quantity <= 0 or not grown?
end

to-report fishes::dead?
  report true
end

;to-report fishes::not-dead?
;  report true
;end

to-report fishes::depleted?
  report quantity < 500
end

to-report fishes::grown?
  report grown?
end

to fishes::clear
  set grown? false
  set size 0.2
end

to fishes::grow
  set quantity quantity + 1
  if (quantity > 250) [ set size 0.5 ]
  if (quantity >= 500)
    [ set size 1
      set grown? true ]
end



to animals::filter-neighbors
  ioda:filter-neighbors-in-radius 1
end

to animals::wiggle
  right random 45 left random 45
  if ((not any? other turtles in-cone 45 speed) and ([pcolor] of (patch-ahead speed) != turquoise))  [ fd speed ]
end

to animals::move-towards
  face ioda:my-target
  if ([pcolor] of patch-ahead speed != turquoise)
    [ fd speed ]
end

to-report animals::dead?
  report life <= 0
end

to-report animals::ennemy?
  report false
end

to animals::move-away
  face ioda:my-target
  right 180
  if ([pcolor] of patch-ahead speed != turquoise)
    [ fd speed ]
end

to-report animals::decomposed?
  report quantity <= 0
end

to animals::clear
  ioda:die
end

to animals::deteriorate
  set color gray
  set quantity quantity - 1
  if (quantity < 0) [ set quantity 0 ]
end

to-report animals::quantity
  report quantity
end

to-report animals::effort
  report 500 - quantity
end








to agoras::update-view
  set label (word food "/" wood "/" stone "/" gold)
  set changed-view? false
end

to agoras::update-needs
  let l item level levels
  set needs []
  if (food < item 0 l) [ set needs fput "food" needs ]
  if (count my-workforce >= 5) [
    if (wood < item 1 l) [ set needs fput "wood" needs ]
    if (stone < item 2 l) [ set needs fput "stone" needs ]
    if (gold < item 3 l) [ set needs fput "gold" needs ]
  ]
end

to-report agoras::ready-for-upgrade?
  let l item level levels
  report (food >= item 0 l) and (wood >= item 1 l) and (stone >= item 2 l) and (gold >= item 3 l) and (count my-workforce >= item 4 l) and (count my-army >= item 5 l)
end

to agoras::start-upgrade
  set grown? false
  set life 1
  set label "UPGRADING..." set label-color white
  let l item level levels
  set food food - item 0 l
  set wood wood - item 1 l
  set stone stone - item 2 l
  set gold gold - item 3 l
end

to-report agoras::upgrading?
  report not grown?
end

to agoras::continue-upgrade
  ifelse (life < 100)
    [ set label "UPGRADING..."
      set life life + 1 ]
    [ set grown? true
      set label-color color
      let c color
      set changed-view? true
      set level level + 1
      ask houses with [color = c] [houses::change-shape]
      set size size + 0.5
      let l item level levels
      set target-workforce item 4 l
      set target-army item 5 l
      ask patch-set [ neighbors with [pcolor = black]] of patches with [shade-of? pcolor c]
        [ set pcolor c - 4 ]
    ]
end

to-report agoras::enough-workforce?
  report count my-workforce >= target-workforce
end

to-report agoras::resources-for-peasant?
  report (food >= 100) and (not agoras::needs-house?)
end

to agoras::train-peasant
  set food food - 100
  set changed-view? true
  hatch-peasants 1
    [ create-worker-with myself [ set thickness 0.1 hide-link ]
      init-peasant
      fd 1 ]
end

to-report agoras::needs-assistance?
  report attacked? and agoras::damaged?
end

to-report agoras::enough-army?
  report count my-army >= target-army
end

to-report agoras::dead?
  report life <= 0
end

to-report agoras::decomposed?
  report life <= 0
end

to agoras::clear
  ioda:die
end

to agoras::deteriorate
  set life life - 1
end

to-report agoras::barracks?
  let c color
  report any? barracks with [(color = c) and grown?]
end

to-report agoras::resources-for-soldier?
  report (food >= 80) and (gold >= 10)
end

to-report agoras::damaged?
  report life < 100
end

to agoras::create-soldier
  set food food - 80
  set gold gold - 10
  set changed-view? true
  hatch-soldiers 1
    [ create-hoplite-with myself [ set thickness 0.1 set color brown hide-link ]
      init-soldier
      fd 1 ]
end

to-report agoras::grown?
  report grown?
end

to-report agoras::changed-view?
  report changed-view?
end

to-report agoras::knows-interesting-places?
;  let c color
  report not empty? places
end

to agoras::filter-neighbors
  ioda:filter-neighbors-in-radius 2
  ioda:add-neighbors-on-links my-links
end

to agoras::suggest-place-to-go
  let p  first places
  set places remove p places
  ask ioda:my-target [ set last-place p ]
end

to-report agoras::needs-house?
  let t color
  report (count my-workforce) + (count my-army) >= (5 + level) * (count agoras with [color = t and grown? ]) + (5 + level) * (count houses with [color = t and grown? ])
end

to-report agoras::place-for-house?
  let c color
  report (count houses with [not grown? and color = c] < 2) and
  (any? (patches in-radius 5) with [(not any? trees-here) and (pcolor != turquoise) and (not any? agoras-on neighbors) and (no-building-here?)])
end

to-report agoras::resources-for-house?
  report wood >= 100
end

to agoras::create-house-base
  set wood wood - 100
  let c color
  let p (patches in-radius 5) with [(not any? trees-here) and (pcolor != turquoise) and (not any? agoras-on neighbors)
    and (no-building-here?)]
  let x one-of p
  ask x [ sprout-houses 1 [ init-house c]]
  set places fput (list [pxcor] of x [pycor] of x) places
end

to-report agoras::needs-harbor?
  report level > 0
end

to-report agoras::no-harbor?
  let c color
  report  not any? harbors with [color = c]
end

to agoras::create-harbor-base
  set wood wood - 250
  set stone stone - 150
  let c color
  let p patches with [(pcolor = black) and (count neighbors with [pcolor = turquoise] > 2) and (no-building-here?)]
  let x min-one-of p [distance myself]
  ask x [ sprout-harbors 1 [ init-harbor c ]]
  set places fput (list [pxcor] of x [pycor] of x) places
end

to-report agoras::needs-barracks?
  report level > 0
end

to-report agoras::no-barracks?
  let c color
  report  not any? barracks with [color = c]
end

to-report agoras::fire?
  report any? fires-on patch-here
end

to agoras::create-barracks-base
  set wood wood - 300
  set stone stone - 100
  let c color
  let p (patches in-radius 6) with [(ioda:distance myself > 3) and (not any? trees-here) and (pcolor != turquoise) and (no-building-here?)]
  let x one-of p
  ask x [ sprout-barracks 1 [ init-barracks c]]
  set places fput (list [pxcor] of x [pycor] of x) places
end

to agoras::create-farm-base
  set wood wood - 200
  let c color
  let p patches with [(shade-of? pcolor c) and (not any? agoras-on neighbors) and (no-building-here?)]
  let x min-one-of  p [distance myself]
  ask x [ sprout-farms 1 [ init-farm c ]]
  set places fput (list [pxcor] of x [pycor] of x) places
end

to-report agoras::place-for-harbor?
  report any? patches with [(pcolor = black) and (count neighbors with [pcolor = turquoise] > 2) and (no-building-here?)]
end

to-report agoras::resources-for-harbor?
  report (wood >= 250) and (stone >= 150)
end

to-report agoras::needs-farm?
  report (level > 0) and (member? "food" needs) and (count farms < 4 * level)
end

to-report agoras::place-for-farm?
  let c color
  report any? patches with [(shade-of? pcolor c) and (not any? agoras-on neighbors) and (no-building-here?)]
end

to-report agoras::resources-for-farm?
  report (wood >= 200)
end

to-report agoras::place-for-barracks?
  report any? (patches in-radius 6) with [(ioda:distance myself > 3) and (not any? trees-here) and (pcolor != turquoise) and (no-building-here?)]
end

to-report agoras::resources-for-barracks?
  report (wood >= 300) and (stone >= 100)
end


to init-harbor [c]
  ioda:init-agent
  set attacked? false
  set color c
  set grown? false
  set size 0.5
  set life 1
  set label "1/400"
  set pcolor c - 4
  ask neighbors with [pcolor = black]
    [ set pcolor c - 4 ]
end

to-report farms::ripe?
  report ripe?
end

to-report farms::depleted?
  report quantity <= 0
end

to farms::grow
  set quantity quantity + 1
  ifelse (quantity > 400)
    [ set shape "plant"
      if (quantity >= 500)
        [ set ripe? true set resource-type "food" set shape "flower" ] ]
    [ ifelse (quantity > 200)
        [ set shape "plant medium"]
        [ set shape "plant small" ]]
end

to farms::new-seeds
  set ripe? false
  set resource-type ""
  set quantity 1
  set shape "plant small"
end

to-report harbors::needs-assistance?
  report (not harbors::grown?) or harbors::damaged?
end

to-report harbors::damaged?
  report life < 400
end

to-report harbors::dead?
  report life <= 0
end

to-report harbors::decomposed?
  report true
end

to harbors::clear
  ioda:die
end

to-report harbors::grown?
  report grown?
end

to-report harbors::enough-workforce?
  let c color
  let l max [level] of agoras with [color = c]
  report (count my-workforce >= 1 + l)
end

to-report harbors::fire?
  report any? fires-on patch-here
end

to-report harbors::resources-for-boat?
  let c color
  report (sum [wood] of agoras with [color = c]) >= 300
end

to harbors::train-boat
  let c color
  ask (max-one-of (agoras with [color = c]) [wood])
    [ set wood wood - 300 set changed-view? true ]
  hatch-boats 1
    [ create-worker-with myself [ set thickness 0.1 ]
      init-boat
      move-to one-of neighbors with [pcolor = turquoise]]
end

to harbors::deteriorate
  set life life - 1
end

to harbors::build
  set life life + 1
  set label (word life "/400")
  if (life >= 400)
    [ set grown? true set size 1 set label "" ]
end

to init-farm [c]
  ioda:init-agent
  set attacked? false
  set color c
  set resource-type ""
  set grown? false
  set size 0.5
  set life 1
  set ripe? false
  set label "1/50"
  set pcolor c - 4
  ask neighbors with [pcolor = black]
    [ set pcolor c - 4 ]
end

to-report farms::needs-assistance?
  report farms::damaged?
end

to-report farms::damaged?
  report life < 50
end

to-report farms::dead?
  report life <= 0
end

to-report farms::fire?
  report any? fires-on patch-here
end

to-report farms::decomposed?
  report true
end

to farms::clear
  ioda:die
end

to farms::build
  set life life + 1
  set label (word life "/50")
  if (life >= 50)
    [ set grown? true set size 1 set label ""
      let c color let p (list xcor ycor)
      ask agoras with [color = c] [set places fput p places]]
end

to farms::deteriorate
  set life life - 1
end







to init-house [c]
  ioda:init-agent
  set color c
  set attacked? false
  set grown? false
  set size 0.5
  set life 1
  set label "1/100"
  set pcolor c - 4
  ask neighbors [ set pcolor c - 4 ]
end

to houses::change-shape
  let c color
  let l max [level] of (agoras with [color = c])
  if (l < 5)
    [set shape item l ["house" "house efficiency" "house bungalow" "house colonial" "house two story" ]]
  if (l > 0) [ set size 2 ]
end

to-report houses::needs-assistance?
  report (not houses::grown?) or houses::damaged?
end

to-report houses::grown?
  report grown?
end

to-report houses::damaged?
  report life < 100
end

to-report houses::dead?
  report life <= 0
end

to-report houses::decomposed?
  report true
end

to houses::clear
  ioda:die
end

to houses::deteriorate
  set life life - 1
end

to-report houses::fire?
  report any? fires-on patch-here
end

to houses::build
  set life life + 1
  set label (word life "/100")
  if (life >= 100)
    [ set grown? true set size 1 set label "" houses::change-shape ]
end



to peasants::filter-neighbors
  ioda:filter-neighbors-in-radius 5
  ioda:add-neighbors-on-links my-links
end

to peasants::wiggle
  right random 45 left random 45
  if ((not any? trees in-cone 45 speed) and ([pcolor] of patch-ahead speed != turquoise))
    [ fd 0.5 ]
end

to-report peasants::ennemy?
  let t ioda:my-target
  report [color] of t != color
end

to-report peasants::same-team?
  let t ioda:my-target
  report [color] of t = color
end

to-report peasants::want-target-dead?
  let b [breed] of ioda:my-target
  ifelse ((b = peasants) or (b = soldiers))
    [ report peasants::ennemy? ]
    [ report peasants::needs-target? ]
end

to-report peasants::needs-target?
  report member? [resource-type] of ioda:my-target ([needs] of one-of link-neighbors)
end

to-report peasants::dead?
  report life <= 0
end

to-report peasants::decomposed?
  report life <= -100
end

to peasants::clear
  ioda:die
end

to peasants::deteriorate
  if (life <= 0) [ set color gray ]
  set life life - 1
end


to peasants::hit-target
  ask ioda:my-target
    [ set life life - 5
      if (life < 0) [ set life 0 ]]
end

to peasants::extract-resources
  let t ioda:my-target
  ask t [ set quantity quantity - 1 ]
  set basket-type [ resource-type ] of ioda:my-target
  set basket basket + 1
  let p (list [xcor] of t [ycor] of t)
  set last-place p
  ask ([other-end] of one-of my-workforce)
    [ if (not member? p places) [set places lput p places] ]
end

to peasants::move-towards
  face ioda:my-target
  while [ [pcolor] of patch-ahead speed = turquoise]
    [ right random 90 left random 90 ]
  fd speed
end

to-report peasants::basket-full?
  report basket >= 10
end

to peasants::empty-basket
  let b basket let t basket-type
  set basket 0 set basket-type ""
  ask ioda:my-target
    [ add-resource t b ]
end

to-report peasants::remember-last-place?
  report (not empty? last-place)
end

to peasants::move-to-place
  ifelse (distancexy (item 0 last-place) (item 1 last-place) > speed)
    [ facexy (item 0 last-place) (item 1 last-place)
      while [ [pcolor] of patch-ahead speed = turquoise]
        [ right random 90 left random 90 ]
      fd speed ]
    [ set last-place []]
end

to add-resource [ t q ]
  ifelse (t = "food")
    [ set food food + q ]
    [ ifelse (t = "wood")
      [ set wood wood + q ]
      [ ifelse (t = "stone")
        [set stone stone + q]
        [ ifelse (t = "gold")
          [set gold gold + q]
          []]]
    ]
  set changed-view? true
end


to boats::empty-basket
  let b basket let t basket-type
  set basket 0 set basket-type ""
  let c color
  ask one-of agoras with [color = c] [ add-resource t b ]
end

to-report boats::needs-target?
  let c color
  let r [resource-type] of ioda:my-target
  report any? agoras with [(color = c) and (member? r needs)]
end

to-report boats::remember-last-place?
  report (not empty? last-place)
end

to-report boats::fire?
  report any? fires-on patch-here
end

to-report boats::dead?
  report life <= 0
end

to-report boats::decomposed?
  report true
end

to boats::filter-neighbors
  ioda:filter-neighbors-in-radius 3
  ioda:add-neighbors-on-links my-links
end

to boats::extract-resources
  let t ioda:my-target
  ask t [ set quantity quantity - 1 ]
  set basket-type [ resource-type ] of ioda:my-target
  set basket basket + 1
  let p (list [xcor] of t [ycor] of t)
  set last-place p
end

to boats::move-to-place
  ifelse (distancexy (item 0 last-place) (item 1 last-place) > speed)
    [ facexy (item 0 last-place) (item 1 last-place)
      while[ [pcolor] of patch-ahead speed != turquoise]
        [ ifelse (random 2 = 0) [ right 90 ] [ left 90 ]]
      fd speed ]
    [ set last-place []]
end

to boats::move-towards
  face ioda:my-target
  while [ [pcolor] of patch-ahead speed != turquoise]
    [ ifelse (random 2 = 0) [ right 90 ] [ left 90 ] ]
  fd speed
end

to boats::wiggle
  if (random 100 = 0) [ set heading random 360 ]
  while [ [pcolor] of patch-ahead speed != turquoise]
    [ ifelse (random 2 = 0) [ right 90 ] [ left 90 ] ]
  fd speed
end

to boats::clear
  ioda:die
end

to-report boats::basket-full?
  report basket >= 20
end

to-report boats::same-team?
  report [color] of ioda:my-target = color
end

to boats::deteriorate
  set life life - 1
end





to init-barracks [c]
  ioda:init-agent
  set attacked? false
  set color c
  set grown? false
  set size 1
  set life 1
  set label "1/400"
  set pcolor c - 4
  ask neighbors [ set pcolor c - 4 ]
end

to-report barracks::decomposed?
  report life <= 0
end

to barracks::deteriorate
  set life life - 1
end

to-report barracks::grown?
  report grown?
end

to-report barracks::needs-assistance?
  report (not barracks::grown?) or barracks::damaged?
end

to-report barracks::damaged?
  report life < 400
end

to-report barracks::dead?
  report life <= 0
end

to barracks::clear
  ioda:die
end

to-report barracks::fire?
  report any? fires-on patch-here
end

to barracks::build
  set life life + 1
  set label (word life "/400")
  if (life >= 400)
    [ set grown? true set size 1.5 set label "" ]
end

to barracks::filter-neighbors
  ioda:filter-neighbors-in-radius 2
end




to init-flag [c]
  ioda:init-agent
  set heading 0
  set strength 1
  set color c
  flags::recolor
end

to-report flags::on-border?
  let c [color] of ioda:my-target
  report (pcolor = black) and (any? neighbors with [shade-of? pcolor c])
end

to flags::recolor
  set color scale-color color strength -0.1 2
end

to-report flags::lowest
  report 100 - strength
end

to flags::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here)
end

to-report flags::dead?
  report true
end

to-report flags::decomposed?
  report strength <= 0
end

to flags::digest
  set strength strength + [strength] of ioda:my-target
end

to flags::clear
  ioda:die
end

to flags::deteriorate
  set strength strength * 0.99
  if (strength < 0.0001) [ set strength 0 ]
end


to-report soldiers::ennemy?
  report [color] of ioda:my-target != color
end

to-report soldiers::attacked?
  report attacked?
end

to-report soldiers::border-nearby?
  let c color
  report any? patches in-radius 8 with [ (pcolor = black) and (any? neighbors with [shade-of? pcolor c]) and (not any? flags-here)]
end

to-report soldiers::on-border?
  let c color
  report (pcolor = black) and (any? neighbors with [shade-of? pcolor c])
end

to-report soldiers::flag?
  report any? flags-here
end

to soldiers::select-border
  let c color
  let p one-of (patches in-radius 8 with [ (pcolor = black) and (any? neighbors with [shade-of? pcolor c]) and (not any? flags-here)])
  set last-place (list [pxcor] of p [pycor] of p)
end

to soldiers::drop-flag
  let c color
  if (pcolor = black) and (any? neighbors with [shade-of? pcolor c])
    [ ask patch-here [ sprout-flags 1 [ init-flag c ]]]
end

to soldiers::move-to-place
  ifelse (distancexy (item 0 last-place) (item 1 last-place) > speed)
    [ facexy (item 0 last-place) (item 1 last-place)
      while [ [pcolor] of patch-ahead speed = turquoise]
        [ ifelse (random 2 = 0) [ right 30 + random 60 ] [ left 30 + random 60 ] ]
      fd speed ]
    [ set last-place []]
end

to-report soldiers::dead?
  report life <= 0
end

to-report soldiers::decomposed?
  report life <= -100
end

to soldiers::clear
  ioda:die
end

to soldiers::deteriorate
  set life life - 1
end

to-report soldiers::war?
  let c color
  report min [level] of agoras  with [color = c] > 2
end

to-report soldiers::trained?
  report trained?
end

to-report soldiers::same-team?
  report [color] of ioda:my-target = color
end

to soldiers::filter-neighbors
  ioda:filter-neighbors-in-radius 8
  ioda:add-neighbors-on-links my-links
end

to soldiers::move-towards
  face ioda:my-target
  while [ [pcolor] of patch-ahead speed = turquoise]
    [ ifelse (random 2 = 0) [ right 30 + random 60 ] [ left 30 + random 60 ]]
  fd speed
end

to soldiers::train
  set skills skills + 1
  if (skills >= 50)
    [ set trained? true set skills 0 set size 1 ]
end

to soldiers::wiggle
  if (random 100 = 0) [ set heading random 360 ]
  while [ [pcolor] of patch-ahead speed = turquoise]
    [ ifelse (random 2 = 0) [ right 30 + random 60 ] [ left 30 + random 60 ]]
  fd speed
end

to soldiers::ignite
  let p [patch-here] of ioda:my-target
  ask p [ sprout-fires 1 [ init-fire ]]
end

to soldiers::move-away
  face ioda:my-target
  right 180
  while [ [pcolor] of patch-ahead speed = turquoise]
    [ ifelse (random 2 = 0) [ right 30 + random 60 ] [ left 30 + random 60 ]]
  fd speed
end




to init-fire
  ioda:init-agent
  set size 1
  set color orange + 3
end

to-report fires::windy-weather?
  report true
end

to fires::filter-neighbors
  ioda:filter-neighbors-on-patches neighbors
end

to fires::ignite
  let pp ioda:my-target
  if (not is-list? ioda:my-target) [ set pp (list pp)]
  foreach pp
    [ [?1] ->
      let p [patch-here] of ?1
      ask p [ if not any? fires-here [sprout-fires 1 [ init-fire ]]]]
end

to fires::clear
  ioda:die
end


to-report farms::grown?
  report grown?
end
@#$#@#$#@
GRAPHICS-WINDOW
511
10
1257
757
-1
-1
18.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
1
1
1
ticks
60.0

BUTTON
11
10
77
43
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
13
56
76
89
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
87
10
273
43
nb-gold-mines
nb-gold-mines
0
5
2.0
1
1
p. agora
HORIZONTAL

SLIDER
280
10
473
43
nb-stone-mines
nb-stone-mines
0
5
2.0
1
1
p. agora
HORIZONTAL

SLIDER
86
48
258
81
nb-trees
nb-trees
0
1000
500.0
1
1
NIL
HORIZONTAL

SLIDER
279
48
451
81
nb-animals
nb-animals
0
500
200.0
1
1
NIL
HORIZONTAL

BUTTON
14
105
77
138
step
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

SLIDER
85
86
257
119
sea-area
sea-area
1
200
70.0
1
1
patches
HORIZONTAL

CHOOSER
85
123
223
168
team-to-observe
team-to-observe
"red" "blue" "yellow" "cyan" "magenta"
1

PLOT
7
172
502
495
Team summary
time
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"population x10" 1.0 0 -16777216 true "" "plot 10 * ((count peasants with [color = read-from-string team-to-observe]) + (count soldiers with [color = read-from-string team-to-observe]))"
"food" 1.0 0 -2674135 true "" "plot (sum [food] of agoras with [color = read-from-string team-to-observe])"
"wood" 1.0 0 -10899396 true "" "plot (sum [wood] of agoras with [color = read-from-string team-to-observe])"
"stone" 1.0 0 -7500403 true "" "plot (sum [stone] of agoras with [color = read-from-string team-to-observe])"
"gold" 1.0 0 -955883 true "" "plot (sum [gold] of agoras with [color = read-from-string team-to-observe])"
"buildings x10" 1.0 0 -13345367 true "" "plot 10 * ((count agoras with [color = read-from-string team-to-observe]) + (count farms with [color = read-from-string team-to-observe]) + (count houses with [color = read-from-string team-to-observe]))"

SLIDER
280
91
452
124
starting-level
starting-level
0
5
0.0
1
1
NIL
HORIZONTAL

PLOT
8
498
501
769
World summary
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

@#$#@#$#@
## WHAT IS IT?

This model is a little game simulation of villages managing their environmental resources to build their civilization. Depending on their civilization level, they can build advanced structures such as harbors, barracks, farms, etc.   
It certainly can be endowed with many improvements!

## IODA NETLOGO FEATURES

Several agents (e.g. agoras) use both a space-based perception (filter-neighbors-in-radius 2) and a link-based perception (the agora uses a kind of "telepathic" contact with all its peasants for instance). See `agoras::filter-neighbors`.

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

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

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

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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

campsite
false
0
Polygon -7500403 true true 150 11 30 221 270 221
Polygon -16777216 true false 151 90 92 221 212 221
Line -7500403 true 150 30 150 225

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

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

container
false
0
Rectangle -7500403 false false 0 75 300 225
Rectangle -7500403 true true 0 75 300 225
Line -16777216 false 0 210 300 210
Line -16777216 false 0 90 300 90
Line -16777216 false 150 90 150 210
Line -16777216 false 120 90 120 210
Line -16777216 false 90 90 90 210
Line -16777216 false 240 90 240 210
Line -16777216 false 270 90 270 210
Line -16777216 false 30 90 30 210
Line -16777216 false 60 90 60 210
Line -16777216 false 210 90 210 210
Line -16777216 false 180 90 180 210

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300
Polygon -7500403 true true 120 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 165 90 180 90 165 90 180 90 165 135 135 135 120 90 120 195

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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

harbor
false
0
Rectangle -7500403 true true 30 15 45 300
Polygon -7500403 true true 60 135 240 75 60 15
Line -7500403 true 45 120 60 120
Line -7500403 true 45 30 60 30
Rectangle -7500403 true true 15 255 300 270
Rectangle -7500403 true true 0 240 15 315
Rectangle -7500403 true true 120 240 135 300
Rectangle -7500403 true true 180 240 195 300
Rectangle -7500403 true true 240 240 255 300
Rectangle -7500403 true true 60 240 75 300

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

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

logs
false
0
Polygon -7500403 true true 15 241 75 271 89 245 135 271 150 246 195 271 285 121 235 96 255 61 195 31 181 55 135 31 45 181 49 183
Circle -1 true false 132 222 66
Circle -16777216 false false 132 222 66
Circle -1 true false 72 222 66
Circle -1 true false 102 162 66
Circle -7500403 true true 222 72 66
Circle -7500403 true true 192 12 66
Circle -7500403 true true 132 12 66
Circle -16777216 false false 102 162 66
Circle -16777216 false false 72 222 66
Circle -1 true false 12 222 66
Circle -16777216 false false 30 240 30
Circle -1 true false 42 162 66
Circle -16777216 false false 42 162 66
Line -16777216 false 195 30 105 180
Line -16777216 false 255 60 165 210
Circle -16777216 false false 12 222 66
Circle -16777216 false false 90 240 30
Circle -16777216 false false 150 240 30
Circle -16777216 false false 120 180 30
Circle -16777216 false false 60 180 30
Line -16777216 false 195 270 285 120
Line -16777216 false 15 240 45 180
Line -16777216 false 45 180 135 30

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

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

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

plant medium
false
0
Rectangle -7500403 true true 135 165 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 165 120 120 150 90 180 120 165 165

plant small
false
0
Rectangle -7500403 true true 135 240 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 240 120 195 150 165 180 195 165 240

rabbit
false
0
Polygon -7500403 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -7500403 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -7500403 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -7500403 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 105 90 60 195 90 210 135 105
Polygon -6459832 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -6459832 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -7500403 true true 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -7500403 true true 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -7500403 true true 114 187 128 208
Rectangle -7500403 true true 177 187 191 208

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
