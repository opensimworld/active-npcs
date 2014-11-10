// This is the listener script for clothes. 
// The main controller sends osMessageAttachment objects to the NPCS which are 
// picked by this script to hide/show the clothes
// Drop this on your each of your clothes and wear them. 
// This actually does not open any llListen() channels and thus uses minimal resources.

string chatKey = "";
string NPCNAME="INVALID";
key npc = NULL_KEY;
string status = "";


default
{
    state_entry () 
    {

    }
    
    
    dataserver(key qid, string mes) 
    {
        if (mes == "hide") {
            llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
        }
        else if (mes == "show") {
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        }
        else if (mes == "shine") {
            //Set prim perams to make it shiny
            llSetLinkPrimitiveParams(LINK_SET, [ PRIM_BUMP_SHINY, ALL_SIDES, PRIM_SHINY_LOW, PRIM_BUMP_NONE]);
        }
        else if (mes == "reset")
        {
           llSetLinkPrimitiveParams(LINK_SET, [ PRIM_BUMP_SHINY, ALL_SIDES, PRIM_SHINY_NONE, PRIM_BUMP_NONE]);
        }
        else if (llGetSubString(mes, 0,3) == "SET ")
        {
            list params = llParseString2List(llGetSubString(mes, 4, llStringLength(mes)) , [","], []);
            llSetLinkPrimitiveParams(LINK_SET, params);
        }
    }
}

