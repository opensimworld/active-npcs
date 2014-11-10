// The listener script listens on channel 0 for messages directed to this NPC. 
// It uses osListenRegex to filter the commands referring to its name only. 
// It also listens for "hello" and "hi" so it can greet strangers with a help message
// The listener doesnt actually execute any commands, it relays them to the controller
// The listener is also used to llSensor() for nearby poseballs

// Drop this on an invisible attachment and wear it anywhere on your NPCs. Dont use it as an HUD, 
// since it needs to llSensor and listen for nearby chat

string chatKey = "";
string NPCNAME="INVALID";
key npc = NULL_KEY;
integer gListener=-1;
integer zListener=-1;
integer aviNameLength;
string status = "";
integer lightOn = 0;
list talkedUids;
string lastAnim="";



default
{
    state_entry ()
    {   


    }
    
    attach( key id ) {
        if (id)
        {
            string name= llKey2Name(llGetOwner());
            NPCNAME = llGetSubString(name, 0, llSubStringIndex(name, " ") - 1);
    
            zListener = osListenRegex(0, "", "", "^(?i)(hi|hello|"+NPCNAME+" )(?-i)", OS_LISTEN_REGEX_MESSAGE);
                
            llOwnerSay("attached to /"+NPCNAME+ "/" +  llGetOwner() + "/ listening on channel 0 ");
        }
    }

    listen(integer chan, string name, key id, string mes) 
    {
        // Relay to controller
        //llOwnerSay("Relaying :'"+mes+"'");
        llRegionSay(68, "! "+(string)id+ " " +NPCNAME+ " "+mes);
    }
    
    dataserver(key qid, string mes)
    {
        if (mes == "find-balls")
        {
            // This is used to search for nearby MLPV2 furniture pose balls
            llSensor("~ball3", "", SCRIPTED, 16, PI);
            llSensor("~ball2", "", SCRIPTED, 16, PI);
            llSensor("~ball1", "", SCRIPTED, 16, PI);
            llSensor("~ball0", "", SCRIPTED, 16, PI);
            status="looking1";
        }
        else if (llGetSubString(mes, 0,1) == "do")
        {
            string bn = llGetSubString(mes, 3, llStringLength(mes));
            //llSay(0,"Got /"+bn+"/ look for /"+bn+"/");
            llSensor(bn, "", SCRIPTED, 16, PI);
            status="looking2";
        }
        else if (llGetSubString(mes, 0, 4) == "light")
        {
            // Turn on a light
            lightOn = !lightOn;
            llSetPrimitiveParams([PRIM_POINT_LIGHT, lightOn, <0.973, 0.543, 0.055>, 1.0, 20.0, 0.1]);
        }
        else if (llGetSubString(mes, 0, 3) == "anim")
        {
            
            // Can be used to run any included anumations
            llStopAnimation(lastAnim);
            integer sep =  llSubStringIndex(mes, ":");
            integer dur = (integer)llGetSubString(mes, 5, sep);

            lastAnim = llGetSubString(mes, sep+1, llStringLength(mes));
            llOwnerSay("Playing /" + lastAnim+"/");
            llStartAnimation(lastAnim);
            llSetTimerEvent(dur);
        }
     
    }
    
    sensor(integer detected)
    {

        list det = [];
        integer i;
        for (i=0;i < detected; i++)
        {
            key k = llDetectedKey(i);
            det += k;
        }
        // We found some balls, send them to the controller to decide if we should sit.
        llRegionSay(68, "FBALL "+NPCNAME+" "+llDumpList2String(det," "));
    }
    
    timer()
    {
        llStopAnimation(lastAnim);
        llSetTimerEvent(0);
    }
    
}

