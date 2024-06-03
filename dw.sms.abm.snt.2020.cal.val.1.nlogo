extensions [ gis nw bitmap time rnd] ;time added

globals [
  starting-seed; for reproducible outcomes
  current-time ; temporal simulation
  study_area
  WWTP_data
  destination_node
  blocks_data
  households_data
  pipes_data
  pipes_lines
  stations_data
  economic.points_data; new
  ;accumulated.wwps; monitoring wpps generated -> see count.hatching.wwps procedure
]

patches-own [
  R_CVEGEO; new
];new

breed [ nodes node ]
breed [ wwps wwp ] ;watewater particles
breed [ wwtps  wwtp] ;wastewater treatment plant
breed [ stations station ]  ;monitoring stations
breed [ households household ]
breed [ inhabitants inhabitant]
breed [ economic.points economic.point]

directed-link-breed [ pipes pipe ]

pipes-own [ speed ]

households-own [
  own_id
  block_id
  CVEGEO ;new
]

stations-own [
  closest_node
  z_value
  total_volume
  travel_path ;monitoring stations also the drains
  manhole.id.instation; new to generate timeseries
]
wwtps-own [
  closest_node
  ;total_volume
]

wwps-own [
  origin_station
  travel_path ;the travel-path of wwps is just the copy of the travel-path of buildings
  dw.type ;new
  ind.id ;new
  manhole.id.instation;new
  manhole.id.dymc.old; new to generate manhole timeseries
  CVEGEO; new
  CVEGEO.reloc; new
  hatching.time ;new
  dead.time ;new
  wwps_speed
]

nodes-own [
  z_value
  travel_path
  slope ]

;;**********************************************************************
inhabitants-own [ ; new
  ind.id; new
  sex
  age
  go.school
  go.work
  escolar.grade
  escolar.level
  CVEGEO; new
  CVEGEO.reloc; new
  located.at; new
  wwtp.conex; new
  wwtp.conex.reloc;new
  ]

economic.points-own [
  id
  CVEGEO
  avg.workers
  school.exist
]

; ------------- Setup - Loading GIS data etc. -------------------------------------------------------------------------------------------

to setup

  ca
  set starting-seed new-seed
  random-seed starting-seed
  ;random-seed reproducible.seed; setting seed for reproducibility

  ask patches [set pcolor grey + 4 ]

;QGIS Processing

  ; To all shape files:
  ; Before loding shp's in netlogo: export shapes with ITRF and save them with wgs84

  ; Generate the following shape files:
     ;pipes: blueprints or propoused
     ;manholes: convert polygon/line vertices to points - shpaes: pipes
              ; a 'height' column is required for manhole stations with realistic flow directions
              ; when no blueprints are available, can be propoused with DEM
              ; Implement qgis 'sample raster values' tool. inputs: manholes.shp (points), DEM (raster)
              ; Adapt shpaes pipes and manholes as required to create and calcualte travel paths
     ;study area - qgis Extract layer extent to mz

;Mobility dynamycs

  ; Workers
  ; Based on economic poits: if DENUE (shape of economic units) is not available,
  ; comment the following procedures at the go-until procedure:
  ; homeworkrelocation, workhomerelocation
  ; Implication: Represents home-office DW generation

  ; Students
  ; Based on school locations: Contained at DENUE.

  ; Add the following fields
  ; In .shp economic.points_data:
  ; R_school_e, R_avg_work
  ; uncomment R_avg_work (if not available) at the economic.points-generation prodecure

  gis:load-coordinate-system ("data/13m.loc.snt.2020.mz800.wgs84.prj")
  set blocks_data gis:load-dataset "data/13m.loc.snt.2020.mz800.wgs84.shp" ;new
  set economic.points_data gis:load-dataset "data/schools.points.snt.wgs84.shp" ;new

  set stations_data gis:load-dataset "data/manholes.snt.height.shp"
  set households_data gis:load-dataset "data/households.snt.wgs84.shp" ;new
  set study_area gis:load-dataset "data/extent.snt.shp"
  set WWTP_data gis:load-dataset "data/wwtp.snt.g.shp"
  set pipes_data gis:load-dataset "data/pipes.snt.shp"

  gis:set-world-envelope-ds (gis:envelope-of study_area )
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of blocks_data))

  gis:set-drawing-color grey + 3
  gis:fill blocks_data 1
;  gis:set-drawing-color grey + 0.5
;  gis:fill households_data 5
  gis:set-drawing-color brown
  gis:fill WWTP_data 1
  gis:set-drawing-color green
  gis:fill economic.points_data 5

  pipes-lines-generation  ;to only generate the lines of pipes (without direction)
  nodes-generation  ;to generate the nodes in the lines of pipes (the nodes involve stations)
  wwtp-generation  ;to generate the wwtp agent
  stations-generation  ;to generate the stations (different from the nodes)
  pipes-generation  ;to generate the real-world pipes (with directions)
  create-path  ;to calculate the path to wwtp/destination_node for each station (the path calculation is based on nodes-pipes context)

  ;read-agent-data-2; new
  time:anchor-schedule time:create model.starting.at 60 "minute" ; definition of starting and ending of model
  set current-time time:anchor-to-ticks time:create model.starting.at 60 "minute"

  RCVEGEO-dataset-in-patches ;new
  households-generation ;new
  read-sms-agent ;new
  economic.points-generation ;new
  ;set accumulated.wwps 0 ;new to count accumulated.wwps

  ;RCVEGEO; new
  ;avg.worker

  ;gis:set-drawing-color black
  ;gis:draw scalebar 1

  ;bitmap:copy-to-drawing ( bitmap:scaled ( bitmap:import "data/legend.png" ) 150 120 ) 495 400

  reset-ticks

end

; ------------- Setup - Agents Generation -------------------------------------------------------------------------------------

to pipes-lines-generation
  let polylines gis:feature-list-of pipes_data  ;to get the set of features (one feature might have several lines)
  set polylines map [ i -> first gis:vertex-lists-of i ] polylines  ;to get the set of lines (here, one feature has only one line)
  set polylines map [ i -> map [ ?i -> gis:location-of ?i ] i ] polylines  ;to get the set of nodes (the nodes of the same line is also included within a [])
  set polylines remove [] map [ i -> remove [] i ] polylines  ;remove the blank nodes and lines
  set pipes_lines polylines
end

to nodes-generation
  foreach pipes_lines [ i ->
    let j i
    (foreach i [ ?i -> ifelse any? nodes with [ xcor = first ?i and ycor = last ?i ] [] [ create-nodes 1 [
      setxy first ?i last ?i
      set z_value 0
      set slope gis:property-value ( item ( position j pipes_lines ) gis:feature-list-of pipes_data ) "SLOPE"
      hide-turtle
      ;set shape "circle"
      ;set color red
      ;set size 2.1
    ] ] ] )
    set i j
  ]
end

to wwtp-generation
  let destination_center gis:centroid-of ( item 0 gis:feature-list-of WWTP_data )
  create-wwtps 1 [
    setxy (item 0 gis:location-of destination_center) (item 1 gis:location-of destination_center)
    set size 0.1
    set label "WWTP"
    set label-color black
    show-turtle
    set closest_node one-of nodes with-min [ distance myself ]
    set destination_node closest_node
  ]
end

to stations-generation
  foreach gis:feature-list-of stations_data [ ? ->
    create-stations 1 [
      setxy (item 0 gis:location-of (gis:centroid-of (?))) (item 1 gis:location-of (gis:centroid-of (?)))
      set shape "circle"
      set color black
      set size 1.5
      show-turtle
      set total_volume 0
      set z_value gis:property-value ? "HEIGHT"
      set manhole.id.instation gis:property-value ? "manhole_id"
      ask nodes with-min [ distance myself ] [ set z_value gis:property-value ? "HEIGHT" ] ;set nodes' z_value
    ]
  ]
end

to pipes-generation
  foreach pipes_lines [ i ->
    if ( [ z_value ] of one-of nodes with [ xcor = first first i and ycor = last first i ] < [ z_value ] of one-of nodes with [ xcor = first last i and ycor = last last i ] ) [ set i reverse i ]
    (foreach butlast i butfirst i [ [ ?1 ?2 ] -> if ?1 != ?2 [ ;skip nodes on top of each other due to rounding
      ask nodes with [ xcor = first ?2 and ycor = last ?2 ] [
        create-pipes-from nodes with [ xcor = first ?1 and ycor = last ?1 ]
        ]
      ]
    ])
  ]
  ask pipes [ set color turquoise - 1 set thickness 0.001 ]
end

to create-path
  nw:set-context nodes pipes
  ask stations [
    set closest_node one-of nodes with-min [ distance myself ]
    set travel_path calculate-path closest_node destination_node

  ]
end

to-report calculate-path [ node_1 node_2 ]
  ask node_1 [ set travel_path nw:turtles-on-path-to node_2 ]
  report [ travel_path ] of node_1
end

; ------------- Setup - Synthetic Population Generation -------------------------------------------------------------------------------------

to households-generation
  foreach gis:feature-list-of households_data [ ? ->
    create-households 1 [
      setxy item 0 gis:location-of (gis:centroid-of (?))
      item 1 gis:location-of (gis:centroid-of (?))
      set size 8
      set shape "house"
      set color white
      show-turtle
      ;hide-turtle
      set own_id gis:property-value ? "id"
      set CVEGEO gis:property-value ? "CVEGEO"
      ;set block_id gis:property-value ? "BLOCK_ID"
      ;set laundry_load ( 0 - laundry )
      ;set dish_load ( 0 - dish )
    ]
  ]
