; Chloe Johnson and Anna Novak
; Professor Dickerson
; CSCI 0390
; April 4, 2018

globals [
  player                  ; Reference to the user's basket
  player-size             ; The size of the player's basket
  fruit-list              ; A list of strings that relate to possible fruit shapes
  junk-food-list          ; A list of strings that relate to possible junk food shapes
  fruit-size              ; The size of a piece of fruit
  junk-food-size          ; The size of a piece of junk food
  fruit-frequency         ; Determines approximately how frequently a piece of fruit will randomly appear
  junk-food-frequency     ; Determines approximately how frequently a piece of junk food will randomly appear
  min-fruit-speed         ; The minimum speed a piece of fruit can fall
  max-fruit-speed         ; The maximum speed a piece of fruit can fall
  min-junk-food-speed     ; The minimum speed a piece of junk food can fall
  max-junk-food-speed     ; The maximum speed a piece of junk food can fall
  score                   ; The player's score (increases when the player catches fruit
                          ; and decreases when an ant steals fruit from the basket)
  level                   ; The level that a player is on (the game becomes more difficult as the level goes up)
  lives                   ; The number of lives a player has until it is game over
  level-goal              ; The number of fruit pieces a player must catch to move on to a new level
  level-goal-decrement    ; The number of fruit pieces remaining to be caught in the current level
  ant-speed               ; The speed at which an ant move
  fruity-ants             ; A list of strings that relate to possible shapes for ants carrying pieces of fruit
  juice-time              ; The number of a ticks a juice box will be alive for
  juice-frequency         ; Determines approximately how frequently a juice box will randomly appear
  juice-box-size          ; The size of a piece of juice box
  rot-time                ; The number of a ticks a piece of fruit on the ground will rot for
]

breed [ baskets basket ]
breed [ fruits fruit ]
breed [ ants ant ]
breed [ junk-foods junk-food ]
breed [ juice-boxes juice-box ]

fruits-own [ fruit-type speed time ]
junk-foods-own [ junk-food-type speed ]
baskets-own [ bottom-left bottom-right ]
juice-boxes-own [ time ]


; Setup procedure
to setup
  ca
  reset-ticks
  setup-patches
  init-variables
  start-new-level
  ask fruits [ set hidden? true ]
end


; Make the world a field
to setup-patches
  import-pcolors "field.jpg"
end


; Initialize variables
to init-variables
  set player-size 100
  ; create the player
  create-baskets 1 [
    set color black
    set heading 0
    set size player-size
    set shape "basket"
    set xcor 0
    set ycor min-pycor + player-size / 2
    set-corners
    set player self
  ]
  set fruit-list (list "apple" "banana" "grapes")
  set junk-food-list (list "chips" "cupcake" "ice-cream")
  set fruit-size 35
  set junk-food-size 35
  set fruit-frequency 200000
  set junk-food-frequency fruit-frequency * 2 ; 500000
  set min-fruit-speed 0.001
  set max-fruit-speed 0.01 ; 0.0005
  set min-junk-food-speed 0.001
  set max-junk-food-speed 0.01 ; 0.0005
  set score 0
  set level 0
  set lives 3
  set level-goal 0
  set level-goal-decrement 0
  set ant-speed 0.0005
  set fruity-ants (list "apple-ant") ; "banana-ant" "grapes-ant"
  set juice-time 50000
  set juice-frequency fruit-frequency * 50
  set juice-box-size 45
  set rot-time 25000
end


; Initializes a new level
; Each level becomes increasingly more difficult
; Observer context
to start-new-level
  ask fruits [die]
  ask ants [die]
  set fruit-frequency 200000 - (1000 * level * level)
  set junk-food-frequency fruit-frequency * 2
  set juice-frequency fruit-frequency * 50
  set level level + 1
  set level-goal level-goal + 5
  set level-goal-decrement level-goal
  output-type "Level " output-type level output-print ""
  wait 1
  make-fruit
end


