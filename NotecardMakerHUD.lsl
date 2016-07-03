integer channel;
integer listener = -1;
string status;
list btns ;
key owner;

string cardName = "_script.scr";

string scriptText;

list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) +
        llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
 
string anim = "";
integer menuindex;
 
DialogPlus(key avatar, string message, list buttons, integer channel, integer CurMenu)
{
    if (12 < llGetListLength(buttons))
    {
        list lbut = buttons;
        list Nbuttons = [];
        if(CurMenu == -1)
        {
            CurMenu = 0;
            menuindex = 0;
        }
 
        if((Nbuttons = (llList2List(buttons, (CurMenu * 10), ((CurMenu * 10) + 9)) + ["<<", ">>"])) == ["<<", ">>"])
        {
            menuindex =0;
            DialogPlus(avatar, message, lbut, channel, menuindex);
        }
        else
            llDialog(avatar, message,  order_buttons(Nbuttons), channel);
    }
    else
        llDialog(avatar, message,  order_buttons(buttons), channel);
}

showDialog()
{
      btns = ["Close", "movetov", "AddCode", "Clear", "SaveCard", "Reload"]; 
      llDialog(llGetOwner(), "Current Script: \n"+llGetSubString(scriptText, -480, -1), btns, channel);
}

startListen()
{
     channel = -1 - (integer)("0x" + llGetSubString( (string) llGetOwner(), -6, -1) ) - 12313 ;
        llListen(channel, "","","");
}

default
{
    state_entry()
    {
        llSetText("Notecard Editor", <1,1,1>, 1.0);
        startListen();

    }


    attach(key u)
    {
       startListen();
    }
    
    on_rez(integer n)
    {
        llResetScript();
    }
    
    touch_start(integer num)
    {
        
        showDialog();
        status = "";
    }
    
    listen(integer chan, string who, key id, string msg)
    {
        if (status == "entertext")
        {
            scriptText =  llStringTrim(scriptText, STRING_TRIM) + "\n"+msg+"\n";
            status = "";
        }
        else if (msg == "movetov" )
        {

            list res = llGetObjectDetails(llGetOwner(), [OBJECT_POS]);
            scriptText += "movetov " +(string)llList2Vector(res,0) + "\n";
            llOwnerSay("movetov " +(string)llList2Vector(res,0) );
            
        }
        else if (msg == "AddCode")
        {
            llTextBox(llGetOwner(), "" +llGetSubString(scriptText, -120,-1)+ "\nAdd code:" ,  channel);
            status = "entertext";
            return;
        }
        else if (msg == "Clear")
        {
            scriptText = "";
        }
        else if (msg == "Reload")
        {
            scriptText = osGetNotecard(cardName);
        }
        else if (msg == "SaveCard")
        {

            if (llGetInventoryType(cardName)==INVENTORY_NOTECARD)
            {
                llRemoveInventory(cardName);
                llSleep(0.25);
            }
            osMakeNotecard(cardName,scriptText);
            llOwnerSay("Card Saved");
        }
        else if (msg == "Close")
        {
            return;
        }
        showDialog();
    }
    
    
    
}
