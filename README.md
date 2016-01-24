# OpenSimWorld NPC Controller

This is a full-featured controller for creating interactive NPCs, scripting them (through notecards) and creating waypoints of your region so that the NPCs can roam around. The controller is lightweight (a single script manages all the NPCs) and the NPCs are interactive (i.e. you can give them commands through the local chat).

You can get the latest OSWNPC package from the OpenSimWorld region in OSGrid, where you can also see them in action:

  hg.osgrid.org:80:OpenSimWorld

(move down near the bunker to find the package)

Please send questions and comments here: http://opensimworld.com/forum/viewtopic.php?id=2


# Installation

The controller requires OSSL functions to work. Apart from the osNpc*() functions you should also enable: osListenRegex(), osGetNotecard(), osMessageAttachments(), osSetSpeed().   The controller uses channel 68 for all its functions. 

Before you create an NPC, you need to add its name to the __npc_names notecard. Edit the __npc_names notecard, and add the *first* names of your NPCs, one at a line. The last name of your NPCs will always be (NPC). 

*After making any configuration changes in notecards,  reset the NPC controller scripts, or click on it and select "ReConfig"*.

To create an NPC, first wear the "Listener" object in your RIGHT PEC. The Listener is an object that all your NPCs must wear. It listens to the local chat for commands and sends them to the NPC controller for processing.  After wearing the listener, move within 20 meters  near the controller,  click on the controller, select SaveNPC and then the name of the NPC you wish to create.  You should see a message "Appearance saved to APP_xxxx" . This means your appearance has been saved in a notecard inside the controller. 
(Your NPCs can have multiple appearances - more on this later).

You can now load your NPC. Click the controller, click LoadNPC, then click the name of the NPC to load.  If all has gone well, your NPC should now respond to commands. Try "[name] come" or "[name] follow me"  to test it.  There are many commands you can use to have your NPCs do things.


# NPC supported commands 

The NPCs support a number of commands.  You  give these commands through the public chat when the NPC is near you.  The syntax is: 

   [npc-firstname] [command]

For example, assuming our NPC is called Bob: 
```
  Bob come
  Bob leave
  Bob follow me
  ...
  etc.
```
You can have the NPCs execute these commands whenever they reach a waypoint by creating a "scenario" notecard.   A scenario is just a list of commands, one per line, that is executed by the all NPCs whenever they reach that waypoint (Read the next section for waypoints).
 
For more complex behavior, the following control commands are supported in  notecards:  if, if-not, jump
 
Example of a notecard:
```
  if name-is Bob Alice
   say hi
   say I am either Bob or Alice
   jump @outofhere
  end-if
  say i am not bob or alice
  @outofhere
  if-not name-is Bob
    say I am definitely not Bob
  end-if
  say ... and i 'm now leaving
  leave
```

This example shows how to use if blocks, the jump command and how to create labels like @outofhere

As you see, in notecards, the name of the NPC is omitted. It is replaced with the name of the NPC automatically, for example when Bob runs this notecards "say hi" becomes "Bob say hi". 

In order to add a scenario to a waypoint, create a notecard with the name format:  "_"+[waypoint-number]+".scr" and drop it in the controller object.
 
For example the "_10.scr" notecard will be executed at waypoint #10, "_11.scr" at waypoint #11 and so on. Waypoints start at #0. You can find the waypoint number on top of the pegs when editing waypoints (Read below).


# List of NPC commands

These commands must be preceded by the name of the NPC. Here we assume our NPC is called "Bob"
```
  Bob come         = "Come here ". Bob will come move close to you

  Bob moveto 23      : walk towards  waypoint #23

  Bob movetov <23,24,25>  :  walk towards point with coordinates <23,24,25> 

  Bob flytov <23,24,25>  :  fly towards point <23,24,25> in region
  
  Bob movetovr <23,24,25>  <33,34,25>   : walk to a random point between the points   <23,24,25>  <33,34,25>  
  
  Bob runtovr <23,24,25>  <33,34,25>  : same as above, but run

  ** Note: never leave spaces in coordinate vectors, i.e. <23,24,25> NOT <23, 24, 25> **
```

## Sit commands

The NPC can sit on objects. The way it works is as follows:
```
Bob use chair         
```
Bob will attempt to find an object named "chair" (Object Name) near him and try to sit on it if its transparency (alpha) is less than 100%. Since by convention poseballs turn transparent when users sit on them, this ensures that Bob will not sit on an already-occupied poseball.

```
Bob stand             : Bob will stand up if he is sitting
```
## Variables
Variables can be used with IF commands for more complex scenarios. Variables are global and can be shared between notecards and NPCs. 
```
Bob setvar foo 13                : set variable foo to be "13". Only string variables are supported. Variables can be used with IF blocks
Bob setvar foo                   :  set variable foo to the empty string. The empty string is the default value if a variable does not exist
Bob say $foo        : Bob says "13"
```

## Flow control with IF commands
There is support for multiple levels of IF blocks. blocks end with "end-if". There is no "else" command, but you can achieve the same effect with "jump" commands

```
if name-is bob alice            : if the npc's name is Bob or alice
   use dance                    : Sit on the poseball  named "dance" (if the poseball is not transparent)
end-if                          : always end IF blocks with end-if.  You  can nest if blocks

if-not name-is Bob              : Example of negative if

if-prob 0.3                     : IF block will be executed with probabilty 0.3 (the if block will be executed 30% of the time)

if var-is party 1               : Will execute the IF block if the variable party is "1"

if var-is party               : Will execute the IF block if the variable party is empty ("")
```

