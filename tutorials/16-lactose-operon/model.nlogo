__includes ["../../IODA_3_0.nls"]
extensions [ioda]

breed [ genes gene ]
breed [ RNAs RNA ]
breed [ operators operator ]
breed [ promoters promoter ]
breed [ terminators terminator ]
breed [ repressors repressor ]
breed [ membranes membrane ]
breed [ polymerases polymerase ]
breed [ cAMPs cAMP ]
breed [ CAPs CAP ]
breed [ ATPs ATP ]
breed [ permeases permease ]
breed [ galactosidases galactosidase ]
breed [ lactoses lactose ]
breed [ glucoses glucose ]

globals [ total-metabolized-lactose total-metabolized-glucose initial-lactose initial-glucose ]
turtles-own [ speed ]
patches-own [ inside? near-dna? ]
genes-own [ protein ]
rnas-own [ protein ]
polymerases-own [ transcription? ]
repressors-own [ bound? complexed? lifespan ]
permeases-own [ bound? lifespan ]
galactosidases-own [ complexed? lifespan ]
promoters-own [ strength base-strength ]
CAPs-own [ complexed? bound? ]
ATPs-own [ lifespan ]
operators-own [ binds-with ]
membranes-own [ binds-with ]



to setup
  clear-all
  ioda:load-interactions "interactions.txt"
  ioda:load-matrices "matrix.txt" " \t"
  init-cell
  ioda:setup
  ioda:set-metric "Moore"
  reset-ticks
end

to init-cell
  set-default-shape genes "dna"
  set-default-shape RNAs "mrna"
  set-default-shape promoters "dna"
  set-default-shape operators "dna"
  set-default-shape terminators "dna"
  set-default-shape repressors "repressor"
  set-default-shape membranes "membrane"
  set-default-shape polymerases "arrow"
  set-default-shape lactoses "lactose"
  set-default-shape glucoses "glucose"
  set-default-shape permeases "permease"
  set-default-shape galactosidases "galactosidase"
  set-default-shape CAPs "cap"
  set-default-shape cAMPs "camp"
  set-default-shape ATPs "atp"
  create-cell
end

to create-cell
  ask patches [ set inside? false set near-dna? false]
  ask patches with [ pycor = 0 and abs pxcor < 8 ] [ sprout-genes 1 [ genes::init ]]
  ask patches with [ any? genes-here or any? neighbors with [any? genes-here]] [ set near-dna? true ]
  ask patches with [ abs pycor = 7 and abs pxcor <= 10 ] [ sprout-membranes 1 [ set color gray set heading 0 if pycor < 0 [ set heading 180]]]
  ask patches with [ abs pxcor = 10 and abs pycor < 7 ] [ sprout-membranes 1 [ set color gray set heading 90 if pxcor < 0 [ set heading -90]]]
  ask patches with [ abs pxcor < 10 and abs pycor < 7 ] [ set inside? true set pcolor black + 1]
  ask membranes [ set color gray set binds-with [ -> permeases ]  ]
  build-operon
  create-polymerases 20 [ polymerases::init ]
  create-repressors 10 [ repressors::init ]
  create-CAPs 10 [ caps::init ]
  create-cAMPs 20 [ camps::init]
  create-ATPs 20 [ atps::init]
  ask patches [set pcolor
    ifelse-value inside? [ white - 1 ] [white]]
end

to build-operon
  ask genes-on patch 0 0 [ set breed promoters set base-strength 0.1 promoters::init ]
  ask genes-on patch 1 0 [ set breed operators set color orange set binds-with [ -> repressors ]]
  ask genes-on patch 2 0 [ set protein galactosidases set color violet ]
  ask genes-on patch 3 0 [ set protein permeases set color lime ]
  ask genes-on patch 4 0 [ set breed terminators set color pink]
  ask genes-on patch -1 0 [ set breed operators set color orange set binds-with [ -> CAPs with [ complexed? ] ]]
  ask genes-on patch -2 0 [ set breed terminators set color pink ]
  ask genes-on patch -3 0 [ set protein repressors set color red ]
  ask genes-on patch -4 0 [ set breed promoters set base-strength 1 promoters::init ]
