integer channel = 68;


// Add the first names of your NPCs here. Last name is always "NPC"
list availableNames = [];//"Kelvin", "Berton", "Sartorius"];

// Change this to the URL of your web server (if you have set up one) and remember to change the cityKey to your own key
string BASEURL = "http://opensimworld.com/oscity/?ac=1";


// These will be loaded from notecards
list wNodes = [];
list wLinks = [];

// List of auto-run notecards. The NPC will automatically run the specified notecard when they are in this node
list wAutorunScripts = [

];



//  list of nodes for the "Flyaround" command
list flyTargets = [0,1,2,3,4];


// Put some animations and add their names here for the "dance" command
list dance1 = [
"rock1", 
"rock7" 
];

list customCommands = ["fuck", "wear", "blow"];
list notecardScripts;

// Change this to the key of an object used for the "mark" command
key INDICATOR = "db87ca3d-8403-4c59-bc5e-2e2d31806568";


list menuItems = ["SaveNPC", "LoadNPC", "RemoveNPC", "RemoveAll", "LoadAll", "UploadData", "ReConfig","InitCmds",  "DumpData", "TimerOnOff","Close"];

list allowedUsers; 


key MAT_KEY = "12e632f9-ac6f-4b38-9f71-630bb47df81d";
key RUN_CONTROLLER="6649f153-2bbd-48a2-a39d-70342c126176";
key STADIUM_CONTROLLER="a0887ae1-593e-4660-a4a0-539383218a9a";
integer TIMER_INTERVAL=5;

string userInputState ="";
integer greetTime;
integer gListener;
integer zListener;
integer howmany;
list avis;
integer curVisitors=1;
integer deflectToNode = -1;

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
list scriptVars;
list aviScriptState;
list aviWho; // Who they are interacting with
list aviBotHttp;
list aviBotConvId;
integer aviIndex = -1;
integer a;
integer b;
integer animSetCounter =0;
list seenArchive;

list positionsList;
list greetedAvis;
integer timerRuns;
integer timerRunning;

string name;

key npc;
key avi;
list candidateNode=[];

list animSets = [] ; // Playing animation sets

key getAgentByName(string firstName)
{
        firstName = llToLower(firstName);
        list ag = osGetAvatarList();
        integer howmany = llGetListLength(ag);
        integer i;
        for (i =0; i < howmany; i+=3)
        {
            string name = llList2String(ag, i+2);
            integer sep = llSubStringIndex(name, " ");
            if (llToLower(llGetSubString(name, 0,sep-1)) == firstName)
            {
                return llList2Key(ag, i);
            }
        }
    return NULL_KEY;            
}

integer GetScriptVar(string cmd3)
{
    integer i;
    for (i=0; i < llGetListLength(scriptVars); i+=2)
    {
        if (llList2String(scriptVars,i) == cmd3 )
        {
            return llList2Integer(scriptVars, i+1);
        }
    }
    return 0; // default value;
}

ReloadConfig()
{
    
    allowedUsers = [(string)llGetOwner(), "59fc25d9-1ce8-4d43-8998-025f84f52b89", "e8c50471-56a7-4bfd-b200-bd7a431e73ba"];

    availableNames = llParseString2List(osGetNotecard("__npc_names"), [" ", "\n", ","] , []);
    flyTargets = llParseString2List(osGetNotecard("__fly_targets"), [" ", "\n", ","] , []);
    llOwnerSay("__npc_names: "+llList2CSV(availableNames));
    string ckey = osGetNotecard("__city_key");
    BASEURL += "&cityKey="+llStringTrim(ckey, STRING_TRIM)+"&";
    //llOwnerSay("cityKey="+llStringTrim(ckey, STRING_TRIM));
    
    
    customCommands = [];
    customCommands = llParseString2List(osGetNotecard("__custom_commands"), [" ","\n",","] , []);
    llOwnerSay("customCommands="+llList2CSV(customCommands));
}


integer countVisitors()
{
    list avis = llGetAgentList(AGENT_LIST_REGION, []);
    integer howmany = llGetListLength(avis);
    integer i;
    integer nNew =0;
    for ( i = 0; i < howmany; i++ ) {
        if ( ! osIsNpc(llList2Key(avis, i)) )
        {
            nNew++; // only non-NPC's
            key uu = llList2Key(avis, i);
            string nm = llKey2Name(uu);
            if (nm != "")
            {
                integer fnd = llListFindList(seenArchive, [nm]);
                if (fnd >=0)
                    seenArchive = [] + llListReplaceList(seenArchive, [nm, llGetUnixTime()], fnd, fnd+1);
                else 
                    seenArchive = [] + seenArchive  + [nm, llGetUnixTime()];
            }
        }
    }
    return nNew;
}

doLoadNPC(string mes)
{                 
        integer idx =(GetNPCIndex(mes));
        if (idx >=0)
        {
            llOwnerSay(mes + " is already in region, not loading");
            osNpcStand(llList2Key(aviUids, idx));
            return;
        }
        key unpc = osNpcCreate(mes, "Aeon(NPC)", llGetPos()+<0,0,3>, "APP_"+llToLower(mes),  OS_NPC_NOT_OWNED | OS_NPC_SENSE_AS_AGENT);
        if (unpc != NULL_KEY)
            doAddNpc(mes, unpc);
}