; Create a new, randomly-shaped, randomly-fast falling piece of fruit
; Observer context
to make-fruit
  create-fruits 1 [
    set fruit-type one-of fruit-list
    set xcor random world-width
    set ycor max-pycor - (fruit-size / 2)
    set size fruit-size
    set shape fruit-type
    set heading 0
    while [speed < min-fruit-speed or speed > max-fruit-speed] [
      set speed random-float max-fruit-speed
    ]
    set time rot-time
    color-fruit
  ]
end


; Color the piece of fruit according to the type of fruit
; Fruit context
to color-fruit
  if shape = "apple" [
    set color red
  ]
  if shape = "banana" [
    set color yellow
  ]
  if shape = "grapes" [
    set color violet
  ]
end


; Move the player to the left
; Observer context
to move-left
  ask player [
    set xcor xcor - 10
    set-corners
  ]
end


; Move the player to the right
; Observer context
to move-right
  ask player [
    set xcor xcor + 10
    set-corners
  ]
end


; Reassigns the bottom corners of the basket when a player moves (or is initialized)
; Basket context
to set-corners
  set bottom-left patch (xcor - (player-size / 2) + 25) (ycor - (player-size / 2) + 25)
  set bottom-right patch (xcor + (player-size / 2) - 20) (ycor - (player-size / 2) + 25)
end


; Plays the game by making all of the agents move accordingly at each tick
; Forever button
; Observer context
to play
  ifelse alive? [
    ask fruits [ set hidden? false ]
    make-agents-randomly
    catch-fruit
    catch-junk-food
    food-fall
    stomp
    drink
    reduce-juice-box-life
    ask ants [
      eat-fruit
      move-to-basket
      steal-fruit
      leave-basket
      go-home
    ]
    if new-level? [ start-new-level ]
    tick
  ][
    output-write "Game over. Press setup and then play to try again."
    stop
  ]
end


; Randomly create pieces of fruit, junk food, and juice boxes
; Observer context
to make-agents-randomly
  let random-fruit random fruit-frequency
  if random-fruit = 0 [ make-fruit ]
  let random-junk-food random junk-food-frequency
  if random-junk-food = 0 [ make-junk-food ]
  let random-juice random juice-frequency
  if random-juice = 0 [ make-juice-box ]
end


; Reports true if the player is still alive and false otherwise
; Observer context
to-report alive?
  let status true
  if lives < 1 [ set status false ]
  report status
end


; Create a new, randomly-shaped, randomly-fast falling piece of junk-food
; Observer context
to make-junk-food
  create-junk-foods 1 [
    set junk-food-type one-of junk-food-list
    set xcor random world-width
    set ycor max-pycor - (junk-food-size / 2)
    set size junk-food-size
    set shape junk-food-type
    set heading 0
    while [speed < min-junk-food-speed or speed > max-junk-food-speed] [
      set speed random-float max-junk-food-speed
    ]
  ]
end


; Create a new, randomly placed juice box
; Observer context
to make-juice-box
  create-juice-boxes 1 [
    set xcor random max-pxcor
    set ycor random max-pycor
    set size juice-box-size
    set heading 0
    set shape "juice-box"
    set time juice-time
  ]
end


; Reduce the life of a juice box until it gets to 0 and then ask the juice-box to die
; Observer context
to reduce-juice-box-life
  ask juice-boxes [
    set time time - 1
    if time < 0 [ die ]
  ]
end

; If there is a fruit just above the basket, then catch it (kill the fruit agent) and increment the score
; Observer context
to catch-fruit
  ask player [
    let catching-fruits fruits with [
      distance player < (player-size - 2) / 2
      and ycor > [ycor] of player
    ]
    if any? catching-fruits [
      set level-goal-decrement level-goal-decrement - count catching-fruits
      set score score + (10 * count catching-fruits) ; determine-score catching-fruits
      ask player [ set color [color] of one-of catching-fruits ]
      ask catching-fruits [die]
    ]
  ]
end


