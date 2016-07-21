
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

// This can be used to send a command back to the controller, e.g. ControllerDo("Bob", "say i am an NPC");
ControllerDo(string npcName, string msg)
{
     
    llMessageLinked(LINK_THIS, 0, "! 0000 UUUU " +npcName+ " "+msg, NULL_KEY);
}


default
{
    link_message(integer lnk, integer num, string command, key uNPC) // This script is in the object too.
    {
        if (num!=-1) return;/// Only process what the controller sent
        
        list tokens = llParseString2List(command, [",", " "], [] );        

        if (llList2String(tokens,0) == "!")
        {            
            // The commands are of the form "! <sending-object-uuid> Bob Bob follow me" (notice the name of the NPC given twice)
        
            string sendUid = llList2String(tokens,1);
            string npcName = llToLower(llList2String(tokens,2));
                
            string name2 = llToLower(llList2String(tokens,3));
            string cmd1 = llList2String(tokens, 4);
            string cmd2 = llList2String(tokens, 5);
            
           
            if (cmd1=="hide" || cmd1 == "show")
            {
                // This can be used to hide-show appropriately-scripted attachments
                osMessageAttachments(uNPC, cmd2+"-"+cmd1, [ATTACH_LHAND, ATTACH_RHAND], 0);
            }
            else if (cmd1 == "help")
            {
                osNpcSay(uNPC, "Say '"+ npcName+ " <command>', where <command> can be: 'follow ', 'fly with me', 'use', 'go to', 'dance', 'stand', 'stop', 'light', 'leave'.");
            }
            else if (cmd1 == "go") //take a step back (b) forward (f) right (r) or left (l)
            {
                rotation r = osNpcGetRot(uNPC);
                vector v = osNpcGetPos(uNPC);
                vector m;
                if (cmd2 == "f") m = <1,0,0>;
                else if (cmd2 == "b") m = <-1,0,0>;
                else if (cmd2 == "l") m = <0,1,0>;             
                else if (cmd2 == "r") m = <0,-1,0>;
                
                osNpcMoveToTarget(uNPC, v + m*r, OS_NPC_NO_FLY );
            }
            else
            {
              /* Unknown command */
            }
        }
    }
}
