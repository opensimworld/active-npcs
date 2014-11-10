
integer channel = 68;

// Enter a list of names of your avatars. For each one you need to save a notecard by clicking on the controller object
// and selecting "SaveAvi". The full name of the avatar will be "Foo NPC"
list availableNames = ["Foo", "Bar", "John", "Doe"];

// Base url in case you use an external http server for the "goto" command
string BASEURL = "http://opensimworld.com/oscity/?ac=1&cityKey=&";


// The contents of these lists are loaded from the "waypoints" and "links" notecards
list wNodes = [];
list wLinks = [];


// Specify a list of targets for the "flyfollow" command. The numbers are the waypoing number, i.e. the line number that
// correspond to the node in the "waypoints" notecard
list flyTargets = [7, 9, 10,  13, 14, 15, 16, 17, 18, 19, 20, 21 , 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33,  35,36,37,38,39,40,41,42];


// Specify notecards to execute at specific map points
// When an avi reaches this node, it will execute the notecard.
list wAutorunScripts = [
3, "gym.scr"
];


// Put some dance animations in the controller object and add their names here
list dance1 = [
"Modern 01", 
"Modern 02", 
"Modern 03", 
"Modern 04"
];



// Put the key of an object that you can use to mark map points by using the "mark" command
key INDICATOR = "db87ca3d-8403-4c59-bc5e-2e2d31806568";


// Dialog commands
list menuItems = ["SaveAvi", "LoadAvi", "RemoveAvi", "RemoveAll", "Rescan",  "TimerOff", "UploadWP", "UploadLnk", "ReloadMap", "Close"];

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
integer aviIndex = -1;
integer a;
integer b;

list greetedAvis;
integer timerRuns;

string name;

key npc;
key avi;
list candidateNode=[];



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