end

to polymerases::init
  set speed 0.1
  set color orange
  set transcription? false
  move-to one-of patches with [ near-dna? ]
  set size 0.5
  ioda:init-agent
end

to promoters::init
  set color yellow set heading 90
  set strength base-strength
  ioda:init-agent
end

to repressors::init
  set speed 0.1
  set color red
  move-to one-of patches with [ near-dna?]
  set bound? false
  set complexed? false
  set lifespan random-poisson 400
  ioda:init-agent
end

to add-lactose [ nb ]
  create-lactoses nb [ lactoses::init ]
end

to add-glucose [ nb ]
    create-glucoses nb [ move-to one-of patches with [not inside? and not any? membranes-here] glucoses::init ]
end

to lactoses::init
  set speed 0.2
  move-to one-of patches with [not inside? and not any? membranes-here]
  ioda:init-agent
end

to genes::init
  set color brown
  set heading 0
  set protein nobody
  ioda:init-agent
end

to-report out-lactose
  report  (count lactoses-on patches with [not inside?]) / (count patches with [not inside?])
end

to-report out-glucose
  report  (count glucoses-on patches with [not inside?]) / (count patches with [not inside?])
end

to-report in-lactose
  report  (count lactoses-on patches with [inside?]) / (count patches with [inside?])
end

to-report in-glucose
  report  (count glucoses-on patches with [inside?]) / (count patches with [inside?])
end

to go
  ioda:go
  if constant-concentrations?
    [ if out-lactose < initial-lactose
        [ add-lactose 1 ]
      if out-glucose < initial-glucose
        [ add-glucose 1 ]
    ]
  tick
end


to wiggle [angle]
  right random angle left random angle
end


to-report polymerases::time-to-turn?
  report not transcription? and random 100 < 5
end

to polymerases::random-turn
  set heading random 360
end


to-report polymerases::can-move?
  report [near-dna?] of patch-ahead speed
end

to polymerases::advance
  fd speed
end

to-report lactoses::can-move?
  report not any? membranes-on patch-ahead speed
end

to-report lactoses::time-to-turn?
  report random 100 < 5
end

to lactoses::advance
  fd speed
end

to lactoses::random-turn
  wiggle 60
end

to-report lactoses::chance-to-cross?
  report random-float 1000 < natural-permeability
end

to-report membranes::permeable?
  report false
end

to lactoses::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-ahead 1)
end

to lactoses::move-to-other-side
 let x [xcor] of ioda:my-target
 let y [ycor] of ioda:my-target
 setxy (xcor + (x - xcor) * 2) (ycor + (y - ycor) * 2)
end

to-report repressors::can-move?
  report [near-dna?] of patch-ahead speed
end

to-report repressors::time-to-turn?
  report random 100 < 5
end

to repressors::advance
  fd speed
end

to repressors::random-turn
  wiggle 60
end

to-report polymerases::transcribing?
  report transcription?
end

to polymerases::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here)
end

to polymerases::change-state
  set transcription? not transcription?
end

to polymerases::choose-direction
  move-to [patch-here] of ioda:my-target
  set heading [heading] of ioda:my-target
end

to terminators::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here)
end

to-report operators::occupied?
  let t ioda:my-target
  report (any? repressors-here with [self != t]) or (any? CAPs-here with [self != t])
end

to-report operators::chance-to-unbind?
  report random 1000 < 1
end

to repressors::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here)
end

to operators::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here)
end

to repressors::bind-to-target
  set bound? true
  move-to ioda:my-target
end

to repressors::unbind
  set bound? false
  move-to one-of neighbors
end

to-report repressors::bound?
  report bound?
end

to-report repressors::complexed?
  report complexed?
end

to repressors::make-complex
  set complexed? true
  set shape "repressor-lac"
end

to lactoses::die
  ioda:die
