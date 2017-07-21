/* Put this in an attachment that the NPC wears. You can then hide/show that attachment using the commands "hide" and "show" which are defined in the Extension.lsl script.
  
  Example: "Bob hide bottle"   will show the attachment named (Object name) "bottle" 
  "Bob show bottle" will hide it
   */


default
{
    state_entry () 
    {
    }
 

    // This receives messages through osMessageAttachments(). No channels are used    
    dataserver(key qid, string mes) 
    {
        string name = llGetObjectName();
        if (mes == name+"-hide") {
            llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
        }
        else if (mes == name+"-show") {
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        }
    }
}