end

to economic.points-generation
  set-default-shape economic.points "circle"
  foreach gis:feature-list-of economic.points_data [ ? ->
    create-economic.points 1 [
      hide-turtle
      set size 2
      setxy item 0 gis:location-of (gis:centroid-of (?))
      item 1 gis:location-of (gis:centroid-of (?))
      set id gis:property-value ? "id"
      set CVEGEO gis:property-value ? "CVEGEO"
      set school.exist gis:property-value ? "R_school_e"
      ifelse school.exist = "no" [set color red] [set color green]

      ;Note: (Un)comment wheter economic points are available
      ;set avg.workers gis:property-value ? "R_avg_work"

    ]

  ]
end

to read-sms-agent
  set-default-shape inhabitants "person"
  file-open sms.agent.csv ; opens connection to file - last line in procedure closes it
  while [not file-at-end?][ ; outer loop through all rows
     let $case file-read-line ; reads single line from .csv file
     set $case word $case "," ; add a comma at the end
     let $data.list []  ; set empty list to collect elements from each case
     create-inhabitants 1[ ; create single agent and read their data:
       while [not empty? $case] [  ; inner loop through all elements in row
         let $pos position "," $case  ; find next comma
         let $item read-from-string substring $case 0 $pos  ; extract item before the comma
         set $data.list lput $item $data.list  ; add the item to the list
         set $case substring $case ($pos + 1) length $case  ; remove item and comma from case. repeat loop
         ]
       ; now all the items from the row are a items in data.list. assign them to the agent
       set sex item 0 $data.list
       set age item 1 $data.list
       set go.school item 2 $data.list
       set go.work item 3 $data.list
       set escolar.grade item 4 $data.list
       set escolar.level item 5 $data.list
       set CVEGEO item 6 $data.list
       set ind.id item 7 $data.list
       set wwtp.conex item 8 $data.list
       set CVEGEO.reloc item 6 $data.list
       set located.at "home.place"
       set wwtp.conex.reloc item 8 $data.list
       set size 4
       ;hide-turtle
       ifelse sex = "m" [set color blue] [set color pink] ; assign colour based on sex
       ;to allocate inhabitants.points into households: a)same CVEGEO b)from high to low age ranges
       ifelse age = "P_25A130" [move-to one-of households with [CVEGEO = [CVEGEO] of myself]] []
       ifelse age = "P_18A24" [move-to one-of households with [CVEGEO = [CVEGEO] of myself]] []
       ifelse age != "P_25A130" and age != "P_18A24"  [move-to one-of households with [CVEGEO = [CVEGEO] of myself]] []
     ]
  ]
  file-close
end


;;**********************************************************************

to RCVEGEO-dataset-in-patches
  gis:apply-coverage blocks_data "R_CVEGEO" R_CVEGEO
end

; ------------- Go Procedure ----------------------------------------------------------------------------------------------------------------

to go.pee

  hatch-wwps 1 [
      set shape "circle"
      set color yellow
      set size 3
      show-turtle
      ;DW data analysis
      set dw.type "pee"
      set hatching.time time:show current-time "yyyy:MM:dd HH:mm"
      set ind.id ind.id
      set CVEGEO.reloc CVEGEO.reloc

      ;Traveling related code
      set origin_station one-of stations with-min [ distance myself ]
      set travel_path [ travel_path ] of origin_station
      ifelse travel_path = false or length travel_path = 0 [ set wwps_speed 0 ] [
      set wwps_speed 6  ;the wwps generated at households will reach its nearest station at a uniform speed 1
      ]

    ask wwp who[

    file-open "results/calibration.snt/dwpee.snt.cal1.csv"
    file-print (
    word ;precision ticks 1","
    ind.id","
    time:show current-time "yyyy:MM:dd HH:mm" ","
    time:show current-time "EEE"","
    "pee"","
    CVEGEO.reloc","
    who","
        starting-seed","
        behaviorspace-run-number","
        behaviorspace-experiment-name )
      file-close]

  ]

  ;set accumulated.wwps (accumulated.wwps + 1); count the hatched wwps

  ; hatch washing hands after pee
  time:schedule-event self [ [] -> go.washbasin ] (time:plus current-time 1 "minutes")

end

to go.poo

hatch-wwps 1 [
      set shape "circle"
      set color brown
      set size 5
      show-turtle
      ;DW data analysis
      set dw.type "poo"
      set hatching.time time:show current-time "yyyy:MM:dd HH:mm"
      set ind.id ind.id
      set CVEGEO.reloc CVEGEO.reloc

    ;Traveling related code
      set origin_station one-of stations with-min [ distance myself ]
      set travel_path [ travel_path ] of origin_station
      ifelse travel_path = false or length travel_path = 0 [ set wwps_speed 0 ] [
      set wwps_speed 6  ;the wwps generated at households will reach its nearest station at a uniform speed 1
      ]

    ask wwp who[

    file-open "results/calibration.snt/dwpoo.snt.cal1.csv"
  file-print (
    word ;precision ticks 1","
    ind.id","
    time:show current-time "yyyy:MM:dd HH:mm" ","
    time:show current-time "EEE"","
    "poo"","
    CVEGEO.reloc","
        who","
        starting-seed","
        behaviorspace-run-number","
        behaviorspace-experiment-name)
      file-close]

    ]
  ; count number of wwps
  ;set accumulated.wwps (accumulated.wwps + 1)
  ; hatching washing hands after poo
  time:schedule-event self [ [] -> go.washbasin ] (time:plus current-time 1 "minutes")
end

to go.washbasin ; washing hands after poo

  hatch-wwps 1 [
      set shape "circle"
      set color blue
      set size 3
      show-turtle
      ;DW data analysis
      set dw.type "washbasin"
      set hatching.time time:show (current-time) "yyyy:MM:dd HH:mm"
      set ind.id ind.id
      set CVEGEO.reloc CVEGEO.reloc

    ;Traveling related code
      set origin_station one-of stations with-min [ distance myself ]
      set travel_path [ travel_path ] of origin_station
      ifelse travel_path = false or length travel_path = 0 [ set wwps_speed 0 ] [
        set wwps_speed 6  ;the wwps generated at households will reach its nearest station at a uniform speed 1
      ]

    ask wwp who [

        file-open "results/calibration.snt/dwwashbasin.snt.cal1.csv"
  file-print (
    word ;precision ticks 1","
    ind.id","
    time:show current-time "yyyy:MM:dd HH:mm" ","
    time:show current-time "EEE"","
    "washbasin"","
    CVEGEO.reloc","
        who","
        starting-seed","
        behaviorspace-run-number","
        behaviorspace-experiment-name)
file-close

    ]

    ]
  ; count number of wwps
  ;set accumulated.wwps (accumulated.wwps + 1)
end

to go.kitchensink

  hatch-wwps 1 [
      set shape "circle"
      set color brown
      set size 5
      ;show-turtle
;
      ;DW data analysis
      set dw.type "kitchensink"
      set hatching.time time:show current-time "yyyy:MM:dd HH:mm"
      ;set dead.time 0
      set ind.id ind.id
      set CVEGEO.reloc CVEGEO.reloc

      ;Traveling related code
      set origin_station one-of stations with-min [ distance myself ]
      set travel_path [ travel_path ] of origin_station
      ifelse travel_path = false or length travel_path = 0 [ set wwps_speed 0 ] [
      set wwps_speed 6  ;the wwps generated at households will reach its nearest station at a uniform speed 1
      ]

    ask wwp who[

      file-open "results/calibration.snt/dwkitchensink.snt.cal1.csv"
  file-print (
    word ;precision ticks 1","
    ind.id","
    time:show current-time "yyyy:MM:dd HH:mm" ","
    time:show current-time "EEE"","
    "kitchensink"","
    CVEGEO.reloc","
        who","
        starting-seed","
        behaviorspace-run-number","
        behaviorspace-experiment-name)
file-close

    ]

    ]

  ;set accumulated.wwps (accumulated.wwps + 1); count the hatched wwps

  ; hatching washing hands before and after kitchen
  time:schedule-event self [ [] -> go.washbasin ] (time:plus current-time 1 "minutes")
  time:schedule-event self [ [] -> go.washbasin ] (time:plus current-time 30 "minutes")

end

to go.shower

hatch-wwps 1 [
      set shape "circle"
      set color brown
      set size 5
      ;show-turtle

      ;DW data analysis
      set dw.type "shower"
      set hatching.time time:show current-time "yyyy:MM:dd HH:mm"
      ;set dead.time 0
      set ind.id ind.id
      set CVEGEO.reloc CVEGEO.reloc

      ;Traveling related code
      set origin_station one-of stations with-min [ distance myself ]
      set travel_path [ travel_path ] of origin_station
      ifelse travel_path = false or length travel_path = 0 [ set wwps_speed 0 ] [
      set wwps_speed 6  ;the wwps generated at households will reach its nearest station at a uniform speed 1
      ]

    ask wwp who[

      file-open "results/calibration.snt/dwshower.snt.cal1.csv"
  file-print (
    word ;precision ticks 1","
    ind.id","
    time:show current-time "yyyy:MM:dd HH:mm" ","
    time:show current-time "EEE"","
    "shower"","
    CVEGEO.reloc","
        who","
        starting-seed","
        behaviorspace-run-number","
        behaviorspace-experiment-name)
file-close

    ]

    ]

  ;set accumulated.wwps (accumulated.wwps + 1); count the hatched wwps
  ;wash hands after shower
  time:schedule-event self [ [] -> go.washbasin ] (time:plus current-time 15 "minutes")