end

to-report repressors::chance-to-dissociate?
  report random 1000 < 1
end

to repressors::break-complex
  hatch-lactoses 1 [ move-to one-of neighbors ioda:init-agent]
  set complexed? false
  set shape "repressor"
end

to-report rnas::chance-for-translation?
  report random 100 < 1
end

to-report rnas::can-move?
  report [inside?] of patch-ahead speed
end

to-report rnas::time-to-turn?
  report random 100 < 5
end

to-report genes::coding?
  report protein != nobody
end

to rnas::build-protein
  let b protein
  hatch 1 [set breed b run ioda:concrete-primitive-task self "init"]
end

to rnas::die
  ioda:die
end

to rnas::advance
  fd speed
end

to rnas::random-turn
  wiggle 60
end

to genes::build-RNA
  hatch-rnas 1 [ set heading random 360 set speed 0.1 fd speed ioda:init-agent ]
end

to galactosidases::init
  set lifespan random-poisson 150
  set complexed? false
  set shape "galactosidase"
  ioda:init-agent
end

to permeases::init
  set lifespan random-poisson 150
  set shape "permease"
  ioda:init-agent
  set bound? false
end

to-report galactosidases::can-move?
  report [inside?] of patch-ahead speed
end

to-report galactosidases::time-to-turn?
  report random 100 < 5
end

to-report permeases::can-move?
  report (not bound?) and ([inside?] of patch-ahead speed) or (any? membranes-on patch-ahead speed)
end

to-report permeases::time-to-turn?
  report random 100 < 5
end

to galactosidases::advance
  fd speed
end

to galactosidases::random-turn
  wiggle 60
end

to permeases::advance
  fd speed
end

to permeases::random-turn
  wiggle 60
end

to-report promoters::occupied?
  let t ioda:my-target
  report any? other turtles-here with [ self != t ]
end

to-report membranes::occupied?
  let t ioda:my-target
  report any? other turtles-here with [ self != t ]
end

to permeases::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-ahead 1)
end

to permeases::bind-to-target
  let t ioda:my-target
  move-to t
  set heading [heading] of t
  ask t [set color alphaize color 100]
  set bound? true
end

to-report alphaize [ col value ]
  let lrgb ifelse-value is-list? col [ col ] [ extract-rgb col ]
  report lput value (sublist lrgb 0 3)
end

to-report permeases::bound?
  report bound?
end

to-report permeases::permeable?
  report bound? and [not inside?] of ioda:my-target
end

to-report galactosidases::time-to-die?
  report (lifespan <= 0) and not complexed?
end

to-report permeases::time-to-die?
  report lifespan <= 0
end

to galactosidases::increase-age
  set lifespan lifespan - 1
end

to galactosidases::die
  ioda:die
end

to permeases::increase-age
  set lifespan lifespan - ifelse-value bound? [0.5] [1]
end

to permeases::die
  if bound? and any? membranes-here
    [ ask membranes-here
      [ set color gray ]]
  ioda:die
end

to-report galactosidases::complexed?
  report complexed?
end

to galactosidases::make-complex
  set complexed? true
  set shape "galactosidase-lac"
end

to-report galactosidases::chance-to-dissociate?
  report random 100 < 5
end

to galactosidases::break-complex
  set complexed? false
  hatch-glucoses 1 [ glucoses::init ]
  set shape "galactosidase"
end

to glucoses::init
  set shape "glucose"
  set speed 0.2
  set heading random 360
  ioda:init-agent
end

to-report glucoses::can-move?
  report not any? membranes-on patch-ahead speed
end

to-report glucoses::time-to-turn?
  report random 100 < 5
end

to glucoses::advance
  fd speed
end

to glucoses::random-turn
  wiggle 60
end

to-report terminators::active?
  report true
end

to-report repressors::active?
  report not complexed?
end

to-report repressors::time-to-die?
  report lifespan <= 0
end

to repressors::increase-age
  set lifespan lifespan - 1
end

