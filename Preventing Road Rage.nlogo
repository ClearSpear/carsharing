globals
[
  roadrage-count
  crash-count
  stopped-count
  cars-passed
  time-deviation
  time-total
]

turtles-own
[
  speed         ;; the current speed of the car
  lane          ;; the current lane of the car
  target-lane   ;; the desired lane of the car
  patience      ;; the driver's current patience
  max-patience  ;; the driver's maximum patience
  change?       ;; 1 if the car wants to move up, -1 if the car wants to move down, 0 if it wants to stay 
  started-time  
]

to setup
  clear-all
  draw-road
  set-default-shape turtles "car"
  crt number [ setup-cars ]
  reset-ticks
end

to draw-road
  ask patches [
    set pcolor green  
    
    if(lanes = 2 and merge-to = 1)
    [
      if ((pycor > -4) and (pycor < 4)) [ set pcolor gray ]
      if ((pycor = 0) and ((pxcor mod 3) = 0)) [ set pcolor yellow ]
      if ((pycor = 4) or (pycor = -4)) [ set pcolor black ]
      
      if pxcor > 40 
      [
        if (pycor <= -1 and pycor >= -3) [set pcolor green ]
        if pycor = 0 [set pcolor black]
      ]
    ]
    
    if(lanes = 3 and merge-to = 2) 
    [
      if ((pycor > -8) and (pycor < 4)) [set pcolor gray]
      if ((pycor = 0 or pycor = -4) and ((pxcor mod 3) = 0)) [set pcolor yellow]
      if ((pycor = 4) or (pycor = -8)) [ set pcolor black ]
      
      if pxcor > 40
      [
        if (pycor <= -5 and pycor >= -7) [ set pcolor green ]
        if pycor = -4 [ set pcolor black ]
      ]
    ]
    
    if(lanes = 3 and merge-to = 1)
    [
      if ((pycor > -8) and (pycor < 4)) [set pcolor gray]
      if ((pycor = 0 or pycor = -4) and ((pxcor mod 3) = 0)) [set pcolor yellow]
      if ((pycor = 4) or (pycor = -8)) [ set pcolor black ]
      
      if pxcor > 40 
      [
        if (pycor <= -1 and pycor >= -7) [set pcolor green]
        if pycor = 0 [set pcolor black]
      ]
    ]
    
    if pxcor = tolerance-distance [ set pcolor red ]
    if pxcor = courtesy-distance [ set pcolor violet ]
  ]
end