doAddNpc(string name, string unpc)
{

        llOwnerSay( "Adding '"+name+"'");
        aviUids += unpc;
        aviNames += llToLower(name);
        aviNodes += 1;
        aviPrevNodes += 0;
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
        aviWho += ""; //Key
        aviBotHttp += "";
        aviBotConvId += "";
        osNpcMoveToTarget(unpc, osNpcGetPos(unpc) + <1,0,0>, OS_NPC_NO_FLY );
}

doRemoveNpc(string who)
{
        integer idx = GetNPCIndex(who);
        if (idx <0) return;
        
        key u = llList2Key(aviUids, idx);
        aviNames =  [] + llDeleteSubList(aviNames, idx, idx);
        aviUids =  [] + llDeleteSubList(aviUids, idx, idx);
        aviNodes =  [] + llDeleteSubList(aviNodes, idx, idx);
        aviPrevNodes = [] + llDeleteSubList(aviNodes, idx, idx);
        aviFollow = [] + llDeleteSubList(aviFollow, idx, idx); [];
        aviStatus = [] + llDeleteSubList(aviStatus, idx, idx);
        aviTime = [] + llDeleteSubList(aviTime, idx, idx);
        aviDanceAnim = [] + llDeleteSubList(aviDanceAnim, idx, idx);
        aviCurrentAnim = [] + llDeleteSubList(aviCurrentAnim, idx, idx);
        aviSearching = [] + llDeleteSubList(aviSearching, idx, idx);
        aviPath = [] + llDeleteSubList(aviPath, idx, idx);
        aviHttpId = [] + llDeleteSubList(aviHttpId, idx, idx);
        aviAlarm = [] + llDeleteSubList(aviAlarm, idx, idx);
        aviScriptIndex = [] + llDeleteSubList(aviScriptIndex, idx, idx);
        aviScriptText = [] + llDeleteSubList(aviScriptText, idx, idx);
        aviVar1 = [] + llDeleteSubList(aviVar1, idx, idx);
        aviScriptState = [] + llDeleteSubList(aviScriptState, idx, idx);
        aviWho = [] + llDeleteSubList(aviWho, idx, idx);
        aviBotHttp = [] + llDeleteSubList(aviBotHttp, idx, idx);
        aviBotConvId = [] + llDeleteSubList(aviBotConvId, idx, idx);
       
        llOwnerSay("Removing "+who + "");
        osNpcStand(u);
        osNpcRemove(u);
}


setVar(string cmd2, integer cmd3)
{
            integer i;
            for (i=0; i < llGetListLength(scriptVars); i+=2)
            {
                if (llList2String(scriptVars,i) == cmd2)
                { 
                    scriptVars = [] + llListReplaceList(scriptVars, [(integer)cmd3], i+1, i+1);
                    return;
                }
            }
            scriptVars += cmd2;
            scriptVars += (integer)cmd3;
}



integer RescanAvis()
{
        avis = osGetAvatarList();
        howmany = llGetListLength(avis);
        integer i;
        for (i =0; i < howmany; i+=3)
        {
            if (osIsNpc(llList2Key(avis, i)))
            {
                integer sep = llSubStringIndex(llList2Key(avis, i+2), " ");
                string nm = llGetSubString(llList2Key(avis, i+2), 0, sep-1 );
                doAddNpc(nm,  llList2Key(avis, i));
            }
        }
        llOwnerSay(llList2CSV(aviNames));
        llOwnerSay(llList2CSV(aviStatus));
        return llGetListLength(aviUids);
}


LoadMapData()
{
    integer tl = osGetNumberOfNotecardLines("__waypoints");
    integer i;
    wNodes = [];
    wAutorunScripts = [];
    for (i=0; i < tl; i++)
    {
        string line = osGetNotecardLine("__waypoints",i);
        list tok = llParseStringKeepNulls(line, [","], []);
        float x = llList2Float(tok,0);
        if (x>0)
        {
            vector v = <llList2Float(tok,0), llList2Float(tok,1),llList2Float(tok,2)>;
            wNodes += v;
            wNodes += llList2String(tok,3);
            if (llStringLength(llList2String(tok,4)))
            {
                wAutorunScripts += i;
                wAutorunScripts += llList2String(tok,4);
                llOwnerSay("waypoint "+i+ " autorun='"+llList2String(tok,4)+"'");;
            }
            
        }
    }
    llOwnerSay("loaded "+(string)(llGetListLength(wNodes)/2)+" waypoints");
    
    integer tnodes = llGetListLength(wNodes)/2;
    
    wLinks = [];
    tl = osGetNumberOfNotecardLines("__links");
    for (i=0; i < tl; i++)
    {
        string line = osGetNotecardLine("__links",i);
        list tok = llParseString2List(line, [","],"");
        integer a= llList2Integer(tok,0);
        integer b = llList2Integer(tok,1);
        if (a !=b)
        {
            wLinks += [a,b];
        }
    }
    llOwnerSay("loaded "+(string)(llGetListLength(wLinks)/2)+" links");
}


integer GetNPCIndex(string name) /// name is in lowercase
{
    return llListFindList(aviNames, [llToLower(name)]);
}


integer GetWalkTime(float distance)
{
    return llCeil(distance / 2.0);
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


integer GetNPCIndexByUid(key name)
{
    return llListFindList(aviUids, [name]);
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
        if (llStringTrim(line, STRING_TRIM) == toFind)
        {
            foundLine =endIdx;
            jump _foundIdxOut;
        }
    }
    @_foundIdxOut;
    return foundLine;
}