to repressors::die
  if complexed? [ repressors::break-complex ]
  ioda:die
end

to-report promoters::affinity-for-source?
  report random-float 1.0 <= strength
end

to caps::init
  set speed 0.1
  set complexed? false
  set bound? false
  move-to one-of patches with [ near-dna? ]
  ioda:init-agent
end

to camps::init
  set speed 0.2
  move-to one-of patches with [ inside? ]
  set color blue - 2
  ioda:init-agent
end

to atps::init
  set speed 0.2
  set lifespan (random-poisson 300) - (random 100)
  set color blue + 2
  move-to one-of patches with [inside?]
  ioda:init-agent
end


to-report atps::can-move?
  report [inside?] of patch-ahead speed
end

to-report atps::time-to-turn?
  report random 100 < 5
end

to-report camps::can-move?
  report [inside?] of patch-ahead speed
end

to-report camps::time-to-turn?
  report random 100 < 5
end

to-report caps::can-move?
  report [near-dna?] of patch-ahead speed
end

to-report caps::time-to-turn?
  report random 100 < 5
end

to atps::advance
  fd speed
end

to atps::random-turn
  wiggle 60
end

to camps::advance
  fd speed
end

to camps::random-turn
  wiggle 60
end

to caps::advance
  fd speed
end

to caps::random-turn
  wiggle 60
end

to-report atps::time-to-die?
  report lifespan <= 0
end

to atps::increase-age
  set lifespan lifespan - 1
end

to atps::die
  hatch-camps 1  [ set color blue - 2 ioda:init-agent ]
  ioda:die
end

to-report camps::complexed?
  report false
end

to glucoses::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-ahead 1)
end

to camps::make-complex
  hatch-atps 1 [ set lifespan random-poisson 300 set color blue + 2 ioda:init-agent ]
  ioda:die
end

to glucoses::die
  ioda:die
end

to-report glucoses::chance-to-cross?
  report (random-float 1000 < natural-permeability) and (not inside?)
end

to glucoses::move-to-other-side
 let x [xcor] of ioda:my-target
 let y [ycor] of ioda:my-target
 setxy (xcor + (x - xcor) * 2) (ycor + (y - ycor) * 2)
end

to-report caps::complexed?
  report complexed?
end

to camps::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-ahead 1)
end

to caps::make-complex
  set complexed? true
  set shape "cap-camp"
end

to camps::die
  ioda:die
end

to-report caps::chance-to-dissociate?
  report random 1000 < 10
end

to caps::break-complex
  hatch-camps 1 [ set color blue - 2 move-to one-of neighbors ioda:init-agent ]
  set complexed? false
  set bound? false
  set shape "cap"
end

to-report membranes::allows-binding?
  report member? ioda:my-target runresult binds-with
end

to-report operators::allows-binding?
  report member? ioda:my-target runresult binds-with
end

to caps::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here neighbors4)
  ioda:remove-neighbors-on-patches (neighbors with [any? promoters-here])
end

to caps::bind-to-target
  set bound? true
  move-to ioda:my-target
  let p promoters-on neighbors
end

to-report caps::bound?
  report bound?
end

to promoters::filter-neighbors
  ioda:filter-neighbors-on-patches (patch-set patch-here patch-ahead -1)
end

to promoters::increase-strength
  set strength 1
end

to promoters::reduce-strength
  set strength base-strength
end

to caps::unbind
  set bound? false
  move-to one-of neighbors
end

to-report repressors::bad-conformation?
  report complexed?
end

to-report caps::bad-conformation?
  report false
end

to-report glucoses::chance-to-unbind?
  report true
end

to-report caps::promoter-nearby?
  report any? promoters-on neighbors4
end


to caps::help-target
  let p promoters-on neighbors4
  if any? p
    [ ask ioda:my-target [ move-to one-of p face myself right 180 ] ]
end

to polymerases::align-to-target
  let t ioda:my-target
  setxy xcor [ycor] of t
  let dh abs (subtract-headings heading 90)
  if (dh > 2) and (abs (dh - 180) > 2) [ set heading 90 + 180 * random 2]
