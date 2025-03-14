globals [
  infinity
  highlight-string
  ticktimer
  ticktimerswitch

  average-path-length-of-lattice
  average-path-length

  clustering-coefficient-of-lattice
  clustering-coefficient

  numnodes
  skepticism
  friendliness
  pollution
  pvar
  totgeneralhealth
  totvictimhealth
  totleaderhealth
  avggeneralhealth
  avgvictimhealth
  avgleaderhealth
  totgeneralcc
  totvictimcc
  totleadercc
  totgenerallinkneighbors
  totvictimlinkneighbors
  totleaderlinkneighbors
  avggeneralcc
  avgvictimcc
  avgleadercc
  generalcc
  leadercc
  victimcc
  avggenerallinkneighbors
  avgvictimlinkneighbors
  avgleaderlinkneighbors
  avggenerallinkneighbordelta
  avgvictimlinkneighbordelta
  avgleaderlinkneighbordelta
  deadcircles
  deadstars
  deadtriangles
  tothouseholds
  totcircles
  tottriangles
  totstars
  totsquares
  generaldr
  victimdr
  faccuserdr
  pctvictims
  timetoritual
  timetoritualswitch
  ritualtime
  timetoleader
  timetoleaderswitch
]

breed [households household]
breed [wells well]
breed [deadhouseholds deadhousehold]

extensions [ nw ]

households-own [
  tension
  accuser
  faccuser
  faccused
  accused
  health
  countlinkneighbors
  countlinkneighborsprime
  deltalinkneighbors
  dead
  stopsign
  accuseswitch
  linkswitch
  distance-from-other-households ; list of distances of this node from other households
  my-clustering-coefficient   ; the current clustering coefficient of this node
  my-clustering-coefficient-round
]


to startup
  set highlight-string ""
end

to setup
  clear-all
  reset-ticks

  set pollution 0
  set pvar 0
  set totgeneralhealth 0
  set totvictimhealth 0
  set totleaderhealth 0
 set  avggeneralhealth 0
  set avgvictimhealth 0
  set avgleaderhealth 0
  set totgeneralcc 0
  set totvictimcc 0
  set totleadercc 0
  set avggeneralcc 0
  set avgvictimcc 0
  set avgleadercc 0
  set generalcc 0
  set leadercc 0
  set victimcc 0
  set totgenerallinkneighbors 0
  set totvictimlinkneighbors 0
  set totleaderlinkneighbors 0
  set avggenerallinkneighbors 0
  set avgvictimlinkneighbors 0
  set avgleaderlinkneighbors 0
  set avggenerallinkneighbordelta 0
  set avgvictimlinkneighbordelta 0
  set avgleaderlinkneighbordelta 0
  set deadcircles 0
  set deadstars 0
  set deadtriangles 0
  set totcircles 0
  set tottriangles 0
  set totstars 0
  set totsquares 0
  set generaldr 0
  set victimdr 0
  set faccuserdr 0
  set timetoritual 0
  set timetoritualswitch 0
  set ritualtime 0
  set ticktimer 0
  set ticktimerswitch 0
  set timetoleader 0
  set timetoleaderswitch 0

  set numnodes (random 70) + 30
  set skepticism (random 50) + 50
  set friendliness (random 20)

  ; set the global variables
  set infinity 99999
  set highlight-string ""

  ; make the nodes and arrange them in a circle in order by who number
  set-default-shape households "circle"
  create-households numnodes
  layout-circle (sort households) max-pxcor - 1


  ; Create the initial lattice
  wire-lattice

  ; Fix the color scheme
  ask households [
    set color green
    set tension 0
    set accuser 0
    set accused 0
    set dead 0
    set health 4
    set countlinkneighbors 0
    set countlinkneighborsprime 0
    set stopsign green
  ]
  ask links [ set color gray + 2 ]

  ; Calculate the initial average path length and clustering coefficient
  set average-path-length find-average-path-length
  set clustering-coefficient find-clustering-coefficient

  set average-path-length-of-lattice average-path-length
  set clustering-coefficient-of-lattice clustering-coefficient

  create-wells 1 [setxy 0 0]
  ask wells
  [
    set shape "circle"
    set size 4
    set color blue
    set pollution 0
  ]

end

to-report in-neighborhood? [ hood ]
  report ( member? end1 hood and member? end2 hood )
end


to-report find-clustering-coefficient

  let cc infinity

  ifelse all? households [ count link-neighbors <= 1 ] [
    ; it is undefined
    ; what should this be?
    set cc 0
  ][
    let total 0
    ask households with [ count link-neighbors <= 1 ] [ set my-clustering-coefficient "undefined" ]
    ask households with [ count link-neighbors > 1 ] [
      let hood link-neighbors
      set my-clustering-coefficient (2 * count links with [ in-neighborhood? hood ] /
                                         ((count hood) * (count hood - 1)) )
      ; find the sum for the value at households
      set total total + my-clustering-coefficient
    ]
    ; take the average
    set cc total / count households with [count link-neighbors > 1]
  ]

  report cc
end


to-report find-average-path-length

  let apl 0

  find-path-lengths

  let num-connected-pairs sum [length remove infinity (remove 0 distance-from-other-households)] of households
  ifelse num-connected-pairs != (count households * (count households - 1)) [
    set apl infinity
  ][
    set apl (sum [sum distance-from-other-households] of households) / (num-connected-pairs)
  ]

  report apl
end