; If there is a junk food item just above the basket, then catch it (kill the fruit agent) and decrement the number of lives
; Observer context
to catch-junk-food
  ask player [
    let catching-junk-foods junk-foods with [
      distance player < (player-size - 2) / 2
      and ycor > [ycor] of player
    ]
    if any? catching-junk-foods [
      set lives lives - 1
      ask catching-junk-foods [die]
    ]
  ]
end


; If the fruit hasn't hit the ground, then keep falling, otherwise spawn an ant (if there isn't already an ant there)
; If the junk food hasn't hit the ground, then keep falling, otherwise die
; Observer context
to food-fall
  ask fruits [
    let ants-here ants-on patch-here
    if ycor - (fruit-size / 2) > min-pycor [
      set ycor ycor - speed
    ]
    if ycor - (fruit-size / 2) <= min-pycor and not any? ants-here [
      make-ant
    ]
  ]
  ask junk-foods [
    ifelse ycor - (junk-food-size / 2) > min-pycor [
      set ycor ycor - speed
    ][
      die
    ]
  ]
end


; Spawn an ant at the site of a fallen fruit
; Observer context
to make-ant
  hatch-ants 1 [
    set shape "bug"
    set size 10
    set color black
    face player
  ]
end


; Stomp on an ant by clicking on it
; Observer context
to stomp
  if mouse-down? [
    ask ants [
      if distance patch mouse-xcor mouse-ycor < 10 and shape = "bug" [ die ]
    ]
  ]
end


; Drink a juice box by clicking on it
; Observer context
to drink
  if mouse-down? [
    ask juice-boxes [
      if distance patch mouse-xcor mouse-ycor < juice-box-size / 2 [
        set lives lives + 1
        die
      ]
    ]
  ]
end

; The ant eats the piece of fruit it is currently on (thus killing the fruit)
; Ant context
to eat-fruit
  let fruits-here fruits-on patch-here
  if any? fruits-here [
    ask fruits-here [
      let ants-here ants-on patch-here
      if any? ants-here [
        set time time - 1
        if time < 0 [ die ]
      ]
    ]
  ]
end


; If the ant is not on a piece of fruit, not at the basket, and has not yet stolen fruit, then move toward the basket
; Ant context
to move-to-basket
  let fruits-here fruits-on patch-here
  if not any? fruits-here
  and patch-here != [bottom-left] of player
  and patch-here != [bottom-right] of player
  and shape != one-of fruity-ants [
    face closer-of
    fd ant-speed
  ]
end


; If the ant is at the basket, steal a piece of fruit (i.e. make the level goal 1 piece of fruit greater), and decrement the score
; Ant context
to steal-fruit
  if patch-here = [bottom-left] of player or patch-here = [bottom-right] of player [
    if shape != one-of fruity-ants [
      set score score - 25
      set level-goal level-goal + 1
      set shape one-of fruity-ants
    ]
  ]
end


; If the ant has already stolen a piece of fruit, then it heads toward the side of the world
; Ant context
to leave-basket
  if shape = one-of fruity-ants [
    face patch max-pxcor ycor
    fd ant-speed
  ]
end


; If the ant has already stolen a piece of fruit and is at the side of the world, then it dies
; Ant context
to go-home
  if shape = one-of fruity-ants and patch-here = patch max-pxcor ycor [
    die
  ]
end


; Determines if the bottom left corner of the basket or the bottom right corner of the basket is closer to the ant
; Ant context
to-report closer-of
  let dist [bottom-left] of player
  if distance [bottom-right] of player < distance dist [ set dist [bottom-right] of player ]
  report dist
end


; Reports true if it's time to initiate a new level and false otherwise
; Observer context
to-report new-level?
  let nl false
  if level-goal-decrement < 1 [
    set nl true
  ]
  report nl
end

@#$#@#$#@
GRAPHICS-WINDOW
210
10
669
470
-1
-1
1.0
1
10
1
1
1
0
1
0
1
-225
225
-225
225
0
0
1
ticks
30.0

BUTTON
44
17
110
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
378
497
441
530
left
move-left
NIL
1
T
OBSERVER
NIL
J
NIL
NIL
1