end

to-report polymerases::aligned?
  let t ioda:my-target
  if abs (ycor - [ycor] of t) > 0.1
    [ report false ]
  let dh abs (subtract-headings heading 90)
  report (dh <= 2) or (abs (dh - 180) <= 2)
end
@#$#@#$#@
GRAPHICS-WINDOW
482
90
1310
599
-1
-1
20.0
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
-12
12
1
1
1
ticks
30.0

BUTTON
482
10
548
43
setup
setup\n
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
481
49
544
82
go
;if (ticks mod 10 = 0) [movie-grab-view]\ngo
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
559
10
751
43
natural-permeability
natural-permeability
0
50
13.0
1
1
‰
HORIZONTAL

PLOT
8
10
474
202
Metabolites
time
unit/patch
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"out-lactose" 1.0 0 -8431303 true "" "plot (count lactoses-on patches with [not inside?]) / (count patches with [not inside?])"
"in-lactose" 1.0 0 -1184463 true "" "plot (count lactoses-on patches with [inside?]) / (count patches with [inside?])"
"out-glucose" 1.0 0 -10141563 true "" "plot (count glucoses-on patches with [not inside?]) / (count patches with [inside?])"
"in-glucose" 1.0 0 -13345367 true "" "plot (count glucoses-on patches with [inside?]) / (count patches with [inside?])"

BUTTON
788
10
890
43
add lactose
add-lactose 200\nset initial-lactose out-lactose
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
896
10
1005
43
clear lactose
ask lactoses with [ioda:alive?] [ioda:die]
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
8
206
473
422
Proteins
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
"galacosidase" 1.0 0 -8630108 true "" "plot count galactosidases"
"permease" 1.0 0 -10899396 true "" "plot count permeases"
"c-repressor" 1.0 0 -2064490 true "" "plot count repressors with [ complexed? ]"
"b-repressor" 1.0 1 -955883 true "" "plot count repressors with [ bound? ]"
"repressors" 1.0 0 -2674135 true "" "plot count repressors"

PLOT
8
426
474
619
Energy
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
"ATP" 1.0 0 -8020277 true "" "plot count ATPs"
"cAMP" 1.0 0 -15390905 true "" "plot count cAMPs"

BUTTON
897
49
1005
82
clear glucose
ask glucoses with [ioda:alive?] [ioda:die]
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
788
49
890
82
add glucose
add-glucose 200\nset initial-glucose out-glucose\n  
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
561
49
778
82
constant-concentrations?
constant-concentrations?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This example is a very schematic model of the "Lactose operon" (or LAC operon), a genetic structure described in _Escherichia coli_ by François Jacob, Jacques Monod and André Lwoff (Nobel prize 1965). The underlying concepts are the key ideas of genetic regulation. The LAC operon model explains how bacteria are able to switch from glucose metabolism to lactose metabolism when no glucose is available.

## HOW IT WORKS

In this model, the `setup` button initializes a single cell (prokaryote) with its DNA strand, composed of different items (genes, operator/promoter/terminator segments). Genes are transcribed by the RNA-polymerase into RNA, which in turn are translated into specific proteins. Some of those proteins have a regulatory activity upon gene transcription, while others are in charge of glucose/lactose metabolism, and others are responsible for membrane permeability. 

The model exhibits several cell reactions depending on the nature of metabolites which are available in the environment.

The principle of this model is the following:

  * The LAC operon is composed of a sequence of three genes, starting with an operator site and ending with a terminator site (actually, only the two first genes are used in the current model).
  * In order to have those genes transcribed into RNA, the RNA polymerase has to bind first to the promoter site which is located just before the LAC operon. Then, the polymerase builds RNA strands which, in turn, are translated into the corresponding proteins. One (beta-galactosidase, purple) is in charge of hydrolyze the lactose, while another one (permease, green) binds to the cell membrane and make lactose molecules enter the cell.
  * Most of the time, the expression of those genes is **repressed**, because a repressor protein binds to the operator site of the LAC operon, preventing the RNA to bind to the promoter. The repressor is itself the result of the transcription and translation of a specific gene.
  * But, lactose molecules form a complex with that repressor, changing its shape so that it cannot bind to the operator site.