to find-path-lengths
  ask households [
    set distance-from-other-households []
  ]

  let i 0
  let j 0
  let k 0
  let node1 one-of households
  let node2 one-of households
  let node-count count households
  while [i < node-count] [
    set j 0
    while [ j < node-count ] [
      set node1 household i
      set node2 household j
      ifelse i = j [
        ask node1 [
          set distance-from-other-households lput 0 distance-from-other-households
        ]
      ][
        ifelse [ link-neighbor? node1 ] of node2 [
          ask node1 [
            set distance-from-other-households lput 1 distance-from-other-households
          ]
        ][ ;
          ask node1 [
            set distance-from-other-households lput infinity distance-from-other-households
          ]
        ]
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  set i 0
  set j 0
  let dummy 0
  while [k < node-count] [
    set i 0
    while [i < node-count] [
      set j 0
      while [j < node-count] [
        set dummy ( (item k [distance-from-other-households] of household i) +
                    (item j [distance-from-other-households] of household k))
        if dummy < (item j [distance-from-other-households] of household i) [
          ask household i [
            set distance-from-other-households replace-item j distance-from-other-households dummy
          ]
        ]
        set j j + 1
      ]
      set i i + 1
    ]
    set k k + 1
  ]

end

to wire-lattice
  ; iterate over the households
  let n 0
  while [ n < count households ] [
    ; make edges with the next two neighbors
    ; this makes a lattice with average degree of 4
    make-edge household n
              household ((n + 1) mod count households)
              "default"
    ; Make the neighbor's neighbor links curved
    make-edge household n
              household ((n + 2) mod count households)
              "curve"
    set n n + 1
  ]


  ask link 0 (count households - 2) [ set shape "curve-a" ]
  ask link 1 (count households - 1) [ set shape "curve-a" ]
end

to make-edge [ node-A node-B the-shape ]
  ask node-A [
    create-link-with node-B  [
      set shape the-shape
    ]
  ]
end


to highlight
  ask households [ set color gray + 2 ]
  ask links   [ set color gray + 2 ]

  if mouse-inside? [ do-highlight ]


  display
end

to do-highlight
  let min-d min [ distancexy mouse-xcor mouse-ycor ] of households
  let node one-of households with [count link-neighbors > 0 and distancexy mouse-xcor mouse-ycor = min-d]

  if node != nobody [
    ask node [
      set color white
      let pairs (length remove infinity distance-from-other-households)
      let my-apl (sum remove infinity distance-from-other-households) / pairs

      let coefficient-description ifelse-value my-clustering-coefficient = "undefined"
        ["undefined for single-link"]
        [precision my-clustering-coefficient 3]
      set highlight-string (word "clustering coefficient = " coefficient-description
        " and avg path length = " precision my-apl 3
        " (for " pairs " households )")
    ]

    let neighbor-nodes [ link-neighbors ] of node
    let direct-links [ my-links ] of node

    ask neighbor-nodes [
      set color orange
      ask my-links [
        ifelse (end1 = node or end2 = node)
          [ set color orange ]
          [ if (member? end1 neighbor-nodes and member? end2 neighbor-nodes) [ set color yellow ]
        ]
      ]
    ]
  ]
end

to go
  if any? households with [shape = "square" and dead = 0]
  [set ticktimerswitch 1]

  if ticktimerswitch = 1
  [set ticktimer ticktimer + 1]

  if ticktimer > 1999
  [
    if datacollector?
  [
  file-open "scapegoat.txt"
    file-print (word numnodes ", " friendliness " , "skepticism " , "pctvictims " , " avggeneralhealth " , " avgleaderhealth " , " avgvictimhealth " , " avggenerallinkneighbors " , " avgvictimlinkneighbors " , " avgleaderlinkneighbors " , " avggenerallinkneighbordelta " , " avgvictimlinkneighbordelta " , " avgleaderlinkneighbordelta " ," avggeneralcc " , " avgleadercc " , " avgvictimcc " , " generaldr " , " faccuserdr " , " victimdr " , "timetoritual" , "ritualtime ", "timetoleader)
    file-close
    ]
     setup
  ]

    tick

  ask households
  [
    set stopsign green
    set accuseswitch green
    set linkswitch green
  ]





  if any? households with [accused = 1]
  [
    ask households with [dead = 0]
    [
      set tension 0
      set accused 0
      set faccuser 0
      set faccused 0
    ]
  ]

  ask households with [dead = 0 and color != blue]
  [
    set accuser 0
    set accused 0
    set faccuser 0
    set faccused 0
  ]

  ask households with [dead = 0 and color != blue]
  [
    if tension < 0
    [set tension 0]
    if tension > 3
    [set tension 3]

    if tension = 0
    [set color green]
    if tension = 1
    [set color yellow]
    if tension = 2
    [set color orange]
    if tension = 3
    [set color red]


  ]


  if random 100 > 93
  [
    ask one-of links
    [die]
  ]

  if random 100 > 93
  [
    ask one-of households with [dead = 0 and color != blue]
    [
      create-link-with one-of other households with [dead = 0] who-are-not link-neighbors
    ]
  ]

  if random 100 > 90 and count households with [dead = 1] > 0
  [
    ask one-of households with [dead = 1]
    [
      set dead 0
      set accuser 0
      set accused 0
      set faccuser 0
      set faccused 0
      set tension 0
      set health 3
      set shape "circle"
      set color green
      set size 1
      create-link-with min-one-of other households who-are-not link-neighbors [distance myself]
      create-link-with min-one-of other households who-are-not link-neighbors [distance myself]
      create-link-with min-one-of other households who-are-not link-neighbors [distance myself]
      create-link-with min-one-of other households who-are-not link-neighbors [distance myself]
      set countlinkneighborsprime 4
    ]
  ]




  ask households with [dead = 0]
  [
    if random 100 = 1
    [
      set tension tension + 1
      set stopsign red
    ]
  ]





  ask households with [dead = 0]
  [
    if health < 4
    [set health health + 0.1]
    if tension > 0
    [
      if pollution = 1
      [
        set tension tension - random 1
        set stopsign red
      ]
      if pollution = 2
      [
        set tension tension + random 1
        set stopsign red
      ]
      if pollution = 3
      [
        set tension tension + 1
        set stopsign red
      ]
    ]

    if tension > 2
    [
      ask link-neighbors
      [
      if stopsign = green
      [
          if random 100 > 50
          [
        set tension tension + 1
        set stopsign red
          ]
      ]
      ]
    ]
  ]

  ask households with [dead = 0]
  [
    if all? link-neighbors [color = red]
    [
      if random 100 > 74
      [
        set health health - 0.5
      ]
    ]
  ]

  if any? households with [shape = "square" and color != blue]
  [
    if random 100 > 97
    [
      ask one-of households with [shape = "square" and color != blue]
      [
        set shape "circle"
        set size 1
      ]
    ]
  ]


  ask households
  [
    if health > 4
    [
      set health 4
    ]
    if health < 1
    [
      set dead 1
      set color black
      set size 0
      ask my-links [die]
      if shape = "circle"
    [
        set deadcircles deadcircles + 1
  ]
      if shape = "star"
    [
        set deadstars deadstars + 1
  ]
      if shape = "triangle"
    [
        set deadtriangles deadtriangles + 1
  ]
    ]
  ]





ask households
  [
  if scapegoat?
    [

      if count households with [shape = "star" and dead = 0] > count households with [dead = 0] / 10 and any? households with [shape = "square" and dead = 0] and not any? households with [color = blue]
        [
        ask one-of households with [dead = 0 and shape = "square"]
        [
          set accuser 1
                  set shape "square"
                  set color blue
                  set size 3
                ask one-of households with [shape = "star" and dead = 0]
                [
                  set accused 1
                  set size 3
                  set color blue
                 set health 0
              if not datacollector?
              [
                wait 1
              ]
                ask other households with [shape != "square" and dead = 0 and color != blue]
                [
                  set shape "circle"
                  set color green
                  set size 1
                  set accuser 0
                  set accused 0
                  set tension 0
                    if nw:distance-to one-of other households with [dead = 0 and shape = "square"] != false
                    [
                    if random 100 > ((65 + friendliness + (nw:distance-to min-one-of other households with [dead = 0 and shape = "square"] [distance myself] * 2)))
                    [
                    create-link-with one-of other households with [shape = "square" and dead = 0]
                    ]
                    ]

                ]
              ask households
              [set accuseswitch red]
                ]
              ]
      ]



      if accuseswitch = green
      [
        if any? households with [shape = "square" and color = blue]
        [
          if count households with [color = red] > (.95 * (count households with [dead = 0] - count households with [color = blue]))
          [
          ifelse any? households with [shape = "star" and dead = 0]
          [
          ask one-of households with [shape = "star" and dead = 0]
          [
                 set health 0
                set accused 1
                ask other households with [shape != "square" and dead = 0 and color != blue]
                [
                  set shape "circle"
                  set color green
                  set size 1
                  set accuser 0
                  set accused 0
                  set tension 0
                    if nw:distance-to one-of other households with [dead = 0 and shape = "square"] != false
                    [
                    if random 100 > ((50 + friendliness + (nw:distance-to min-one-of other households with [dead = 0 and shape = "square"] [distance myself] * 2)))
                    [
                    create-link-with one-of other households with [shape = "square" and dead = 0]
                    ]
                ]
                  ]
                ask households
                      [set accuseswitch red]
              ]
            ]

         [
              ask households with [color = blue]
              [
                set shape "circle"
                set color green
                set size 1
                ask households
                [set accuseswitch red]
              ]
            ]
          ]
        ]
      ]






      if accuseswitch = green and not any? households with [color = blue]
      [
        ifelse count households with [shape = "square" and dead = 0] < (count households with [dead = 0] / 20)
          [

  ask one-of households with [dead = 0 and color != blue]
  [
    if tension = 3 and all? link-neighbors [color = red]
      [

                while [accuseswitch = green]
                [
            if random 100 > 74 and accuseswitch = green
          [
              if any? other households with [dead = 0 and count link-neighbors < 2]
            [
                  set faccuser 1
                  set shape "triangle"
                  set color white - 2
                  set size 2
                  set health health - random 5
                  ask one-of other households with [dead = 0 and count link-neighbors < 2]
          [
                set faccused 1
                        if color != blue
                        [
                    set color white - 2
                    set shape "x"
                    set size 2
                          ask households
                        [
                    set accuseswitch red
                        ]
                        ]
              ]
     set stopsign red
                    stop

          ]
          ]

            if random 100 > skepticism and accuseswitch = green
          [
              if any? households with [dead = 0 and shape = "x" and nw:distance-to min-one-of households [distance myself] != false]
            [
                if any? households with [dead = 0 and shape = "x" and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
            [
                  set faccuser 1
                  set shape "triangle"
                  set color white - 2
                  set size 2
                  set health health - random 5
                  ask one-of households with [dead = 0 and shape = "x" and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
          [
                set faccused 1
                          if color != blue
                          [
                    set color white - 2
                    set shape "x"
                    set size 2
                          ]
                          ask households
                        [
                    set accuseswitch red
                        ]
              ]
                      set stopsign red
                      stop
                ]

          ]
          ]

          if random 100 > skepticism and accuseswitch = green
          [
              if any? households with [dead = 0 and nw:distance-to min-one-of households [distance myself] != false]
            [
                if any? households with [dead = 0 and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
            [
                  set faccuser 1
                  set shape "triangle"
                  set color white - 2
                  set size 2
                  set health health - random 5
                  ask one-of households with [dead = 0 and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
          [
                set faccused 1
                          if color != blue
                          [
                    set color white - 2
                    set shape "x"
                    set size 2
                          ]
                          ask households
                        [
                    set accuseswitch red
                        ]
              ]
                  set stopsign red
                      stop
                ]
          ]
          ]

            if random 100 > skepticism and accuseswitch = green
          [
                  set faccuser 1
                  set shape "triangle"
                  set color white - 2
                  set size 2
                  set health health - random 5
                  ask one-of households with [dead = 0 and shape != "square"]
          [
                set faccused 1
                      if color != blue
                      [
                    set color white - 2
                    set shape "x"
                    set size 2
                      ]
                      ask households
                        [
                    set accuseswitch red
                        ]
              ]
                  set stopsign red
                  stop
                ]




if random 100 > 50 and accuseswitch = green
          [
              if any? households with [dead = 0 and count link-neighbors < 2]
              [
                  set accuser 1
                  set shape "square"
                  set color white
                  set size 2
                  ask one-of households with [dead = 0 and count link-neighbors < 2]
          [
            set accused 1
                        if color != blue
                        [
           set shape "star"
            set color white
                    set size 2
                        ]
             set health health - random 5
              ask households
                        [
                    set accuseswitch red
                        ]
                      ]
                  set stopsign red
                    stop
    ]
            ]

          if random 100 > 50 and accuseswitch = green
          [
              if any? households with [dead = 0 and shape = "x" and nw:distance-to min-one-of households [distance myself] != false]
              [
                if any? households with [dead = 0 and shape = "x" and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
            [
                  set accuser 1
                  set shape "square"
                  set color white
                  set size 2
                  ask one-of households with [dead = 0 and shape = "x" and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
          [
            set accused 1
                          if color != blue
                          [
           set shape "star"
            set color white
                    set size 2
                          ]
             set health health - random 5
              ask households
                        [
                    set accuseswitch red
                        ]
                        ]
                  set stopsign red
                      stop
          ]
    ]
            ]


          if random 100 > 50 and accuseswitch = green
          [
              if any? households with [dead = 0 and nw:distance-to min-one-of households [distance myself] != false]
              [
                if any? households with [dead = 0 and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
            [
                  set accuser 1
                  set shape "square"
                  set color white
                  set size 2
                  ask one-of households with [dead = 0 and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
          [
            set accused 1
                          if color != blue
                          [
           set shape "star"
            set color white
                    set size 2
                          ]
             set health health - random 5
              ask households
                        [
                    set accuseswitch red
                        ]
                  set stopsign red
                      stop
          ]
    ]
            ]
                  ]


          if random 100 > 50 and accuseswitch = green
          [
            set accuser 1
                  set shape "square"
                  set color white
              set size 2
              ask one-of households with [dead = 0 and shape != "square"]
            [
              set accused 1
           set shape "star"
            set color white
                set size 2
             set health health - random 5
             ask households
                        [
                    set accuseswitch red
                        ]
            ]
            set stopsign red
                  stop
          ]

          ]
              ]
            ]
      ]

      [

        ask one-of households with [dead = 0 and shape = "square" and color != blue]
            [

              if tension = 3 and all? link-neighbors [color = red]
      [
                while [accuseswitch = green]
                [

          if random 100 > ((skepticism / 100) * 10 + 90) and accuseswitch = green
              [

                  if any? households with [dead = 0 and nw:distance-to min-one-of households [distance myself] != false]
            [
                    if any? households with [dead = 0 and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
            [
                         set faccuser 1
               set shape "triangle"
                    set color white - 2
                        set size 2
                    set health health - random 5
                      ask min-one-of households with [dead = 0 and nw:distance-to one-of households with [faccuser = 1] > 2 and nw:distance-to one-of households with [accuser = 1] < 6] [distance myself]
          [
                set faccused 1
                            if color != blue
                            [
                        set shape "x"
                        set color white - 2
                          set size 2
                            ]
                          ask households
                        [
                    set accuseswitch red
                        ]
              ]
                      set stopsign red
                      stop
          ]
              ]

            ]



if random 100 > 50 and accuseswitch = green
              [
                if any? households with [dead = 0 and count link-neighbors < 2]
            [
                  set accuser 1
                  set color white
                  set size 2
                  ask one-of households with [dead = 0 and count link-neighbors < 2]
                  [
            set accused 1
                          if color != blue
                          [
                    set color white
                    set shape "star"
                            set size 2
                          ]
                    set health health - random 5
              ask households
                        [
                    set accuseswitch red
                        ]
                  ]
                    set stopsign red
                    stop
          ]
    ]


            if random 100 > 50 and accuseswitch = green
            [
                if any? households with [dead = 0 and nw:distance-to min-one-of households [distance myself] != false] and count households with [shape = "x"] > 0
            [
                  if any? households with [dead = 0 and shape = "x" and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
                  [
                  set accuser 1
                  set color white
                  set size 2
                  ask one-of households with [dead = 0 and shape = "x" and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
                  [
            set accused 1
                            if color != blue
                            [
                    set color white
                    set shape "star"
                            ]
                              set size 2
                    set health health - random 5
             ask households
                        [
                    set accuseswitch red
                        ]
                  ]
                      set stopsign red
                      stop
          ]
          ]
            ]


            if random 100 > 50 and accuseswitch = green
            [
                if any? households with [dead = 0 and nw:distance-to min-one-of households [distance myself] != false]
            [
                  if any? households with [dead = 0 and nw:distance-to min-one-of households [distance myself] > 2 and nw:distance-to min-one-of households [distance myself] < 6]
         [
                set accuser 1
                  set color white
                    set size 2
                    ask one-of households with [dead = 0 and nw:distance-to min-one-of households with [accuser = 1] [distance myself] > 2 and nw:distance-to min-one-of households with [accuser = 1] [distance myself] < 6]
          [
                set accused 1
                            if color != blue
                            [
                      set color white
                      set shape "star"
                      set size 2
                            ]
                      set health health - random 5
             ask households
                        [
                    set accuseswitch red
                        ]
                    ]
                      set stopsign red
                      stop
          ]
          ]
            ]


            if random 100 > 50 and accuseswitch = green
          [
                set accuser 1
                  set color white
                    set size 2
                ask one-of households with [dead = 0 and shape != "square"]
          [
                set accused 1
                        if color != blue
                        [
                      set color white
                      set shape "star"
                      set size 2
                        ]
                      set health health - random 5
              ask households
                        [
                    set accuseswitch red
                        ]
                    ]
                  set stopsign red
                  stop
          ]
                ]
              ]
        ]
      ]
  ]
  ]
  ]




  if not any? households with [color = blue]
  [

  if any? households with [dead = 0 and count link-neighbors < 2]
  [
          if random 100 > (80 + friendliness)
          [
           ask households with [dead = 0 and count link-neighbors < 2 and color != blue]
          [
        ifelse any? other households with [dead = 0 and (shape = "star" or shape = "x") and color != blue]
  [
            create-link-with one-of other households with [dead = 0 and (shape = "star" or shape = "x") and color != blue]
            ]
        [
      if random 100 > (90 + friendliness / 2)
      [
       ask households with [dead = 0 and count link-neighbors < 2 and color != blue]
        [
      create-link-with one-of other households with [dead = 0 and color != blue]
        ]
    ]
    ]
      ]
    ]
    ]


  if any? households with [dead = 0 and shape = "square" and color != blue] and any? households with [dead = 0 and shape = "star" and color != blue]
    [
      if any? households with [dead = 0 and shape = "star" and color != blue and nw:distance-to min-one-of other households with [shape = "square" and color != blue] [distance myself] != false]
    [
        ask one-of households with [dead = 0 and shape = "star" and color != blue and nw:distance-to min-one-of other households with [shape = "square"] [distance myself] != false]
  [
          ifelse nw:distance-to min-one-of other households with [dead = 0 and shape = "square" and color != blue] [distance myself] != false
          [
            if nw:distance-to min-one-of other households with [dead = 0 and shape = "square" and color != blue] [distance myself] < 6
              [
            if (random  100 > (80 + friendliness) + nw:distance-to min-one-of other households with [dead = 0 and shape = "square"] [distance myself]) and linkswitch = green
          [
            create-link-with one-of other households with [dead = 0 and shape = "square"]
            set linkswitch red
          ]
          if random 100 > ((80 + (friendliness / 2)) + nw:distance-to min-one-of other households with [dead = 0 and shape = "square"] [distance myself]) and linkswitch = green and any? other households with [shape = "square" and count link-neighbors > 0]
          [
                  if any? other households with [color != blue and nw:distance-to one-of households with [dead = 0 and shape = "square"] != false]
                  [
                    if any? other households with [color != blue and nw:distance-to min-one-of households with [dead = 0 and shape = "square"] [distance myself] = 1]
                    [
                      create-link-with min-one-of other households with [nw:distance-to min-one-of households with [dead = 0 and shape = "square"] [distance myself] = 1] [distance myself]
            set linkswitch red
          ]
          ]
          ]
  ]
  ]
          []
        ]
  ]
    ]

  if any? households with [dead = 0 and shape = "star" and color != blue] and any? households with [dead = 0 and shape = "square" and color != blue]
  [
  if any? households with [dead = 0 and shape = "star" and color != blue and nw:distance-to min-one-of households with [shape = "square"] [distance myself] != false]
  [
    ask one-of households with [dead = 0 and shape = "star" and color != blue and nw:distance-to min-one-of households with [shape = "square"] [distance myself] != false]
    [
    if nw:distance-to min-one-of households with [dead = 0 and shape = "square"] [distance myself] > 2 and nw:distance-to min-one-of households with [dead = 0 and shape = "square"] [distance myself] < 6
      [
        if count link-neighbors > 0
        [
          if any? link-neighbors with [nw:distance-to min-one-of households with [dead = 0 and shape = "square"] [distance myself] != false]
          [
            ask link-with min-one-of link-neighbors [nw:distance-to min-one-of households with [dead = 0 and shape = "square"] [distance myself]]
        [die]
      ]
        ]
      ]
        ]
    ]
    ]

  if any? households with [shape = "square" and dead = 0]
  [
    if any? households with [dead = 0 and color != blue and nw:distance-to min-one-of households with [dead = 0 and shape = "square"] [distance myself] != false]
  [
      ask households with [dead = 0 and color != blue and nw:distance-to min-one-of households with [dead = 0 and shape = "square"] [distance myself] != false]
    [
      if nw:distance-to one-of households with [dead = 0 and shape = "square"] = 5
      [
          if count link-neighbors with [dead = 0 and shape = "square"] > 0
          [
            ask link-with one-of link-neighbors with [dead = 0 and shape = "square"]
        [die]
      ]
          ]
    ]
  ]
  ]
  ]

  set tothouseholds tothouseholds + count households with [dead = 0]
set totcircles totcircles + count households with [shape = "circle" and dead = 0]
  set totstars totstars + count households with [shape = "star" and dead = 0]
  set tottriangles tottriangles + count households with [shape = "triangle" and dead = 0]
  set totsquares totsquares + count households with [shape = "square" and dead = 0]

  set totgeneralhealth totgeneralhealth + sum [health] of households with [shape = "circle" and dead = 0]
    set avggeneralhealth totgeneralhealth / totcircles
  if count households with [shape = "star"] > 0
  [
  set totvictimhealth totvictimhealth + sum [health] of households with [shape = "star" and dead = 0]
  set avgvictimhealth totvictimhealth / totstars
  ]
  if count households with [shape = "square"] > 0
  [
  set totleaderhealth totleaderhealth + sum [health] of households with [shape = "square" and dead = 0]
  set avgleaderhealth totleaderhealth / totsquares
  ]



  set pvar random 100
  if pvar < 25 and pollution > 0
  [set pollution pollution - 1]
  if pvar > 75 and pollution < 3
  [set pollution pollution + 1]

  if pollution = 0
  [
    ask wells [die]
  create-wells 1
  [setxy 0 0
      set shape "circle"
    set size 4
    set color blue
  ]
  ]

  if pollution = 1
      [
  ask wells [die]
  create-wells 1
  [setxy 0 0
    set size 4
    set color green
          set shape "circle"
  ]
      ]

  if pollution = 2
      [
        ask wells [die]
  create-wells 1
  [setxy 0 0
          set shape "circle"
    set size 4
    set color yellow
  ]
      ]

  if pollution = 3
      [
        ask wells [die]
  create-wells 1
  [setxy 0 0
          set shape "circle"
    set size 4
    set color brown
  ]
      ]


 ask households with [ count link-neighbors <= 1 ] [ set my-clustering-coefficient 0 ]
  ifelse any? households with [ count link-neighbors > 1 ]
  [
    ask households with [ count link-neighbors > 1 ]
  [
      let hood link-neighbors
      set my-clustering-coefficient (2 * count links with [ in-neighborhood? hood ] /
                                         ((count hood) * (count hood - 1)) )
  ]
  ]
  []

  set generalcc mean [my-clustering-coefficient] of households with [shape = "circle"]

  ifelse count households with [shape = "square"] < 1
  [
    set leadercc 0
  ]
  [
    set leadercc mean [my-clustering-coefficient] of households with [shape = "square"]
  ]

  ifelse count households with [shape = "star"] < 1
  [
    set victimcc 0
  ]
  [
    set victimcc mean [my-clustering-coefficient] of households with [shape = "star"]
  ]

  ask households
  [
  if my-clustering-coefficient < 0.1
  [
    set my-clustering-coefficient-round 0
  ]
if my-clustering-coefficient > 0.1 and my-clustering-coefficient <= 0.2
  [
    set my-clustering-coefficient-round 1
  ]
  if my-clustering-coefficient > 0.2 and my-clustering-coefficient <= 0.3
  [
    set my-clustering-coefficient-round 2
  ]
  if my-clustering-coefficient > 0.3 and my-clustering-coefficient <= 0.4
  [
    set my-clustering-coefficient-round 3
  ]
  if my-clustering-coefficient > 0.4 and my-clustering-coefficient <= 0.5
  [
    set my-clustering-coefficient-round 4
  ]
  if my-clustering-coefficient > 0.5 and my-clustering-coefficient <= 0.6
  [
    set my-clustering-coefficient-round 5
  ]
  if my-clustering-coefficient > 0.6
  [
    set my-clustering-coefficient-round 6
  ]
  ]

  set totgeneralcc totgeneralcc + (generalcc * count households with [shape = "circle" and dead = 0])
    set avggeneralcc totgeneralcc / totcircles
  if count households with [shape = "star"] > 0
  [
    set totvictimcc totvictimcc + (victimcc * count households with [shape = "star" and dead = 0])
  set avgvictimcc totvictimcc / totstars
  ]
  if count households with [shape = "square"] > 0
  [
    set totleadercc totleadercc + (leadercc * count households with [shape = "square" and dead = 0])
  set avgleadercc totleadercc / totsquares
  ]

  ask households with [dead = 0]
  [
    set countlinkneighbors countlinkneighbors + count link-neighbors
    set deltalinkneighbors countlinkneighbors - countlinkneighborsprime
    set countlinkneighborsprime countlinkneighbors
  ]

  set totgenerallinkneighbors totgenerallinkneighbors + mean [countlinkneighbors] of households with [shape = "circle" and dead = 0]
    set avggenerallinkneighbors totgenerallinkneighbors / totcircles
  if count households with [shape = "star" and dead = 0] > 0
  [
    set totvictimlinkneighbors totvictimlinkneighbors + mean [countlinkneighbors] of households with [shape = "star" and dead = 0]
  set avgvictimlinkneighbors totvictimlinkneighbors / totstars
  ]
  if count households with [shape = "square" and dead = 0] > 0
  [
    set totleaderlinkneighbors totleaderlinkneighbors + mean [countlinkneighbors] of households with [shape = "circle" and dead = 0]
  set avgleaderlinkneighbors totleaderlinkneighbors / totsquares
  ]

  set avggenerallinkneighbordelta mean [deltalinkneighbors] of households with [shape = "circle" and dead = 0]
  if any? households with [shape = "star" and dead = 0]
 [
  set avgvictimlinkneighbordelta mean [deltalinkneighbors] of households with [shape = "star" and dead = 0]
  ]
  if any? households with [shape = "square" and dead = 0]
  [
  set avgleaderlinkneighbordelta mean [deltalinkneighbors] of households with [shape = "square" and dead = 0]
  ]

  set pctvictims (totstars / tothouseholds) * 100

  if any? households with [color = blue]
  [
    set timetoritualswitch 1
    set ritualtime ritualtime + 1
  ]

  if not any? households with [color = blue] and timetoritualswitch = 0
  [set timetoritual timetoritual + 1]

  if any? households with [shape = "square" and dead = 0]
  [set timetoritualswitch 1]

  if timetoritualswitch = 0
  [set timetoritual timetoritual + 1]

  set generaldr (deadcircles / totcircles)
  if totstars > 0
  [set victimdr (deadstars / totstars)]
  if tottriangles > 0
  [set faccuserdr (deadtriangles / tottriangles)]



end



; Copyright 2015 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
10
50
438
479
-1
-1
12.0
1
10
1
1
1
0
0
0
1
-17
17
-17
17
1
1
0
ticks
30.0

SLIDER
120
10
435
43
num-nodes
num-nodes
10
75
60.0
1
1
NIL
HORIZONTAL

BUTTON
11
10
116
43
setup
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
460
15
523
48
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
1

SWITCH
535
15
657
48
scapegoat?
scapegoat?
0
1
-1000

PLOT
445
60
665
215
General population health
NIL
NIL
0.0
5.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [health] of households with [shape = \"circle\"]"

PLOT
445
215
665
370
Leader health
NIL
NIL
0.0
5.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 1 -2674135 true "" "ifelse count turtles with [shape = \"square\"] = 0\n[]\n[histogram [health] of turtles with [shape = \"square\"]]"

PLOT
445
370
665
525
Victim health
NIL
NIL
0.0
5.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 1 -13840069 true "" "ifelse count turtles with [shape = \"star\"] = 0\n[]\n[histogram [health] of turtles with [shape = \"star\"]]"

PLOT
670
60
900
215
General population cc
NIL
NIL
0.0
7.0
0.0
1.0
true
false
"" ""
PENS
"General cc" 1.0 1 -16777216 true "" "histogram [my-clustering-coefficient-round] of households  with [shape = \"circle\"]"

PLOT
670
215
900
370
Leader cc
NIL
NIL
0.0
7.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "ifelse count turtles with [shape = \"square\"] > 0\n[\nhistogram [my-clustering-coefficient-round] of turtles with [shape = \"square\"]\n]\n[]"

PLOT
670
370
900
525
Victim cc
NIL
NIL
0.0
7.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "ifelse count turtles with [shape = \"star\"] > 0\n[\nhistogram [my-clustering-coefficient-round] of turtles with [shape = \"star\"]\n]\n[]"

MONITOR
60
485
142
530
# total links
count links
17
1
11

MONITOR
5
485
62
530
NIL
ticks
17
1
11

MONITOR
140
485
210
530
general dr
deadcircles / totcircles
17
1
11

MONITOR
210
485
277
530
victim dr
deadstars / totstars
17
1
11

MONITOR
280
485
355
530
faccuser dr
deadtriangles / tottriangles
17
1
11

MONITOR
355
485
432
530
NIL
pctvictims
17
1
11

SWITCH
660
15
802
48
datacollector?
datacollector?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model explores the formation of networks that result in the "small world" phenomenon -- the idea that a person is only a couple of connections away from any other person in the world.

A popular example of the small world phenomenon is the network formed by actors appearing in the same movie (e.g., "[Six Degrees of Kevin Bacon](https://en.wikipedia.org/wiki/Six_Degrees_of_Kevin_Bacon)"), but small worlds are not limited to people-only networks. Other examples range from power grids to the neural networks of worms. This model illustrates some general, theoretical conditions under which small world networks between people or things might occur.

## HOW IT WORKS

This model is an adaptation of the [Watts-Strogatz model](https://en.wikipedia.org/wiki/Watts-Strogatz_model) proposed by Duncan Watts and Steve Strogatz (1998). It begins with a network where each person (or "node") is connected to his or her two neighbors on either side. Using this a base, we then modify the network by rewiring nodes–changing one end of a connected pair of nodes and keeping the other end the same. Over time, we analyze the effect this rewiring has the on various connections between nodes and on the properties of the network.

Particularly, we're interested in identifying "small worlds." To identify small worlds, the "average path length" (abbreviated "apl") and "clustering coefficient" (abbreviated "cc") of the network are calculated and plotted after a rewiring is performed. Networks with _short_ average path lengths and _high_ clustering coefficients are considered small world networks. See the **Statistics** section of HOW TO USE IT on how these are calculated.

## HOW TO USE IT

The NUM-NODES slider controls the size of the network. Choose a size and press SETUP.

Pressing the REWIRE-ONE button picks one edge at random, rewires it, and then plots the resulting network properties in the "Network Properties Rewire-One" graph. The REWIRE-ONE button _ignores_ the REWIRING-PROBABILITY slider. It will always rewire one exactly one edge in the network that has not yet been rewired _unless_ all edges in the network have already been rewired.

Pressing the REWIRE-ALL button starts with a new lattice (just like pressing SETUP) and then rewires all of the edges edges according to the current REWIRING-PROBABILITY. In other words, it `asks` each `edge` to roll a die that will determine whether or not it is rewired. The resulting network properties are then plotted on the "Network Properties Rewire-All" graph. Changing the REWIRING-PROBABILITY slider changes the fraction of edges rewired during each run. Running REWIRE-ALL at multiple probabilities produces a range of possible networks with varying average path lengths and clustering coefficients.

When you press HIGHLIGHT and then point to a node in the view it color-codes the nodes and edges. The node itself turns white. Its neighbors and the edges connecting the node to those neighbors turn orange. Edges connecting the neighbors of the node to each other turn yellow. The amount of yellow between neighbors gives you a sort of indication of the clustering coefficient for that node. The NODE-PROPERTIES monitor displays the average path length and clustering coefficient of the highlighted node only. The AVERAGE-PATH-LENGTH and CLUSTERING-COEFFICIENT monitors display the values for the entire network.

### Statistics

**Average Path Length**: Average path length is calculated by finding the shortest path between all pairs of nodes, adding them up, and then dividing by the total number of pairs. This shows us, on average, the number of steps it takes to get from one node in the network to another.

In order to find the shortest paths between all pairs of nodes we use the [standard dynamic programming algorithm by Floyd Warshall] (https://en.wikipedia.org/wiki/Floyd-Warshall_algorithm). You may have noticed that the model runs slowly for large number of nodes. That is because the time it takes for the Floyd Warshall algorithm (or other "all-pairs-shortest-path" algorithm) to run grows polynomially with the number of nodes.

**Clustering Coefficient**: The clustering coefficient of a _node_ is the ratio of existing edges connecting a node's neighbors to each other to the maximum possible number of such edges. It is, in essence, a measure of the "all-my-friends-know-each-other" property. The clustering coefficient for the entire network is the average of the clustering coefficients of all the nodes.

### Plots

1. The "Network Properties Rewire-One" visualizes the average-path-length and clustering-coefficient of the network as the user increases the number of single-rewires in the network.

2. The "Network Properties Rewire-All" visualizes the average-path-length and clustering coefficient of the network as the user manipulates the REWIRING-PROBABILITY slider.

These two plots are separated because the x-axis is slightly different.  The REWIRE-ONE x-axis is the fraction of edges rewired so far, whereas the REWIRE-ALL x-axis is the probability of rewiring.

The plots for both the clustering coefficient and average path length are normalized by dividing by the values of the initial lattice. The monitors CLUSTERING-COEFFICIENT and AVERAGE-PATH-LENGTH give the actual values.

## THINGS TO NOTICE

Note that for certain ranges of the fraction of nodes rewired, the average path length decreases faster than the clustering coefficient. In fact, there is a range of values for which the average path length is much smaller than clustering coefficient. (Note that the values for average path length and clustering coefficient have been normalized, so that they are more directly comparable.) Networks in that range are considered small worlds.

## THINGS TO TRY

Can you get a small world by repeatedly pressing REWIRE-ONE?

Try plotting the values for different rewiring probabilities and observe the trends of the values for average path length and clustering coefficient.  What is the relationship between rewiring probability and fraction of nodes? In other words, what is the relationship between the rewire-one plot and the rewire-all plot?

Do the trends depend on the number of nodes in the network?

Set NUM-NODES to 80 and then press SETUP. Go to BehaviorSpace and run the VARY-REWIRING-PROBABILITY experiment. Try running the experiment multiple times without clearing the plot (i.e., do not run SETUP again).  What range of rewiring probabilities result in small world networks?

## EXTENDING THE MODEL

Try to see if you can produce the same results if you start with a different type of initial network. Create new BehaviorSpace experiments to compare results.

In a precursor to this model, Watts and Strogatz created an "alpha" model where the rewiring was not based on a global rewiring probability. Instead, the probability that a node got connected to another node depended on how many mutual connections the two nodes had. The extent to which mutual connections mattered was determined by the parameter "alpha." Create the "alpha" model and see if it also can result in small world formation.

## NETLOGO FEATURES

Links are used extensively in this model to model the edges of the network. The model also uses custom link shapes for neighbor's neighbor links.

Lists are used heavily in the procedures that calculates shortest paths.

## RELATED MODELS

See other models in the Networks section of the Models Library, such as Giant Component and Preferential Attachment.

Check out the NW Extension General Examples model to see how similar models might implemented using the built-in NW extension.

## CREDITS AND REFERENCES

This model is adapted from: Duncan J. Watts, Six Degrees: The Science of a Connected Age (W.W. Norton & Company, New York, 2003), pages 83-100.

The work described here was originally published in: DJ Watts and SH Strogatz. Collective dynamics of 'small-world' networks, Nature, 393:440-442 (1998).

The small worlds idea was first made popular by Stanley Milgram's famous experiment (1967) which found that two random US citizens where on average connected by six acquaintances (giving rise to the popular "six degrees of separation" expression): Stanley Milgram. The Small World Problem, Psychology Today, 2: 60-67 (1967).

This experiment was popularized into a game called "six degrees of Kevin Bacon" which you can find more information about here: https://oracleofbacon.org

Thanks to Connor Bain for updating this model in 2020.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2015).  NetLogo Small Worlds model.  http://ccl.northwestern.edu/netlogo/models/SmallWorlds.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2015 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2015 -->
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
setup
repeat 5 [rewire-one]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="vary-rewiring-probability" repetitions="5" runMetricsEveryStep="false">
    <go>rewire-all</go>
    <timeLimit steps="1"/>
    <exitCondition>rewiring-probability &gt; 1</exitCondition>
    <metric>average-path-length</metric>
    <metric>clustering-coefficient</metric>
    <steppedValueSet variable="rewiring-probability" first="0" step="0.025" last="1"/>
  </experiment>
</experiments>
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

curve
3.0
-0.2 0 0.0 1.0
0.0 0 0.0 1.0
0.2 1 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

curve-a
-3.0
-0.2 0 0.0 1.0
0.0 0 0.0 1.0
0.2 1 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