Jump command.  You can use the syntax @label to create labels in your notecards. The syntax is:
```
jump myLabel   :  like "jump" in LSL or "goto" in other languages. the label should be on a line by itself prefixed with '@' 
@myLabel       : a label
```

## Useful script commands
```
wait 200           : wait 200 seconds

wait 200  300      : wait between 200 and 300 second before executing the next command

waitvar foo 13     : wait until the variable foo gets the value 13

waitvar foo        : wait until the variable foo is empty.
```


## Pathfinding commands

The NPCs can find the paths between waypoints and walk from point A to point B. Because this is computationally intensive, only paths with less than 10 waypoints between are supported. The following pathfinding commands are supported:

```
Bob go to Bar   : this uses pathfinding  to go to the waypoint with the name "Bar"
Bob go to       : without  an argument, bob will print the names of waypoints he knows
Bob goto 13     : go to waypoint #13 
```

## Other commands
```
Bob say hi                            : Says "hi" on public channel 
Bob saych 90 blablah                  : say "blablah" on channel 90
Bob teleport Bar                      : Teleports bob to the "Bar" waypoint
```
```
Bob msgatt  attachment_command 12 13 14 15  
```
Uses osMessageAttachements to send the message "attachment_command" to attachments at attach points 12 13 14 15. 
This can be useful for scripting NPC attachments. Read the OSSL docs of osMessageAttachments() for more. 

```
Bob lookat me            : attempts to look at you 

Bob lookat <x,y,z>       : look towards point x,y,z

Bob lookat Bar           : look towards the waypoint named "Bar"

Bob anim dance           : play animation "dance" . the animation must be in the inventory of the controller object

Bob light                :  turn on/off a light the NPCs have on them

Bob follow me            : self-explanatory

Bob follow  Alice        : follow alice around. Only the first name of the other avatar is needed

Bob fly with me         : self-explanatory 

Bob fly with alice      : fly with another user

Bob stop                :  Stops his animation and his movement.  and stops following you

Bob leave               : start wandering  between waypoints

Bob run-notecard my_script.scr     : execute the contents of the notecard my_script.scr (the notecard must be in the controller inventory

Bob stop-script         :  stop executing the notecard script

Bob batch say hi ; wait 10; say bye  : executes multiple commands , separated by ";"

Bob dress  swimming     : load the appearance from notecard "APP_bob_swimming"

Bob dress               : load the appearance from notecard "APP_bob" (The default appearance notecard)
```
You can have multiple appearance notecards per NPC, just rename their appearance notecard from "APP_bob" to "APP_bob_your-name" 


## Extras

The controller checks the number of visitors in your region every 2 minutes. If there are no visitors in the region it will stop executing commands thus avoiding unnecessary load to the region. In addition, it keeps track of the  latest visitors, giving you a log:

```
Bob seen all    : will print everyone who visited
Bob seen foo    : will print information about foo
```


# Creating waypoints

You can use the controller to create paths within your region, and the NPCs can wander along those paths. In addition, you can have them do interesting actions whenever they reach specific points by creating "scenario" notecards. 

Each waypoint has a number (starting from 0) and optionally a name. Waypoints can be connected to other waypoints, thus creating a map (graph) between them. The NPC can then wander between the waypoints (Use "Bob leave" to make them start wandering), and they can also go from waypoint A to waypoint B (if there are appropriate links between the two).

To create a map, wear the WaypointEditor HUD. The HUD works by rezzing a number of "traffic cone" pegs around your region, which represent the waypoints that your NPCs follow. You can use the HUD to edit those points and create links between them. 

If you already have a map, click RezPegs on the HUD. This will rez  a peg in each waypoint.  If you are starting with an empty map, you do not need to do this

To add a waypoint, move your avatar to the desired position, and select "AddPeg" from the HUD. A peg should appear in front of you. To create a second waypoint, move to another position, and  AddPeg again. 

To link two waypoints, click on the first one, then click on the second one and select "LinkPegs" from the popup. 

To unlink two waypoints, click on the first one, then click on the second one and select "UninkPegs" from the popup. 

To set a name for a waypoint, click the peg, select "SetName", and enter the name (E.g. "Bar")

You can make adjustments by moving the waypoints. *Be careful, after you move a peg, you MUST select "ScanPegs" from the HUD or your changes will not be saved be lost.*

To save the changes in the controller, click the HUD and select "SaveCards".  To test if all went well, clear the pegs and rez them again. 

After creating the map, it is possible to have the NPCs walk to specific waypoints. For example, if you have a waypoint named "Bar" , you can ask an NPC to go there (but only if it is up to 10 hops away), like this: "Bob go to Bar"

## Extensions

You can add extra commands with extension scripts.  Extensions are scripts that are placed in the  controller. Commands that are not processed by the NPC controller are sent via link_message to the extensions for processing. The extensions can then send back commands to the NPC controller. The default NPC controller object already contains an extension that implements the "help" command (the "..Extension" script). The script in it shows how extensions parse the data sent from the controller (through link_message)  and how they can respond.

In addition, you can use your own scripts to send commands directly to the NPC controller from any object. The NPC controller listens at channel 68.
The format of the command is:
```
! 0000 UUUU Bob say hi
```
i.e. you  prefix the command that you would normally give to the NPC through the chat by prefixing it with "! 0000 UUUU " and sending it to channel 68. For commands such as "Bob follow me" "0000" can must be replaced with the  uuid if the avatar giving the command. 


# Technical Notes

The controller runs through a single timer, that updates the states of the NPCs every 5 seconds. This allows it to be extremely lightweight, as it does not block processing, but also causes small delays expected between commands. 
