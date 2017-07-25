# ActiveNPCs NPC Controller

This is a full-featured controller for creating interactive NPCs , scripting them (through notecards) and creating waypoints of your region so that the NPCs can walk around your region. The controller is extremely lightweight (a single script manages all the NPCs) and the NPCs are interactive (i.e. you can give them commands through the local chat).

You can get the latest  package from the OpenSimWorld region in Metropolis, where you can also see them in action:

http://opensimworld.com/hop/74730-OpenSimWorld

Hypergrid: hypergrid.org:8002:OpenSimWorld

(You have to  move down near the bunker to find the package)

Visit https://github.com/opensimworld/active-npcs/edit/master/README.md for an up-to-date version of this documentation.


# Quickstart

The controller requires OSSL functions to work. You need to have permission to use the osNpc*() functions and, additionally: , osGetNotecard(), osGetNotecardLines(), osMessageAttachments(), osSetSpeed(). The controller uses the channel 68 to communicate. 

To start using the controller:
- Rez the OSW NPC Controller object somewhere in your region. Make sure your avatar is within distance of 20m or less from the controller
- Wear the OSW NPC Listener object (it should attach automatically to your Right Pec!)
- Edit the `__npc_names` notecard, and place first name and last names of each of your NPCs in a line by itself. Example:
```
Bob TheRobot
Alice TheNPC
```
- Touch the controller ->  ReConfig
- Touch the controller,  SaveNPC -> Bob (You should see a message "Saved appearance xxx-xxx -> APP_bob"
- Touch the controller -> LoadNPC -> Bob

Your npc should now be responding to commands , e.g. "Bob come"


# Controller object Contents

* The controller script (..Controller). This is the single script that runs everything.
* An example extension script (..Extension). This can be used to add commands to the system (explained below).
* The Listener object. All our NPCs must wear this invisible object on their Right Pec. This object listens for commands from the local chat and forwards them to the controller script for processing.
* The __npc_names notecard. This notecard contains the  names of the NPCs, one in each line . After making changes to this notecard, select "Reconfig" from the controller menu.
* The __initcommands notecard. This is a notecard with the commands that are executed when you click  "InitCmds" on the controller menu.
* The __waypoints notecard. This contains a list of points in your region. The NPCs can walk from one point to the other, if they are connected (via the __links notecard) . *You do not need to edit this by hand. There is an HUD for editing the map*
* The __links notecard. This contains a list of pairs of connected points. I.e. if you want to link point 1 to point 2, there will be a line "1,2" in the notecard. *You do not need to edit this by hand. There is an HUD for editing the map*
* The __config notecard. This contains configuration ootions.
* Command notecards. You can put any list of commands for NPCs a notecard named [command-name].scr. You can then order your NPCs to execute the notecards from the local chat. E.g. if you create a notecard "dance.scr", you can say "Bob dance" to execute it.
* Waypoint notecards. Notecards named _1.scr , _2.scr etc are executed automatically when the NPCs reach the waypoint number 1, number 2 etc. 
* The appearance notecards are stored as APP_[firstname] for each NPC. You can also have multiple appearances per NPC (see below). 
* The Waypoint HUD is used to edit the map and create/update the __waypoints and __links notecards

# Overview of commands

The NPCs respond to commands that you give to them through the local chat. 

Assuming your NPC is named "Bob", you can say the following in the local chat:
```
  Bob come
  Bob leave
  Bob stop
  Bob follow me
  Bob fly with me
  Bob say hi
  ...
  etc.
```
You can put these commands in notecards in order to create complex scenarios. 

For more complex behavior, the following control commands are supported in  notecards:  if, if-not, jump
 
Example of a scenario notecard:
```
  if name-is Bob Alice
   say hi
   say I am either Bob or Alice
   jump outofhere
  end-if
  say i am not bob or alice
  @outofhere
  if-not name-is Bob
    say I am definitely not Bob
  end-if
  say ... and i 'm now leaving
  leave
```
You can add these commands to a notecard named "test.scr" inside the controller object, and then ask the Bob to execute them by saying "Bob test" in the local chat.


# List of NPC commands

When giving commands through the local chat, commands must be preceded by the first name of the NPC. Here we assume our NPC is called "Bob"
```
  Bob come           : "Come here ". Bob will  move close to you

  Bob moveto 23      :  Walk towards  waypoint #23

  Bob movetov <23,24,25>  :  walk towards point with coordinates <23,24,25> (Note, no spaces between vector coordinates)
  
  Bob runtov <23,24,25>  :  run towards point with coordinates <23,24,25> 

  Bob flytov <23,24,25>  :  fly towards point <23,24,25> in region
  
  Bob movetovr <23,24,25>  <33,34,25>   : walk to a random point between the points   <23,24,25>  <33,34,25>  
  
  Bob runtovr <23,24,25>  <33,34,25>  : same as above, but run

```
* * Note: never leave spaces in coordinate vectors, i.e. <23,24,25> NOT <23, 24, 25> **

```
Bob say hi                            : Says "hi" on public channel 

Bob saych 90 blablah                  : say "blablah" on channel 90

Bob shout Blah bleh

Bob teleport <23,30,40>                     : Teleports to a point. REMEMBER: no spaces inside the vector brackets

Bob lookat me            : attempts to look at you 

Bob lookat <x,y,z>       : look towards point x,y,z


Bob anim dance           : play animation "dance" . the animation must be in the inventory of the controller object

Bob sound 1c8a3af2-6e5a-4807-a7a3-a42e5744217c 1.0   : The NPC will trigger the sound with the given UUID  at the volume specified by the second parameter (1.0 is max volume)

Bob light               :  turn on/off a light the NPCs have on them

Bob give Apple      : Give the object "Apple" from the controller's inventory to the user. For security, only Objects can be given.

Bob follow me

Bob follow  Alice       : follow the avatar whose first name is 'Alice'

Bob fly with me

Bob fly with alice      : fly with another user

Bob stop                : Stops his animation and his movement, and stops following you
```

### Waypoint and Pathfinding commands
You need to have set up the map of your region for these commands. That is described elsewhere. The NPC can automatically try to find how to walk from waypoint A to  B. Because this is computationally intensive, only paths with less than 15 connections between them are supported. 

```
Bob leave               : Start walking randomly between connected waypoints

Bob teleport Bar        : Teleports bob to the waypoint named "Bar"

Bob lookat Bar           : look towards the waypoint named "Bar"

Bob moveto  1         : Walk to waypoint #1

Bob nearest           : Tell me which is the nearest waypoint

Bob setpath 0:1:3:5:1:0            : Walk through the given waypoints, i.e. walk to waypoint 0 , then to 1, then to 3, then to 5 etc. 

Bob goto 13     : Will walk between connected waypoints to waypoint #13 

Bob go to Bar   :  Will walk between connected waypoints to the waypoint named "Bar"

Bob go to       : without  a destination, Bob will print the names of waypoints he knows

```

### Batch command Notecards 
Multiple commands can be appended to a notecard, and then the NPC can execute them.

```
Bob run-notecard my_script.scr     : Execute the contents of the notecard my_script.scr (the notecard must be in the controller inventory

Bob my_script       : Simpler syntax. Same as run-notecard: Starts executing the notecard "my_script.scr" 

Bob batch say hi ; wait 10; say bye     : Executes multiple commands one after the other. Commands are separated by ";" The commands will be executed as if they were in a notecard

Bob stop-script     : Stop executing the notecard script

```


### Multiple appearances 

You can have multiple appearance notecards for an NPC by renaming them. The default notecard for NPC Bob is stored in the APP_bob notecard. You can rename the notecard to, e.g.  APP_bob_swimming, and then ask bob to load that notecard:

```
Bob dress  swimming     : load the appearance from notecard "APP_bob_swimming"

Bob dress               : load the NPC's default appearance from notecard "APP_bob" 
```


## Sitting on objects

The NPCs can sit on objects with the  "use" command. 
```
Bob use chair         
```
Bob will attempt to find a SCRIPTED object (e.g. a poseball) named "chair" (You can change the Object Name from the properties box when editing it) near him and try to sit on it if its transparency (alpha) is less than 100%. Since by convention poseballs change their transparency to 100% when users sit on them, this ensures that Bob will not sit on an already-occupied poseball. If you just say "Bob use", the NPC will sit on the nearest scripted object.

```
Bob stand             : Bob will stand up if he is sitting
```


## Variables
Variables can be used with IF commands in notecards for more complex behavior.Variables are global and shared between notecards and NPCs. 
```
Bob setvar foo 13                : set variable foo to be "13". Only string variables are supported. Variables can be used with IF blocks

Bob setvar foo                   :  set variable foo to the empty string. (The empty string is the default value if a variable does not exist)

Bob say $foo        : Bob says "13"

if var-is foo 13
   say foo is thirteen
end-if
if var-is foo 
   say foo is empty string or not set 
end-if

waitvar foo 13    : wait (and do nothing) until the variable foo becomes 13
```

The following commands increase and decrease a variable by 1. They are useful in cases where you want 2 or more avatars to be present to proceed:
```
increase totalAvatarsHere  : Increase the variable "totalAvatarsHere" by 1

decrease totalAvatarsHere  : Decrease the variable "totalAvatarsHere" by 1

zero totalAvatarsHere   : Set variable totalAvatarsHere to 0 (same as setvar totalAvatarsHere 0)
```
Example usage in a notecard:
```
increase totalAvatarsHere
waitvar totalAvatasHere 2
 say Now there are 2 of us
 anim dance
 wait 10
 stop
 ...
 say Time to depart
decrease totalAvatarsHere
```


## IF commands
There is support for multiple levels of IF blocks. Blocks must end with "end-if". There is no "else" command, but you can achieve the same effect with "jump" commands

```
if name-is bob alice            : if the npc's name is Bob or alice
      say I am either Bob or Alice
      if-not name-is Bob
        say I must be Alice
      end-if
end-if                          : always end IF blocks with end-if.  You  can nest if blocks

if-not name-is Bob              : Example of negative if
  say I am not Bob
end-if
  
if-prob 0.3                     : IF block will be executed with probabilty 0.3 (the if block will be executed 30% of the time)
  say This will be heard 30% of the times
end-if

if var-is party 1               : Will execute the IF block if the variable party is "1"
  say We are having a party already!
end-if

if var-is party               : Will execute the IF block if the variable party is empty or not set
  say No party yet, let's start one!
  setvar party 1
end-if
```

Jump command.  You can use the syntax @label to create labels in your notecards. The syntax is:
```
@myLabel       : a label
  say This will loop forever
jump myLabel   :  like "jump" in LSL or "goto" in other languages. the label should be on a line by itself prefixed with '@' 

```


## WAIT commands
```
wait 200           : wait (don't do anything) for 200 seconds

wait 200  300      : wait between 200 and 300 second before executing the next command

waitvar foo 13     : wait until the variable foo gets the value 13

waitvar foo        : wait until the variable foo is empty.

```


## Other commands

```
Bob msgatt  attachment_command 12 13 14 15  
```
Uses osMessageAttachments to send the message "attachment_command" to attachments at attach points 12 13 14 15. 
This can be useful for scripting NPC attachments. Read the OSSL docs of osMessageAttachments() for more. 


## Custom command notecards

You can extend the list of commands with  notecards. To create a command notecard, enter the commands for the NPC to execute in a notecard, and save it into the controller's inventory with the name [command-name].scr

E.g. a dance command notecard would be named "dance.scr" and contain the following
```
say I love to dance!
anim RockDance
wait 600 800
say oops, I am  tired...
stop
```
You can then say "Bob dance" to have bob execute the notecard


# Interactive menus

With interactive menus, your NPCs can ask your visitors to make a choice from a menu in the local chat. The following notecard asks the user if they want apple or an orange and gives an object to them:

```
say Welcome to the shop!
@prompt
  prompt Do you want an [apple] or an [orange]?
  say I didn't catch that. Starting over.
  jump prompt
@apple
  say Here is an apple
  give Apple
  jump end
@orange
  say Here is your orange
  give Orange
  jump end
@end
say Goodbye
```

Here is how it works:
- The options of the menu are specified in the prompt string itself, in square brackets:
```
prompt Do you want an [apple] or an [orange]?
```
- Bob will say "Do you want an [apple] or an [orange]?" to the local chat, and it will expect to read the words "apple" or "orange" in the local chat from your visitor. 
- If he hears "apple", he will jump to the label "@apple" in the notecard. 
- If he hears "orange", he will jump to label "@orange" in the notecard. 
- If he hears something else, he will not jump, but continue normally to the next notecard line  after the "prompt" line. (In our case, he asks again).
- The menu options can only be single words (e.g. "orange", or "apple"). They are case-insensitive, and the menu will work even if the word is said in a phrase (I.e. "I want an apple" will still jump to @apple) 




# Waypoints and Pathfinding

You can use the controller to create waypoints and links between them in your region. Bob can then walk between the connected points when you say 'Bob leave'

Each waypoint has a number (starting from 0) and optionally a name. Waypoints can be connected to other waypoints, thus creating a map (graph) between them. Bob can then wander between the waypoints (Say "Bob leave" to start walking), and you can also ask him to find his way from point A to point B (say Bob go to [destination]).

The waypoint data are stored in the __waypoints notecard, one in each line, and the links data is stored in the __links notecard. You do not need to edit these notecards by hand however, as you can use the included Waypoint Editor HUD.

To create a map, first wear the WaypointEditor HUD.  If you already have created a map before, click RezPegs from the HUD menu. This will rez  a peg in each waypoint you have already created.  If you are starting with an empty map, you do not need to do this.

To add a waypoint, move your avatar to the desired position, and select "AddPeg" from the HUD menu. A peg should appear in front of you. To create a second waypoint, move to another position, and repeat. 

To link the two waypoints X and Y, click on the first one (X), then click on the second one (Y). The pop up dialog should say "Current peg: Y, previous: X". To link them, select "LinkPegs" from the popup dialog. To unlink two waypoints, again, click on the first one, then click on the second one and select "UnlinkPegs" from the popup. Be careful to disregard all other dialogs that have popped up.

You can give a name to waypoints. Click the peg, select "SetName", and enter the name (E.g. "Bar"). You can use this name to give commands to your NPCs later (e.g. "Bob go to bar").

You can move the waypoints around to correct their positions. Important: After you move pegs to new positions click "ScanPegs" from the editor HUD. If you don't do this your changes will be lost.

After you have created/edited your waypoints, click the WaypointEditor HUD and select "SaveCards". This will update/create the __waypoints and the __links notecards inside the controller to match your new map.  To test that all went well, clear the pegs and rez them again. 

Note! Removing waypoints is not supported, as it would break the numbering and would mess up the notecard naming scheme. Although deleting is not supported, you can unlink a waypoint from all other waypoints, in which case the NPCs will never go there when wandering. If you want to start over with an empty map, edit the __waypoints and __links notecards, remove all their contents, and then select "Reconflg" from the controller. 


## Configuration
Configurable options for the controller are added in the __config  notecard:
```
AutoLoadOnReset=0
```
Change AutoLoadOnReset=0 to AutoLoadOnReset=1 to make the controller rez the NPCs automatically on region restart or script reset. Please note that autoloading NPCs may not always work well with some opensim versions.



## Permissions

Permissions allow you to limit access to NPCs ,  and to specific commands to certain users or to all users. An access control list is specified in the __permissions notecard which is inside the controller object.

Each line in the __permissions notecard has the format 
```
<npc-name> <command-name> = <RULE> <avatar name>
```
Where RULE is ALLOW, DENY, ALLOWID, DENYID or ALLOWSAMEGROUP (read below for usage). 

The following line blocks (denies) avatar  "Bad Hombre"  from issuing the "bob come" command:
```
bob come = DENY Bad Hombre
```
You can substitute the name of the NPC or the name of the command or the name of the avatar with the wildcard  character '*'. 
for example, this blocks any the avatar from using the command:
```
bob come = DENY *
```
you can block any avatar from issuing the "come" command with any NPC:
```
* come = DENY *
```
you can block any avatar from issuing any command command with Bob:
```
Bob * = DENY *
```
you can block a specific avatar from using any command on any npc:
```
* * = DENY Bad Hombre
```
you can also use the DENYID command to block an avatar by UUID
```
* * = DENYID d37a3f5b-562a-4bfd-b780-68c0b9b940b1
```
and you can block any avatar from using any command with any NPC DENYID command to block an avatar by UUID
```
* * = DENYID d37a3f5b-562a-4bfd-b780-68c0b9b940b1
```
The rules specified in the notecard are executed from top to bottom, therefore you can add exceptions for specific users with the ALLOW and ALLOWID commands at the end of the list:
```
* come = ALLOW Good User
* come = ALLOWID d37a3f5b-562a-4bfd-b780-68c0b9b940b1
```
You can also use the keyword ALLOWSAMEGROUP, which allows any avatar that is in the same group as the controller object.
```
* come = ALLOWSAMEGROUP
```
You  can use the wildcard '*'  with the ALLOW commands as well
```
Bob come = ALLOW *
* come = ALLOW * 
Bob * = ALLOW *
```

An example __permissions notecard is given below which blocks any avatar from controlling the NPC "Alice" and disallows the "exec" command, but allows exceptions to certain users. It also Blocks "evil user" from any command: 
```
Alice * = DENY *
* exec = DENY *
Alice * = ALLOW Good User
Alice * = ALLOWSAMEGROUP
* exec = ALLOW Good User
* exec = Allow Another Gooduser
* * = DENY Evil User
```

Note that the ALLOW, DENY, ALLOWID etc. rules need to be in CAPITALS. Also, There must always be a space before and after the '='  character.  

The owner of the controller is always able to use all commands with all NPCs. 

## Initialization commands
The notecard __initcommands contains initial commands to give to the NPCs. If AutoLoadOnReset is enabled, the notecard contents are executed automatically after loading. You can also manually execute the notecard by clicking "InitCmds" from the controller menu.  You can use  the __initcommands  to add any command that sets your NPCs in motion. Typically you would tell them to "leave" so that they start  walking between waypoints. An example of __initcommands is : 

```
Bob say I am rezzed!
Bob teleport <64,64,22>
Alice  teleport <128,64,22>
Bob leave
Alice leave  : Start walking!
```


## Extension scripts

You can extend the functionality of the controller with extension scripts.  Extensions are LSL scripts that you create and add  inside the controller object.  If a command given to an NPCs is not understood by the NPC controller, the NPC controller will send a  link_message to the extension scripts to process it. The extensions can also use link_message to send back commands to the NPC controller (the  "number" parameter must be greater than 0) . The OSW NPC Controller object already contains an extension that implements the "help" command (look at the "..Extension" script). The script in it shows how extensions parse the data sent from the controller (sent through link_message)  and how they can respond back.

The number parameter of the link_message is -1 if it comes from the controller script. The key parameter of the link_message is the UUID of the NPC. The string parameter of the link_message (or through channel 68) is of the format:
```
! [uuid]  Bob Bob help
```
Where:
- [uuid] is the UUID of the user who gave the command
- Bob is the name of the NPC. The name is repeated once again.
- What follows is the rest of the command that the NPC heard (e.g. "help")

You can easily split the string with llParseString2List. Look into the ..Extension script for an example. 

## Sending commands from other objects

You can send commands directly to the NPC controller from any object. The NPC controller listens on channel 68. You have to remember to send the command using llRegionSay region-wide, so that the controller can hear it.
The syntax is the same as the one used in link_message:
```
llRegionSay(68, "! 0000-0000-0000-0000  Bob Bob say hello");
```
The UUID can be zero, and the name of the NPC must be repeated twice, as shown above
* ONLY scripts owned by the owner of the controller can send commands this way * 


## Setting controller variables from other objects

Another way to interact with the controller is by setting variables from other objects by sending SETVAR [variable name] [value] from other objects to channel 68. This is the syntax:
```
llRegionSay(68,  "SETVAR foo 1");
```
(SETVAR must be in capitals. This example will set the variable "foo" to "1"). 

The variables can be used normally in notecards. In this example notecard, the NPC will waits for the variable "foo" to become '1' before starting to dance:
```
@start
say Waiting for variable foo to become 1...
waitvar foo 1
say Variable foo is now 1! Let's dance!
anim dance1
wait 10
stop
setvar foo 0        : Reset var foo to 0 before waiting again
jump start
```

# Technical Notes

The controller runs a single timer, that updates the states of all the NPCs every 5 seconds. This allows it to be extremely lightweight, as it does not block any script processing, but it may also cause delays when executing commands. 

The controller checks the number of visitors in your region every 2 minutes. If there are no visitors in the region for 2 minutes, it will stop executing commands to avoid creating unnecessary load to the region. 

# Bugs 

The controller was tested with version 0.8.2.1 . There may be multiple issues with other versions. Please add an issue, or get in touch with Satyr Aeon @ hypergrid.org:8002

