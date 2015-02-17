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
integer CONTROLLER_CHAN=698;


default
{
    on_rez(integer m)
    {
        num = m;
    }
    
    state_entry()
    {
        channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -7, -1) );
        zListener =  llListen(channel, "","","");
        gListener =  llListen(PEG_CHAN, "","","");
    }
    
    touch_start(integer n)
    {
        
        string str="Peg Num:"+(string)num+"\nName:"+name+"\nLinks:"+llList2CSV(links)+"\nNotecard:"+notecard;
        
        llOwnerSay(str);

        llDialog(llGetOwner(), " "+ str, ["Name", "Links", "Notecard"], channel);
    }
    
    listen(integer chan, string wname, key id, string data)
    {
        if (chan == channel) // Local channel
        {
            if (data == "Notecard")
            {
                llTextBox(llGetOwner(), "Current Notecard:"+notecard, channel);
                status="save_notecard";
            }
            else if (data == "Links")
            {
                llTextBox(llGetOwner(), "Current links:"+llList2CSV(links), channel);
                status="save_links";
            }
            else if (data == "Name")
            {
                llTextBox(llGetOwner(), "Current name:"+(name), channel);
                status="save_name";
            }
            else if (status =="save_notecard")
            {
                notecard = llStringTrim(data,STRING_TRIM);
                
            }
            else if (status =="save_name")
            {
                name = llStringTrim(data,STRING_TRIM);
                llOwnerSay("name="+name);
            }
            else if (status =="save_links")
            {
                links = llParseString2List(data, ",", []);
                llOwnerSay("Links="+llList2CSV(links));
            }

        }
        else
        {
            list l = llParseStringKeepNulls(data, ["|"], []);
            if ((integer)llList2String(l,0) != num)             return;
            
            string cmd = llList2String(l,1);
            if (cmd == "die")
            {
                llDie();
            }
            else if (cmd == "report")
            {
                string str = "MARKER report|"+(string)num+"|"+(string)llGetPos()+"|"+name+"|"+llList2CSV(links)+"|"+notecard;
                llOwnerSay(str);
                llRegionSay(CONTROLLER_CHAN, str);
            }
            else if (cmd == "setdata")
            {
                //llSleep(2);
                pos = (vector)llList2String(l, 2);
                name =   llList2String(l, 3);
                string lstr  = llList2String(l, 4);
                notecard  = llList2String(l, 5);
                
                links = llParseString2List(lstr, [","],[]);
                
                llSetRegionPos(pos);
                llSetText("Num="+(string)num+"\nName="+name+"\nNotecard="+notecard+"\nLinks:"+llList2CSV(links), <1,0,0>, 1.0);
            }
        }
    }
}

