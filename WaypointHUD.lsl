/* Waypoint editor HUD. This only forwards the click to the controller. Controller does all the work */


default
{
    state_entry()
    {
       llSetText("WaypointEditor", <0,0,1>, 1.0);
        //startListen();
       
    }


    touch_start(integer num)
    {
        llRegionSay(68, "ShowPegDialog");
        return;
    }
        
}
