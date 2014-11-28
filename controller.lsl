integer channel = 68;


// Add the first names of your NPCs here. Last name is always "NPC"
list availableNames = [ "One", "Two", "Three", "Four", "Five"];

// Change this to the URL of your web server (if you have set up one) and remember to change the cityKey to your own key
string BASEURL = "http://your-server.com/index.php?ac=1&cityKey=your-key-here&";

// These will be loaded from notecards
list wNodes = [];
list wLinks = [];

// List of auto-run notecards. The NPC will automatically run the specified notecard when they are in this node
list wAutorunScripts = [
33, "gym.scr",
0, "baths.scr"
];


//  list of nodes for the "Flyaround" command
list flyTargets = [3,5,7, 8, 9, 10, 12,  13, 14, 15, 16, 17, 18, 19, 20, 21 , 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33,  35,36,37,38,39,40,41,42,44];


// Put some animations and add their names here for the "dance" command
list dance1 = [
"Modern 01", 
"Modern 02", 
"Modern 03", 
"Modern 04", 
"Modern 05", 
"Modern 06", 
"Modern 07", 
"Modern 08", 
"Modern 09", 
"Modern 10", 
"Modern 11", 
"Modern 12", 
"Modern 13", 
"Modern 14", 
"Modern 15", 
"Modern 16", 
"Modern 17", 
"Modern 18", 
"Modern 19",
"Modern 20"  
];


// Change this to the key of an object used for the "mark" command
key INDICATOR = "db87ca3d-8403-4c59-bc5e-2e2d31806568";


list menuItems = ["SaveAvi", "LoadAvi", "RemoveAvi", "RemoveAll", "Rescan",  "TimerOff", "UploadWP", "UploadLnk", "ReloadMap", "Close"];


key MAT_KEY = "12e632f9-ac6f-4b38-9f71-630bb47df81d";
key RUN_CONTROLLER="6649f153-2bbd-48a2-a39d-70342c126176";
key STADIUM_CONTROLLER="a0887ae1-593e-4660-a4a0-539383218a9a";

string userInputState ="";
integer gListener;
integer zListener;
integer howmany;
list avis;

list aviUids;
list aviNames;
list aviNodes;
list aviPrevNodes;
list aviStatus;
list aviFollow;
list aviTime;  // Generic timestamp
list aviDanceAnim;
list aviCurrentAnim;
list aviSearching;
list aviPath;
list aviAlarm;
list aviScriptIndex;
list aviScriptText;
list aviHttpId;
list aviVar1;
list aviScriptState;
integer aviIndex = -1;
integer a;
integer b;
integer animSetCounter =0;


list positionsList;
list greetedAvis;
integer timerRuns;

string name;

key npc;
key avi;
list candidateNode=[];

list animSets = [] ; // Playing animation sets


integer RescanAvis()
{
            aviUids = [];
            aviNames = [];
            avis = osGetAvatarList();
            howmany = llGetListLength(avis);
            integer i;

            
            for (i =0; i < howmany; i+=3)
            {
                if (osIsNpc(llList2Key(avis, i)))
                {
                    string nm = llGetSubString(llList2Key(avis, i+2), 0, -5 );
                    //if (llListFindList(aviUids, [llList2Key(avis, i)]) >=0)
                    if (0)
                    {
                        llOwnerSay("Known " + nm);
                    }                    
                    else
                    {

                        aviUids += llList2Key(avis, i);
                        aviNames += llToLower(nm);
                        aviNodes += 8;
                        aviPrevNodes += 7;
                        aviStatus += "";
                        aviFollow += "";
                        aviTime += 9999;
                        aviDanceAnim += "";
                        aviCurrentAnim += "";
                        aviSearching += "";
                        aviPath += "";
                        aviHttpId += "";
                        aviAlarm += -1;
                        aviScriptIndex += -1;
                        aviScriptText += "";
                        aviVar1 += 0;
                        aviScriptState += "";
                        llOwnerSay("Added '"+ nm + "'");
                    }

                }
            }
            llOwnerSay(llList2CSV(aviNames));
            llOwnerSay(llList2CSV(aviStatus));
            //Select the first
            aviIndex = 0;
            npc = llList2Key(aviUids, 0);
            return llGetListLength(aviUids);
}


LoadMapData()
{
    integer tl = osGetNumberOfNotecardLines("waypoints");
    integer i;
    wNodes = [];
    for (i=0; i < tl; i++)
    {
        string line = osGetNotecardLine("waypoints",i);
        list tok = llParseString2List(line, [","],"");
        float x = llList2Float(tok,0);
        if (x>0)
        {
            vector v = <llList2Float(tok,0), llList2Float(tok,1),llList2Float(tok,2)>;
            wNodes += v;
            wNodes += llList2String(tok,3);
        }
    }
    
    integer tnodes = llGetListLength(wNodes)/2;
    
    wLinks = [];
    tl = osGetNumberOfNotecardLines("links");
    for (i=0; i < tl; i++)
    {
        string line = osGetNotecardLine("links",i);
        list tok = llParseString2List(line, [","],"");
        integer a= llList2Integer(tok,0);
        integer b = llList2Integer(tok,1);
        if (a !=b)
        {
            wLinks += [a,b];
        }
    }
    llOwnerSay((string)wLinks);
}


integer GetNPCIndex(string name) /// name is in lowercase
{
    integer i;
    string ln = llToLower(name);
    for (i=0; i < llGetListLength(aviNames); i++)
    {
        if (llToLower(llList2String(aviNames,i)) == ln)
            return i;
    }
    return -1;
}


integer GetWalkTime(float distance)
{
    return llCeil(distance / 3.3);
}

integer GetNearestNode(vector pos)
{
    integer i;
    float min = 9999991.;
    integer l =-1;
    for (i=0;i < llGetListLength(wNodes); i+=2)
    {
        float dist = llVecDist(pos, (vector)llList2String(wNodes,i));
        if (dist < min)
        {
            min = dist;
            l=i;
        }
    }
    return l/2;
}



