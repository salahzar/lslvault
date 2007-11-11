// listens to channel 4000 where commands are shouted

integer CMDCHANNEL=4000;
integer MENUCHANNEL=3000; // TO BE RANDOMIZED

key baseObject=NULL_KEY;

//
vector obj_pos=ZERO_VECTOR;
rotation obj_rot=ZERO_ROTATION;
vector obj_size=ZERO_VECTOR;
list obj_type;

// to implement undo
string save_message="";
vector save_pos=ZERO_VECTOR;
rotation save_rot=ZERO_ROTATION;
vector save_size=ZERO_VECTOR;



integer obj_faces;

debug(string str)
{
    llOwnerSay("DEBUG: "+str);
}
info(string str)
{
    llSay(0,str);
}

// doMenu with the possibility of undoing undo=0, normal, =1 undo
doMenu(string message, integer undo, key id)
{
    if(message=="Undo") {
        if(save_message!="") doMenu(save_message,1,id);
        info("No undo information");
        doDialog(id);
        return;
    }
    integer done=0;
    if(undo==0){
        if(message=="Position"){
            save_message=message;
            save_pos=llGetPos(); // for undo
            llSetPos(obj_pos);
            done=1;

        }
        if(message=="Rotation"){
            save_message=message;
            save_rot=llGetRot();
            llSetRot(obj_rot);
            done=1;
        }
        if(message=="Size"){
            save_message=message;
            save_size=llGetScale();
            llSetScale(obj_size);
            done=1;
        }
        if(done==1)
            info(message+" done.");
        else info("can't do that "+message);
    }
    else
    {
        if(save_message==""){
            info("Nothing to undone");
            return;
        }
        if(message=="Position"){
            llSetPos(save_pos);
            done=1;
        }
        if(message=="Rotation"){
            llSetRot(save_rot);
            done=1;
        }
        if(message=="Size"){
            llSetScale(save_size);
            done=1;
        }
        if(done==1){
            save_message="";
            info("Command undone");
        } else info("can't undone "+save_message);
    }
    doDialog(id);
}

doDialog(key id)
{
    debug("trying to launch menu");
    llDialog(id,"Decide What you want to copy",
        ["Position", "Rotation", "Size", "Texture","Undo" ],MENUCHANNEL);
}

default
{
    state_entry()
    {
        llSay(0, "Listening on channel "+(string)CMDCHANNEL);
        llListen( CMDCHANNEL, "", NULL_KEY, "" );
        llListen( MENUCHANNEL,"", NULL_KEY, ""); //menu
    }

    touch_start(integer total_number)
    {
        debug("touched... baseObject="+(string)baseObject);
        if(baseObject!=NULL_KEY)
        {
            doDialog(llDetectedKey(0));
            return;
        }

        state first_touch;
    }
    // this listens on channel CMDCHANNEL
    listen( integer channel, string name, key id, string message )
    {
        if(channel==MENUCHANNEL) {
            doMenu(message,0,id);
            return;
        }
        string first=llGetSubString(message,0,3);
        list rest =llCSV2List(llGetSubString(message,4,-1));
        if(first=="BASE")
        {
            baseObject=id;
            debug("Setting base object to "+(string)baseObject);
            //debug("rest is: "+llList2CSV(rest));
            obj_pos=(vector)llList2String(rest,0);
            obj_rot=(rotation)llList2String(rest,1);
            obj_size=(vector)llList2String(rest,2);
            debug("Got pos: "+(string)obj_pos+" rot: "+(string)obj_rot+" size: "+(string)obj_size);

        }
        if(first=="TYPE")
        {
            obj_type=rest;
            debug("Got type info: "+message);
        }
        if(first=="SIDE")
        {
            obj_faces=llList2Integer(rest,0);
            integer i;
            integer offset=1;
            debug("Object has "+(string)obj_faces+" faces");
            for(i=0;i
            {
                //debug("Information on face: "+(string)i);
                string texture=llList2String(rest,offset++);
                vector scale=(vector)llList2String(rest,offset++);
                vector txoffset=(vector)llList2String(rest,offset++);
                float rot=llList2Float(rest,offset++);
                vector color=(vector)llList2String(rest,offset++);
                float alpha=llList2Float(rest,offset++);

                //debug("Texture: "+texture+" scale: "+(string)scale+ " offset: "+(string)txoffset+" rotation: "+(string)rot+" color: "+(string)color+" alpha: "+(string)alpha);


            }

        }
        if(first=="RSET")
        {
            baseObject=NULL_KEY;
            debug("Resetting base object");
        }
        rest=[];

    }

}
// when entering here collect ALL information on this prim and publish around
state first_touch
{
    state_entry()
    {

        // return basic information from prim
        llShout(CMDCHANNEL,"BASE"+llList2CSV(llGetPrimitiveParams([ PRIM_POSITION, PRIM_ROTATION, PRIM_SIZE ])));
        // return prim_type information
        llShout(CMDCHANNEL,"TYPE"+llList2CSV(llGetPrimitiveParams( [ PRIM_TYPE ])));
        // now return texture information on all faces

        // try to get PRIM_TEXTURE and PRIM_COLOR (.2 sec x 6
        integer i;
        list lst=[];
        integer sides=llGetNumberOfSides();
        for(i=0;i< sides;i++){
            lst += [ PRIM_TEXTURE , i, PRIM_COLOR, i];
        }

        // will output SIDE + csv with number of sides etc...
        llShout(CMDCHANNEL,"SIDE"+llList2CSV(sides+llGetPrimitiveParams(lst)));
        debug("Information about this prim broadcasted...");

    }
    touch_start(integer total_number)
    {
        llShout(CMDCHANNEL,"RSET");
        state default;
    }
}