BUTTON
456
496
519
529
right
move-right
NIL
1
T
OBSERVER
NIL
K
NIL
NIL
1

BUTTON
37
58
120
91
NIL
play
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
683
10
740
55
NIL
score
17
1
11

MONITOR
744
10
801
55
NIL
level
17
1
11

MONITOR
808
10
868
55
until full
level-goal-decrement
17
1
11

MONITOR
874
10
931
55
NIL
lives
17
1
11

OUTPUT
683
65
930
119
13

@#$#@#$#@
Chloe Johnson and Anna Novak
Professor Dickerson
CSCI 0390
April 4, 2018

## PICNIC PANIC

Welcome to Picnic Panic!

In this game, you control a picnic basket. Your goal is to move your basket left and right to catch the falling fruit and avoid the falling junk food. Catching fruit will earn you points and help you move on to the next level, but accidentally grabbing a piece of junk food will result in a loss of 1 life.  If you let a piece of fruit fall to the ground, then an ant will appear and start toward your basket. Squash the ant with a mouse click before it can get to your basket and steal your food! To reach the end of a level, simply fill up your basket with enough fruit (as indicated by "until full" monitor).

Catching food will earn you 10 points. Allowing an ant to steal your food will cost you 25 points and increase the "until full" monitor by 1.


### Key and mouse commands
J - move the basket left
K - move the basket right
Left click (with mouse) - stomp an ant
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
true
0
Polygon -2674135 true false 150 75 135 60 90 45 45 60 30 105 30 195 30 210 45 225 105 255 150 255 195 255 255 225 270 210 270 105 255 60 210 45 165 60 150 75
Polygon -6459832 true false 135 60 135 30 150 15 180 15 180 30 165 30 165 60 150 75 135 60

apple-ant
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 220 30
Line -7500403 true 150 100 80 30
Polygon -2674135 true false 150 225 135 210 120 210 120 210 105 225 105 255 120 270 180 270 195 255 195 225 180 210 165 210 150 225
Polygon -6459832 true false 135 210 135 210 150 195 180 195 165 195 165 210 165 210 150 225 135 210

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

banana
true
0
Polygon -1184463 true false 45 75 60 90 90 105 150 120 210 105 240 90 255 75 255 90 240 120 210 150 150 165 90 150 60 120 45 90 45 75

basket
true
15
Polygon -6459832 true false 45 90 75 60 225 60 255 90 255 210 225 240 75 240 45 210 45 90
Polygon -16777216 true false 75 90 90 75 210 75 225 90 75 90
Line -16777216 false 75 120 225 120
Line -16777216 false 225 120 255 105
Line -16777216 false 75 120 45 105
Line -16777216 false 45 135 75 150
Line -16777216 false 75 150 225 150
Line -16777216 false 225 150 255 135
Line -16777216 false 45 165 75 180
Line -16777216 false 75 180 225 180
Line -16777216 false 225 180 255 165
Line -16777216 false 45 195 75 210
Line -16777216 false 75 210 225 210
Line -16777216 false 225 210 255 195
Line -16777216 false 75 240 75 120
Line -16777216 false 225 240 225 120
Line -16777216 false 150 120 150 240
Polygon -1 true true 75 90 90 75 210 75 225 90 75 90

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
Line -7500403 true 150 100 220 30
Line -7500403 true 150 100 80 30

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

chips
true
14
Polygon -1184463 true false 75 45 75 75 90 105 75 135 60 195 60 240 60 255 240 255 225 210 240 180 240 150 240 105 240 75 255 60 225 45 75 45
Line -16777216 true 105 120 105 150
Line -16777216 true 105 150 120 150
Line -16777216 true 105 120 120 120
Line -16777216 true 135 120 135 150
Line -16777216 true 150 120 150 150
Line -16777216 true 135 135 150 135
Line -16777216 true 165 120 165 150
Line -16777216 true 180 150 180 120
Line -16777216 true 180 120 195 120
Line -16777216 true 180 135 195 135
Line -16777216 true 195 135 195 120
Line -16777216 true 210 120 225 120
Line -16777216 true 210 120 210 135
Line -16777216 true 210 135 225 135
Line -16777216 true 225 135 225 150
Line -16777216 true 225 150 210 150

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