end

to go.washingmachine

  hatch-wwps 1 [
      set shape "circle"
      set color brown
      set size 5
      ;show-turtle

    ;DW data analysis
      set dw.type "washingmachine"
      set hatching.time time:show current-time "yyyy:MM:dd HH:mm"
      set ind.id ind.id
      set CVEGEO.reloc CVEGEO.reloc

    ;Traveling related code
      set origin_station one-of stations with-min [ distance myself ]
      set travel_path [ travel_path ] of origin_station
      ifelse travel_path = false or length travel_path = 0 [ set wwps_speed 0 ] [
      set wwps_speed 6  ;the wwps generated at households will reach its nearest station at a uniform speed 1
      ]

    ask wwp who[

      file-open "results/calibration.snt/dwwmachine.snt.cal1.csv"
  file-print (
    word ;precision ticks 1","
    ind.id","
    time:show current-time "yyyy:MM:dd HH:mm" ","
    time:show current-time "EEE"","
    "washingmachine"","
    CVEGEO.reloc","
        who","
        starting-seed","
        behaviorspace-run-number","
        behaviorspace-experiment-name)
file-close

    ]

    ]

  ;set accumulated.wwps (accumulated.wwps + 1); count the two hatched wwps
  ;wash hands after washingmachine
  time:schedule-event self [ [] -> go.washbasin ] (time:plus current-time 5 "minutes")
end

to go.homeworkrelocation

  let entry.economicpoint (economic.point who)
  ask entry.economicpoint [
  ifelse count (inhabitants with [located.at = "home.place" and go.work = "PEA"]) > 0 [

    let economic.point.workers ([avg.workers] of entry.economicpoint)
    let work.CVEGEO ([CVEGEO] of entry.economicpoint)
    ask up-to-n-of (economic.point.workers) inhabitants with [located.at = "home.place" and go.work = "PEA"]
     [move-to entry.economicpoint
      set color white
      set located.at "work.place"
      set CVEGEO.reloc (work.CVEGEO)]
    ;ask entry.economicpoint [show count inhabitants-here ]
    ;print time:show current-time "yyyy:MM:dd HH:mm"
    ] []
  ]

end

to go.workhomerelocation

  let entry.economicpoint (economic.point who)
  ask entry.economicpoint [

    ifelse count (inhabitants-here) > 0 [
      foreach sort inhabitants-here [ entry.inhabitant ->
        ask entry.inhabitant[
          move-to one-of households with [CVEGEO = [CVEGEO] of entry.inhabitant]
          set color black
          set located.at "home.place"
          set CVEGEO.reloc ([CVEGEO] of entry.inhabitant)]
      ]
    ]
    []
    ;print time:show current-time "yyyy:MM:dd HH:mm"
  ]

end

to go.homeschoolrelocation

  let entry.economicpoint (economic.point who)
  ask entry.economicpoint [

    ifelse count (inhabitants with [located.at = "home.place" and go.school = "PA"]) > 0 [
      let school.CVEGEO ([CVEGEO] of entry.economicpoint)
      let school.level ([school.exist] of entry.economicpoint)

      ;send to preschoolar
      if (school.level = "school.pre")[
        ask inhabitants with [
          located.at = "home.place" and
          go.school = "PA" and
          go.work = "PE_INAC" and
          escolar.level = "1"]
        [move-to one-of economic.points with [school.exist = "school.pre"]
          set color white
          set located.at (school.level)
          set CVEGEO.reloc (school.CVEGEO)
          set wwtp.conex.reloc "n"
          ;ask entry.economicpoint [show count inhabitants-here ]
          ;print time:show current-time "yyyy:MM:dd HH:mm"
        ]
      ]

      ;send to elementary schools
      if (school.level = "school.elementary")[
        ask inhabitants with [
          located.at = "home.place" and
          go.school = "PA" and
          go.work = "PE_INAC" and
          escolar.level = "2"]
        [move-to entry.economicpoint
          set color white
          set located.at (school.level)
          set CVEGEO.reloc (school.CVEGEO)
          set wwtp.conex.reloc "n"
          ;ask entry.economicpoint [show count inhabitants-here ]
          ;print time:show current-time "yyyy:MM:dd HH:mm"
        ]
      ]

      ;send to highschool
      if (school.level = "school.high")[
        ask inhabitants with [
          located.at = "home.place" and
          go.school = "PA" and
          go.work = "PE_INAC" and
          escolar.level = "3"]
        [move-to entry.economicpoint
          set color white
          set located.at (school.level)
          set CVEGEO.reloc (school.CVEGEO)
          set wwtp.conex.reloc "y"
          ;ask entry.economicpoint [show count inhabitants-here ]
          ;print time:show current-time "yyyy:MM:dd HH:mm"
        ]
      ]

      ;send to elementary multilevel
      if (school.level = "school.multilevel")[
        ask inhabitants with [
          located.at = "home.place" and
          go.school = "PA" and
          escolar.level != "1" and
          escolar.level != "2" and
          escolar.level != "3"]
        [move-to entry.economicpoint
          set color yellow
          set located.at (school.level)
          set CVEGEO.reloc (school.CVEGEO)
          ;ask entry.economicpoint [show count inhabitants-here ]
          ;print time:show current-time "yyyy:MM:dd HH:mm"
        ]
      ]
    ] []
  ]

end

to go.schoolhomerelocation

  let entry.economicpoint (economic.point who)
  ask entry.economicpoint [

    ifelse count (inhabitants-here) > 0 [
      foreach sort inhabitants-here [ entry.inhabitant ->
        ask entry.inhabitant[
          move-to one-of households with [CVEGEO = [CVEGEO] of entry.inhabitant]
          set color black
          set located.at "home.place"
          set CVEGEO.reloc ([CVEGEO] of entry.inhabitant)
          set wwtp.conex.reloc ([wwtp.conex] of entry.inhabitant)];new
      ]
    ]
    []
    ;print time:show current-time "yyyy:MM:dd HH:mm"
  ]

end

to pee

  ;To define probabilities of
  ; 1) number of pee events (from 2 to 11 times a day)
  ; 2) in specific hours of the day (from 0 to 23 hours)
let pee.times.aday [ 2 3 4 5 6 7 8 9 10 11 ]; people pee a minimum of 2 and max of 11 times a day
let prob.pee.times.aday [ .02 .05 .07 .13 .19 .17 .18 .12 .05 .02 ]; probabilities of each time to happen
let prob.pee.times.aday.weekend [ .01 .03 .05 .10 .19 .20 .18 .12 .08 .04 ]
  ; report the first item of the pair selected using; the second item (i.e., `last p`) as the weight

let pee.hour [
    0
    1 2 3 4 5
    6 7 8 9 10
    11 12 13 14 15
    16 17 18 19 20
    21 22 23 ]
 let prob.pee.hour [
    .02
    .02 .02 .02 .02 .05
    .05 .05 .03 .03 .04
    .05 .04 .03 .03 .03
    .04 .05 .06 .06 .07
    .07 .06 .06
 ]
  let prob.pee.hour.weekend [
    .02 .02 .01 .01 .02 .05
    .06 .06 .03 .03 .02
    .03 .03 .06 .03 .06
    .05 .04 .04 .06 .07
    .08 .07 .06]

;    peewkh6 peewkh7 peewkh8 peewkh9 peewkh10
;    peewkh11 peewkh12 peewkh13 peewkh14 peewkh15
;    peewkh16 peewkh17 peewkh18 peewkh19 peewkh20

