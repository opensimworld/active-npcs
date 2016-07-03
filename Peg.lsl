/* The Peg script for waypoint management */

integer num;
string notecard;
list links;
integer channel;
string name;
string status;
vector pos;
integer zListener;
integer gListener;
integer PEG_CHAN=699;
integer CONTROLLER_CHAN=68;


default
{
    on_rez(integer m)
    {
        num = m;
        llSetText("Uninitialized", <1,1,1>, 1.0);
        //zListener =  llListen(channel, "","","");
        gListener =  llListen(PEG_CHAN, "","","");
    }
    
    touch_start(integer n)
    {
            string str="Peg Num:"+(string)num+"\nName:"+name+"\nLinks:"+llList2CSV(links)+"\nNotecard:"+notecard;
            //llOwnerSay(str);    
            llRegionSay(CONTROLLER_CHAN, "CLICKED|"+num);
            //llDialog(llGetOwner(), " "+ str, ["Name", "Links", "Notecard"], channel);
    }
    
    listen(integer chan, string wname, key id, string data)
    {
            if (data == "die")
            {
                llDie();
            }
            else if (data == "REPORT")
            {
                string str = "MARKER|"+(string)num+"|"+(string)llGetPos()+"|"+name+"|"+(string)llGetKey();
                llRegionSay(CONTROLLER_CHAN, str);
            }
            
            list l = llParseStringKeepNulls(data, ["|"], []);
            if ((integer)llList2String(l,0) != num)     return;
            
            string cmd = llList2String(l,1);

            if (cmd == "SETDATA")
            {
                pos = (vector)llList2String(l, 2);
                name =   llList2String(l, 3);
                string lstr  = llList2String(l, 4);
                notecard  = llList2String(l, 5);   
                links = llParseString2List(lstr, [","],[]);
                llSetRegionPos(pos);
                llSetText("Num="+(string)num+"\nName="+name+"\nLinks:"+llList2CSV(links), <1,0,0>, 1.0);
            }

    }
}