// Get  path through LSL -- Slow
integer GenPath(integer a, integer tgt, string path, list foundPaths, integer depth)
{
    
    //llOwnerSay("genPath "+a+", "+tgt+", "+opath + ", " + depth);
    
    if (depth > 10) 
    {
        return 0;
    }

    
    integer i;
    for (i=0; i < llGetListLength(wLinks); i+=2)
    {
        integer ca = llList2Integer(wLinks, i);
        integer cb = llList2Integer(wLinks, i+1);
        integer fn = -1;

        if (cb == a || ca == a)
        {
            if (cb == a)
                fn = ca;
            else if (ca == a)
                fn = cb;

            if (llSubStringIndex(path, ":"+fn+":")<0)
            {
                if (fn == tgt)
                {
                    path += ""+fn+":";
                    foundPaths += (path);
                    return 1;
                }
                else
                {
                    GenPath(fn, tgt, path+""+fn+":", foundPaths,  depth+1);
                }
            }
        }
        
        if (llGetListLength(foundPaths)>5)
            return 2;
        
    }
    return 0;
}

list gotoCache;

string GetGotoPath(integer nodeA, integer nodeB)
{
    integer i;
    integer ww;
    
    list foundPaths = [];
    string tmpPath = ":"+(string)nodeA+":";
    GenPath(nodeA, nodeB, tmpPath, foundPaths, 0);

    llOwnerSay(llList2CSV(foundPaths));
    
    if (llGetListLength(foundPaths) ==0)
        return "";
    
    integer min = 99999;
    string least = "";
    for (i=0; i < llGetListLength(foundPaths); i++)
    {
        ww = llStringLength(llList2String(foundPaths, i));
        if (ww < min)
        {
            min = ww;
            least = llList2String(foundPaths, i);
        }
    }

    return least;
}


integer GetNPCIndexByUid(key name) /// name is in lowercase
{
    integer i;
    for (i=0; i < llGetListLength(aviUids); i++)
    {
        if (llList2String(aviUids,i) == (name))
            return i;
    }
    return -1;
}




string GetScriptLine(string scriptData, integer line)
{
    list scriptLines = llParseStringKeepNulls(scriptData, ["\n",";"], []);
    return llList2String(scriptLines, line-1);
}



integer FindScriptLineAfter(string scriptData, string lineToFind, integer afterLine)
{
    integer endIdx;
    list scriptLines = llParseStringKeepNulls(scriptData, ["\n",";"], []);
    string toFind = llToLower(lineToFind);
    integer foundLine = -1;
    string line;
    for  (endIdx = afterLine+1;endIdx < llGetListLength(scriptLines); endIdx++)
    {
        line = llList2String(scriptLines, endIdx);
        if (llToLower(line) == toFind)
        {
            foundLine =endIdx;
            jump _foundIdxOut;
        }
    }
    @_foundIdxOut;
    return foundLine;
}


integer GetNodeIndexByName(string nodeName)
{
    integer i=0; 
    for (i=0; i < llGetListLength(wNodes); i+=2)
    {
        if (llToLower(llList2String(wNodes, i+1)) == nodeName)
        {
            return i;
        }
    }
    return -1;
}

SetScriptAlarm(integer aviId, integer time)
{
    aviAlarm = llListReplaceList(aviAlarm, [llGetUnixTime() + time], aviId, aviId);
}