integer GenPath(integer a, integer tgt, string path, list foundPaths, integer depth)
{
    
    //llOwnerSay("genPath "+a+", "+tgt+", "+opath + ", " + depth);
    //string path = opath;
    if (depth > 10) 
    {
        //llOwnerSay("Break after " + (path));
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

            if (llSubStringIndex(path, ":"+fn+":")<0) // llListFindList(path, [fn])<0)
            {
                //llOwnerSay("Dive "+ fn);
                if (fn == tgt)
                {
                    path += ""+fn+":";
                    llOwnerSay("Found " + (path));
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

SetScriptAlarm(integer aviId, integer time)
{
    aviAlarm = llListReplaceList(aviAlarm, [llGetUnixTime() + time], aviId, aviId);
}



integer ProcessNPCCommand(list tokens)
{
    //list tokens = llParseString2List(mes,[" "],["."]);
    // first is just !
    string sendUid = llList2String(tokens,1);
    string npcName = llToLower(llList2String(tokens,2));
    string name2 = llToLower(llList2String(tokens,3));
    
    //integer nmend = llSubStringIndex(mes, " ");
    //if  (nmend <0 || nmend > 50) return 0;
    //string npcName = llGetSubString(mes, 37, nmend-1);
    
    integer idx = GetNPCIndex(npcName);
    if (idx <0)
    {
        return 3;
    }
    key uNPC= llList2Key(aviUids, idx);
    
    //llOwnerSay("NPCNAME='"+npcName+"'");
    
    string cmd1= llList2String(tokens,4);
    string cmd2= llList2String(tokens,5);
    
    //llOwnerSay("UID='"+sendUid+"' npcName='"+npcName+"' CMD='"+cmd1+"' '"+cmd2+"'");

    list userData = llGetObjectDetails((key)sendUid, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
    //llOwnerSay("U"+ llList2String(userData, 0)+ " at "+ (string)llList2Vector(userData,1) + " -> command "+cmd);
    string org = llList2String(userData, 0);

    if (llToLower(npcName) == "ares"  && org != "Satyr Bator")
    {
        //osNpcSay(uNPC, "I am Ares the God of War! I do NOT take orders!"); 
        //return 1;
    }
    

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
    else if (cmd1 == "var1")
    {
            if (cmd2 == "++" || cmd2 == "--")
            {
                integer var1 = llList2Integer(aviVar1, idx);
                if (cmd2 == "--") ++var1;
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
    else if (cmd1 == "fly" && cmd2=="with")
    {
        string who = llList2String(tokens, 6);
        if (who == "me")
        {
            aviFollow = llListReplaceList(aviFollow, [(key)sendUid], idx, idx);
        }
        else
        {
            aviFollow = llListReplaceList(aviFollow, [llList2Key(aviUids, GetNPCIndex(who))], idx, idx);
        }
        aviStatus = llListReplaceList(aviStatus, ["flyfollow"], idx, idx);
        osNpcSay(uNPC, "OK");

    }
    else if (cmd1 == "help")
    {
        osNpcSay(uNPC, "Say '"+ npcName+ " <command>', where <command> can be: 'follow me', 'fly with me', 'do', 'go to', 'wear', 'drop', 'dance', 'stand up', 'stop', 'light', 'leave'.");
    }
    else if (cmd1 == "leave")
    {
        // Start wandering
        aviNodes = llListReplaceList(aviNodes, [GetNearestNode(osNpcGetPos(uNPC))], idx, idx);
        aviStatus = llListReplaceList(aviStatus, ["wander"], idx, idx);
        string nm = llList2String(userData, 0);
        osNpcSay(uNPC, "Goodbye!");

    }
    else if (cmd1 == "flyaround")
    {
        
        //aviFollow = llListReplaceList(aviFollow, [(key)sendUid], idx, idx);
        aviStatus = llListReplaceList(aviStatus, ["flyaround"], idx, idx);
        string nm = llList2String(userData, 0);
        osNpcSay(uNPC, "Flying around like an eagle!");

    }
    else if (cmd1 == "dance")
    {
        aviStatus = llListReplaceList(aviStatus, ["dance"], idx, idx);
        osNpcSay(uNPC, "Oh, with pleasure Sir!");
        aviTime = llListReplaceList(aviTime, [0], idx, idx);
        
        osNpcStand(uNPC);
        string old_anim = llList2String(aviDanceAnim, idx);
        osNpcStopAnimation(uNPC, old_anim);
    }
    else if (cmd1 == "stop")
    {
        aviStatus = llListReplaceList(aviStatus, [""], idx, idx);
        osNpcSay(uNPC, "OK!");
        aviTime = llListReplaceList(aviTime, [0], idx, idx);
        string old_anim = llList2String(aviDanceAnim, idx);

        integer d;
        for  (d=0; d < llGetListLength(dance1); d++)
        {
            //llOwnerSay("Stopping " + old_anim);
            osNpcStopAnimation(uNPC, llList2String(dance1, d));
        }
        osNpcStopMoveToTarget(uNPC);
        osNpcStand(uNPC);
        osSetSpeed(uNPC, 1.0);
    }
    else if (cmd1 == "come")
    {
        //aviFollow = llListReplaceList(aviFollow, [(key)sendUid], idx, idx);
        //aviStatus = llListReplaceList(aviStatus, ["follow"], idx, idx);
        osNpcStand(uNPC);
        osTeleportAgent(uNPC, llList2Vector(userData, 1) + <1, 0, 0>
, <1,1,1>);
        osNpcSay(uNPC, "Coming right over!");

    }
    else if (cmd1 == "stand")
    {
        aviStatus = llListReplaceList(aviStatus, [""], idx, idx);
        osNpcSay(uNPC, "OK!");
        //osNpcStopAnimation(uNPC, "assupB");
        //osNpcPlayAnimation(uNPC, "stand1");
        osNpcStand(uNPC);
        vector tgt = osNpcGetPos(uNPC) + <2,0,0>*osNpcGetRot(npc);
        osNpcMoveToTarget(uNPC, tgt, OS_NPC_NO_FLY );
    }
    else if (cmd1 == "moveto" || cmd1 == "movetov" || cmd1 == "runtovr")
    {
        vector v;
        if  (cmd1 == "runtovr")
        {
            // Run to somewhere within the volume enclosed by v1 and v2
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
        osNpcStand(uNPC); 
        osNpcStopMoveToTarget(uNPC);
        if (cmd1 == "runtovr")
        {
            osNpcMoveToTarget(uNPC, v + <0,0,1>, OS_NPC_NO_FLY | OS_NPC_RUNNING);
            SetScriptAlarm(idx, (integer)(GetWalkTime(dist)/2.0));
        }
        else
        {
            osNpcMoveToTarget(uNPC, v + <0,0,1>, OS_NPC_NO_FLY );
            SetScriptAlarm(idx, GetWalkTime(dist));
        }
        
        
    }
    else if (cmd1 == "if" || cmd1 == "if-not")
    {
        // Only 1 level of ifs is supported
        string what = cmd2;
        integer res = 0;
        if (cmd2 == "name-is")
        {
            if (llToLower(npcName) == llToLower(llList2String(tokens,6)))
            {
                res=1;
            }
            llOwnerSay("Name-is:" + llList2String(tokens,6));
        }
        else if (cmd2 == "var1-gt" || cmd2 == "var1-lt" || cmd2=="var1-eq")
        {
            integer var1 =llList2Integer(aviVar1, idx);
            integer val  =(integer)llList2String(tokens, 6);
            
            if (cmd2=="var1-gt" && var1>val) res=1;
            else if (cmd2=="var1-lt" && var1  < val) res=1;
            else if (cmd2=="var1-eq" && var1 == val) res=1;
        }
        
        if (cmd1 == "if-not")
            res = !res;
        llOwnerSay("res-is:" + (string)res);
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
        //integer scrline = llList2Integer(aviScriptIndex, idx);
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
        //The go to/goto commands perform interpolation between the map points. However this requires 
        // an external web server. We have provided an alternative LSL function above (GetGotoPath()) , but 
        //it is too slow. Use the PHP scripts we provide for faster performance.
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
            for (i=0; i < llGetListLength(wNodes); i+=2)
            {
                if (llToLower(llList2String(wNodes,i+1)) == where)
                {
                    foundId = (integer)i/2;
                    jump fbreak;
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
        // Set an alarm for later
        SetScriptAlarm(idx, (integer) cmd2);
    }
    else if (cmd1 == "repeat")
    {
        // Go back to the beginning of script
        SetScriptAlarm(idx, 0);
    }
    else if (cmd1 == "say")
    {
        string txt = "";
        integer i;
        for (i=5; i < llGetListLength(tokens); i++)
            txt += llList2String(tokens,i) + " ";
        osNpcSay(uNPC, txt);
    }
    else if (cmd1 == "mark")
    {
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
    else if (cmd1 == "wear" || cmd1 == "drop")
    {
                
        // Example wear / drop command. Tailor this according to your attached clothing
        // For these to work, you must add the clotheslistener script to your attached clothes
        // In this example, the avis wear a an a toga in the chest and pelvis, a helment in the head, a shield in the left 
        // hand and a spear in the right hand
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
        else if (what == "toga") 
            osMessageAttachments(uNPC, com, [ATTACH_CHEST, ATTACH_PELVIS], 0);
        else if (what == "armour") // should be armour
        {
           osMessageAttachments(uNPC, com, [ATTACH_LHAND, ATTACH_RHAND, ATTACH_HEAD], 0);
        }
        else
            osNpcSay(uNPC, "Say '"+npcName+" "+cmd1+" <item>', <item> can be: helmet, shield, spear, toga, armour");
    }
    else if (cmd1 == "do") // Sit on the poseball having the name specified as the second argument
    {
            // E.G. assuming there are 2 poseballs named 'bar-sit' nearby
            // entering "Foo do bar-sit"
            // will cause the NPC to sit on the first poseball that is not transparent
       if (cmd2 == "")
       {
           osNpcSay(uNPC, "When i am near a pose ball, say '"+npcName+" do <ball label>' and i will sit on it. If using a menu-driven bed or mat, say '"+npcName+" sit' and i will hop on.");
       }
       else
       {
           string cmd = llStringTrim(cmd2+" "+llList2String(tokens, 6)+" "+llList2String(tokens,7), STRING_TRIM);
           // There may be multiple balls with the same name, the avatar will sit on the first one that 
           // is not transparent
           osMessageAttachments(uNPC, "do "+cmd, [ATTACH_RIGHT_PEC], 0);
       }
    }
    else if (cmd1 == "sit")
    {   
        // This is the same as the "do" command, except that it searches for the balls created by MLPv1/2 beds
        // It will search nearby for the poseballs named ~ball5, ~ball4,~ball3, ~ball2, ~ball1, ~ball0 (in this order).
        osMessageAttachments(uNPC, "find-balls", [ATTACH_RIGHT_PEC], 0);
    }
    else if (cmd1 == "script")
    {
        // Specify a script to run in the chat window. Multiple commands can be separaated by ';'
        // example: foo goto 3; do bar-sit; wait 20; stand up
        string str = llDumpList2String(llList2List(tokens, 5, llGetListLength(tokens))," ");
        aviScriptText = llListReplaceList(aviScriptText, str, idx, idx);
        aviScriptIndex = llListReplaceList(aviScriptIndex, [1], idx, idx);
        SetScriptAlarm(idx, 0);

    }
    else if (cmd1 == "run-notecard")
    {
        // The NPC will run the script commands specified in the notecard that is given as the second argument
        // e.g. "Foo run-notecard gym.scr"
        // Script Notecards can contain any of the chat-commands as well as "if", "jump", "variable" counters etc.
        string stext= osGetNotecard(cmd2 );
        aviStatus= llListReplaceList(aviStatus, "", idx, idx);
        if (stext == "")
        
            osNpcSay(uNPC,"Could not load notecard '"+cmd2+"'");
            return 1;
        }
        aviScriptText = llListReplaceList(aviScriptText, stext, idx, idx);
        aviScriptIndex = llListReplaceList(aviScriptIndex, [1], idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (cmd1 == "stop-script")
    {       
        // Stop  the execution of the script that was given in chat or though a notecard. Is the equivalent
        // of an exit() command  for notecard scripts
        aviScriptIndex = llListReplaceList(aviScriptIndex, [-1], idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (llGetSubString(cmd1,0,0) == "@")
    {
        // This is a label; do nothing
    }
    else
    {
        osNpcSay(uNPC, "I do not know how to "+cmd1+". Say '"+npcName+" help' for more");
    }

    return 1;
}

// Try to find a new destination from the current map node, but dont go back to where we came from.
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
    vector pos = osNpcGetPos(uuid);

    float eh = 0.2; // extra height for big avis    
    if (llList2String(aviNames, idx) == "ares")
        eh = 2.5;
    
    vector wp = llList2Vector(wNodes, 2*curNode);
    float dist = llVecDist(pos, wp);
    if (dist>10)
    {
        osTeleportAgent(uuid,  wp, <1,1,7+eh>);
    }

    integer nt = FindNewTarget(curNode, prevNode);
    //llOwnerSay("New target="+(string)nt);
    if (nt <0) return 0;
    vector tgt = llList2Vector(wNodes, 2*nt);

    tgt += <llFrand(2.)-1., llFrand(2.)-1.,eh>;
    osSetSpeed(uuid, 0.7);
    osNpcMoveToTarget(uuid, tgt, OS_NPC_NO_FLY);
    
    aviTime = llListReplaceList(aviTime, [ llGetUnixTime() + GetWalkTime( llVecDist(wp, tgt) )], idx, idx);
    aviNodes = llListReplaceList(aviNodes, [nt], idx, idx);
    aviPrevNodes = llListReplaceList(aviPrevNodes, [curNode], idx, idx);
    return 1;
}


ExecScriptLine(string aviName, string scriptline)
{
    // The full script command expected has the following form, ( we expect the name of the npc twice). We use BATCH instedd of the sending-uid
    string command = "! BATCH " + aviName+" "+ aviName + " " + scriptline;

    list tokens = llParseString2List(command, [" "], [] );
    llOwnerSay(" Running: "+command + " " );
    // Process the command as if we received it from from chat
    ProcessNPCCommand(tokens);
}


default
{

    state_entry()
    {
        llListenRemove(gListener);
        // The controller listener used by the dialog and for getting commands from npcs.
        gListener = llListen(channel, "", "", "");
        llOwnerSay("Listening on channel "+channel);
        // Loads the map nodes from the notecard named "waypoints"
        // Loads the lins between map nodes from the notecard named "links"
        LoadMapData();
        //llOwnerSay(llList2CSV(wNodes));
        //llOwnerSay(llList2CSV(wLinks));
        
        // Searches for active NPCs and initializes their properties.
        RescanAvis();  
        // Start the main loop timer, which executes everything
        llSetTimerEvent(5);
        greetedAvis = [];
    }
    
    touch_start(integer num)
    {
        avi = llDetectedKey(0);
        llDialog(avi, "Welcome", menuItems, channel);
    }
    
    
    timer()
    {
        integer total = llGetListLength(aviUids);
        integer g;
        integer advanceScript;
        // Go through each avi and do something  according to its current state
        for (g=0; g < total ; g++)
        {
                advanceScript =0;
                aviIndex = g;
                npc = llList2Key(aviUids, g);
                //name = llList2String(aviNames, g); 
                string status = llList2String(aviStatus, g); 

                if (status == "follow" || status == "flyfollow") // this npc is followng a user or is flying with one
                {
                    integer stat=llGetAgentInfo(npc);
                    if (stat & AGENT_SITTING)
                    {
                        // We 've been sat. stop following
                        //aviStatus = llListReplaceList(aviStatus, [""], g, g);
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

                    // Try to stay behind the avatar we are following, and try not to overlap with other avis 
                    //that  may be following the same avi
                    vector v = llList2Vector(userData,0) + <-0.6-g*0.6, (ang-0.5)*2.0,0>*rot;
                    float dist = llVecDist(osNpcGetPos(npc), v);
                    // If we are too far, we are probably stuck somewhere. Teleport us to where we should be
                    if  (status == "follow" && dist>50.)
                    {
                        osTeleportAgent(npc, v, <1,1,1>);
                    }
                    else if  (dist>8)
                    {
                        osNpcStopMoveToTarget(npc);    
                        if (status == "flyfollow")                
                           osNpcMoveToTarget(npc, v+<0,0,2.>, OS_NPC_FLY );
                        else
                            osNpcMoveToTarget(npc, v, OS_NPC_NO_FLY );
                    }
                }
                else if (status == "wander") // This is the status of NPCs that have been told to "leave". They wander around aimlessly 
                {

                    if (1)
                    {
                        if (llGetUnixTime()  > llList2Integer(aviTime, g) +1)
                        {
                            integer curNode = llList2Integer(aviNodes, g);
                            integer i;
                            integer shouldMove =1;
                            // If there is an autorun notecard defined for the current location, run it. See the wAutorunScripts array at the top
                            // However avoid running it again for the next two minutes (otherwise the NPC wouldnt have a chance to leave the location and would replay the script indefinitely)
                            if (llGetUnixTime() >  llList2Integer(aviAlarm, g)+120)
                            {
                                for (i=0; i < llGetListLength(wAutorunScripts); i+=2)
                                {
                                    if (llList2Integer(wAutorunScripts,i) == curNode)
                                    {
                                        // There is an autorun notecard associated with this node, ask the NPC to run it
                                        ExecScriptLine(llList2String(aviNames, g), "run-notecard "+llList2String(wAutorunScripts,i+1));
                                        shouldMove =0;
                                    }
                                }
                            }
                            
                            if (shouldMove>0)
                            {
                               MoveToNewTarget(g);
                            }
                        }
                    }

                }
                else if (status == "flyaround") // Fly from node to node, good for birds
                {
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
                else if (status == "pathf") // Following a specific path  to a target node
                {
                    integer avits = llList2Integer(aviTime, g);
                    if (llGetUnixTime() > avits)
                    {
                    
                        vector p = osNpcGetPos(npc);
                        string path = llList2String(aviPath, g);
                        list pnodes = llParseString2List(path, [":"], [""]);
                        
                        //llOwnerSay("p="+llList2CSV(pnodes));
                        if (llGetListLength(pnodes) <1)
                        {
                            osNpcSay(npc, "I have arrived");
                            
                            aviStatus = llListReplaceList(aviStatus, [ "" ], g, g);
                            // wake up the script when we have arrived at our destination
                            SetScriptAlarm(g, 0); 

                        }
                        else
                        {
                            integer nextTgt = llList2Integer(pnodes, 0);
                            string ndleft = ":"+llDumpList2String( llList2List(pnodes, 1, llGetListLength(pnodes)), ":");


                            aviPath = llListReplaceList(aviPath, [ ndleft ], g, g);
                            vector v = llList2Vector(wNodes, 2*nextTgt);              
                            aviTime = llListReplaceList(aviTime, [ llGetUnixTime() + GetWalkTime(llVecDist(p, v)) ], g, g);
                            llOwnerSay("time="+(GetWalkTime(llVecDist(p,v) ) ));                            
              
                            osNpcMoveToTarget(npc, v + <llFrand(1.0),llFrand(1.0), 0.1> , OS_NPC_NO_FLY );
                        }
                        
                    }
                    
                }
                else if  (status == "dance")
                {
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
                    //unimplemented
                     
                }
                
                
                // If there is an active script, run the next line
                integer scriptIndex = llList2Integer(aviScriptIndex, g);
                if (scriptIndex > 0) // This avi is executing a script
                {
                    integer tsAlarm = llList2Integer(aviAlarm, g);
                    integer diff = llGetUnixTime() - tsAlarm;

                    if (tsAlarm >0 && llGetUnixTime() >= tsAlarm ) 
                    {        
                        // The script should wake and move to the next command now
                        string scriptData = llList2String(aviScriptText, g);
                        string scriptline = GetScriptLine(scriptData, scriptIndex);
                        if (scriptline == "") // an empty line means end of script
                        {
                                // This will prevent any further execution
                                llOwnerSay("Script End:"+ llList2String(aviNames, g));
                                aviScriptIndex = llListReplaceList(aviScriptIndex, [-1], g, g);
                        }
                        else
                        {
                            // Run the next command in the next tick of the timer loop. 
                            // Some commands will override this (e.g. goto, wait).
                            SetScriptAlarm(g, 1);
                            ExecScriptLine( llList2String(aviNames, g), scriptline);
                            // Advance script pointer 
                            scriptIndex = llList2Integer(aviScriptIndex, g); // may have been changed
                            aviScriptIndex = llListReplaceList(aviScriptIndex, [scriptIndex+1], g,g);
                        }
                    }
                }
        }
        timerRuns++;
    }
    


    listen(integer chan, string name, key id, string str) {    // WARNING id is not the NPC sernder's dont use it

        list tok = llParseString2List(str, [" "] , [""]);
        string mes = llList2String(tok, 0);
        //llOwnerSay("Listening: " + str);
        if  (mes == "SaveAvi") // Dialog command, save the appearance of an avatar 
        {
            llDialog(avi, "Select a slave", availableNames, channel);       
            //llTextBox(avi, "Enter NPC Name:", channel);
            userInputState = "WAIT_APPNAME";
        }
        else if (mes == "Rescan")
        {
            RescanAvis();
        }
        else if (mes == "LoadAvi") // Load an avatar (you must have saved its appearance first)
        {
 //           llTextBox(llGetOwner(), "Load NPC Name:", channel);
            llDialog(avi, "Select a slave", availableNames, channel);
            userInputState = "WAIT_AVINAME";
        }
        else if (mes == "RemoveAvi")
        {
 //           llTextBox(llGetOwner(), "Load NPC Name:", channel);
            llDialog(avi, "Select a slave", availableNames, channel);
            userInputState = "WAIT_REMOVEAVI";
        }
        else if (mes == "RemoveAll") // Warning: will remove all NPCS (even those created by other scripts)
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
        else if (mes == "initcommands") // Specify a list of initial commands to run here. Use /68 initcommands to run them
        {
            integer i;
            list commands = [
            "foo fly with bar",
            "bar flyaround",
            "john leave",
            "jane go to stadium",
            ];
            
            for (i=0; i < llGetListLength(commands); i++)
            {
                // Fake the commands
                list toks = llParseString2List(llList2String(commands,i), [" "], []);    
                list tok2 = ["!", "0000", llList2String(toks, 0)]; /// Need name of npc twice
                tok2 += toks;
                //llOwnerSay("Cmd="+llList2CSV(tok2));
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
            // Upload the waypoint data to the external web server
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
            //upload the links data to the  external web server
            list lst; 
            integer i;
            integer j;
            string wpdata;
            string wpname;
            wpdata = llList2CSV(wLinks);
            
            llHTTPRequest(BASEURL+"act=updateLinks", [HTTP_METHOD, "POST"], ""+wpdata);
            llOwnerSay("Length="+llStringLength(wpdata));
            //llOwnerSay(wpdata);
            //osMakeNotecard("links", wpdata);
            
        }
        else if (mes =="fetch")
        {
            // bring an avatar by name near you.
            //e.g. /68 fetch Foo
            
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
            // This is sent by the llSensor commands that the NPCs perform when we ask them to sit somewhere
            // We need to check if the ball is transparent first. We can do that only if the balled is owned 
            //by the owner of the controller script.
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
                        // This is a non-transparent poseball, which means that it's not in use.  Sit on it.
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
        else if (mes == "!") // somebody said sth to the npcs
        {
            // This message has been heard from an NPC, process it.
            ProcessNPCCommand(tok);   
        } 
        else if (userInputState != "" && mes != "")// dialog input 
        {
            //llOwnerSay("USER MSG WAIT");
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
            else if (userInputState = "SAY_WHAT")
            {
                osNpcSay(npc, mes);
            }
 
            userInputState="";
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

