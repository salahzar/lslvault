//
// october 2007
// Script to let a bubble disappear after some minutes
// and possibly be driven by commands:
// DIE!!! for dying
// C<color> : change color
// D<string>: display string
// P<pos>   : position to <pos>
//

vector COLOR=<1,1,1>;

integer WHISPERCHANNEL=31415;
integer inhibit=0;
string str="";

default
{
    on_rez(integer channel)
    {
        
        WHISPERCHANNEL=channel;
        // makes things easier having the object be temp-rez
        llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);

    }

    state_entry()
    {
        // wait for text to be displayed  
        //llOwnerSay("Listening to channel "+(string)WHISPERCHANNEL); 
        llListen(WHISPERCHANNEL,"",NULL_KEY,"");
        
        llSetText(" ",COLOR,1);

        // this make a slow rotation
        llTargetOmega(<0,0,1>,PI/4,1);

        // a light Buoyancy towards the up
        llSetBuoyancy(1.0005);
    }
        
    listen(integer channel,string name, key id, string message)
    {
        // DIE!!! is always honored
        //llOwnerSay("Received message: "+message);
        if(message=="DIE!!!") llDie();

        // so we can use the same channel for easy destroying
        if(inhibit==1) return;
        
        // find out objnum, 0-9, and command 
        string command=llGetSubString(message,0,0);
        string rest=llGetSubString(message,1,-1);
        
        if(command=="C") 
        {
            COLOR=(vector)rest;
            llSetText(str,COLOR,1);
        }
        if(command=="K")
        {
            llSetColor((vector)rest,ALL_SIDES);
        }
        if(command=="T")
        {
            llSetTexture((key)rest,ALL_SIDES);
        }
        if(command=="B")
        {
            llSetBuoyancy((float)rest);
        }
        if(command=="P") llSetPos((vector)rest);
        if(command=="D") 
        {
            str=rest;
            llSetText(rest,COLOR,1);
            inhibit=1;
        }
    }

}
