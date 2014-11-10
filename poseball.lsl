// This is a generic  poseball script that works well with opensim
// Create a small sphere, add the animation that you want to perform, 
// change the object name of the ball to the label that you want to appear on top of it
// and then drop this script in the object. Change the default action of the ball to "sit" for extra convenience. 
// You may  need to adjust the  position of the animation 
// by editing it and (while editing) right click and sit on it. 
// 
// You can ask  "Foo NPC" to sit on it when Foo is nearby by entering this in chat:
// Foo do <poseball-name>
// where <poseball-name> is the name that you gave to the ball.



vector COLOR = <1.0,1.0,1.0>;
float ALPHA_ON = 1.0;
float ALPHA_OFF = 0.0;
string TITLE="Float";
 
show(){
    //visible = TRUE;
    llSetText(TITLE, COLOR,ALPHA_ON);        
    llSetAlpha(ALPHA_ON, ALL_SIDES);
}
 
hide(){
//    visible = FALSE;
    llSetText("", COLOR,ALPHA_ON);        
    llSetAlpha(ALPHA_OFF, ALL_SIDES);
}
 

startAnimation()
{
    string name = llGetInventoryName(INVENTORY_ANIMATION, 0);
    hide();
    llStopAnimation("sit"); // Stop the default animation
    llStartAnimation(name); // and start the new one
}

stopAnimation()
{
    string name = llGetInventoryName(INVENTORY_ANIMATION, 0);
    show();
    llStopAnimation(name); // Stop the animation
}

default
{
    state_entry()
    {
        llSitTarget(<0.0, 0.0, -1.0>, ZERO_ROTATION);
        TITLE = llGetObjectName();
        llSetText(TITLE, COLOR,ALPHA_ON);        
    }
    
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (llGetInventoryNumber(INVENTORY_ANIMATION)) // If there is at least one animation in the inventory
            {
                key who = llAvatarOnSitTarget();
                integer perm = llGetPermissions();

                if (who!= NULL_KEY) // If someone sits down, animate the avatar
                {
                    if ( (perm & PERMISSION_TRIGGER_ANIMATION) &&
                         (who == llGetPermissionsKey())
                       ) startAnimation();
                    else
                        llRequestPermissions(who, PERMISSION_TRIGGER_ANIMATION);
                }
                else // If the person stands up and was playing the animation, stop the animation
                {
                    if (perm & PERMISSION_TRIGGER_ANIMATION)
                        stopAnimation();
                }
            }
        }
    }
    
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION) // If the permission is granted, start the animation
            startAnimation();
    }
}