cupcake
true
13
Polygon -8630108 true false 45 120 75 240 225 240 255 120 45 120
Polygon -2064490 true true 45 120 30 105 45 75 90 45 210 45 255 75 270 105 255 120 45 120
Line -1 false 60 90 75 90
Line -1 false 120 90 120 75
Line -1 false 180 105 195 90
Line -1 false 165 90 150 75
Line -1 false 90 105 105 90
Line -1 false 90 75 75 60
Line -1 false 240 105 225 105
Line -1 false 225 90 225 75
Line -1 false 195 75 210 60
Line -1 false 135 60 150 60
Line -1 false 180 75 180 60
Line -1 false 135 90 150 105
Line -1 false 105 75 120 60

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

grapes
true
0
Circle -8630108 true false 99 159 42
Circle -8630108 true false 114 189 42
Circle -8630108 true false 75 75 60
Circle -8630108 true false 150 135 60
Circle -8630108 true false 120 120 60
Circle -8630108 true false 146 71 67
Circle -8630108 true false 135 225 30
Circle -8630108 true false 135 165 60
Circle -8630108 true false 150 210 30
Circle -8630108 true false 120 60 60
Circle -8630108 true false 90 105 60
Circle -8630108 true false 120 165 30
Circle -8630108 true false 165 105 60
Circle -8630108 true false 195 90 30
Circle -8630108 true false 105 60 30
Circle -8630108 true false 150 60 30
Polygon -6459832 true false 135 60 135 30 150 15 165 15 165 30 150 30 150 60 135 60
Circle -8630108 true false 135 45 30
Circle -8630108 true false 165 60 30

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

ice-cream
true
15
Polygon -6459832 true false 90 135 105 270 195 270 210 135 90 135
Polygon -1 true true 90 135 75 120 60 75 60 60 75 30 105 15 150 15 195 15 225 30 240 60 240 75 225 120 210 135 90 135

juice-box
true
1
Polygon -2674135 true true 240 270 240 90 195 60 45 60 75 90 75 270 240 270
Polygon -2674135 true true 45 60 45 240 75 270 75 90 45 60
Polygon -1 true false 120 15 150 15 150 75 120 75 120 15
Line -16777216 false 75 90 75 90
Line -16777216 false 75 90 45 60
Line -16777216 false 75 90 75 270
Line -16777216 false 75 90 240 90
Line -16777216 false 240 90 240 270
Line -16777216 false 75 270 240 270
Line -16777216 false 45 60 45 240
Line -16777216 false 45 240 75 270
Line -16777216 false 45 60 120 60
Line -16777216 false 150 60 195 60
Line -16777216 false 195 60 240 90
Line -1 false 120 15 120 75
Line -1 false 120 75 150 75
Line -1 false 150 75 150 15
Line -1 false 120 15 150 15
Line -16777216 false 105 135 105 180
Line -16777216 false 105 180 90 180
Line -16777216 false 90 135 120 135
Line -16777216 false 90 165 90 180
Line -16777216 false 120 150 120 180
Line -16777216 false 120 180 135 180
Line -16777216 false 135 150 135 180
Line -16777216 false 150 150 150 180
Line -16777216 false 180 150 165 150
Line -16777216 false 165 150 165 180
Line -16777216 false 165 180 180 180
Line -16777216 false 195 165 195 180
Line -16777216 false 195 180 210 180
Line -16777216 false 195 165 210 165
Line -16777216 false 195 165 195 150
Line -16777216 false 195 150 210 150
Line -16777216 false 210 165 210 150
Line -16777216 false 225 135 225 165
Rectangle -16777216 true false 225 180 225 180
Rectangle -16777216 true false 150 135 150 135

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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
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