integer FindMatchingEndif(string scriptData, integer afterLine)
{
    integer endIdx;
    list scriptLines = llParseStringKeepNulls(scriptData, ["\n",";"], []);
    string toFind = "end-if";
    integer foundLine = -1;
    string line;
    integer ifLevel=1;
    for  (endIdx = afterLine+1;endIdx < llGetListLength(scriptLines); endIdx++)
    {
        line = llStringTrim(llList2String(scriptLines, endIdx), STRING_TRIM);
        //llOwnerSay("chk '"+llGetSubString(line, 0, 2)+"'");
        if (llGetSubString(line, 0, 1) == "if")
        {
            ifLevel++;
        }
        else if (line == "end-if")
        {
            ifLevel--;
            if (ifLevel==0)
            {
                foundLine =endIdx;
                jump _foundEIIdxOut;
            }
        }
    }
    @_foundEIIdxOut;
    return foundLine;
}


integer GetNodeIndexByName(string nodeName)
{
    integer i=0; 
    for (i=0; i < llGetListLength(wNodes); i+=2)
    {
        if (llToLower(llList2String(wNodes, i+1)) == nodeName)
        {
            return i/2;
        }
    }
    return -1;
}

SetScriptAlarm(integer aviId, integer time)
{
    aviAlarm = [] + llListReplaceList(aviAlarm, [llGetUnixTime() + time], aviId, aviId);
}


doStopNpc(integer idx, key uNPC)
{
    aviStatus = [] + llListReplaceList(aviStatus, [""], idx, idx);
    aviTime = [] + llListReplaceList(aviTime, [0], idx, idx);
    SetScriptAlarm(idx, 30);
    string old_anim =  llList2String(aviDanceAnim, idx);
    list anToStop=llGetAnimationList(uNPC);
    integer stop=llGetListLength(anToStop);
    while (--stop>=0) { osNpcStopAnimation(uNPC,llList2Key(anToStop,stop)); }
    osNpcStopMoveToTarget(uNPC);
    osNpcStand(uNPC);
}