to setup-cars
  set color black
  
  set lane (random lanes)
  set target-lane lane
  if(lane = 0)
  [
    setxy random-xcor 2
  ]
  if(lane = 1)
  [
    setxy random-xcor -2
  ]
  if(lane = 2)
  [
    setxy random-xcor -6
  ]
  
  set heading 90
  set speed speed-limit - random-float .9
  
  set change? 0
  set max-patience (average-patience - 5) + random 10
  set patience (max-patience - (random 5))
  
  ;; make sure no two cars are on the same patch
  loop 
  [
    ifelse any? other turtles-here 
    [ fd 1 ] 
    [ stop ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DRIVING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to maintain-road
  ;ramdomize cars coming in
  if random 3 < 1
  [
    crt random( spawn-rate )
    [
      setup-cars
      set xcor -50
      set started-time ticks
    ]
  ]
  
  ;kill off turtles that are done
  set cars-passed cars-passed + count turtles with [pxcor >= 49]
  ask turtles with [pxcor >= 49]
  [
    if started-time > 0
    [
      set time-total time-total + (ticks - started-time)
      set time-deviation time-deviation + ((ticks - started-time) - (time-total / cars-passed)) ^ 2 
    ]
    die
  ]
  
  ;make sure turtles are not off road
  ifelse merge-to = 1
  [
    ask turtles with [ xcor >= 40 and not (ycor > 0 and ycor < 4)] 
    [
      set xcor 40
      set stopped-count stopped-count + count turtles with [ xcor >= 40 and not (ycor > 0 and ycor < 4)] 
    ]
  ]
  [
    ask turtles with [ xcor >= 40 and not (ycor > -4 and ycor < 4)]
    [
      set xcor 40
      set stopped-count stopped-count + count turtles with [ xcor >= 40 and not (ycor > -4 and ycor < 4)]
    ]
  ]
end

to change-speed
  ;Decelerate if turtles ahead or turtles need to merge, accelerate if empty ahead
  ask turtles 
  [
    let spot xcor
    ifelse ( (count turtles with [pycor = ycor and xcor > spot and (xcor <= (spot + 1 * speed + .25))]) > 0 ) or 
      ( merge-to = 1 and lane = 0 and any? turtles-at 0 -4 ) or 
      ( merge-to = 2 and lane = 1 and any? turtles-at 0 -4 )
    [
      if (any? (turtles with [pycor = ycor and pxcor > xcor and (pxcor <= xcor + 2 * speed + .25)]))
      [ 
        set speed ([speed] of (one-of (turtles with [pycor = ycor and pxcor > xcor and (pxcor <= xcor + 2 * speed + .25)])))
        decelerate one-of (turtles with [pycor = ycor and pxcor > xcor and (pxcor <= xcor + 2 * speed + .25)])
      ]
      decelerate-flat
    ]
    [
      ifelse (look-ahead = 2) 
      [
        ifelse ((count turtles with [pycor = ycor and pxcor > xcor and (pxcor <= xcor + 2 * speed + .25)]) > 0 )
        [
          set speed ([speed] of (one-of turtles with [pycor = ycor and pxcor > xcor and (pxcor <= xcor + 2 * speed + .25)]))
          decelerate one-of (turtles with [pycor = ycor and pxcor > xcor and (pxcor <= xcor + 2 * speed + .25)])
        ]
        [
          accelerate
        ]
      ]
      [
        accelerate
      ]
    ]
    ;regulate speed
    if (speed < 0.01) [ set speed 0.01 ]
    if (speed > speed-limit) [ set speed speed-limit ]
  ]
end

to move-forward 
  ;; if there is a car right ahead of you, match its speed then slow down
  ask turtles 
  [
    ;let car-ahead one-of turtles-on patch-ahead 1
    ;ifelse car-ahead != nobody
    ;[ decelerate car-ahead ]
    ;;; otherwise, speed up
    ;[ accelerate ]
    ;;; don't slow down below speed minimum or speed up beyond speed limit
    ;if speed < 0  [ set speed .01 ]
    ;if speed > speed-limit   [ set speed speed-limit ]
    fd speed 
  ]
end

to count-road-rage
  ;ROAD RAGE
  ask turtles
  [
    set color black
    if (any? other turtles-at 0 0 and xcor > -40)
    [
      set color violet
      set crash-count crash-count + 1
    ]
    if (any? turtles-at 1 0)
    [
      if ( speed > ([speed] of (one-of turtles-at 1 0) + .50 * speed) )
      [
        set color yellow
        set roadrage-count roadrage-count + 1
      ]
    ]
  ]
end

;; All turtles look first to see if there is a turtle directly in front of it,
;; if so, set own speed to front turtle's speed and decelerate.  Otherwise, if
;; look-ahead is set for 2, look ahead one more patch and do the same.  If no front
;; turtles are found, accelerate towards speed-limit

to drive
  if (ticks = 1500)
  [
    stop
  ]
  maintain-road
  change-speed  
  count-road-rage
  move-forward
  change-lanes-and-drive
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;LANE SWITCHING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to change-lanes-and-drive
  ask turtles
  [
    signal ;set change?
    
           ;If not out of bounds, change if want to
    if (change? = 1 and not (ycor >= 2))
    [
      change-lanes 1
    ]    
    if (change? = -1)
    [
      if (lanes = 2 and merge-to = 1 and (not (xcor > 40 and ycor <= 2)) ) 
      or (lanes = 3 and merge-to = 1 and (not (xcor > 40 and ycor <= 2)) )
      or (lanes = 3 and merge-to = 2 and (not (xcor > 40 and ycor <= -2)) )
      [
        change-lanes -1
      ]
    ]
    
    ;; Control for making sure no one crashes.
    ifelse (any? turtles-at 1 0) and (xcor != min-pxcor - .5) 
    [
      set speed [speed] of (one-of turtles-at 1 0)
    ]
    [
      ifelse ((any? turtles-at 2 0) and (speed > 1.0)) 
      [
        set speed ([speed] of (one-of turtles-at 2 0))
      ]
      [
        jump speed
      ]
    ]
  ]
end

;; undergoes search algorithms
; -1 means down
; 1 means up 
to change-lanes [direction] ;; turtle procedure
                            ;if (target-lane = lane)
                            ;[
  set target-lane lane - direction
  ;]
  move-switching
end

to move-switching 
  ;If you are in your target lane 
  ;ifelse (target-lane = lane) 
  ;[
    ;ifelse (target-lane = 0) 
    ;[
    ;  set target-lane 1
    ;  set change? false
    ;]
    ;[
    ;  set target-lane 0
    ;  set change? false
    ;]
    
    ;set target-lane 
    ;  set change? 0
    ;]
    ;[ ;If you are not in your target lane yet 
    
    if (target-lane = 0)
    [ 
      ifelse (pycor = 2)
      [
        set lane 0
        set change? 0
      ]
      [
        ifelse (not (any? turtles-at 0 1 or any? turtles-at -1 1))
        [
          set ycor (ycor + 1)
        ]
        [
          if (any? turtles-at 1 0) 
          [
            decelerate one-of turtles-at 1 0
            if (speed <= 0) [ set speed 0.1 ]
          ]
        ]
      ]
    ]
    
    if (target-lane = 1) 
    [
      ifelse (pycor = -2) 
      [
        set lane 1
        set change? 0 ;target-lane is 1   ;lane is 1
      ]
      [
        ifelse lane = 0
        [
          if (not (any? turtles-at 0 -1 or any? turtles-at -1 -1)) 
          [set ycor (ycor - 1)]
        ]
        [     ;lane = 2
          if (not any? turtles-at 0 1) [set ycor (ycor + 1)]
        ]
        
        if (any? turtles-at 1 0) 
        [
          decelerate one-of turtles-at 1 0
          if (speed <= 0) [ set speed 0.1 ]
        ]
      ]
    ]
     
    if (target-lane = 2) 
    [
      ifelse (pycor = -6) 
      [
        set lane 2
        set change? 0 
      ]
      [
        ifelse (not (any? turtles-at 0 -1 or any? turtles-at -1 -1)) 
        [set ycor (ycor - 1)]
        [
          if (any? turtles-at 1 0) 
          [
            decelerate one-of turtles-at 1 0
            if (speed <= 0) [ set speed 0.1 ]
          ]
        ]
      ]
    ]
end

to signal
  ;If there's space to the sides and the turtle ahead is too slow  
  if( any? turtles-at 1 0)
  [
    if (ycor = 2)
    [
      if not (any? turtles-at -4 0 or any? turtles-at -4 1 or any? turtles-at -4 2) 
      [
        tick-patience
      ]
    ]
    if (ycor = -2)
    [
      if not (any? turtles-at 4 0 or any? turtles-at 4 1 or any? turtles-at 4 2) or 
      not (any? turtles-at -4 0 or any? turtles-at -4 1 or any? turtles-at -4 2) 
      [
        tick-patience
      ]
    ]
    if (ycor = -6)
    [
      if not (any? turtles-at 4 0 or any? turtles-at 4 1 or any? turtles-at 4 2)
      [
        tick-patience
      ]
    ]
  ]
  
  ;lane closing
  ifelse merge-to = 1
  [
    if (pxcor > tolerance-distance and (lane = 1 or lane = 2))
    [
      set change? 1
    ]
  ]     ;merge-to = 2
  [
    if (pxcor > tolerance-distance and lane = 2)
    [
      set change? 1
    ]
  ]
  
  ;courtesy 
  if merge-to = 2
  [
    if (any? turtles-at -4 0 and pxcor > courtesy-distance and lane = 1)
    [
      tick-patience
    ]
  ]
end
  
to tick-patience
  ifelse (patience <= 0) 
  [ 
    ifelse (max-patience <= 1)
    [
      set max-patience (random average-patience) + 1
    ]
    [
      set max-patience (max-patience - (random 5))
    ]
    set patience max-patience
    if not (xcor > tolerance-distance and lane < merge-to)
    [
      if not (any? turtles-at 4 0 or any? turtles-at 4 1 or any? turtles-at 4 2)
      [
        set change? 1
      ]
      if not (any? turtles-at -4 0 or any? turtles-at -4 1 or any? turtles-at -4 2) 
      [
        set change? -1
      ]
    ]    
  ]
  [
    set patience (patience - 1)
  ]
end

;; turtle (car) procedure
to decelerate  [car-ahead]
  ;; slow down so you are driving more slowly than the car ahead of you
  set speed [speed] of car-ahead - deceleration
  if (speed <= 0) [ set speed 0.1 ]
end

to decelerate-flat
  set speed speed - deceleration
  if (speed <= 0) [ set speed 0.1 ]
end

;; turtle (car) procedure
to accelerate
  set speed speed + acceleration
end

; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
271
10
1089
209
50
10
8.0
1
10
1
1
1
0
0
0
1
-50
50
-10
10
1
1
1
ticks
30.0

BUTTON
7
58
82
91
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
7
143
82
176
go
drive
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
7
99
94
132
go once
drive
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
251
400
365
445
average speed
mean [speed] of turtles
2
1
11

SLIDER
102
58
264
91
number
number
0
134
27
1
1
NIL
HORIZONTAL

SLIDER
18
312
180
345
deceleration
deceleration
0
1
0.136
.001
1
NIL
HORIZONTAL

SLIDER
18
276
180
309
acceleration
acceleration
0
1
0.075
.001
1
NIL
HORIZONTAL

SLIDER
1102
50
1264
83
look-ahead
look-ahead
1
2
1
1
1
NIL
HORIZONTAL

PLOT
251
221
617
397
Car Speeds
Time
Speed
0.0
300.0
0.0
2.5
true
true
"set-plot-y-range 0 ((max [speed-limit] of turtles) + .5)" ""
PENS
"average" 1.0 0 -10899396 true "" "plot mean [speed] of turtles"
"max" 1.0 0 -11221820 true "" "plot max [speed] of turtles"
"min" 1.0 0 -13345367 true "" "plot min [speed] of turtles"

MONITOR
127
95
236
140
NIL
count turtles
17
1
11

MONITOR
833
347
991
392
NIL
roadrage-count / ticks * 100
17
1
11

PLOT
831
219
991
339
100 * Anger Frequency 
ticks
anger/time
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot roadrage-count / ticks * 100"

SLIDER
1102
93
1274
126
tolerance-distance
tolerance-distance
-50
50
29
1
1
NIL
HORIZONTAL

MONITOR
623
376
807
421
Flow
cars-passed / ticks
17
1
11

PLOT
623
219
823
369
Flow over time
ticks
cars/ticks
0.0
2.0
0.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot cars-passed / ticks"

SLIDER
92
144
264
177
spawn-rate
spawn-rate
0
5
4
1
1
NIL
HORIZONTAL

SLIDER
1102
10
1274
43
average-patience
average-patience
0
100
32
1
1
NIL
HORIZONTAL

PLOT
997
219
1157
339
100 * Crash Frequency
ticks
crashes/time
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot crash-count / ticks * 100"

MONITOR
998
345
1156
390
NIL
crash-count / ticks * 100
17
1
11

SLIDER
18
229
190
262
merge-to
merge-to
1
2
1
1
1
NIL
HORIZONTAL

SLIDER
18
189
190
222
lanes
lanes
2
3
2
1
1
NIL
HORIZONTAL

SLIDER
1103
132
1275
165
courtesy-distance
courtesy-distance
-50
50
-8
1
1
NIL
HORIZONTAL

SLIDER
1104
173
1276
206
speed-limit
speed-limit
0
6.5
2
.1
1
NIL
HORIZONTAL

PLOT
10
365
236
515
Standard Deviation of Time to Pass
time (ticks)
standard deviation
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sqrt ( time-deviation / (cars-passed + 1) )"

MONITOR
240
470
483
515
NIL
sqrt ( time-deviation / (cars-passed + 1) )
17
1
11

MONITOR
997
408
1161
453
100 * Roadrage Frequency
(roadrage-count + crash-count + stopped-count) / ticks * 100
17
1
11

MONITOR
1163
345
1327
390
NIL
stopped-count / ticks * 100
17
1
11

MONITOR
491
470
622
515
Average time to pass
time-total / cars-passed
17
1
11

PLOT
1163
218
1323
338
100 * Stop Frequency
ticks
stops / time
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot stopped-count / ticks * 100"

@#$#@#$#@
## WHAT IS IT?

This project is a more sophisticated two-lane version of the "Traffic Basic" model.  Much like the simpler model, this model demonstrates how traffic jams can form. In the two-lane version, drivers have a new option; they can react by changing lanes, although this often does little to solve their problem.

As in the traffic model, traffic may slow down and jam without any centralized cause.

## HOW TO USE IT

Click on the SETUP button to set up the cars. Click on DRIVE to start the cars moving. The STEP button drives the car for just one tick of the clock.

The NUMBER slider controls the number of cars on the road. The LOOK-AHEAD slider controls the distance that drivers look ahead (in deciding whether to slow down or change lanes). The SPEED-UP slider controls the rate at which cars accelerate when there are no cars ahead. The SLOW-DOWN slider controls the rate at which cars decelerate when there is a car close ahead.

You may wish to slow down the model with the speed slider to watch the behavior of certain cars more closely.

The SELECT-CAR button allows you to pick a car to watch. It turns the car red, so that it is easier to keep track of it. SELECT-CAR is best used while DRIVE is turned off. If the user does not select a car manually, a car is chosen at random to be the "selected car".

The AVERAGE-SPEED monitor displays the average speed of all the cars.

The CAR SPEEDS plot displays four quantities over time:
- the maximum speed of any car - CYAN
- the minimum speed of any car - BLUE
- the average speed of all cars - GREEN
- the speed of the selected car - RED

## THINGS TO NOTICE

Traffic jams can start from small "seeds." Cars start with random positions and random speeds. If some cars are clustered together, they will move slowly, causing cars behind them to slow down, and a traffic jam forms.

Even though all of the cars are moving forward, the traffic jams tend to move backwards. This behavior is common in wave phenomena: the behavior of the group is often very different from the behavior of the individuals that make up the group.

Just as each car has a current speed and a maximum speed, each driver has a current patience and a maximum patience. When a driver decides to change lanes, he may not always find an opening in the lane. When his patience expires, he tries to get back in the lane he was first in. If this fails, back he goes... As he gets more 'frustrated', his patience gradually decreases over time. When the number of cars in the model is high, watch to find cars that weave in and out of lanes in this manner. This phenomenon is called "snaking" and is common in congested highways.

Watch the AVERAGE-SPEED monitor, which computes the average speed of the cars. What happens to the speed over time? What is the relation between the speed of the cars and the presence (or absence) of traffic jams?

Look at the two plots. Can you detect discernible patterns in the plots?

## THINGS TO TRY

What could you change to minimize the chances of traffic jams forming, besides just the number of cars? What is the relationship between number of cars, number of lanes, and (in this case) the length of each lane?

Explore changes to the sliders SLOW-DOWN, SPEED-UP, and LOOK-AHEAD. How do these affect the flow of traffic? Can you set them so as to create maximal snaking?

## EXTENDING THE MODEL

Try to create a 'traffic-3 lanes', 'traffic-4 lanes', 'traffic-crossroads' (where two sets of cars might meet at a traffic light), or 'traffic-bottleneck' model (where two lanes might merge to form one lane).

Note that the cars never crash into each other- a car will never enter a patch or pass through a patch containing another car. Remove this feature, and have the turtles that collide die upon collision. What will happen to such a model over time?

## NETLOGO FEATURES

Note the use of `mouse-down?` and `mouse-xcor`/`mouse-ycor` to enable selecting a car for special attention.

Each turtle has a shape, unlike in some other models. NetLogo uses `set shape` to alter the shapes of turtles. You can, using the shapes editor in the Tools menu, create your own turtle shapes or modify existing ones. Then you can modify the code to use your own shapes.

## RELATED MODELS

Traffic Basic


## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Wilensky, U. (1998).  NetLogo Traffic 2 Lanes model.  http://ccl.northwestern.edu/netlogo/models/Traffic2Lanes.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.
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
NetLogo 5.1.0
@#$#@#$#@
setup
repeat 50 [ drive ]
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
