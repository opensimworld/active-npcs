/* Simple greeter script that checks for visitors. If a new, previously unseen visitor is found, 
   it sends a number of commands to an NPC.  The commands teleport the NPC in front  of the user, and say a welcome message. 
   */

list seen = [];
list alreadyGreeted = [];

string vec2str(vector v)
{
    return "<"+v.x+","+v.y+","+v.z+">";
}

checkVisitors()
{
    list avis = llGetAgentList(AGENT_LIST_REGION, []);
    integer howmany = llGetListLength(avis);
    integer i;
    for ( i = 0; i < howmany; i++ ) {
        if ( ! osIsNpc(llList2Key(avis, i)) )
        {
            key u = llList2Key(avis, i);
            if (llListFindList(seen, [u])<0)
            {

                list ud =llGetObjectDetails(u, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
                vector v = llList2Vector(ud, 1);
                rotation r = llList2Rot(ud, 2);
                
                string scr;
                if ( llListFindList(already, [u])<0)
                {
                
                // These are the notecard commands, separated by ';' which position the NPC, and say a welcome message. You can change the commands 
                    scr = "teleport "+vec2str(v+<2,0,0>*r) +"; stop; lookat "+vec2str(v)+"; anim bow; say  Welcome to My Region! If you need help, say 'Magnus help'. Enjoy your stay!; wait 50; leave";
                    
                    llRegionSay(68, "! 00000000-0000-0000-0000-000000000000 magnus magnus batch "+scr);
                    alreadySeen += u;
                }
            }
        }
    }
    seen = avis;
}


default
{
    state_entry()
    {
        llSetTimerEvent(30);
        checkVisitors();
    }
    timer()
    {
        checkVisitors();
    }
}