// Handler for all commands coming from chat
integer ProcessNPCCommand(list tokens)
{
    // first token is just "!"
    string sendUid = llList2String(tokens,1);
    string npcName = llToLower(llList2String(tokens,2));
    string name2 = llToLower(llList2String(tokens,3));
    
    //integer nmend = llSubStringIndex(mes, " ");
    //if  (nmend <0 || nmend > 50) return 0;
    //string npcName = llGetSubString(mes, 37, nmend-1);
    
    
    //llOwnerSay("NPCNAME='"+npcName+"'");
    
    integer idx = GetNPCIndex(npcName);
    if (idx <0)
    {
        return 3;
    }
    key uNPC= llList2Key(aviUids, idx);
    if (uNPC == NULL_KEY)
    {
        return 1;
    }
    
    string cmd1= llList2String(tokens,4);
    string cmd2= llList2String(tokens,5);
    
    list userData = llGetObjectDetails((key)sendUid, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
    
    string org = llList2String(userData, 0);

    if (name2 != npcName)
    {
        if (name2 == "hello" || name2 == "hi")
        {
            osNpcSay(uNPC, "Hello, if you need help say '"+npcName+" help'");
            return 1;
        }
    }
    else if (cmd1 == "follow")
    {
        aviStatus = llListReplaceList(aviStatus, ["follow"], idx, idx);
        if (cmd2=="me" || cmd2=="")
        {
            aviFollow = llListReplaceList(aviFollow, [(key)sendUid], idx, idx);
            osNpcSay(uNPC, "Following you Sir "+ llList2String(userData, 0));
        }
        else
        {
            list ag = osGetAvatarList();
            integer howmany = llGetListLength(ag);
            integer i;
            for (i =0; i < howmany; i+=3)
            {
                string name = llList2String(ag, i+2);
                integer sep = llSubStringIndex(name, " ");
                if (llToLower(llGetSubString(name, 0,sep-1)) == llToLower(cmd2))
                {
                    aviFollow = llListReplaceList(aviFollow, [llList2Key(ag, i)], idx, idx);
                    osNpcSay(uNPC, "Following " + name);
                }
            }
        }

    }
    else if (cmd1 == "set-state") // set a variable that indicates the current state of an NPC -- useful for scripts
    {
        aviScriptState= llListReplaceList(aviScriptState, [cmd2], idx, idx);
    }
    else if (cmd1 == "var1") // Do something on the counter var1
    {
            if (cmd2 == "++" || cmd2 == "--")
            {
                integer var1 = llList2Integer(aviVar1, idx);
                if (cmd2 == "--") --var1;
                else ++var1;
                aviVar1= llListReplaceList(aviVar1, [var1], idx, idx);
            }
            else if (cmd2 == "zero")
            {
                aviVar1= llListReplaceList(aviVar1, [0], idx, idx);
            }
            else
                llOwnerSay("Unknown: "+ cmd2);
    }
    else if (cmd1 == "fly" && cmd2=="with")  // "fly with me" "fly with Foo"
    {
        string who = llList2String(tokens, 6);
        if (who == "me")
        {
            aviFollow = llListReplaceList(aviFollow, [(key)sendUid], idx, idx);
        }
        else
        {
            list ag = osGetAvatarList();
            integer howmany = llGetListLength(ag);
            integer i;
            for (i =0; i < howmany; i+=3)
            {
                string name = llList2String(ag, i+2);
                integer sep = llSubStringIndex(name, " ");
                if (llToLower(llGetSubString(name, 0,sep-1)) == llToLower(who))
                {
                    aviFollow = llListReplaceList(aviFollow, [llList2Key(ag, i)], idx, idx);
                    osNpcSay(uNPC, "Following " + name);
                    jump _foundflyfollow;
                }
            }
        }
        @_foundflyfollow;
        
        aviStatus = llListReplaceList(aviStatus, ["flyfollow"], idx, idx);
        osNpcSay(uNPC, "Flying ");

    }
    else if (cmd1 == "help")
    {
        osNpcSay(uNPC, "Say '"+ npcName+ " <command>', where <command> can be: 'follow me', 'fly with me', 'do', 'go to', 'wear', 'drop', 'dance', 'stand up', 'stop', 'light', 'leave'.");
    }
    else if (cmd1 == "leave")
    {
        // Start wandering between waypoints
        aviNodes = llListReplaceList(aviNodes, [GetNearestNode(osNpcGetPos(uNPC))], idx, idx);
        aviStatus = llListReplaceList(aviStatus, ["wander"], idx, idx);
        string nm = llList2String(userData, 0);
        osNpcSay(uNPC, "OK, goodbye sir!");

    }
    else if (cmd1 == "positioner")
    {
        llRegionSay(78, ""+(string)idx + " setpos " + (string)osNpcGetPos(uNPC) + " " + (string)osNpcGetRot(uNPC));
    }
    else if (cmd1 == "animset")
    {
        // try to play an animation set from the notecard with this NPC as the first avi
        vector basePos = osNpcGetPos(uNPC);
        string animset = llToLower(cmd2);
        integer tl = osGetNumberOfNotecardLines("animsets");
        integer i;
        for (i=0; i < tl; i++)
        {
            list animtoks = llParseString2List(osGetNotecardLine("animsets", i), [" "] , []);
            
            if (llToLower(llList2String(animtoks,0)) == animset)
            {
                integer j;
                animSetCounter++;
                vector pos = llGetPos();
                integer channel = 600+animSetCounter;
                integer posInSet =0;
                for (j=1; j < llGetListLength(animtoks); j+= 3)
                {
                    
                    //llRezObject("positioner", pos+<j*0.3,0,0>, <0,0,0>, <0,0,0>, channel*100 + posInSet);
                    posInSet++;
                }
                llSleep(1);
                posInSet =0;
                vector ref = ZERO_VECTOR;
                for (j=1; j < llGetListLength(animtoks); j+= 3)
                {
                    string animname = llList2String(animtoks,j);
                    vector v = (vector)llList2String(animtoks,j+1);
                    rotation rot = (rotation)llList2String(animtoks,j+2);
                    
                    if (ref == ZERO_VECTOR)
                    {
                        ref = v;
                        ref.z = 0;
                    }
                    v -= ref;
                    llRegionSay(channel, (string)posInSet+" params "+(string)v+" " + (string)rot+ " "+ animset);
                    posInSet++;
                }
                
                jump _afterAnimFound;
            }
        }
        
        @_afterAnimFound;
        
    }
    else if (cmd1 == "flyaround")
    {
        // Start flying about between the waypoints in the "flyTargets" list -- useful for birds
        aviStatus = llListReplaceList(aviStatus, ["godfly"], idx, idx);
        string nm = llList2String(userData, 0);
        osNpcSay(uNPC, "Flying like an eagle!!");

    }
    else if (cmd1 == "dance")
    {
        //Drop a few dance animations in the controller object and change the "dance1" list at the top. This will start cycling the dances

        aviStatus = llListReplaceList(aviStatus, ["dance"], idx, idx);
        osNpcSay(uNPC, "Oh, with pleasure Sir!");
        aviTime = llListReplaceList(aviTime, [0], idx, idx);        
        osNpcStand(uNPC);
        string old_anim = llList2String(aviDanceAnim, idx);
        osNpcStopAnimation(uNPC, old_anim);
    }
    else if (cmd1 == "stop")
    {
        // Stand up and stop  all animations
        aviStatus = llListReplaceList(aviStatus, [""], idx, idx);
        //osNpcSay(uNPC, "OK sir!");
        aviTime = llListReplaceList(aviTime, [0], idx, idx);
        string old_anim = llList2String(aviDanceAnim, idx);
        osNpcStopAnimation(uNPC, llList2String(aviCurrentAnim, idx));
        integer d;
        for  (d=0; d < llGetListLength(dance1); d++)
        {
            osNpcStopAnimation(uNPC, llList2String(dance1, d));
        }
        osNpcStopMoveToTarget(uNPC);
        osNpcStand(uNPC);
        osSetSpeed(uNPC, 1.0);
    }
    else if (cmd1 == "come")
    {
        
        // "Come here"
        osNpcStand(uNPC);
        osNpcStopMoveToTarget(uNPC);
        osTeleportAgent(uNPC, llList2Vector(userData, 1) + <1, 0, 0>
, <1,1,1>);
        osNpcSay(uNPC, "Coming right over Sir!");

    }
    else if (cmd1 == "stand")
    {
        // Stand up
        aviStatus = llListReplaceList(aviStatus, [""], idx, idx);
        osNpcStand(uNPC);
        osNpcStopMoveToTarget(uNPC);
    }
    else if (cmd1 == "moveto" || cmd1 == "movetov" || cmd1 == "runtovr")
    {
        // Walk to the specified waypoint or vector
        vector v;
        if  (cmd1 == "runtovr")
        {
            // run to somewhere within the volume enclosed by v1 and v2
            vector v1 = (vector) cmd2;
            vector v2 = (vector) llList2String(tokens, 6);
            v.x= v1.x + llFrand(v2.x-v1.x);
            v.y= v1.y + llFrand(v2.y-v1.y);
            v.z= v1.z + llFrand(v2.z-v1.z);
        }
        else if (cmd1 == "movetov" || cmd1 == "runtovr")
            v = (vector)cmd2;
        else
            v = llList2Vector(wNodes, 2*(integer)cmd2);
        
        float dist = llVecDist(osNpcGetPos(uNPC), v);        
        
        if (cmd1 == "runtovr")
        {

            osNpcMoveToTarget(uNPC, v + <0,0,1>, OS_NPC_NO_FLY | OS_NPC_RUNNING);
            SetScriptAlarm(idx, (integer)(GetWalkTime(dist)/2.0));
        }
        else
        {
            osNpcStand(uNPC); 
            osNpcStopMoveToTarget(uNPC);
            osNpcMoveToTarget(uNPC, v + <0,0,1>, OS_NPC_NO_FLY );
            SetScriptAlarm(idx, GetWalkTime(dist));
        }
        
        
    }
    else if (cmd1 == "if" || cmd1 == "if-not")
    {
        // Only 1 level of ifs is supported
        // must be followed by 'end-if'
        integer res = 0;
        if (cmd2 == "name-is")
        {
            integer k;
            for (k=6; k < llGetListLength(tokens); k++)
            {
                if (llToLower(npcName) == llToLower(llList2String(tokens,k)))
                    res=1;
            }
        }
        else if (cmd2 == "state-is")
        {
            // If state-is <avi-name> <state-value>
            integer nwho = GetNPCIndex(llList2String(tokens,6));
            if (nwho >=0)
            {
                string what = llList2String(aviScriptState,nwho);
                integer k;
                for (k=7; k < llGetListLength(tokens); k++)
                {v
                    if (what == llList2String(tokens,k))
                                      res=1;
                }
            }
        }
        else if (cmd2 == "var1-gt" || cmd2 == "var1-lt" || cmd2=="var1-eq")
        {
            // check if value of var1 is >, < or == to the second argument
            integer var1 =llList2Integer(aviVar1, idx);
            integer val  =(integer)llList2String(tokens, 6);
            
            if (cmd2=="var1-gt" && var1>val) res=1;
            else if (cmd2=="var1-lt" && var1  < val) res=1;
            else if (cmd2=="var1-eq" && var1 == val) res=1;
        }
        
        if (cmd1 == "if-not")
            res = !res;
            
        integer scrline = llList2Integer(aviScriptIndex, idx);
        if (scrline <0) 
        {
            return 1; // wtf
        }

        if (!res)
        {
           
            integer foundLine = FindScriptLineAfter(llList2String(aviScriptText,idx), "end-if", scrline);
            if (foundLine == -1)
            {
                llOwnerSay("Error: end-if not found near "+cmd1 + " "+cmd2 + "...");
            }
            else
            {
                aviScriptIndex  = llListReplaceList(aviScriptIndex, [foundLine], idx, idx);
            }
        }

    }
    else if (cmd1 == "end-if")
    {
        // Do nothing
    }
    else if (cmd1 == "jump")
    {
        // Jump to a label in the notecard
        integer foundLine = FindScriptLineAfter(llList2String(aviScriptText,idx), "@"+cmd2,-1);
        if (foundLine == -1)
        {
            llOwnerSay("Error: @"+cmd2+" label not found");
        }
        else
        {
            aviScriptIndex  = llListReplaceList(aviScriptIndex, [foundLine], idx, idx);
        }
    }
    else if ((cmd1 == "go" && cmd2 == "to")   || cmd1 == "goto")
    {
     
        // Pathfinding command
        // Goto: go to specified waypoint
        // Go to <target>: go to the waypoint named <target>
        
        integer nearest = GetNearestNode(osNpcGetPos(uNPC));
    
        integer foundId =-1;        
        if (cmd1 == "goto")
        {
            foundId = (integer) cmd2;
        }
        else
        {
            string where = llToLower(llStringTrim(llList2String(tokens,6) +" "+ llList2String(tokens,7) +" "+ llList2String(tokens,8), STRING_TRIM));
            
            integer i;
            llOwnerSay("" + where);
            if (llStringLength(where))
            {
                for (i=0; i < llGetListLength(wNodes); i+=2)
                {
                    if (llToLower(llList2String(wNodes,i+1)) == where)
                    {
                        foundId = (integer)i/2;
                        jump fbreak;
                    }
                }
            }
            @fbreak;
            if (foundId <0)
            {
                    osNpcSay(uNPC, "Sorry i dont know how to get to the "+where+ "");
                    string txt;
                    
                    for (i=0; i < llGetListLength(wNodes); i+=2)
                    {
                        string tt = llList2String(wNodes, i+1);
                        if (tt != "")
                            txt += tt+", ";
                    }
                    osNpcSay(uNPC, "Here's some of the places i know: " +txt);
                    return 1;      
            }
        }
        
        osNpcSay(uNPC, "Let me think... ");
        SetScriptAlarm(idx, 999); /// Set script  alarm far to the future - the alarm will be set back when the avi arrives at the destination
        string url=BASEURL+"act=getPath&src="+nearest+"&tgt="+foundId;
        key httpid = llHTTPRequest(url, [], "");
        aviStatus = llListReplaceList(aviStatus, ["http-"+httpid], idx, idx);
        llOwnerSay("Sending out /"+url+"/");
        
    }
    else if (cmd1 == "wait")
    {
        // cause the script to wait for <arg> seconds 
        SetScriptAlarm(idx, (integer) cmd2);
    }
    else if (cmd1 == "say")
    {
        // Say something on chat
        string txt = "";
        integer i;
        for (i=5; i < llGetListLength(tokens); i++)
            txt += llList2String(tokens,i) + " ";
        osNpcSay(uNPC, txt);
    }
    else if (cmd1 == "mark")
    {
        // Move the indicator object to the specified waypoint (used for debugging the map)
        integer l=0;
        if (cmd2 == "nearest")
        {
            vector pos = llList2Vector(userData, 1);
            l = GetNearestNode(pos);
        }
        else l = (integer)cmd2;
        
        vector p = llList2Vector(wNodes, l*2);
        llOwnerSay((string)p);
        osMessageObject(INDICATOR, (string)p + " " + (string)l);   
    }
    else if (cmd1 == "get")
    {
        //llOwnerSay("Getting "+uNPC+ " " + cmd2);
        osMessageAttachments(uNPC, "penis-"+cmd2, [ATTACH_PELVIS], 0);
    }
    else if (cmd1 == "wear" || cmd1 == "drop")
    {
        // Hide or show clothes. You want to customize this for 
        // your own set of garments
        string what = cmd2;
        string com = "show";
        if (cmd1== "drop")
            com = "hide";
        
        if (what == "helmet")
            osMessageAttachments(uNPC, com, [ATTACH_HEAD], 0);
        else if (what == "shield")
            osMessageAttachments(uNPC, com, [ATTACH_LHAND], 0);
        else if (what == "spear")
            osMessageAttachments(uNPC, com, [ATTACH_RHAND], 0);
        else if (what == "chiton" || what == "toga") 
            osMessageAttachments(uNPC, com, [ATTACH_CHEST, ATTACH_PELVIS], 0);
        else if (what == "arms")
        {
           osMessageAttachments(uNPC, com, [ATTACH_LHAND, ATTACH_RHAND, ATTACH_HEAD], 0);
        }
        else
            osNpcSay(uNPC, "Say '"+npcName+" "+cmd1+" <item>', <item> can be: helmet, shield, spear, chiton, arms");
    }
    else if (cmd1 == "do")
    {
        // Sit-on-a-poseball command
       if (cmd2 == "")
       {
           osNpcSay(uNPC, "When i am near a pose ball, say '"+npcName+" do <ball label>' and i will sit on it. If using a menu-driven bed or mat, say '"+npcName+" sit' and i will hop on.");
       }
       else
       {
           string cmd = llStringTrim(cmd2+" "+llList2String(tokens, 6)+" "+llList2String(tokens,7), STRING_TRIM);
            osMessageAttachments(uNPC, "do "+cmd, [ATTACH_RIGHT_PEC], 0);
       }
    }
    else if  (cmd1 == "lookat")
    {
        vector v = (vector)cmd2;
        if  (v == ZERO_VECTOR)
        {
            integer midx = GetNodeIndexByName(llToLower(cmd2));
            if (midx >=0)
            {
                v = llList2Vector(wNodes, midx);
            }
        }
        osNpcSetRot(uNPC, llRotBetween(<1,0,0>, v-osNpcGetPos(uNPC)));//llEuler2Rot(<0,0,ang>)); 
    }
    else if (cmd1 == "anim")
    {
        osNpcStopAnimation(uNPC, llList2String(aviCurrentAnim, idx));
        aviCurrentAnim = llListReplaceList(aviCurrentAnim, [cmd2], idx, idx);
        osNpcPlayAnimation(uNPC, cmd2);
    }
    else if (cmd1 == "light")
    {
        // Sit on  MLPV1/2 furniture poseballs
        osMessageAttachments(uNPC, "light", [ATTACH_RIGHT_PEC], 0);
    }
    else if (cmd1 == "sit")
    {
        // Sit on  MLPV1/2 furniture poseballs
        osMessageAttachments(uNPC, "find-balls", [ATTACH_RIGHT_PEC], 0);
    }
    else if (cmd1 == "batch")
    {
        // Run multiple commands from the chat, separated by ";"   --- replaces any running script
        string str = llDumpList2String(llList2List(tokens, 5, llGetListLength(tokens))," ");
        aviScriptText = llListReplaceList(aviScriptText, str, idx, idx);
        aviScriptIndex = llListReplaceList(aviScriptIndex, [1], idx, idx);
        SetScriptAlarm(idx, 0);

    }
    else if (cmd1 == "run-notecard")
    {
        // Run the script contained in the notecard <argument>
        string stext= osGetNotecard(cmd2 );
        aviStatus= llListReplaceList(aviStatus, "", idx, idx);
        if (stext == "")
        {
            osNpcSay(uNPC,"Could not load notecard '"+cmd2+"'");
            return 1;
        }
        aviScriptText = llListReplaceList(aviScriptText, stext, idx, idx);
        aviScriptIndex = llListReplaceList(aviScriptIndex, [1], idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (cmd1 == "stop-script")
    {
        // Stop executing the script and exit
        aviScriptIndex = llListReplaceList(aviScriptIndex, [-1], idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (llGetSubString(cmd1,0,0) == "@")
    {
        // It's a label; do nothing
    }
    else
    {
        osNpcSay(uNPC, "I do not know how to "+cmd1+". Say '"+npcName+" help' for more");
    }

    return 1;
}

integer FindNewTarget(integer curNode, integer prevNode)
{
    //vector myloc=osNpcGetPos(npc);
    //integer curNode = llList2Integer(aviNodes,aviIndex);
    
    integer total=llGetListLength(wLinks);
    candidateNode = [];
    integer i;
    for (i=0; i< total; i+=2)
    {

        a = llList2Integer(wLinks,i);
        b = llList2Integer(wLinks,i+1);
        if (a == curNode && prevNode != b) /// dont go back where we came from
            candidateNode += b;
        else if (b == curNode && prevNode !=a)
            candidateNode += a;
    }
    
    integer  l = llGetListLength(candidateNode);
    //llOwnerSay(llList2CSV(candidateNode));
    if (l>0)
    {
        return llList2Integer(candidateNode, (integer)llFrand((float)l));
    }
    else 
        return prevNode; // go back to where we came from if there is no other option
}


integer MoveToNewTarget(integer idx)
{
    integer curNode = llList2Integer(aviNodes,idx);
    integer prevNode = llList2Integer(aviPrevNodes,idx);

    key uuid = llList2Key(aviUids, idx);
    if (uuid == NULL_KEY)
    {
        return 1;
    }
    vector pos = osNpcGetPos(uuid);

    float eh = 0.1; // extra height for big avis    
    if (llList2String(aviNames, idx) == "ares")
        eh = 2.5;

    osNpcStand(uuid);
    
    vector wp = llList2Vector(wNodes, 2*curNode);
    float dist = llVecDist(pos, wp);
    if (dist>10)
    {
        osTeleportAgent(uuid,  wp, <1,1,7+eh>);
    }

    integer nt = FindNewTarget(curNode, prevNode);
    if (nt <0) return 0;
    vector tgt = llList2Vector(wNodes, 2*nt);

            // Try to stay in the right 'lane'
    float rx =0.5;
    if (tgt.y < pos.y)
        rx *= -1.0;

    float ry = 0.5;
    if (tgt.x > pos.x)
        ry *= -1.0;
        
    tgt += <rx, ry, eh>;

    osSetSpeed(uuid, 0.8);
    osNpcSetRot(uuid, llRotBetween(<PI,PI,0>,llVecNorm(tgt - osNpcGetPos(uuid))));
    osNpcMoveToTarget(uuid, tgt, OS_NPC_NO_FLY);
    
    aviTime = llListReplaceList(aviTime, [ llGetUnixTime() + GetWalkTime( llVecDist(wp, tgt) )], idx, idx);
    aviNodes = llListReplaceList(aviNodes, [nt], idx, idx);
    aviPrevNodes = llListReplaceList(aviPrevNodes, [curNode], idx, idx);
    return 0;
}


ExecScriptLine(string aviName, string scriptline)
{
    // The token list expects the name of the avi twice. we use BATCH as the sending-uid identifier
    string command = "! BATCH " + aviName+" "+ aviName + " " + scriptline;

    list tokens = llParseString2List(command, [" "], [] );
    //llOwnerSay(" Running: "+command + " " );
    // Process the command as if we received it from from chat
    ProcessNPCCommand(tokens);
}


default
{

    state_entry()
    {
        llListenRemove(gListener);
        gListener = llListen(channel, "", "", "");
        llOwnerSay("Listening on channel "+channel);
        LoadMapData();
        //llOwnerSay(llList2CSV(wNodes));
        //llOwnerSay(llList2CSV(wLinks));
        
        RescanAvis();  
        llSetTimerEvent(5);
        greetedAvis = [];
        animSets = ["","","","","","","","","","", "",""];  // Empty slots
    }
    
    touch_start(integer num)
    {
        avi = llDetectedKey(0);
        if (llGetOwner() != avi)
            return;
        llDialog(avi, "Welcome", menuItems, channel);
    }
    

    // The main loop where everything happens. 
    // This checks the statuses of all avis and performs commands accordingly
    timer()
    {
        integer total = llGetListLength(aviUids);
        integer g;
        integer advanceScript;
        for (g=0; g < total ; g++)
        {
                advanceScript =0;
                aviIndex = g;
                npc = llList2Key(aviUids, g);
                //name = llList2String(aviNames, g); 
                string status = llList2String(aviStatus, g); 

                if (status == "follow" || status == "flyfollow")
                {
                    // This NPC is following someone
                    integer stat=llGetAgentInfo(npc);
                    if (stat & AGENT_SITTING)
                    {
                        // We 've been sat. stop following
                        return;
                    }
                    
                    key who = llList2Key(aviFollow, g);
                    list userData = llGetObjectDetails(who, [OBJECT_POS, OBJECT_ROT]);
                    if (llGetListLength(userData) ==0)
                    {
                        // User left or died
                        aviStatus= llListReplaceList(aviStatus, [ "" ], g, g);
                        return;
                        
                    }
                    
                    rotation rot = llList2Rot(userData,1);
                    float ang = llFrand(1.0);

                    vector v = llList2Vector(userData,0) + <-0.7,0,0>*rot;
                     //<-1.1*llSin(ang), 1.1*llCos(ang), 0>;
                    float dist = llVecDist(osNpcGetPos(npc), v);
                    if  (status == "follow" && dist>50.)
                    {
                        osTeleportAgent(npc, v, <1,1,1>);
                    }
                    else if  (dist>4)
                    {
                        osNpcStopMoveToTarget(npc);
                        if (status == "flyfollow")                
                           osNpcMoveToTarget(npc, v+<0,0,2.>, OS_NPC_FLY );
                        else
                            osNpcMoveToTarget(npc, v, OS_NPC_NO_FLY );
                    }
                }
                else if (status == "wander")
                {
                    // This NPC is wandering between waypoints
                    if (1)
                    {
                        if (llGetUnixTime()  > llList2Integer(aviTime, g) +1)
                        {
                            integer curNode = llList2Integer(aviNodes, g);
                            integer i;
                            integer shouldMove =1;
                            // avoid looping back to the same script while we are about to leave
                            if (llGetUnixTime() >  llList2Integer(aviAlarm, g)+120)
                            {
                                for (i=0; i < llGetListLength(wAutorunScripts); i+=2)
                                {
                                    if (llList2Integer(wAutorunScripts,i) == curNode)
                                    {
                                        ExecScriptLine(llList2String(aviNames, g), "run-notecard "+llList2String(wAutorunScripts,i+1));
                                        shouldMove =0;
                                    }
                                }
                            }
                            
                            if (shouldMove>0)
                            {
                               if (llFrand(1.0) < 0.5)
                                   ExecScriptLine(llList2String(aviNames, g), "get fart");
                               MoveToNewTarget(g);
                            }
                        }
                    }
                }
                else if (status == "godfly")
                {
                    // This NPC is flying around
                    if (timerRuns%4 == 0)
                    {
                        integer idx = llList2Integer(flyTargets, (integer)llFrand(llGetListLength(flyTargets)));
                        vector nd = llList2Vector(wNodes, 2*idx);
                        integer flag = OS_NPC_FLY;
                        osSetSpeed(npc, 0.5);
                        //if (llFrand(1.0)<.9)
                            flag = OS_NPC_FLY|OS_NPC_LAND_AT_TARGET;
                        integer theight = 10;

                        if (timerRuns%8==0)
                            theight = 25;
                        osNpcMoveToTarget(npc, nd +  <llFrand(1),llFrand(1),theight>, flag);
                    }
                }
                else if (status == "pathf")
                {
                    // Pathfinding - this NPC is following the path to a destination
                    integer avits = llList2Integer(aviTime, g);
                    if (llGetUnixTime() > avits)
                    {
                    
                        vector p = osNpcGetPos(npc);
                        string path = llList2String(aviPath, g);
                        list pnodes = llParseString2List(path, [":"], [""]);
                        
                        llOwnerSay("p="+llList2CSV(pnodes));
                        if (llGetListLength(pnodes) <1)
                        {
                            osNpcSay(npc, "I have arrived");
                            
                            aviStatus = llListReplaceList(aviStatus, [ "" ], g, g);
                            
                            // continue the script (if any), since we reached our destination
                            SetScriptAlarm(g, 0); 

                        }
                        else
                        {
                            integer nextTgt = llList2Integer(pnodes, 0);
                            string ndleft = ":"+llDumpList2String( llList2List(pnodes, 1, llGetListLength(pnodes)), ":");


                            aviPath = llListReplaceList(aviPath, [ ndleft ], g, g);
                            vector v = llList2Vector(wNodes, 2*nextTgt);              
                            aviTime = llListReplaceList(aviTime, [ llGetUnixTime() + GetWalkTime(llVecDist(p, v)) ], g, g);
                            

              
                            osNpcMoveToTarget(npc, v + <llFrand(1.0),llFrand(1.0), 0.1> , OS_NPC_NO_FLY );
                        }
                        
                    }
                    
                }
                else if  (status == "dance")
                {
                    // alternate between dances
                    integer ts = llGetUnixTime();
                    if (ts > llList2Integer(aviTime, g)+60)
                    {
                        aviTime = llListReplaceList(aviTime, [ts], g, g);
                        
                        string old_anim = llList2String(aviDanceAnim, g);
                        integer newidx = (integer)llFrand(llGetListLength(dance1));
                        string new_anim =  llList2String(dance1, newidx);
                        
                        //llOwnerSay("Switching to dance " + new_anim);
                        
                        osNpcStopAnimation(npc, old_anim);
                        osNpcPlayAnimation(npc, new_anim);
                        aviDanceAnim = llListReplaceList(aviDanceAnim, [ new_anim ], g, g);
                    }
                }
                else
                {
                    //
                }
                
                
                // Execute the next script line if a script is active
                
                integer scriptIndex = llList2Integer(aviScriptIndex, g);
                if (scriptIndex > 0) // This avi is executing a script
                {
                    integer tsAlarm = llList2Integer(aviAlarm, g);
                    integer diff = llGetUnixTime() - tsAlarm;

                    if (tsAlarm >0 && llGetUnixTime() >= tsAlarm ) // The script should continue now
                    {        
                        string scriptData = llList2String(aviScriptText, g);
                        string scriptline = GetScriptLine(scriptData, scriptIndex);
                        if (scriptline == "") // End of script
                        {
                                // This will prevent any further execution
                                aviScriptIndex = llListReplaceList(aviScriptIndex, [-1], g, g);
                        }
                        else
                        {
                            // Set the timer for the next command 1 second later by default. Some commands will override this (e.g. go to, wait).
                            SetScriptAlarm(g, 1);
                            ExecScriptLine( llList2String(aviNames, g), scriptline);
                            // Advance script pointer 
                            scriptIndex = llList2Integer(aviScriptIndex, g); 
                            aviScriptIndex = llListReplaceList(aviScriptIndex, [scriptIndex+1], g,g);
                        }
                    }
                }
        }
        timerRuns++;
    }
    


    listen(integer chan, string name, key id, string str) {    // WARNING "id" is not the uid of the NPC-sender

        list tok = llParseString2List(str, [" "] , [""]);
        string mes = llList2String(tok, 0);

        if  (mes == "SaveAvi")
        {
            llDialog(avi, "Select NPC to save your appearance", llList2List(availableNames, 0,11), channel);       

            userInputState = "WAIT_APPNAME";
        }
        else if (mes == "Rescan")
        {
            RescanAvis();
        }
        else if (mes == "LoadAvi")
        {
            llDialog(avi, "Select an NPC to load", llList2List(availableNames, 0,11), channel);     
            userInputState = "WAIT_AVINAME";
        }
        else if (mes == "RemoveAvi")
        {
            llDialog(avi, "Select an NPC to delete", llList2List(availableNames, 0,11), channel);     
            userInputState = "WAIT_REMOVEAVI";
        }
        else if (mes == "RemoveAll")
        {
            avis = osGetAvatarList();
            llSay(0, llList2CSV(avis));
            howmany = llGetListLength(avis);
            integer i;
            for (i =0; i < howmany; i+=3)
            {
                if (osIsNpc(llList2Key(avis, i)))
                {
                    osNpcRemove(llList2Key(avis, i));
                }
            }
            aviUids = [];
            aviNames = [];
        }
        else if (mes == "initcommands")
        {
            // Specify a list of commands here. Send /68 initcommands to execute them
            integer i;
            list commands = [
            "icaros fly with dedalos",
            "dedalos flyaround",
            "ares leave",
            "pan leave",
            "midas leave",
            "kriton leave",
            "leon leave",
            "philon leave",
            "iasos leave",
            "nicanor leave",
            "ariston leave",
            "nais batch goto 2; dance",
            "lydia batch go to tavern; dance" 
            ];
            
            for (i=0; i < llGetListLength(commands); i++)
            {
                list toks = llParseString2List(llList2String(commands,i), [" "], []);    
                list tok2 = ["!", "0000", llList2String(toks, 0)]; /// Need name of npc twice
                tok2 += toks;
                llOwnerSay("Cmd="+llList2CSV(tok2));
                ProcessNPCCommand(tok2);
                llSleep(1);
            }           

        }
        else if (mes == "TimerOff")
        {
            llSetTimerEvent(0.0);
        }
        else if (mes == "ReloadMap")
        {
            LoadMapData();
        }
        else if (mes == "UploadWP")
        {
            // Upload the map waypoints to the web server
            list lst; 
            integer i;
            integer j;
            string wpdata;
            string wpname;
            for (i=0; i < llGetListLength(wNodes); i+=2)
            {
                vector v = llList2Vector(wNodes, i);
                wpname = llList2String(wNodes, i+1);
                wpdata += v.x+"|"+v.y+"|"+v.z+"|"+wpname+"|";
            }
            llHTTPRequest(BASEURL+"act=updateNodes", [HTTP_METHOD, "POST"], ""+wpdata);
            llOwnerSay("Length="+llStringLength(wpdata));
            
        }
        else if (mes == "UploadLnk")
        {
            // Upload the map links to the web server
            list lst; 
            integer i;
            integer j;
            string wpdata;
            string wpname;
            wpdata = llList2CSV(wLinks);
            
            llHTTPRequest(BASEURL+"act=updateLinks", [HTTP_METHOD, "POST"], ""+wpdata);
            llOwnerSay("Length="+llStringLength(wpdata));

            
        }
        else if (mes == "balls")
        {
            string cmd = llList2String(tok, 1);
            integer i;
            if (cmd == "rez")
            {

                vector pos = llGetPos() + <3,0,0>;
                for (i=0; i <llGetListLength(aviNames); i++)
                {
                    
                    llRegionSay(78, (string)i+" die");
                    llRezObject("positioner", pos + <i*0.3,0,1>, ZERO_VECTOR, ZERO_ROTATION, i);
                    //llSleep(1);
                }
            }
            else if (cmd == "kill")
            {
                for (i=0; i <=llGetListLength(aviNames); i++)
                {   
                    llRegionSay(78, (string)i+" die");
                    //llSleep(1);
                }
            }
            else if (cmd == "report")
            {
               positionsList = [];
                for (i=0; i <=llGetListLength(aviNames); i++)
                {   
                    llRegionSay(78, (string)i+" report");
                    //llSleep(1);
                }
            }
            else if (cmd == "makeset")
            {
                //llOwnerSay("something");
                //llOwnerSay(llList2CSV(positionsList));
                string txt = "SET";
                vector ref = ZERO_VECTOR;
                for  (i=2; i < llGetListLength(tok);i++)
                {
                    integer npcId = GetNPCIndex(llList2String(tok, i));
                    if (npcId >=0)
                    {
                        integer j;
                        for (j=0; j < llGetListLength(positionsList); j+=3)
                        {
                            if (llList2Integer(positionsList, j) == npcId)
                            {
                                txt += ( " "+llList2String(aviCurrentAnim, npcId)+ " "+(string)llList2Vector(positionsList,j+1)+ " " +(string)llList2Rot(positionsList, j+2));
                            }
                        }
                    }
                }
                llSay(0, txt);
            }
        }
        else if (mes == "REP") // positioner reporting
        {
            positionsList += [
                (integer)llList2String(tok,1),
                (vector)llList2String(tok,2),
                (rotation)llList2String(tok,3)];
                
        }
        else if (mes == "calc-pos")
        {
            integer i;
            if (llGetListLength(positionsList)<2)  return;
            vector ref = llList2Vector(positionsList, 1);
            ref.x =0;
            ref.y =0;
            for (i=0; i < llGetListLength(positionsList); i+=3)
            {
                 vector v = llList2Vector(positionsList,i+1);
                 v -= ref;
                 rotation r = llList2Rot(positionsList,i+2);
                 llSay(0, ""+(string)llList2Integer(positionsList, i)+" "+(string)v+ " "+(string)r);
            }
        }
        else if (mes =="fetch")
        {
            // fetch an NPC here
            integer idx = GetNPCIndex(llList2String(tok, 1));

            llOwnerSay("Fetching "+(string)idx+"");
            if  (idx >=0)
            {
                list userData = llGetObjectDetails(id, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
                //llOwnerSay("U"+ llList2String(userData, 0)+ " at "+ (string)llList2Vector(userData,1) + " -> command "+cmd);
                key n = llList2Key(aviUids, idx);
                osTeleportAgent(n, llList2Vector(userData,1)+<1,0,0> , <1,1,0>);
            }
                        
        }
        else if (mes =="FBALL")
        {
            // A poseball has been found. We have to check if it is transparent. If it is not, then we sit the NPC on it
            string npcname= llList2String( tok, 1);
            integer  idx = GetNPCIndex(npcname);
            if (idx<0) return;
            key unpc = llList2Key(aviUids, idx);
            integer i;
            for (i=2; i < llGetListLength(tok);i++)
            {
                key ball = llList2String(tok, i);
                list prop = osGetPrimitiveParams(ball, [PRIM_COLOR, 0]); /// DOESNT WORK IF NOT OWNER
                float alpha = llList2Float(prop, 1);
                if (alpha >0)
                {
                        osNpcStand(unpc);
                        osNpcStopMoveToTarget(unpc);
                        osNpcSit(unpc, ball, OS_NPC_SIT_NOW);
                        aviStatus = llListReplaceList(aviStatus, ["sitting"], idx, idx);
                        jump ballFound;
                }
            }          
            llOwnerSay("All balls transparent");  
            @ballFound;
            
        }
        else if (mes == "!") // Something that has been sent from the NPCs
        {
            ProcessNPCCommand(tok);   
        } 
        else if (userInputState != "" && mes != "")//  Process dialog commands
        {
            //llOwnerSay("USER MSG WAIT");
            if (mes == "more")
            {
                 llDialog(avi, "Select an NPC", llList2List(availableNames, 12,-1), channel);
            }
            else
            {
                if (userInputState == "WAIT_APPNAME")
                {
                    osAgentSaveAppearance(avi, "APP_"+mes);
                    llSay(0,  "Saved Appearance " + avi + " -> APP_"+mes);
                }
                else if (userInputState == "WAIT_AVINAME")
                {
                    if (GetNPCIndex(mes)>=0)
                    {
                        llSay(0, mes + " is already in region, not loading");
                        return;
                    }
                    npc = osNpcCreate(mes, "NPC", llGetPos()+<0,0,1>, "APP_"+mes,  OS_NPC_NOT_OWNED | OS_NPC_SENSE_AS_AGENT);
                    aviUids += npc;
                    aviNames += mes;
                    llSay(0, "Created "+mes+" " + (string)npc);
                    osNpcMoveToTarget(npc, osNpcGetPos(npc) + <1,0,0>, OS_NPC_NO_FLY );
                }
                else if (userInputState == "WAIT_SELECTAVI")
                {
                    integer idx = llListFindList(aviNames, [""+mes]);
                    if (idx >=0)
                    {
                        aviIndex = idx;
                        npc = llList2Key(aviUids, idx);
                        name = llList2String(aviNames, idx);
                        llSay(0,"Selected " + name + " " + (string)npc);
                    }
                }
                else if (userInputState == "WAIT_REMOVEAVI")
                {
                    //llOwnerSay(llList2CSV(aviNames));
                    integer idx = llListFindList(aviNames, [""+llToLower(mes)]);
                    if (idx >=0)
                    {
                        aviIndex = idx;
                        npc = llList2Key(aviUids, idx);
                        name = llList2String(aviNames, idx);
                        osNpcRemove(llList2Key(aviUids, idx));
                        
                        llSay(0,"Removing " + name + " " + (string)npc);
                        aviUids = llDeleteSubList(aviUids, idx, idx);
                        aviNames = llDeleteSubList(aviNames, idx, idx);
                    }
                    else 
                        llSay(0, "Not found:" + mes);
                }

 
                userInputState="";
            }
        }
   
            
    }
    
    
    http_response(key request_id, integer status, list metadata, string body)
    {
        
        llOwnerSay("Got response/"+body+"/");
        integer idx;
        for (idx=0; idx < llGetListLength(aviUids); idx++)
        {
            if (llList2String(aviStatus, idx) == "http-"+request_id)
            {
            
                list tok = llParseString2List(body, ["|"], ["-"]); 
                //llOwnerSay("data="+body+" list="+llList2CSV(tok));
                key uNPC  = llList2Key(aviUids,idx);
                
                string bestpath = llList2String(tok, 0);
                string origname = llList2String(tok, 1);
                if (llGetSubString(bestpath, 0,0) != ":")
                {
                    osNpcSay(uNPC, "Sorry, i don't know how to get to the "+origname + "");
                }
                else
                {
                    osNpcSay(uNPC, "I am now going to "+origname+". If you want to go there, follow me.");
                    aviPath = llListReplaceList(aviPath, [bestpath], idx, idx);
                    aviTime = llListReplaceList(aviTime, [0], idx, idx);
                    aviStatus = llListReplaceList(aviStatus, ["pathf"], idx, idx);
                }   
            }
        }
        

    }
}

