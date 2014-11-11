active-npcs
============

A framework for managing interactive NPC avatars in opensimulator

This framework allows the management of a set of NPC avatars from a single controller object. 

Some features of this package:

- Allows you to talk to your NPCs through the normal chat and ask them to do tasks
- Has its own scripting language that allows you to run series of commands through a notecard
- Uses conventions to avoid scripting for animations, for example, to sit on a "float" poseball, all you need to do is say  "do float"  to your NPC
- Your NPCs can follow you or other avatars or fly with them
- Automatically calculates walk times, so you dont have to 
- Allows the creation of a region map with waypoints and links 
- Your NPCs know how to get from a to b in the map (requires external web server for pathfinding). 
- The provided clothes listener script allows you to hide/show their clothes efficiently, thus allows you to change their appearance without reloading the appearance notecard
- The scripting language allows complex flow control through "if", "jump" and the counter variable "var1"
- Only a single timer is used for all the NPCS, thus drastically reducing load times even for large numbers of NPCs.


Example of commands  that the NPCs  (named "Foo") can perform:
  
    Foo follow me
    Foo follow <other avatar's or other NPCs first name>
    Foo fly with me
    Foo do <poseball-name>
    Foo go to Theater (find the path to the theater with the shortest number of hops and goes there)
    Foo sit  (sits on a nearby MLP poseball)
    Foo leave (starts wandering aimlessly around your region's waypoints)

Example contents of a notecard with a script:
  
    if-not name-is Foo  (We only want the NPC named Foo to run this)
    jump endOfScript
    endif
    moveto 5  (walk to waypoint #5)
    do float  (Sit on the poseball named float)
    wait 20  (wait approximately 20 seconds while still sitting)
    stand up
    movetov <230,10,22> ( walk to a specific point (vector) in your region)
    Go to theater (follow the shortest path that leads to the waypoint named "Theater")
    say blah (Say "blah" on the public channel)
    dance (start playing dance animations)
    wait 50 (keep dancing for 50 seconds)
    stop (stop playing animations and stand up - useful for resetting your NPC)
    drop shirt (hide the shirt)
    wear jacket (show the jacket)
    var1 zero (Set counter variable var1 to zero)
    @looplabel (defines a label to be used below)
    go to house
    go to theater
    var1 ++ (increment the var1 counter)
    if var1-lt 3  (Execute the loop 3 times)
    jump looplabel
    end-if
    go to Bar
    @endOfScipt (another label)
    leave (The NPC will start wandering between waypoints again)

Such notecard scripts can be executed automatically whenever your NPCs reach a waypoint.

ActiveNPCs are designed to be interactive, i.e. they can take commands from the public chat (if they are nearby) and perform actions. These commands can be entered in notecards which in combination with flow control functions allows complex behaviors.

The system is based on a number of conventions commonly used in open worlds. It also uses heavily opensim-specific features such as osListenRegex and osMessageAttachment which allow it to run fast with very little lag and minimal resource consumption. 

Overview of setup:
- Drop the controller script in a controller object. Edit the script and  change the "availableNames" list to contain the names that you want your NPCs to have.
- Create a notecard named "waypoints" which defines the waypoints of your region (optional but you 'll miss half the fun without it). Drop the notecard in the controller object.
-- Each line in the notecard is of the form "x,y,z,name-of-waypoint"
- Create a notecard named "links" that defines which waypoints are connected to each other
-- Each line in this notecard is of the form p1,p2, where p1 and p2 are the line numbers of the waypoints in the "waypoints" notecard. Drop this notecard in the controller object.

For example for a region with 4 waypoints named "house", "gym", "bar" and "theater" the "waypoints" notecard would be 

    30,20,22,House
    40,30,22,Gym
    40,60,22,Bar
    80,90,22,Theater

The "links" notecard would contain something like this:

    0,1
    0,2
    2,3

which means that the house is connected with the gym and bar, and the bar is connected to the theater (all connections are reciprocal)

After editing the list of waypoints or links, click on the controller object and select "ReloadMap" to reload the changed waypoint data.

- If you want your NPCs to be able to interpolate between the points , you have to use an external web server, since LSL is too slow for this (we provide a simplistic interpolation function in the code but it's not used and gets unusably slow for paths that have more than 10 hops). This way, your NPCs can follow commands such as "go to Theater" , which will take them to the theater using the least possible number of hops between waypoints. 

We provide a set of 2 php scripts (index.php, sql.inc.php) and a database schema (schema.sql) that can be used with an external LAMP web server to perform the pathfinding. Upload the scripts to your web server, and edit the database settings. Use the "schema.sql" to create the database. Important: you need to insert a record in the 'city_keys' table for your region amd set the 'ckey' field to something secret. This key must also be the same used in the  BASEURL variable of your controller , which you must also change to point to the URL of your web server.


- To create an NPC, first create a transparent listener object, add the 'listener.lsl' script to it and wear it on your LEFT PEC. This is the listener that listens on the public channels for the npc's name. For example if your NPC is  named "Foo", the NPC will capture all messages that begin with "Foo " such as "Foo go to theater" will ask the controller to handle them. 

- If you want to hide/show clothes, add the 'clotheslistener.lsl' script to your clothes. You will have to customize the "wear"/ drop commands on the listener script to tailor to your needs

Remember that if you edit any of your attachments, you need to detach and reattach them before saving your appearance. This is a requirement for  opensimulator NPCs to work.. 

- When your appearance is ready, click on the controller object, select SaveAvi and choose which NPC's appearance you want to save. 
- You can now load your NPC by clicking on the controller-> LoadAvi-> select your NPC's name. Issue some commands to your npc to make sure it works, e.g. "Foo come here" "Foo say something" "Foo follow me"

- If you want the NPCs to sit on poseballs use the provided "poseball.lsl" script. The convention is that the poseball's name defines the command. E.g. if your poseball object is named "float", then you can say "Foo do float" to make the NPC sit on it. ("Foo stand up" gets the npc back up)

You can easily add your own commands  by extending the "ProcessNPCCommand function in the controller script.

ActiveNPCs was developed for opensim version 0.8.0.1 . Do not expect it to run in older versions.


Have Fun!