;Peridos defined in interface. Used to define iteration in each day of pee
let pee.starting time:create model.starting.at

  ;Calculate number of days bertween pee starting and ending for iterations
  ;+1 is required to starti counting from 1 and not from 0
  ;n-values creates lenght list of number of pee days with values =[0]
  let pee.n.days n-values (time:difference-between (model.starting.at) (model.ending.at) "days") [0]

 foreach sort pee.n.days [
    ifelse ("Saturday" = time:show pee.starting "EEEE") xor ("Sunday" = time:show pee.starting "EEEE")
    [foreach sort inhabitants with [wwtp.conex.reloc = "y"]
      [ the-inhabitant ->
      let list.pee.event.aday (map list pee.times.aday prob.pee.times.aday.weekend)
      let num.pee.event.aday (first rnd:weighted-one-of-list list.pee.event.aday [ [p] -> last p ])
      let list.pee.event.hour (map list pee.hour prob.pee.hour.weekend)
      let many.pee.event.hours (map first rnd:weighted-n-of-list (num.pee.event.aday) list.pee.event.hour [ [p] -> last p ])

      foreach many.pee.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.pee ] (time:plus (pee.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort inhabitants with [wwtp.conex.reloc = "y"]
      [ the-inhabitant ->
      let list.pee.event.aday (map list pee.times.aday prob.pee.times.aday)
      let num.pee.event.aday (first rnd:weighted-one-of-list list.pee.event.aday [ [p] -> last p ])
      let list.pee.event.hour (map list pee.hour prob.pee.hour)
      let many.pee.event.hours (map first rnd:weighted-n-of-list (num.pee.event.aday) list.pee.event.hour [ [p] -> last p ])

      foreach many.pee.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.pee ] (time:plus (pee.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
     set pee.starting time:plus (pee.starting) 1 "day"
    ]
end

to poo

  ;To define probabilities of
  ; 1) number of poo events (from 2 to 11 times a day)
  ; 2) in specific hours of the day (from 0 to 23 hours)
  let poo.times.aday [1 2 3]; people poo a minimum of 0 and max of 3 times a day
  let prob.poo.times.aday [.7 .25 .05]; probabilities of each time to happen
  let prob.poo.times.aday.weekend [.6 .25 .15]
  ; report the first item of the pair selected using; the second item (i.e., `last p`) as the weight

let poo.hour [
    0
    1 2 3 4 5
    6 7 8 9 10
    11 12 13 14 15
    16 17 18 19 20
    21 22 23 ]

 let prob.poo.hour [
    .0
    .0 .0 .0 .0 .0
    .01 .05 .21 .22 .11
    .085 .07 .075 .06 .07
    .005 .005 .005 .005 .01
    .01 .0 .0 ]
  let prob.poo.hour.weekend [
    .0 .0 .0 .0 .0 .0
    .05 .05 .1 .2 .2
    .1 .05 .05 .05 .05
    .02 .02 .02 .02 .02
    .0 .0 .0]

;Peridos defined in interface. Used to define iteration in each day of poo
let poo.starting time:create model.starting.at

  ;Calculate number of days bertween poo starting and ending for iterations
  ;+1 is required to starti counting from 1 and not from 0
  ;n-values creates lenght list of number of poo days with values =[0]
  let poo.n.days n-values (time:difference-between (model.starting.at) (model.ending.at) "days") [0]

 foreach sort poo.n.days [
    ifelse ("Saturday" = time:show poo.starting "EEEE") xor ("Sunday" = time:show poo.starting "EEEE")
    [foreach sort inhabitants with [wwtp.conex.reloc = "y"]
      [ the-inhabitant ->
      let list.poo.event.aday (map list poo.times.aday prob.poo.times.aday.weekend)
      let num.poo.event.aday (first rnd:weighted-one-of-list list.poo.event.aday [ [p] -> last p ])
      let list.poo.event.hour (map list poo.hour prob.poo.hour.weekend)
      let many.poo.event.hours (map first rnd:weighted-n-of-list (num.poo.event.aday) list.poo.event.hour [ [p] -> last p ])

      foreach many.poo.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.poo ] (time:plus (poo.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort inhabitants with [wwtp.conex.reloc = "y"]
      [ the-inhabitant ->
      let list.poo.event.aday (map list poo.times.aday prob.poo.times.aday)
      let num.poo.event.aday (first rnd:weighted-one-of-list list.poo.event.aday [ [p] -> last p ])
      let list.poo.event.hour (map list poo.hour prob.poo.hour)
      let many.poo.event.hours (map first rnd:weighted-n-of-list (num.poo.event.aday) list.poo.event.hour [ [p] -> last p ])

      foreach many.poo.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.poo ] (time:plus (poo.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
     set poo.starting time:plus (poo.starting) 1 "day"
    ]
end


to kitchensink

  ;To define probabilities of
  ; 1) number of kitchensink events (from 2 to 11 times a day)
  ; 2) in specific hours of the day (from 0 to 23 hours)

let kitchensink.times.aday [ 1 2 3 4 5 ]; people kitchen mimum of 1 and max of 5 uses a day

let prob.kitchensink.times.aday.high [ 0.4 0.35 0.15 0.05 0.05 ]; probabilities of each time to happen
let prob.kitchensink.times.aday.weekend.high [ 0.1 0.35 0.45 0.05 0.05 ]
 ; report the first item of the pair selected using; the second item (i.e., `last p`) as the weight

let prob.kitchensink.times.aday.medium [ 0.4 0.35 0.15 0.05 0.05 ]; probabilities of each time to happen
let prob.kitchensink.times.aday.weekend.medium [ 0.05 0.35 0.45 0.1 0.05 ]

let prob.kitchensink.times.aday.low [ 0.4 0.35 0.15 0.05 0.05 ]; probabilities of each time to happen
let prob.kitchensink.times.aday.weekend.low [ 0.05 0.35 0.45 0.1 0.05 ]

let kitchensink.hour [
    0 1  2  3  4  5
    6  7  8  9  10 11
    12 13 14 15 16 17
    18 19 20 21 22 23 ]

  let prob.kitchensink.hour [
    0	0	0	0	0	0.03 ; 0 to 5 hors
    0.05	0.09	0.07	0.07	0.03	0 ; 6 to 11 hours
    0.06	0.13	0.15	0.09	0.03	0 ; 12 to 17 hours
    0	0.07	0.1	0.04	0	0 ; 18 to 23 hours
  ]
  let prob.kitchensink.hour.weekend [
  0	0	0	0	0	0 ; 0 to 5 hors
  0.03	0.05	0.07	0.12	0.08	0 ; 6 to 11 hours
  0.03	0.15	0.2	0.15	0.05	0 ; 12 to 17 hours
  0	0.05	0.07	0.15	0.05	0 ; 18 to 23 hours
  ]

;Peridos defined in interface. Used to define iteration in each day of pee
let kitchensink.starting time:create model.starting.at

  ;Calculate number of days between pee starting and ending for iterations
  ;+1 is required to starti counting from 1 and not from 0
  ;n-values creates lenght list of number of pee days with values =[0]
  let kitchensink.n.days n-values (time:difference-between (model.starting.at) (model.ending.at) "days") [0]

 foreach sort kitchensink.n.days [
    ;;;;;;;;;; HIGH. high probability to use kitchen (no work no study)
    ifelse ("Saturday" = time:show kitchensink.starting "EEEE") xor ("Sunday" = time:show kitchensink.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "NOA" and
      go.work = "PE_INAC"]
            [ the-inhabitant ->
      let list.kitchensink.event.aday (map list kitchensink.times.aday prob.kitchensink.times.aday.weekend.high)
      let num.kitchensink.event.aday (first rnd:weighted-one-of-list list.kitchensink.event.aday [ [p] -> last p ])
      let list.kitchensink.event.hour (map list kitchensink.hour prob.kitchensink.hour.weekend)
      let many.kitchensink.event.hours (map first rnd:weighted-n-of-list (num.kitchensink.event.aday) list.kitchensink.event.hour [ [p] -> last p ])

      foreach many.kitchensink.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.kitchensink ] (time:plus (kitchensink.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "NOA" and
      go.work = "PE_INAC"]
            [ the-inhabitant ->
      let list.kitchensink.event.aday (map list kitchensink.times.aday prob.kitchensink.times.aday.high)
      let num.kitchensink.event.aday (first rnd:weighted-one-of-list list.kitchensink.event.aday [ [p] -> last p ])
      let list.kitchensink.event.hour (map list kitchensink.hour prob.kitchensink.hour)
      let many.kitchensink.event.hours (map first rnd:weighted-n-of-list (num.kitchensink.event.aday) list.kitchensink.event.hour [ [p] -> last p ])

      foreach many.kitchensink.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.kitchensink ] (time:plus (kitchensink.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]

    ;;;;;;;;;; MEDIUM1. probability to use kitchen (work but no study)
    ifelse ("Saturday" = time:show kitchensink.starting "EEEE") xor ("Sunday" = time:show kitchensink.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "NOA" and
      go.work = "PEA"]
            [ the-inhabitant ->
      let list.kitchensink.event.aday (map list kitchensink.times.aday prob.kitchensink.times.aday.weekend.medium)
      let num.kitchensink.event.aday (first rnd:weighted-one-of-list list.kitchensink.event.aday [ [p] -> last p ])
      let list.kitchensink.event.hour (map list kitchensink.hour prob.kitchensink.hour.weekend)
      let many.kitchensink.event.hours (map first rnd:weighted-n-of-list (num.kitchensink.event.aday) list.kitchensink.event.hour [ [p] -> last p ])

      foreach many.kitchensink.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.kitchensink ] (time:plus (kitchensink.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "NOA" and
      go.work = "PEA"]
            [ the-inhabitant ->
      let list.kitchensink.event.aday (map list kitchensink.times.aday prob.kitchensink.times.aday.medium)
      let num.kitchensink.event.aday (first rnd:weighted-one-of-list list.kitchensink.event.aday [ [p] -> last p ])
      let list.kitchensink.event.hour (map list kitchensink.hour prob.kitchensink.hour)
      let many.kitchensink.event.hours (map first rnd:weighted-n-of-list (num.kitchensink.event.aday) list.kitchensink.event.hour [ [p] -> last p ])

      foreach many.kitchensink.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.kitchensink ] (time:plus (kitchensink.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]

    ;;;;;;;;;; MEDIUM2. probability to use kitchen (no work but study)
    ifelse ("Saturday" = time:show kitchensink.starting "EEEE") xor ("Sunday" = time:show kitchensink.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "PA" and
      go.work = "PE_INAC"]
            [ the-inhabitant ->
      let list.kitchensink.event.aday (map list kitchensink.times.aday prob.kitchensink.times.aday.weekend.medium)
      let num.kitchensink.event.aday (first rnd:weighted-one-of-list list.kitchensink.event.aday [ [p] -> last p ])
      let list.kitchensink.event.hour (map list kitchensink.hour prob.kitchensink.hour.weekend)
      let many.kitchensink.event.hours (map first rnd:weighted-n-of-list (num.kitchensink.event.aday) list.kitchensink.event.hour [ [p] -> last p ])

      foreach many.kitchensink.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.kitchensink ] (time:plus (kitchensink.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "PA" and
      go.work = "PE_INAC"]
            [ the-inhabitant ->
      let list.kitchensink.event.aday (map list kitchensink.times.aday prob.kitchensink.times.aday.medium)
      let num.kitchensink.event.aday (first rnd:weighted-one-of-list list.kitchensink.event.aday [ [p] -> last p ])
      let list.kitchensink.event.hour (map list kitchensink.hour prob.kitchensink.hour)
      let many.kitchensink.event.hours (map first rnd:weighted-n-of-list (num.kitchensink.event.aday) list.kitchensink.event.hour [ [p] -> last p ])

      foreach many.kitchensink.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.kitchensink ] (time:plus (kitchensink.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]

    ;;;;;;;;;; LOW probability to use kitchen (work and study)
    ifelse ("Saturday" = time:show kitchensink.starting "EEEE") xor ("Sunday" = time:show kitchensink.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "PA" and
      go.work = "PEA"]
            [ the-inhabitant ->
      let list.kitchensink.event.aday (map list kitchensink.times.aday prob.kitchensink.times.aday.weekend.low)
      let num.kitchensink.event.aday (first rnd:weighted-one-of-list list.kitchensink.event.aday [ [p] -> last p ])
      let list.kitchensink.event.hour (map list kitchensink.hour prob.kitchensink.hour.weekend)
      let many.kitchensink.event.hours (map first rnd:weighted-n-of-list (num.kitchensink.event.aday) list.kitchensink.event.hour [ [p] -> last p ])

      foreach many.kitchensink.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.kitchensink ] (time:plus (kitchensink.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "PA" and
      go.work = "PEA"]
            [ the-inhabitant ->
      let list.kitchensink.event.aday (map list kitchensink.times.aday prob.kitchensink.times.aday.low)
      let num.kitchensink.event.aday (first rnd:weighted-one-of-list list.kitchensink.event.aday [ [p] -> last p ])
      let list.kitchensink.event.hour (map list kitchensink.hour prob.kitchensink.hour)
      let many.kitchensink.event.hours (map first rnd:weighted-n-of-list (num.kitchensink.event.aday) list.kitchensink.event.hour [ [p] -> last p ])

      foreach many.kitchensink.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.kitchensink ] (time:plus (kitchensink.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]

     set kitchensink.starting time:plus (kitchensink.starting) 1 "day"
    ]
end

to shower

  ;To define probabilities of
  ; 1) number of shower events (from 2 to 11 times a day)
  ; 2) in specific hours of the day (from 0 to 23 hours)

let shower.times.aday [ 0 1 2]; people shower mimum of 12 and max of 5 uses a day

let prob.shower.times.aday [ 0.7 0.2 0.1 ]; probabilities of each time to happen
let prob.shower.times.aday.weekend [0.7  0.2 0.1 ]
 ; report the first item of the pair selected using; the second item (i.e., `last p`) as the weight

let shower.hour [
    0 1  2  3  4  5
    6  7  8  9  10 11
    12 13 14 15 16 17
    18 19 20 21 22 23 ]

  let prob.shower.hour.work [
    0	0	0	0	0	0.05 ; 0 to 5 hors
    0.06	0.13	0.10	0.15	0.03	0.01 ; 6 to 11 hours
    0.0	0.0	0.0	0.0	0.0	0 ; 12 to 17 hours
    0.7	0.10	0.10	0.10	0	0 ; 18 to 23 hours
  ]
  let prob.shower.hour.weekend.work [
  0	0	0	0	0	0 ; 0 to 5 hors
  0.0	0.15	0.15	0.15	0.15	0 ; 6 to 11 hours
  0.2	0.2	0.0	0.0	0.0	0 ; 12 to 17 hours
  0	0.00	0.0	0.0	0.00	0 ; 18 to 23 hours
  ]

  let prob.shower.hour.study [
    0	0	0	0	0	0.05 ; 0 to 5 hors
    0.05	0.3	0.20	0.15	.05	0 ; 6 to 11 hours
    0.0	0.0	0.0	0.0	0.0	0 ; 12 to 17 hours
    0	0.0	0.10	0.10	0	0 ; 18 to 23 hours
  ]
  let prob.shower.hour.weekend.study [
  0	0	0	0	0	0 ; 0 to 5 hors
  0.0	0.15	0.15	0.15	0.15	0 ; 6 to 11 hours
  0.2	0.2	0.0	0.0	0.0	0 ; 12 to 17 hours
  0	0.00	0.0	0.0	0.00	0 ; 18 to 23 hours
  ]

;Peridos defined in interface. Used to define iteration in each day of pee
let shower.starting time:create model.starting.at

  ;Calculate number of days bertween pee starting and ending for iterations
  ;+1 is required to starti counting from 1 and not from 0
  ;n-values creates lenght list of number of pee days with values =[0]
  let shower.n.days n-values (time:difference-between (model.starting.at) (model.ending.at) "days") [0]

 foreach sort shower.n.days [
    ;;;;;;;;;; Workers shower time
    ifelse ("Saturday" = time:show shower.starting "EEEE") xor ("Sunday" = time:show shower.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.work = "PEA"]
            [ the-inhabitant ->
      let list.shower.event.aday (map list shower.times.aday prob.shower.times.aday.weekend)
      let num.shower.event.aday (first rnd:weighted-one-of-list list.shower.event.aday [ [p] -> last p ])
      let list.shower.event.hour (map list shower.hour prob.shower.hour.weekend.work)
      let many.shower.event.hours (map first rnd:weighted-n-of-list (num.shower.event.aday) list.shower.event.hour [ [p] -> last p ])

      foreach many.shower.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.shower ] (time:plus (shower.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.work = "PEA"]
            [ the-inhabitant ->
      let list.shower.event.aday (map list shower.times.aday prob.shower.times.aday)
      let num.shower.event.aday (first rnd:weighted-one-of-list list.shower.event.aday [ [p] -> last p ])
      let list.shower.event.hour (map list shower.hour prob.shower.hour.work)
      let many.shower.event.hours (map first rnd:weighted-n-of-list (num.shower.event.aday) list.shower.event.hour [ [p] -> last p ])

      foreach many.shower.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.shower ] (time:plus (shower.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]

    ;;;;;;;;;; Students shower time
    ifelse ("Saturday" = time:show shower.starting "EEEE") xor ("Sunday" = time:show shower.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "PA"]
            [ the-inhabitant ->
      let list.shower.event.aday (map list shower.times.aday prob.shower.times.aday.weekend)
      let num.shower.event.aday (first rnd:weighted-one-of-list list.shower.event.aday [ [p] -> last p ])
      let list.shower.event.hour (map list shower.hour prob.shower.hour.weekend.study)
      let many.shower.event.hours (map first rnd:weighted-n-of-list (num.shower.event.aday) list.shower.event.hour [ [p] -> last p ])

      foreach many.shower.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.shower ] (time:plus (shower.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "PA"]
            [ the-inhabitant ->
      let list.shower.event.aday (map list shower.times.aday prob.shower.times.aday)
      let num.shower.event.aday (first rnd:weighted-one-of-list list.shower.event.aday [ [p] -> last p ])
      let list.shower.event.hour (map list shower.hour prob.shower.hour.study)
      let many.shower.event.hours (map first rnd:weighted-n-of-list (num.shower.event.aday) list.shower.event.hour [ [p] -> last p ])

      foreach many.shower.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.shower ] (time:plus (shower.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]

        ;;;;;;;;;; No Students no workers shower time  = to workers
    ifelse ("Saturday" = time:show shower.starting "EEEE") xor ("Sunday" = time:show shower.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "NOA" and
      go.work = "PE_INAC" ]
            [ the-inhabitant ->
      let list.shower.event.aday (map list shower.times.aday prob.shower.times.aday.weekend)
      let num.shower.event.aday (first rnd:weighted-one-of-list list.shower.event.aday [ [p] -> last p ])
      let list.shower.event.hour (map list shower.hour prob.shower.hour.weekend.work)
      let many.shower.event.hours (map first rnd:weighted-n-of-list (num.shower.event.aday) list.shower.event.hour [ [p] -> last p ])

      foreach many.shower.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.shower ] (time:plus (shower.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "NOA" and
      go.work = "PE_INAC"]
            [ the-inhabitant ->
      let list.shower.event.aday (map list shower.times.aday prob.shower.times.aday)
      let num.shower.event.aday (first rnd:weighted-one-of-list list.shower.event.aday [ [p] -> last p ])
      let list.shower.event.hour (map list shower.hour prob.shower.hour.work)
      let many.shower.event.hours (map first rnd:weighted-n-of-list (num.shower.event.aday) list.shower.event.hour [ [p] -> last p ])

      foreach many.shower.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.shower ] (time:plus (shower.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]

     set shower.starting time:plus (shower.starting) 1 "day"
    ]
end

to washingmachine

  ;To define probabilities of
  ; 1) number of washingmachine events (from 2 to 11 times a day)
  ; 2) in specific hours of the day (from 0 to 23 hours)

let washingmachine.times.aday [ 1 2 ]; people washingmachine mimum of 12 and max of 5 uses a day

let prob.washingmachine.times.aday [ 0.1 0.1 ]; probabilities of each time to happen
let prob.washingmachine.times.aday.weekend [ 0.4 .4 ]
 ; report the first item of the pair selected using; the second item (i.e., `last p`) as the weight

let washingmachine.hour [
    0 1  2  3  4  5
    6  7  8  9  10 11
    12 13 14 15 16 17
    18 19 20 21 22 23 ]

  let prob.washingmachine.hour.work [
    0	0	0	0	0	0.00 ; 0 to 5 hors
    0.00	0.05	0.0	0.0	.00	0 ; 6 to 11 hours
    0.0	0.0	0.0	0.0	0.0	0 ; 12 to 17 hours
    0	0.05	0.05	0.05	0	0 ; 18 to 23 hours
  ]
  let prob.washingmachine.hour.weekend.work [
  0	0	0	0	0	0 ; 0 to 5 hors
  0.0	0.1	0.1	0.2	0.2	0.15 ; 6 to 11 hours
  0.15	0.05	0.05	0.0	0.0	0 ; 12 to 17 hours
  0	0.00	0.0	0.0	0.00	0 ; 18 to 23 hours
  ]

  let prob.washingmachine.hour.study [
    0	0	0	0	0	0.00 ; 0 to 5 hors
    0.00	0.05	0.0	0.0	.00	0 ; 6 to 11 hours
    0.0	0.0	0.0	0.0	0.0	0 ; 12 to 17 hours
    0	0.05	0.05	0.05	0	0 ; 18 to 23 hours
  ]
  let prob.washingmachine.hour.weekend.study [
  0	0	0	0	0	0 ; 0 to 5 hors
  0.0	0.1	0.1	0.2	0.2	0.15 ; 6 to 11 hours
  0.15	0.05	0.05	0.0	0.0	0 ; 12 to 17 hours
  0	0.00	0.0	0.0	0.00	0 ; 18 to 23 hours
  ]

;Peridos defined in interface. Used to define iteration in each day of pee
let washingmachine.starting time:create model.starting.at

  ;Calculate number of days bertween pee starting and ending for iterations
  ;+1 is required to starti counting from 1 and not from 0
  ;n-values creates lenght list of number of pee days with values =[0]
  let washingmachine.n.days n-values (time:difference-between (model.starting.at) (model.ending.at) "days") [0]

 foreach sort washingmachine.n.days [
    ;;;;;;;;;; Workers washingmachine time
    ifelse ("Saturday" = time:show washingmachine.starting "EEEE") xor ("Sunday" = time:show washingmachine.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.work = "PEA"]
            [ the-inhabitant ->
      let list.washingmachine.event.aday (map list washingmachine.times.aday prob.washingmachine.times.aday.weekend)
      let num.washingmachine.event.aday (first rnd:weighted-one-of-list list.washingmachine.event.aday [ [p] -> last p ])
      let list.washingmachine.event.hour (map list washingmachine.hour prob.washingmachine.hour.weekend.work)
      let many.washingmachine.event.hours (map first rnd:weighted-n-of-list (num.washingmachine.event.aday) list.washingmachine.event.hour [ [p] -> last p ])

      foreach many.washingmachine.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.washingmachine ] (time:plus (washingmachine.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    []

    ;;;;;;;;;; Students washingmachine time
    ifelse ("Saturday" = time:show washingmachine.starting "EEEE") xor ("Sunday" = time:show washingmachine.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "PA"]
            [ the-inhabitant ->
      let list.washingmachine.event.aday (map list washingmachine.times.aday prob.washingmachine.times.aday.weekend)
      let num.washingmachine.event.aday (first rnd:weighted-one-of-list list.washingmachine.event.aday [ [p] -> last p ])
      let list.washingmachine.event.hour (map list washingmachine.hour prob.washingmachine.hour.weekend.study)
      let many.washingmachine.event.hours (map first rnd:weighted-n-of-list (num.washingmachine.event.aday) list.washingmachine.event.hour [ [p] -> last p ])

      foreach many.washingmachine.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.washingmachine ] (time:plus (washingmachine.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    []

        ;;;;;;;;;; No Students no workers washingmachine time  = to workers
    ifelse ("Saturday" = time:show washingmachine.starting "EEEE") xor ("Sunday" = time:show washingmachine.starting "EEEE")
    [foreach sort inhabitants with [
      wwtp.conex.reloc = "y" and
      go.school = "NOA" and
      go.work = "PE_INAC" ]
            [ the-inhabitant ->
      let list.washingmachine.event.aday (map list washingmachine.times.aday prob.washingmachine.times.aday.weekend)
      let num.washingmachine.event.aday (first rnd:weighted-one-of-list list.washingmachine.event.aday [ [p] -> last p ])
      let list.washingmachine.event.hour (map list washingmachine.hour prob.washingmachine.hour.weekend.work)
      let many.washingmachine.event.hours (map first rnd:weighted-n-of-list (num.washingmachine.event.aday) list.washingmachine.event.hour [ [p] -> last p ])

      foreach many.washingmachine.event.hours [ hour ->
        ask the-inhabitant [ time:schedule-event (inhabitant who) [ [] -> go.washingmachine ] (time:plus (washingmachine.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    []

     set washingmachine.starting time:plus (washingmachine.starting) 1 "day"
    ]
end

to homeworkrelocation

let work.times.aday [ 0 1 ]; people relocate and go to work a minimum of 0 and max of 1 times a day
let prob.work.times.aday [ 0 1 ]; probabilities of each time to happen during the week
  let prob.work.times.aday.weekend [ 0 .5 ] ;50% of people can go or not to work on weekedns
  ; report the first item of the pair selected using; the second item (i.e., `last p`) as the weight

let workstarting.hour [
    0 1 2 3 4 5
    6 7 8 9 10
    11 12 13 14 15
    16 17 18 19 20
    21 22 23 ]
 let prob.workstarting.hour [
    .0 .0 .0 .0 .0 .0
    .0 .3 .5 .2 .0
    .0 .0 .0 .0 .0
    .0 .0 .0 .0 .0
    .0 .0 .0 ]
  let prob.workstarting.hour.weekend [
    .0 .0 .0 .0 .0 .0
    .0 .0 .3 .5 .2
    .0 .0 .0 .0 .0
    .0 .0 .0 .0 .0
    .0 .0 .0]

;Peridos defined in interface. Used to define iteration in each day of poo
let work.starting time:create model.starting.at

  ;Calculate number of days bertween poo starting and ending for iterations
  ;+1 is required to starti counting from 1 and not from 0
  ;n-values creates lenght list of number of poo days with values =[0]
  let work.n.days n-values (time:difference-between (model.starting.at) (model.ending.at) "days") [0]

 foreach sort work.n.days [
    ifelse ("Saturday" = time:show work.starting "EEEE") xor ("Sunday" = time:show work.starting "EEEE")
    [foreach sort economic.points [ the-economic.point ->
      let list.workstarting.event.aday (map list work.times.aday prob.work.times.aday.weekend)
      let num.workstarting.event.aday (first rnd:weighted-one-of-list list.workstarting.event.aday [ [p] -> last p ])
      let list.workstarting.event.hour (map list workstarting.hour prob.workstarting.hour.weekend)
      let many.workstarting.event.hours (map first rnd:weighted-n-of-list (num.workstarting.event.aday) list.workstarting.event.hour [ [p] -> last p ])

      foreach many.workstarting.event.hours [ hour ->
        ask the-economic.point [ time:schedule-event (economic.point who) [ [] -> go.homeworkrelocation ] (time:plus (work.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort economic.points [ the-economic.point ->
      let list.workstarting.event.aday (map list work.times.aday prob.work.times.aday)
      let num.workstarting.event.aday (first rnd:weighted-one-of-list list.workstarting.event.aday [ [p] -> last p ])
      let list.workstarting.event.hour (map list workstarting.hour prob.workstarting.hour)
      let many.workstarting.event.hours (map first rnd:weighted-n-of-list (num.workstarting.event.aday) list.workstarting.event.hour [ [p] -> last p ])

      foreach many.workstarting.event.hours [ hour ->
        ask the-economic.point [ time:schedule-event (economic.point who) [ [] -> go.homeworkrelocation ] (time:plus (work.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
     set work.starting time:plus (work.starting) 1 "day"
    ]
end

to workhomerelocation

let work.times.aday [ 0 1 ]; people relocate and go to work a minimum of 0 and max of 1 times a day
let prob.work.times.aday [ 0 1 ]; probabilities of each time to happen during the week
  let prob.work.times.aday.weekend [ 0 .5 ] ;50% of people can go or not to work on weekedns
  ; report the first item of the pair selected using; the second item (i.e., `last p`) as the weight

let workending.hour [
    0 1 2 3 4 5
    6 7 8 9 10
    11 12 13 14 15
    16 17 18 19 20
    21 22 23 ]
 let prob.workending.hour [
    .0 .0 .0 .0 .0 .0
    .0 .0 .0 .0 .0
    .0 .0 .0 .0 .0
    .3 .5 .2 .0 .0
    .0 .0 .0 ]
  let prob.workending.hour.weekend [
    .0 .0 .0 .0 .0 .0
    .0 .0 .0 .0 .0
    .0 .0 .3 .5 .2
    .0 .0 .0 .0 .0
    .0 .0 .0]

;Peridos defined in interface. Used to define iteration in each day of poo
let work.ending time:create model.starting.at

  ;Calculate number of days bertween poo starting and ending for iterations
  ;+1 is required to starti counting from 1 and not from 0
  ;n-values creates lenght list of number of poo days with values =[0]
  let work.n.days n-values (time:difference-between (model.starting.at) (model.ending.at) "days") [0]

 foreach sort work.n.days [
    ifelse ("Saturday" = time:show work.ending "EEEE") xor ("Sunday" = time:show work.ending "EEEE")
    [foreach sort economic.points [ the-economic.point ->
      let list.workending.event.aday (map list work.times.aday prob.work.times.aday.weekend)
      let num.workending.event.aday (first rnd:weighted-one-of-list list.workending.event.aday [ [p] -> last p ])
      let list.workending.event.hour (map list workending.hour prob.workending.hour.weekend)
      let many.workending.event.hours (map first rnd:weighted-n-of-list (num.workending.event.aday) list.workending.event.hour [ [p] -> last p ])

      foreach many.workending.event.hours [ hour ->
        ask the-economic.point [ time:schedule-event (economic.point who) [ [] -> go.workhomerelocation ] (time:plus (work.ending) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort economic.points [ the-economic.point ->
      let list.workending.event.aday (map list work.times.aday prob.work.times.aday)
      let num.workending.event.aday (first rnd:weighted-one-of-list list.workending.event.aday [ [p] -> last p ])
      let list.workending.event.hour (map list workending.hour prob.workending.hour)
      let many.workending.event.hours (map first rnd:weighted-n-of-list (num.workending.event.aday) list.workending.event.hour [ [p] -> last p ])

      foreach many.workending.event.hours [ hour ->
        ask the-economic.point [ time:schedule-event (economic.point who) [ [] -> go.workhomerelocation ] (time:plus (work.ending) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
     set work.ending time:plus (work.ending) 1 "day"
    ]
end

to homeschoolrelocation

let school.times.aday [ 0 1 ]; people relocate and go to school a minimum of 0 and max of 1 times a day
let prob.school.times.aday [ 0 1 ]; probabilities of each time to happen during the week
  let prob.school.times.aday.weekend [ 0 .3 ] ;50% of people can go or not to school on weekedns
  ; report the first item of the pair selected using; the second item (i.e., `last p`) as the weight

let schoolstarting.hour [
    0 1 2 3 4 5
    6 7 8 9 10
    11 12 13 14 15
    16 17 18 19 20
    21 22 23 ]
 let prob.schoolstarting.hour [
    .0 .0 .0 .0 .0 .0
    .0 .1 .7 .2 .0
    .0 .0 .0 .0 .0
    .0 .0 .0 .0 .0
    .0 .0 .0 ]
  let prob.schoolstarting.hour.weekend [
    .0 .0 .0 .0 .0 .0
    .0 .0 .5 .5 .0
    .0 .0 .0 .0 .0
    .0 .0 .0 .0 .0
    .0 .0 .0]

;Peridos defined in interface. Used to define iteration in each day of poo
let school.starting time:create model.starting.at

  ;Calculate number of days bertween poo starting and starting for iterations
  ;+1 is required to starti counting from 1 and not from 0
  ;n-values creates lenght list of number of poo days with values =[0]
  let school.n.days n-values (time:difference-between (model.starting.at) (model.ending.at) "days") [0]

 foreach sort school.n.days [
    ifelse ("Saturday" = time:show school.starting "EEEE") xor ("Sunday" = time:show school.starting "EEEE")
    [foreach sort economic.points with [school.exist != "no"] [ the-economic.point ->
      let list.schoolstarting.event.aday (map list school.times.aday prob.school.times.aday.weekend)
      let num.schoolstarting.event.aday (first rnd:weighted-one-of-list list.schoolstarting.event.aday [ [p] -> last p ])
      let list.schoolstarting.event.hour (map list schoolstarting.hour prob.schoolstarting.hour.weekend)
      let many.schoolstarting.event.hours (map first rnd:weighted-n-of-list (num.schoolstarting.event.aday) list.schoolstarting.event.hour [ [p] -> last p ])

      foreach many.schoolstarting.event.hours [ hour ->
        ask the-economic.point [ time:schedule-event (economic.point who) [ [] -> go.homeschoolrelocation ] (time:plus (school.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort economic.points with [school.exist != "no"] [ the-economic.point ->
      let list.schoolstarting.event.aday (map list school.times.aday prob.school.times.aday)
      let num.schoolstarting.event.aday (first rnd:weighted-one-of-list list.schoolstarting.event.aday [ [p] -> last p ])
      let list.schoolstarting.event.hour (map list schoolstarting.hour prob.schoolstarting.hour)
      let many.schoolstarting.event.hours (map first rnd:weighted-n-of-list (num.schoolstarting.event.aday) list.schoolstarting.event.hour [ [p] -> last p ])

      foreach many.schoolstarting.event.hours [ hour ->
        ask the-economic.point [ time:schedule-event (economic.point who) [ [] -> go.homeschoolrelocation ] (time:plus (school.starting) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
     set school.starting time:plus (school.starting) 1 "day"
    ]
end

to schoolhomerelocation

let school.times.aday [ 0 1 ]; people relocate and go to school a minimum of 0 and max of 1 times a day
let prob.school.times.aday [ 0 1 ]; probabilities of each time to happen during the week
  let prob.school.times.aday.weekend [ 0 .3 ] ;50% of people can go or not to school on weekedns
  ; report the first item of the pair selected using; the second item (i.e., `last p`) as the weight

let schoolending.hour [
    0 1 2 3 4 5
    6 7 8 9 10
    11 12 13 14 15
    16 17 18 19 20
    21 22 23 ]
 let prob.schoolending.hour [
    .0 .0 .0 .0 .0 .0
    .0 .0 .0 .0 .0
    .0 .0 .1 .7 .2
    .0 .0 .0 .0 .0
    .0 .0 .0 ]
  let prob.schoolending.hour.weekend [
    .0 .0 .0 .0 .0 .0
    .0 .0 .0 .0 .0
    .0 .0 .5 .5 .0
    .0 .0 .0 .0 .0
    .0 .0 .0]

;Peridos defined in interface. Used to define iteration in each day of poo
let school.ending time:create model.starting.at

  ;Calculate number of days bertween poo starting and ending for iterations
  ;+1 is required to starti counting from 1 and not from 0
  ;n-values creates lenght list of number of poo days with values =[0]
  let school.n.days n-values (time:difference-between (model.starting.at) (model.ending.at) "days") [0]

 foreach sort school.n.days [
    ifelse ("Saturday" = time:show school.ending "EEEE") xor ("Sunday" = time:show school.ending "EEEE")
    [foreach sort economic.points with [school.exist != "no"] [ the-economic.point ->
      let list.schoolending.event.aday (map list school.times.aday prob.school.times.aday.weekend)
      let num.schoolending.event.aday (first rnd:weighted-one-of-list list.schoolending.event.aday [ [p] -> last p ])
      let list.schoolending.event.hour (map list schoolending.hour prob.schoolending.hour.weekend)
      let many.schoolending.event.hours (map first rnd:weighted-n-of-list (num.schoolending.event.aday) list.schoolending.event.hour [ [p] -> last p ])

      foreach many.schoolending.event.hours [ hour ->
        ask the-economic.point [ time:schedule-event (economic.point who) [ [] -> go.schoolhomerelocation ] (time:plus (school.ending) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
    [foreach sort economic.points with [school.exist != "no"] [ the-economic.point ->
      let list.schoolending.event.aday (map list school.times.aday prob.school.times.aday)
      let num.schoolending.event.aday (first rnd:weighted-one-of-list list.schoolending.event.aday [ [p] -> last p ])
      let list.schoolending.event.hour (map list schoolending.hour prob.schoolending.hour)
      let many.schoolending.event.hours (map first rnd:weighted-n-of-list (num.schoolending.event.aday) list.schoolending.event.hour [ [p] -> last p ])

      foreach many.schoolending.event.hours [ hour ->
        ask the-economic.point [ time:schedule-event (economic.point who) [ [] -> go.schoolhomerelocation ] (time:plus (school.ending) (precision (hour + random-float 1) 2) "hour") ]]]
    ]
     set school.ending time:plus (school.ending) 1 "day"
    ]
end

to wwps.move.go

  ;to simulate the movement of WW particles along pipes
  ask wwps [
    ifelse travel_path = false or length travel_path = 0 [ die stop ][

      ;old code
      face first travel_path
      ifelse ( any? stations with [ distance first travel_path < 0.0001 ] ) [] [ set wwps_speed 6 ]  ;to set the speed of wwp based on if the node is a station or not
      ifelse distance first travel_path > wwps_speed [ fd wwps_speed ] [ move-to first travel_path set travel_path remove-item 0 travel_path ]


      ;new: Storing WWTP
      ifelse travel_path = false or length travel_path = 0 [
        ;set accumulated.wwps (accumulated.wwps + 1); count wwps reached WWTP
;        set dead.time time:show current-time "yyyy:MM:dd HH:mm"
;        file-open "results/calibration.snt/wwtp.snt.csv"
;        file-print (
;          word ;precision ticks 1","
;          ind.id","
;          time:show current-time "yyyy:MM:dd HH:mm" ","
;          time:show current-time "EEE"","
;          dw.type","
;          "wwtp"","
;          who
;          ;CVEGEO.reloc
;        )
;        file-close

      ] []
    ]
  ]

  ;For storing manholes tiemeseries
  ask wwps-on stations with
  [manhole.id.instation = 39 or
    manhole.id.instation = 258 or
    manhole.id.instation = 460] ;
   [set manhole.id.instation manhole.id.reporter.of stations-here

    if manhole.id.dymc.old != manhole.id.instation[
    file-open "results/calibration.snt/manholes.snt.cal1.csv"
        file-print (
          word ;precision ticks 1","
          ind.id","
          time:show current-time "yyyy:MM:dd HH:mm:ss" ","
          time:show current-time "EEE"","
          dw.type","
          manhole.id.instation","
          who","
        starting-seed","
        behaviorspace-run-number","
        behaviorspace-experiment-name
      )
      file-close]
    set manhole.id.dymc.old manhole.id.instation
      ]

end

to-report manhole.id.reporter.of [station.here]
  report [manhole.id.instation] of one-of stations-here
end

to wwps.move

  time:schedule-repeating-event-with-period wwps [ [] -> wwps.move.go ] (1 / 3600) 5 "second"

end

; ------------- Output Procedure -------------------------------------------------------------------------------------------------------------

;to plot.hatching.wwps
;  accumulated.wwps
;end

to go-until

  ;uncomen mobility to work when
  ;economic activities are available
  setup
  pee
  poo
  kitchensink
  shower
  washingmachine
  ;homeworkrelocation
  homeschoolrelocation
  ;workhomerelocation
  schoolhomerelocation
  wwps.move
  time:go-until model.ending.at

end
@#$#@#$#@
GRAPHICS-WINDOW
5
10
808
644
-1
-1
1.136
1
12
1
1
1
0
0
0
1
0
699
0
550
1
1
1
ticks
30.0

BUTTON
935
115
1001
148
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
830
115
895
148
NIL
go-until
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
830
305
1000
365
model.starting.at
2022-03-21 00:00
1
0
String (commands)

INPUTBOX
830
390
1000
450
model.ending.at
2022-03-24 00:00
1
0
String (commands)

MONITOR
830
595
1065
640
Current time
;current-time
2
1
11

TEXTBOX
1025
260
1175
278
Import SMS inhabitants
11
0.0
1

TEXTBOX
1025
120
1120
146
Start the simulation
11
0.0
1

TEXTBOX
830
10
1220
105
Modeling spatiotemporal \ndomestic wastewater variability: \nImplications to measure\nsanitation efficiency
19
0.0
1

BUTTON
935
160
1000
193
Off
ask inhabitants [hide-turtle]
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
830
160
895
193
On
ask inhabitants [ show-turtle ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1025
160
1095
191
Show or hide \ninhabitants:
11
0.0
1

CHOOSER
830
250
1000
295
sms.agent.csv
sms.agent.csv
"data/sms.agent.snt.csv"
0

INPUTBOX
830
465
1000
525
reproducible.seed
2.90809219E8
1
0
Number

BUTTON
830
205
895
238
On
ask households [ show-turtle ]
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
935
205
1000
238
Off
ask households [ hide-turtle ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1030
205
1105
235
Show or hide\nhouseholds:
11
0.0
1

TEXTBOX
1020
485
1155
503
Reproducibility of simulation
11
0.0
1

MONITOR
830
535
1002
580
DW particles reaching WWTP
;accumulated.wwps
17
1
11

TEXTBOX
1020
550
1120
568
Robustness test
11
0.0
1

TEXTBOX
1020
330
1170
348
Simulation starting time
11
0.0
1

TEXTBOX
1020
410
1170
428
Simulation ending time
11
0.0
1

TEXTBOX
1080
615
1230
633
Simulated time
11
0.0
1

@#$#@#$#@
## Results

This file belongs to the article journal:

**Modeling spatiotemporal domestic wastewater variability: 
Implications to measure sanitation efficiency**

*Refer to the Results section. 
See figure: 'Model results of domestic wastewater variability'.*

## WHAT IS IT?

This model simulates the generation of domestic wastewater (DW) by inhabitants using water appliances. Inhabitants are generated from the population and housing census 2020 (CPV2020, INEGI). Simulated DW particles are recorded in .txt files across different spatial scales (neighborhood blocks, manholes, and the targeted WWTP). It is also possible to analyze multiple temporal resolutions. Results are analyzed in an R script for plotting the spatiotemporal timeseries of DW pollutants in quality (mg/l) and quantity (l).

Check the R project of the locality from Mexico:

1) Santa Ana, Hidalgo, México: 		dw.sms.abm.snt.2020.Rproj

The objective is to propose a DW quantification and improve the understanding of DW spatiotemporal dynamics. The model reproducibility and replication aim to demonstrate a first step for the method scalability at many localities. 

## HOW IT WORKS

The model has three phases: 

1) Spatial microsimulation (SMS). Generates realistic inhabitants with individual information to define their behavior in the internal submodels of mobility and water appliance events to estimate DW production and characteristics. This data is provided in the sms.agent.csv file.

2) Agent-based modelling (ABM): This phase concerns the current dw.sms.abm.nlogo file. This script provides the dynamics and interactions of the inhabitants for producing the DW dynamics across time and space as follows:

  0 = "Inhabitants are located at their households..." 
  1 = "Inhabitants start generating DW based on water appliances usage..." 
  2 = "Mobility activates sending the respective inhabitants to school or work..." 
  3 = "DW generation continuous based on inhabitants schedules for water usage..."
  4 = "Inhabitants (students and workers) go back home ..." 
  5 = "DW particles travel from households to the treatment plant across the sewage..." 
  6 = "The wastewater treatment plant receives DW particles..." 
  7 = "Every DW particle is stored at multiple places with its timestamp..."
  8 = "The simulation continuous from the starting to ending time that was set considering 	week and weekend differences..."

DW particles move across the network following the flow direction provided from the high in each manhole until reaching the treatment plant. The moving speed of DW particles follows the Mexican norm with an average design speed (minimum and maximum flow speed allowed).

Water appliances usages is defined as probabilities of occurrence based on inhabitants' characteristics. For instance, the number of times an inhabitant defecates per day with random probabilities of defecation at specific hours.

3) DW timeseries analysis: The R script dw.abm.events.r is provided for analyzing simulated results as spatiotemporal DW timeseries dashboards. The script provides the post-processing results showing the spatiotemporal timeseries at different times and spatial resolutions targeting the DW characteristics. Also, a validation analysis defines the differences between observation and simulation.

## HOW TO USE IT

This model has the SMS file of the inhabitants loaded, and all data is provided. It is only required to press the bottom go-until. The model will run from the starting and ending date that is chosen. The procedures of water appliances can change the probabilities of water usage.

## THINGS TO NOTICE

Once the model stars, it cannot be stopped. The model records the outputs of the simulation in the results folder. The file names correspond to the water appliances, manholes, and WWTP.
The model has a defined seed to reproduce the research publication. To obtain different DW dynamics, adapt the random-seed function accordingly.

## NETLOGO FEATURES

Extensions used:

gis 	(loading data, setting coordinates, creating road network)
network (calculations based on road network)
bitmap 	(loading of legend image)
time 	(Managing temporal resolutions of the simulation)
rnd 	(scheduling inhabitants' appliances usage)

## CREDITS AND REFERENCES

Created by Néstor De la Paz Ruíz
PhD Student, Spatiotemporal Analytics maps and processing, ITC University of Twente.
Supervisors: 	Ellen-Wien Augustijn, Mahdi Farnaghi, ITC University of Twente
Promotor: 	Raúl Zurita Milla, ITC University of Twente
PhD program:	https://www.itc.nl/research/research-themes/stamp/
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

triangle_a
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Rectangle -2674135 true false 60 225 60 240
Rectangle -1 true false 120 135 135 225
Rectangle -1 true false 135 165 165 180
Rectangle -1 true false 165 135 180 225
Rectangle -1 true false 135 120 165 135

triangle_b
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Rectangle -2674135 true false 60 225 60 240
Rectangle -1 true false 120 120 135 225
Rectangle -1 true false 135 165 165 180
Rectangle -1 true false 135 120 165 135
Rectangle -1 true false 165 135 180 210
Rectangle -1 true false 135 210 165 225

triangle_c
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Rectangle -2674135 true false 60 225 60 240
Rectangle -1 true false 120 135 135 210
Rectangle -1 true false 120 120 180 135
Rectangle -1 true false 120 210 180 225

triangle_d
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Rectangle -2674135 true false 60 225 60 240
Rectangle -1 true false 120 120 135 225
Rectangle -1 true false 135 120 165 135
Rectangle -1 true false 135 210 165 225
Rectangle -1 true false 165 135 180 210

triangle_e
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Rectangle -2674135 true false 60 225 60 240
Rectangle -1 true false 120 135 135 210
Rectangle -1 true false 120 120 180 135
Rectangle -1 true false 120 210 180 225
Rectangle -1 true false 135 165 165 180

triangle_f
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Rectangle -2674135 true false 60 225 60 240
Rectangle -1 true false 120 135 135 225
Rectangle -1 true false 120 120 180 135
Rectangle -1 true false 135 165 165 180

triangle_g
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Rectangle -2674135 true false 60 225 60 240
Rectangle -1 true false 120 135 135 225
Rectangle -1 true false 120 120 180 135
Rectangle -1 true false 150 165 180 180
Rectangle -1 true false 135 210 180 225
Rectangle -1 true false 165 180 180 210

triangle_h
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Rectangle -2674135 true false 60 225 60 240
Rectangle -1 true false 120 120 135 225
Rectangle -1 true false 135 165 165 180
Rectangle -1 true false 165 120 180 225

triangle_i
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Rectangle -2674135 true false 60 225 60 240
Rectangle -1 true false 142 105 158 222
Rectangle -1 true false 135 105 165 120
Rectangle -1 true false 135 210 165 225

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="cal.val.1" repetitions="25" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go-until</go>
    <timeLimit steps="1"/>
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
@#$#@#$#@
1
@#$#@#$#@