// Handler for all commands coming from chat
integer ProcessNPCCommand(list tokens)
{
    // first token is just "!"
    string sendUid = llList2String(tokens,1);
    string npcName = llToLower(llList2String(tokens,2));
    string name2 = llToLower(llList2String(tokens,3));

    
    integer idx = GetNPCIndex(npcName);
    if (idx <0)
    {
        return 1;
    }
    key uNPC= llList2Key(aviUids, idx);
    if (uNPC == NULL_KEY)
    {
        return 1;
    }
    
    
    if (sendUid != "0000")
    {
        // A human has given us a command - stop whatever we are doing
        //aviScriptIndex = []+llListReplaceList(aviScriptIndex, [-1], idx, idx);
    }
    
    string cmd1= llList2String(tokens,4);
    string cmd2= llList2String(tokens,5);
    
    list userData;
    if (cmd1 == "stop")
    {
        doStopNpc(idx, uNPC);
    }
    else if (cmd1 == "come")
    {
        
        // "Come here"
        doStopNpc(idx, uNPC);
        userData=llGetObjectDetails((key)sendUid, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
        osTeleportAgent(uNPC, llList2Vector(userData, 1) + <1, 0, 0>, <1,1,1>);
        //osNpcMoveTo(uNPC, llList2Vector(userData, 1) + <1, 0, 0>);
        osNpcSay(uNPC, "Coming right over Sir!");

    }
    else if (cmd1 == "stand")
    {
        // Stand up
        aviStatus =  []+llListReplaceList(aviStatus, [""], idx, idx);
        osNpcStand(uNPC);
        osNpcStopMoveToTarget(uNPC);
    }
    else if (cmd1 == "moveto" || cmd1 == "movetov" || cmd1 == "runtovr"|| cmd1 == "movetovr" || cmd1 == "flytov")
    {
        // Walk to the specified waypoint or vector
        vector v;
        if  (cmd1 == "runtovr"||cmd1 == "movetovr")
        {
            // run to somewhere within the volume enclosed by v1 and v2
            vector v1 = (vector) cmd2;
            vector v2 = (vector) llList2String(tokens, 6);
            v.x= v1.x + llFrand(v2.x-v1.x);
            v.y= v1.y + llFrand(v2.y-v1.y);
            v.z= v1.z + llFrand(v2.z-v1.z);
        }
        else if (cmd1 == "movetov" || cmd1 == "flytov" )
        {
            v = (vector)cmd2;
            if (v == ZERO_VECTOR)
            {
                llOwnerSay(npcName + ": "+cmd2+" is not a good position. I am not going there!");
                return 1;
            }
        }
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
            osSetSpeed(uNPC, 0.5);
            if (cmd1 == "flytov")
                osNpcMoveToTarget(uNPC, v + <0,0,1>, OS_NPC_FLY );
            else
                osNpcMoveToTarget(uNPC, v + <0,0,1>, OS_NPC_NO_FLY);
            SetScriptAlarm(idx, GetWalkTime(dist));
        }
    }
    else if (cmd1 == "setvar")
    {
            string cmd3 = llList2String(tokens,6);
            setVar(cmd2, (integer)cmd3);
            return 0;
    }
    else if (cmd1 == "if" || cmd1 == "if-not" || cmd1=="if-prob")
    {
        // Only 1 level of ifs is supported
        // must be followed by 'end-if'
        integer res = 0;
        if (cmd1 == "if-prob")
        {
            if (llFrand(1.0)<(float)cmd2)
                res = 1;
        }
        else if (cmd2 == "name-is")
        {
            integer k;
            res=0;
            for (k=6; k < llGetListLength(tokens); k++)
            {
                if (llToLower(npcName) == llToLower(llList2String(tokens,k)))
                {
                    res=1;
                }
            }
        }
        else if (cmd2 == "is-here")
        {
            integer curNode = llList2Integer(aviNodes,idx);
            integer k;
            res=1;
            for (k=6; k < llGetListLength(tokens); k++)
            {
                    integer nwho = GetNPCIndex(llList2String(tokens,k));
                    if (nwho<0 || llList2Integer(aviNodes, nwho) != curNode)
                    {
                        res=0;
                        jump isHereNotFound;
                    }
            }
            @isHereNotFound;
        }
        else if (cmd2 == "var-is")
        {
            integer k;
            res=0;
            for (k=6; k < llGetListLength(tokens); k+=2)
            {
                string nm = llList2String(tokens,k);
                if (nm == "")  jump varIsBreak;
                string val = llList2String(tokens,k+1);
                if (GetScriptVar(nm) == (integer)val)
                        res =1;
                else 
                {
                    res=0;
                    jump varIsBreak;
                }
            }
            @varIsBreak;
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
                {
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
            integer foundLine = FindMatchingEndif(llList2String(aviScriptText,idx), scrline-1); /// this used to skip a line
            //llOwnerSay("End-if found: "+(string)foundLine);
            if (foundLine == -1)
            {
                llOwnerSay("Error: end-if not found afterr "+cmd1 + " "+cmd2 + "...");
            }
            else
            {
                aviScriptIndex  =  []+llListReplaceList(aviScriptIndex, [foundLine+1], idx, idx);// Go past the end-if -- runs notecards faster 
            }
        }
        return 0;
    }
    else if (cmd1 == "end-if")
    {
        // Do nothing
        //llOwnerSay("Endif");
        return 0;
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
            aviScriptIndex  = []+llListReplaceList(aviScriptIndex, [foundLine], idx, idx);
        }
        return 0;
    }
    else if (cmd1 == "summon")
    {
            string where = cmd2 ;
            //llToLower(llStringTrim(llList2String(tokens,6) +" "+ llList2String(tokens,7) +" "+ llList2String(tokens,8), STRING_TRIM));        
            integer widx = llListFindList(wNodes, [cmd2]);
            if (widx>=0)
            {
                aviScriptIndex  = []+llListReplaceList(aviScriptIndex, [-1], idx, idx);
                aviNodes = []+llListReplaceList(aviNodes, [widx/2], idx, idx);
                aviStatus = []+llListReplaceList(aviStatus, ["wander"], idx, idx);
                osNpcStand(uNPC);
                osNpcStopMoveToTarget(uNPC);
                osTeleportAgent(uNPC, llList2Vector(wNodes, widx+1), <0,0,0>);
                SetScriptAlarm(idx, -10000);
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
                        jump gotoCmdBreak;
                    }
                }
            }
            @gotoCmdBreak;
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
        aviStatus = []+ llListReplaceList(aviStatus, ["http-"+httpid], idx, idx);
        llOwnerSay("Sending out /"+url+"/");
        
    }
    else if (cmd1 == "waitvar")
    {
            // Wait until the value of variable named cmd2 reaches the value cmd3
            string cmd3 = llList2String(tokens,6);
            if (GetScriptVar(cmd2) == (integer)cmd3)
            {
                    return 1; /// OK continue with the next line
            }

            integer scriptIndex = llList2Integer(aviScriptIndex, idx);
            if  (scriptIndex>0)
            {
                aviScriptIndex = []+llListReplaceList(aviScriptIndex, [scriptIndex-1], idx, idx);
            }
    }
    else if (cmd1 == "wait")
    {
        // cause the script to wait for <arg> (to optionally arg3) seconds
        integer tm = (integer)cmd2;
        integer tm2 = (integer)llList2String(tokens,6);
        if (tm2>0)
        {
            tm = (integer)(tm + llFrand(tm2));
        } 
        SetScriptAlarm(idx,  tm);
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
    else if (cmd1 == "saych")
    {
        // Say something on chat
        string txt = "";
        integer i;
        for (i=6; i < llGetListLength(tokens); i++)
            txt += llList2String(tokens,i) + " ";
        osNpcSay(uNPC,  llList2Integer(tokens,5), txt);
    }
    else if (cmd1 == "exec")
    {
        list tok2 = ["!", "0000", cmd2] + llList2List(tokens, 5, -1);
        //llOwnerSay("String="+llList2CSV(tok2));
        ProcessNPCCommand(tok2);
    }
    else if (cmd1 == "mark")
    {
        // Move the indicator object to the specified waypoint (used for debugging the map)
        integer l=0;
        userData=llGetObjectDetails((key)sendUid, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
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
    else if (cmd1 == "msgatt")
    {

        list points = [];
        integer i;
        for (i=6; i < llGetListLength(tokens); i++)
        {
            if (llList2Integer(tokens, i)>0)
            {
                points += llList2Integer(tokens,i);
            }
        }
        //llOwnerSay("msg="+cmd2+" points="+llList2CSV(points));
        osMessageAttachments(uNPC, cmd2, points, 0);
    }
    else if (cmd1 == "teleport")
    {
        vector w = (vector) cmd2;
        if (w == ZERO_VECTOR)
        {
            integer where = GetNodeIndexByName(cmd2);
            if (where >=0)
            {
                w = llList2Vector(wNodes, where*2);
                osTeleportAgent(uNPC, w, <0,0,0>);
                //osNpcMoveTo(uNPC, w);
            }
        }
        else osTeleportAgent(uNPC, w, <0,0,0>);
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
        vector v;
        if (cmd2=="me")
        {
            userData=llGetObjectDetails((key)sendUid, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            v = llList2Vector(userData,1);
        }
        else
        {
            v = (vector)cmd2;
            if  (v == ZERO_VECTOR)
            {
                integer midx = GetNodeIndexByName(llToLower(cmd2));
                if (midx >=0)
                {
                    v = llList2Vector(wNodes, midx*2);
                }
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
        aviScriptText =  []+llListReplaceList(aviScriptText, str, idx, idx);
        aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [1], idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (cmd1 == "forcesit")
    {
        osForceOtherSit((key)cmd2, (key)llList2String(tokens, 6));
    }
    else if (cmd1 == "unsit")
    {
        llUnSit((key)cmd2);
    }
    else if (cmd1 == "moveprim")
    {
        osMessageObject((key)cmd2, "SETPOS "+(llList2String(tokens,6)) + " "+llList2String(tokens,7));
        //osSetPrimitiveParams((key)cmd2, [PRIM_POSITION, (vector)llList2String(tokens,6)]);
    }
    else if (cmd1 == "follow")
    {
        aviStatus =  []+llListReplaceList(aviStatus, ["follow"], idx, idx);
        if (cmd2=="me" || cmd2=="")
        {
            
            userData=llGetObjectDetails((key)sendUid, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            aviFollow =  []+llListReplaceList(aviFollow, [(key)sendUid], idx, idx);
            osNpcSay(uNPC, "Following you Sir "+ llList2String(userData, 0));
        }
        else
        {
            key who = getAgentByName(cmd2);
            if (who != NULL_KEY)
            {
                    aviFollow =  []+llListReplaceList(aviFollow, [who], idx, idx);
                    osNpcSay(uNPC, "Following " + cmd2);
            }
        }

    }
    else if (cmd1 == "set-state") // set a variable that indicates the current state of an NPC -- useful for scripts
    {
        aviScriptState=  []+llListReplaceList(aviScriptState, [cmd2], idx, idx);
        return 0;
    }
    else if (cmd1 == "debug")
    {
        integer dd = llList2Integer(aviScriptIndex, idx);
        string scr;
        if  (dd >=0)
        {
            scr = GetScriptLine(llList2String(aviScriptText,idx) , dd);
        }
        llOwnerSay("Status="+llList2String(aviStatus, idx)+" node = "+llList2Integer(aviNodes, idx)+
            " follow="+llList2String(aviFollow, idx)+" Alarm = "+(string)(llList2Integer(aviAlarm,idx)-llGetUnixTime())+
            " scriptIndex="+llList2Integer(aviScriptIndex, idx)+" scriptText " +scr );
    

    }
    else if (cmd1 == "var1") // Do something on the counter var1
    {
            if (cmd2 == "++" || cmd2 == "--")
            {
                integer var1 = llList2Integer(aviVar1, idx);
                if (cmd2 == "--") --var1;
                else ++var1;
                aviVar1=  []+llListReplaceList(aviVar1, [var1], idx, idx);
            }
            else if (cmd2 == "zero")
            {
                aviVar1=  []+llListReplaceList(aviVar1, [0], idx, idx);
            }
            else
                llOwnerSay("Unknown: "+ cmd2);
    }
    else if (cmd1 == "fly" && cmd2=="with")  // "fly with me" "fly with Foo"
    {
        string who = llList2String(tokens, 6);
        if (who == "me")
        {
            aviFollow =  []+llListReplaceList(aviFollow, [(key)sendUid], idx, idx);
        }
        else
        {
            key w = getAgentByName(who);
            if (w != NULL_KEY)
            {
                aviFollow =  []+llListReplaceList(aviFollow, [w], idx, idx);

            }
        }
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
        osNpcStand(uNPC);
        aviNodes =  []+llListReplaceList(aviNodes, [GetNearestNode(osNpcGetPos(uNPC))], idx, idx);
        aviStatus =  []+llListReplaceList(aviStatus, ["wander"], idx, idx);
    }
    else if (cmd1 == "flyaround")
    {
        // Start flying about between the waypoints in the "flyTargets" list -- useful for birds
        aviStatus =  []+llListReplaceList(aviStatus, ["godfly"], idx, idx);
        osNpcSay(uNPC, "Flying like an eagle!!");

    }
    else if (cmd1 == "dance")
    {
        //Drop a few dance animations in the controller object and change the "dance1" list at the top. This will start cycling the dances

        aviStatus =  []+llListReplaceList(aviStatus, ["dance"], idx, idx);
        osNpcSay(uNPC, "Oh, with pleasure Sir!");
        aviTime =  []+llListReplaceList(aviTime, [0], idx, idx);        
        osNpcStand(uNPC);
        string old_anim = llList2String(aviDanceAnim, idx);
        osNpcStopAnimation(uNPC, old_anim);
    }
    else if (cmd1 == "run-notecard")
    {
        // Run the script contained in the notecard <argument>
        string stext= osGetNotecard(cmd2 );
        aviStatus=  []+llListReplaceList(aviStatus, "", idx, idx);
        if (stext == "")
        {
            osNpcSay(uNPC,"Could not load notecard '"+cmd2+"'");
            return 1;
        }
        aviScriptText =  []+llListReplaceList(aviScriptText, stext, idx, idx);
        aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [1], idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (cmd1 == "stop-script")
    {
        // Stop executing the script and exit
        aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [-1], idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (cmd1 == "dress")
    {
        string suff = "";
        if (cmd2 != "") suff += "_"+cmd2;
        string nm = llList2String(aviNames, idx);
        llOwnerSay("Loading appearance "+"APP_"+nm+suff);
        osNpcLoadAppearance(uNPC, "APP_"+nm+suff);
    }
    else if (cmd1 == "seen")
    {
        integer i;
        if (cmd2 == "all")
        {
            for (i=0; i < llGetListLength(seenArchive); i+=2)
                osNpcSay(uNPC, "I saw "+ llList2String(seenArchive,i) + "  "  + TimeAgo(llList2Integer(seenArchive,i+1) ));
            return 1;
        }
        else
        {
            for (i=0; i < llGetListLength(seenArchive); i+=2)
            {
                if (llSubStringIndex(llToLower(llList2String(seenArchive,i)), llToLower(cmd2))>=0)
                {
                    osNpcSay(uNPC, "I saw "+ llList2String(seenArchive,i) + " around "  + TimeAgo(llList2Integer(seenArchive,i+1) ));
                    return 1;
                }
            }
        }
        osNpcSay(uNPC, "I haven't seen "+ cmd2 + " around");
    }
    else if (cmd1 == "clothing")
    {
        
        osMessageAttachments(uNPC, cmd2, [ATTACH_AVATAR_CENTER], 0); 
    }
    else if (llGetSubString(cmd1,0,0) == "@")
    {
        // It's a label; do nothing
        return 0;
    }
    else
    {
        integer nc = llListFindList(customCommands, [llToLower(cmd1)]);
        if (nc>=0)
        {    
            aviStatus = [] + llListReplaceList(aviStatus, [""], idx, idx);
            llMessageLinked(LINK_ALL_CHILDREN, 0, llList2CSV(tokens), uNPC);
        }
        else 
        {
            
             // have we started a conversation yet?
             key conversationRequest;
             string programoURL="http://hookkk.com/chatbot/chatbot/conversation_start.php?say=";
             
             string message = llDumpList2String(llList2List(tokens, 4, llGetListLength(tokens))," ");
             
             string conversationID = llList2String(aviBotConvId, idx);
             if (conversationID == "")
                conversationRequest = llHTTPRequest(programoURL
                    + llEscapeURL(message)
                    + "&bot_id=1&format=json"
                    , [HTTP_METHOD, "GET", HTTP_MIMETYPE, "plain/text;charset=utf-8"], "");
             else // use the convo_id we have
                conversationRequest = llHTTPRequest(programoURL
                    + llEscapeURL(message)
                    + "&convo_id=" + conversationID
                    + "&bot_id=1&format=json"
                    , [HTTP_METHOD, "GET", HTTP_MIMETYPE, "plain/text;charset=utf-8"], "");   
                    
             aviBotHttp = [] + llListReplaceList(aviBotHttp, [conversationRequest], idx, idx);
             
        }
        //osNpcSay(uNPC, "I do not know how to "+cmd1+". Say '"+npcName+" help' for more");
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

    osSetSpeed(uuid, 0.5);
    osNpcMoveToTarget(uuid, tgt, OS_NPC_NO_FLY);
    
    aviTime =[]+ llListReplaceList(aviTime, [ llGetUnixTime() + GetWalkTime( llVecDist(wp, tgt) )+4], idx, idx);
    aviNodes = []+llListReplaceList(aviNodes, [nt], idx, idx);
    aviPrevNodes = []+llListReplaceList(aviPrevNodes, [curNode], idx, idx);
    return 0;
}


integer ExecScriptLine(string aviName, string scriptline)
{
    // The token list expects the name of the avi twice. we use 0000 as the sending-uid identifier
    string command = "! 0000 " + aviName+" "+ aviName + " " + scriptline;
    list tokens = llParseString2List(command, [" "], [] );
    return ProcessNPCCommand(tokens);
}



string TimeAgo(integer time)
{
    // time difference in seconds
    integer now = llGetUnixTime();
    integer timeDifference = now - time;
    // small bug fix for when timeDifference is 0
    if (timeDifference == 0)
        return "just now";
 
    list periods = ["second",        "minute",        "hour",        "day",        "week",        "month",        "year",        "decade"];
 
    //the number equivalent to periods
    list lenghts = [1,        60,        3600,        86400,        604800,        2630880,        31570560,        315705600];
 
    integer v = llGetListLength(lenghts) - 1;
    integer no;
 
    while((0 <= v) && (no = timeDifference/llList2Integer(lenghts, v) <= 1))    --v; 
    string output = llList2String(periods, v);
 
    //this will get the correct time in periods, then divide the timeDifference
    integer ntime = timeDifference / llList2Integer(lenghts, llListFindList(periods, [output]));
 
    //if integer 'no' is not equal to 1 then it should have an s at the end
    if(no != 1)
        output += "s";
 
    //This produces the finished output
    output = (string)ntime + " "+ output + " ago";
    return output;
}


default
{

    state_entry()
    {
        llSetText("NPCs", <1,1,1>,1.0);
        llListenRemove(gListener);
        gListener = llListen(channel, "", "", "");
        llOwnerSay("Listening on channel "+channel);
        ReloadConfig();
        LoadMapData();
        //llOwnerSay(llList2CSV(wNodes));
        //llOwnerSay(llList2CSV(wLinks));
        timerRuns=0;
        RescanAvis();
        greetedAvis = [];
        scriptVars = [];
        llSetTimerEvent(TIMER_INTERVAL);
    }
    
    touch_start(integer num)
    {
        avi = llDetectedKey(0);
        if (llListFindList(allowedUsers, (string)avi)<0)
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
        list startedScripts = [];
        if (curVisitors>0)
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
                        aviStatus=  []+llListReplaceList(aviStatus, [ "" ], g, g);
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
                            if (llGetUnixTime() >  llList2Integer(aviAlarm, g) + 30)
                            {
                                if (llListFindList(startedScripts, curNode)>=0)
                                {
                                    // dont start the same script simultaneously
                                }
                                else
                                {
                                    integer widx = llListFindList(wAutorunScripts, curNode);
                                    if (widx >=0)
                                    {
                                        if (deflectToNode<0 || deflectToNode == curNode || (llFrand(1.0) <  0.0)  )
                                        {
                                            startedScripts+= curNode;
                                            ExecScriptLine(llList2String(aviNames, g), "run-notecard "+llList2String(wAutorunScripts,widx+1));
                                            shouldMove =0;
                                        }                                 
                                    }                                
                                }
                            }
                            
                            if (shouldMove>0)
                            {
                               if (llFrand(1.0) < 0.03)
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
                        //if (llFrand(1.0)<.4)
                        //    flag = OS_NPC_FLY|OS_NPC_LAND_AT_TARGET;
                        integer theight = 10;
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
                            
                            aviStatus =  []+llListReplaceList(aviStatus, [ "" ], g, g);
                            
                            // continue the script (if any), since we reached our destination
                            SetScriptAlarm(g, 0); 

                        }
                        else
                        {
                            integer nextTgt = llList2Integer(pnodes, 0);
                            string ndleft = ":"+llDumpList2String( llList2List(pnodes, 1, llGetListLength(pnodes)), ":");


                            aviPath =  []+llListReplaceList(aviPath, [ ndleft ], g, g);
                            vector v = llList2Vector(wNodes, 2*nextTgt);              
                            aviTime =  []+llListReplaceList(aviTime, [ llGetUnixTime() + GetWalkTime(llVecDist(p, v)) ], g, g);
                            

              
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
                        aviTime =  []+llListReplaceList(aviTime, [ts], g, g);
                        
                        string old_anim = llList2String(aviDanceAnim, g);
                        integer newidx = (integer)llFrand(llGetListLength(dance1));
                        string new_anim =  llList2String(dance1, newidx);
                        
                        //llOwnerSay("Switching to dance " + new_anim);
                        
                        osNpcStopAnimation(npc, old_anim);
                        osNpcPlayAnimation(npc, new_anim);
                        aviDanceAnim =  []+llListReplaceList(aviDanceAnim, [ new_anim ], g, g);
                    }
                }
                else
                {
                    //
                }
                
                
                // Execute the next script line if a script is active
                integer stopNow=0;
                integer k;
                for (k=0; k < 5 && stopNow==0; k++) // execute up to 5 lines at once if possible
                {
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
                                    aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [-1], g, g);
                            }
                            else
                            {
                                // Set the timer for the next command 1 second later by default. Some commands will override this (e.g. go to, wait).
                                SetScriptAlarm(g, 1);
                                stopNow = ExecScriptLine( llList2String(aviNames, g), scriptline);
                                // Advance script pointer 
                                scriptIndex = llList2Integer(aviScriptIndex, g); 
                                aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [scriptIndex+1], g,g);
                            }
                        }
                    }
                }
                
                llParticleSystem(
                [
                    PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,0,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    PSYS_SRC_TARGET_KEY,llGetKey(),
                    PSYS_PART_START_COLOR,<1.000000,0.000000,0.000000>,
                    PSYS_PART_END_COLOR,<1.000000,0.000000,0.000000>,
                    PSYS_PART_START_ALPHA,1,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
                    PSYS_PART_START_SCALE,<0.500000,0.500000,0.000000>,
                    PSYS_PART_END_SCALE,<4.000000,4.000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,0.5,
                    PSYS_PART_MAX_AGE,2,
                    PSYS_SRC_BURST_RATE,1,
                    PSYS_SRC_BURST_PART_COUNT,1,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_BURST_SPEED_MIN,0,
                    PSYS_SRC_BURST_SPEED_MAX,0,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
                
        }
        
        timerRuns++;
        if (timerRuns%20==0)
        {
            curVisitors = countVisitors();
        }
    }
    


    listen(integer chan, string name, key id, string str) {    // WARNING "id" is not the uid of the NPC-sender

        list tok = llParseString2List(str, [" "] , [""]);
        string mes = llList2String(tok, 0);
        
        if  (mes == "SaveNPC")
        {
            llDialog(avi, "Select NPC to save your appearance", llList2List(availableNames, 0,10)+ "more", channel);       

            userInputState = "WAIT_APPNAME";
        }
        else if (mes == "LoadNPC")
        {
            llDialog(avi, "Select an NPC to load", llList2List(availableNames, 0,10)+"more", channel);     
            userInputState = "WAIT_AVINAME";
        }
        else if (mes == "RemoveNPC")
        {
            llDialog(avi, "Select an NPC to delete",  llList2List(availableNames, 0,10)+ "more", channel); 
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
                    osNpcStand(llList2Key(avis, i));
                    osNpcRemove(llList2Key(avis, i));
                }
            }
            aviUids = [];
            aviNames = [];
        }
        else if (mes == "LoadAll")
        {
            llSetTimerEvent(0);
            integer i;
            avis = osGetAvatarList();
            llOwnerSay(llList2CSV(avis));
            howmany = llGetListLength(avis);
            for (i =0; i < howmany; i+=3)
            {
                if (osIsNpc(llList2Key(avis, i)))
                {
                    osNpcStand(llList2Key(avis, i));
                }
            }
            
            for (i=0; i < llGetListLength(availableNames);i++)
            {
                doLoadNPC(llList2String(availableNames, i));
            }
            llSetTimerEvent(TIMER_INTERVAL); 
        }
        else if (mes == "InitCmds")
        {    
            string notecard= "__initcommands";
            integer i;
            llSetTimerEvent(0);
            for(i=0; i<=osGetNumberOfNotecardLines(notecard); i++) {
                
                string line = osGetNotecardLine(notecard, i);
                if (llStringLength(line)>0 && line != "")
                {
                    list toks = llParseString2List(line, [" "], []);
                    if (llGetListLength(toks)>1)
                    {
                        list tok2 = ["!", "0000", llList2String(toks, 0)]; /// Need name of npc twice
                        tok2 += toks;
                        llOwnerSay("InitCmd="+llList2CSV(tok2));
                        ProcessNPCCommand(tok2);
                    }
                }
            }
            llSetTimerEvent(TIMER_INTERVAL);
        }
        else if (mes == "TimerOnOff")
        {
            timerRunning = !timerRunning;
            llSetTimerEvent(TIMER_INTERVAL*timerRunning);
            llOwnerSay("Timer="+(string)timerRunning);
        }
        else if (mes == "DumpData")
        {
            llOwnerSay("Names="+llList2CSV(aviNames));
            llOwnerSay("Status="+llList2CSV(aviStatus));
            llOwnerSay("Nodes="+llList2CSV(aviNodes));
            llOwnerSay("PrevNodes="+llList2CSV(aviPrevNodes));            
            llOwnerSay("ScriptIndex="+llList2CSV(aviScriptIndex));
            llOwnerSay("Alarm="+llList2CSV(aviAlarm));
            llOwnerSay("Curvisitors="+(string)(curVisitors)+ " Timer=" +timerRunning+" timerRuns="+(string)timerRuns);        
            llOwnerSay("Vars="+llList2CSV(scriptVars));
           // llSetTimerEvent(0.0);
        }
        else if (mes == "ReConfig")
        {
            ReloadConfig();
            LoadMapData();
        }
        else if (mes == "UploadData")
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
            
            // Upload the map links to the web server
            //list lst; 
            //integer i;
            //integer j;
            wpdata="";
            wpname="";
            wpdata = llList2CSV(wLinks);
            
            llHTTPRequest(BASEURL+"act=updateLinks", [HTTP_METHOD, "POST"], ""+wpdata);
            llOwnerSay("Length="+llStringLength(wpdata));

            
        }
        else if (mes == "deflectTo")
        {
            deflectToNode = GetNodeIndexByName(llToLower(llList2String(tok,1)));
            llOwnerSay("Deflecting to #"+(string)deflectToNode);
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
        else if (mes == "SETVAR")
        {
          setVar(llList2String(tok,1), (integer)llList2String(tok,2));
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
                        aviStatus =  []+llListReplaceList(aviStatus, ["sitting"], idx, idx);
                        jump ballFound;
                }
            }          
            llOwnerSay(npcname + ": All balls transparent");  
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
                    osAgentSaveAppearance(avi, "APP_"+llToLower(mes));
                    llSay(0,  "Saved Appearance " + avi + " -> APP_"+llToLower(mes));
                }
                else if (userInputState == "WAIT_AVINAME")
                {
                    doLoadNPC(mes);

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
                    doRemoveNpc(mes);
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
                    aviPath = []+ llListReplaceList(aviPath, [bestpath], idx, idx);
                    aviTime =  []+llListReplaceList(aviTime, [0], idx, idx);
                    aviStatus =  []+llListReplaceList(aviStatus, ["pathf"], idx, idx);
                } 
                return; 
            }
        }
        
        // Must be a bot response
        idx = llListFindList(aviBotHttp, [request_id]);
        if (idx >=0)
        {
            key uNPC  = llList2Key(aviUids,idx);
            string conversationID = llGetSubString(body, 13, 34);
            string botReply  = llGetSubString(body,  llSubStringIndex(body, "\"botsay\":\"") + 10, -3);
            osNpcSay(uNPC, botReply);
            aviBotConvId = []+ llListReplaceList(aviBotConvId, [conversationID], idx, idx);
        }

    }
    
    
    link_message(integer lnk, integer num, string command, key npc) // This script is in the object too.
    {
        list tokens = llParseString2List(command, [" "], [] );
        llOwnerSay("Root: "+command);
        ProcessNPCCommand(tokens);
    }

    changed(integer change)
    {
        if (change & CHANGED_REGION_START)
        {
            llResetScript();
        }
    }    

}

