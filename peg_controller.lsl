

integer PEG_CHAN=699;
integer CTRL_CHAN=698;

integer gListener =-1;
integer zListener =-1;
list wNodes = [];
list wLinks = [];
list wAutorunScripts = [];
string recData = "";
list tempList;

LoadMapData()
{
    integer tl = osGetNumberOfNotecardLines("waypoints");
    integer i;
    wNodes = [];
    for (i=0; i < tl; i++)
    {
        string line = osGetNotecardLine("waypoints",i);
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
    llOwnerSay("loaded "+(string)(llGetListLength(wLinks)/2)+" links");
}


default
{
    state_entry()
    {
        gListener = llListen(PEG_CHAN, "", "", "");
        zListener = llListen(CTRL_CHAN, "", "", "");
    }



    touch_start(integer n)
    {
        llDialog(llDetectedKey(0), "", ["ReloadMap", "RezPegs", "KillPegs", "PegReport", "Debug", "Close"], PEG_CHAN);
    }
    
    
    listen(integer chan, string wname, key id, string str) 
    {
            list tok = llParseString2List(str, [" "] , [""]);
            string cmd = llList2String(tok, 0);
            integer i;
            llOwnerSay("Cmd="+cmd);

            if (cmd == "RezPegs")
            {
                integer nTotal = llGetListLength(wNodes)/2;

                vector pos = llGetPos() + <3,0,0>;
                for (i=0; i <nTotal; i++)
                {
                }
                
                for (i=0; i <nTotal; i++)
                {
                    integer nk;
                    string notecard="";

                    
                    llOwnerSay("Rezzing "+i);

                    llRegionSay(PEG_CHAN, (string)(i)+"|die");
                    
                    llRezObject("peg", pos + <1,0,1>, ZERO_VECTOR, ZERO_ROTATION, i);
                    llSleep(1);
                    
                    for (nk=0; nk < llGetListLength(wAutorunScripts); nk+=2)
                    {
                        if (llList2Integer(wAutorunScripts,nk) == i)
                        {
                            notecard=llList2String(wAutorunScripts, nk+1);
                        }
                    }
                    
                    list lnk = [];
                    for (nk=0; nk < llGetListLength(wLinks); nk+=2)
                    {
                        integer a = llList2Integer(wLinks,nk);
                        integer b = llList2Integer(wLinks,nk+1);
                        if (a == i)   lnk += b;
                        else if (b == i)   lnk += a;
                    }
                    
                    string wstr = "setdata|"+(string)llList2Vector(wNodes, i*2)+"|"+llList2String(wNodes, i*2+1)+"|"+llList2CSV(lnk)+"|"+notecard;
                    llOwnerSay(wstr);
                    
                    llRegionSay(PEG_CHAN, (string)(i)+"|"+wstr);
                    llSleep(1);
                }
            }
            else if (cmd == "KillPegs")
            {
                integer nTotal = llGetListLength(wNodes)/2;
                for (i=0; i <nTotal; i++)
                {   
                    llRegionSay(PEG_CHAN, (string)i+"|die");
                    //llSleep(1);
                }
            }
            else if (cmd == "Debug")
            {

                llOwnerSay(llList2CSV(tempList));
                list orderIdx = [];
                for (i=0; i < llGetListLength(tempList); i++)
                {
                    string ws = llList2String(tempList,i);
                    list l = llParseStringKeepNulls(ws, ["|"], []);
                    integer num=(integer)llList2String(l,1);
                    orderIdx +=  num;
                }
                
                string strout = "";              
                for (i=0; i < llGetListLength(orderIdx); i++)
                {
                    integer j;
  
                    for (j=0; j< llGetListLength(orderIdx); j++)
                    {
                        if (llList2Integer(orderIdx, j)==i)
                        {
                            string ws = llList2String(tempList,i);
                            list l = llParseStringKeepNulls(ws, ["|"], []);
                            //llOwnerSay("lst="+llList2CSV(l));
                            integer num=(integer)llList2String(l,1);
                            vector pos=(vector)llList2String(l,2);   
                            string name=llList2String(l,3);
                            list links =llParseString2List(llList2String(l,4), [","], []);
                            string notecard=llList2String(l,5);

                            strout += "" + pos.x+","+pos.y+","+pos.z+","+name+","+notecard + "\n";
                        }
                    }
                   
                }
               llOwnerSay(strout);
               osMakeNotecard("new_map", strout);
                
            }
            else if (cmd == "PegReport")
            {
                tempList = [];
               integer nTotal = llGetListLength(wNodes)/2;
                for (i=0; i <nTotal; i++)
                {   
                    llRegionSay(PEG_CHAN, (string)i+"|report");
                    llSleep(1);
                }
                
            }
            else if (cmd == "ReloadMap")
            {
                LoadMapData();
            }
            else if (cmd== "MARKER") // positioner reporting
            {
               
                tempList += llGetSubString(str, 7, -1);
                /*
                 //list l = llParseStringKeepNulls(llGetSubString(str, 7, -1), ["|"], []);
                llOwnerSay("lst="+llList2CSV(l));
                integer num=(integer)llList2String(l,1);
                vector pos=(vector)llList2String(l,2);   
                string name=llList2String(l,3);
                list links =llParseString2List(llList2String(l,4), [","], []);
                string notecard=llList2String(l,5);
                */

            }
    }
}