Thus, usually lactose-related genes are not expressed in the cell. Now, if lactose enters the cell (e.g. due to the natural permeability of the membrane), it disables the repressors, so that the LAC genes get expressed. The resulting proteins accelerate the entering of lactose, but also its use in the metabolic pathways.

Besides this, bacteria are also able to use rather glucose when lactose and glucose are available at the same time. This feature is also modeled here:

  * The affinity of the RNA polymerase to the LAC promoter is naturally low. It can however be enhanced by the presence of a specific complex just before the promoter: the CAP-cAMP complex. It is built from a protein (CAP) and cyclic adenosine monophosphate (cAMP). 
  * cAMP is produced when the cell lacks energy (low glucose) ; conversely the presence of glucose converts cAMP to ATP (adenosine triphosphate) which plays the role of energy reserve.

Thus, when glucose is present in the cell, no cAMP can be found: even if some lactose molecules disable the repressor, the low affinity of the RNA polymerase for the LAC promoter prevents the LAC genes to be transcribed. Converserly, a lack of glucose leads to the accumulation of cAMP, thus a high affinity of the RNA polymerase for the LAC promoter: as soon as lactose inhibits the repressor, the transcription of the LAC genes is able to start.
 
## HOW TO USE IT

Just click `setup` to initialize the cell and its components. Then, run `go` for a while. Very quickly, you should get a repressed LAC operon with no (or few) LAC proteins. The repressor gene is transcribed and the corresponding RNA strands translated into repressor proteins. On the second plot ("Proteins"), you can see that one repressor is bound most of the time to the operator site (b-repressors, orange). Meanwhile, on the third plot ("Energy") you can see that the number of cAMP is growing (at the expense of ATP). cAMP form complexes with CAP molecules and bind before the promoter site.

Then, if you add some lactose (green triangles) outside the cell, a few molecules cross
the membrane and start forming complexes with the repressors (c-repressor on the second plot). When all repressors are disabled, thanks to the CAP-cAMP complex, the transcription and translation of the LAC genes can start. Especially, the permease (green) binds to the membrane and helps more lactos molecules to enter the cell, while the galactosidase (purple) hydrolyzes them (producing thus glucose). The first plot ("Metabolites") allow you to track the concentrations of metabolites inside and outside the cell. Of course it takes some time for the cell to digest all lactose available.

Converserly, you can start by adding glucose. While the cell is eating glucose, it is less likely to react to the introduction of lactose, since a high energy level (ATP) 
maintains the affinity of the RNA polymerase for the LAC promoter to a low level.

You can also try to use the `constant-concentrations?` switch which keeps the initial concentration of lactose/glucose outside the cell at its initial level (adding the corresponding molecules).
 
## THINGS TO NOTICE

We acknowledge that actual chemical pathways are much more complicated. Yet, this model gives an insight of what happens in the cell when it is exposed to different sugars. The existence of multiple actors with many interactions makes the IODA approach quite useful to address such models, and can be extended to other regulatory networks. 


## HOW TO CITE

  * More information on the LAC operon: http://en.wikipedia.org/wiki/Lac_operon
  * Original publication: F. JACOB, J. MONOD (1961), "Genetic regulatory mechanisms in the synthesis of proteins". _J Mol Biol._ vol. 3 (3), p. 318–356. DOI:10.1016/S0022-2836(61)80072-7
  * **The IODA methodology and simulation algorithms** (i.e. what is actually in use in this NetLogo extension):  
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

atp
true
10
Circle -13345367 true true 86 11 127
Rectangle -13345367 true true 135 135 165 300
Circle -1184463 true false 120 150 30
Circle -1184463 true false 120 195 30
Circle -1184463 true false 120 240 30

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

camp
true
10
Circle -13345367 true true 86 41 127
Circle -13345367 true true 116 161 67
Circle -16777216 true false 135 180 30
Circle -1184463 true false 105 195 30

cap
true
0
Polygon -14835848 true false 240 135 225 120 180 120 150 135 135 165 135 195 135 225 165 240 120 255 75 210 60 150 75 90 150 75 240 90

cap-camp
true
0
Polygon -14835848 true false 240 135 225 120 180 120 150 135 135 165 135 195 135 225 165 240 120 255 75 210 60 150 75 90 150 75 240 90
Circle -13345367 true false 141 126 108
Circle -13345367 true false 161 221 67
Circle -16777216 true false 180 240 30
Circle -1184463 true false 150 255 30

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

dna
false
3
Polygon -6459832 true true 345 75 300 75 240 240 165 240 165 285 255 285 315 120 405 120 405 75
Polygon -7500403 true false 105 15 60 15 0 180 -75 180 -75 225 15 225 75 60 165 60 165 15
Polygon -6459832 true true 45 75 90 75 150 240 225 240 225 285 135 285 75 120 -15 120 -15 75
Polygon -7500403 true false 300 225 255 225 195 60 120 60 120 15 210 15 270 180 360 180 360 225
Line -7500403 false 120 60 120 150
Line -7500403 false 165 60 165 240
Line -7500403 false 210 105 210 240

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

galactosidase
true
0
Polygon -8630108 true false 300 90 225 195 150 90 150 45 45 45 15 150 30 255 300 255

galactosidase-lac
true
0
Polygon -13840069 true false 225 180 165 90 165 60 285 60 285 90
Polygon -8630108 true false 300 90 225 195 150 90 150 45 45 45 15 150 30 255 300 255

glucose
true
0
Polygon -13791810 true false 0 255 75 75 225 180 300 60 225 240 75 135

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

lactose
true
0
Polygon -13840069 true false 75 150 165 90 195 90 195 210 165 210

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

membrane
true
0
Circle -2674135 true false 0 30 60
Circle -2674135 true false 93 31 60
Circle -2674135 true false 206 32 60
Circle -2674135 true false 60 210 60
Circle -2674135 true false 165 210 60
Circle -2674135 true false 270 210 60
Polygon -7500403 true true 15 90 0 135 30 195 45 195 15 135 30 90
Polygon -7500403 true true 120 90 105 135 135 195 150 195 120 135 135 90
Polygon -7500403 true true 225 90 210 135 240 195 255 195 225 135 240 90
Polygon -7500403 true true 270 105 255 150 285 210 300 210 270 150 285 105
Polygon -7500403 true true 165 105 150 150 180 210 195 210 165 150 180 105
Polygon -7500403 true true 75 105 60 150 90 210 105 210 75 150 90 105
Circle -2674135 true false -30 210 60

mrna
true
0
Polygon -7500403 true true -15 255 30 255 60 75 90 75 90 45 45 45 15 225 -15 225 -15 255
Polygon -7500403 true true 210 45 255 45 285 225 315 225 315 255 270 255 240 75 210 75 210 45
Polygon -7500403 true true 60 45 105 45 135 225 165 225 165 255 120 255 90 75 60 75 60 45
Polygon -7500403 true true 135 255 180 255 210 75 240 75 240 45 195 45 165 225 135 225 135 255

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

permease
true
0
Polygon -10899396 true false 270 15 270 90 225 150 225 300 180 300 180 150 225 90 225 15
Polygon -10899396 true false 30 15 30 90 75 150 75 300 120 300 120 150 75 90 75 15

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

repressor
true
0
Polygon -7500403 true true 255 75 210 30 90 30 30 90 30 210 90 270 210 270 255 225 150 150

repressor-lac
true
0
Polygon -7500403 true true 255 75 210 30 90 30 30 90 30 210 90 270 210 270 255 225 150 150
Polygon -13840069 true false 165 150 255 90 285 90 285 210 255 210

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
