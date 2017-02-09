// LSL script generated - LSLForge (0.1.6.5): hotspotboard.lslp 
// 2017-02-05 19:07:01
/**
This script is free to be used as you like.

Salahzar Stenvaag February 2017

This script is the BOARD part of the hotspot design workflow
it starts in RUNTIME mode reading a notecard with hotspots, but
can be shifted to DESIGN mode by owner.

CONFIG notecard has the following syntax:

NAME|<tlx,tly,brx,bry>

where tlx tly brx bry are TOPLEFT and BOTTOMRIGHT offsets each one 
0<offset<1 which are computed in the design
state and will be used to define an area to be clicked recognized with 
that NAME.

You must link to the board at least one item for each NAME and be
sure to have this item named exactly as NAME (with proper capitalization,
and trimming spaces).

When changing the NOTECARD the script is reset.

RESET:
When script resets, notecard is read and every spot is recorded.
Every labels are shuffled and set on the very left in random order.
Then go to the RUN state.

RUN:
At this point user is requeste do click over a label, which then becomes RED
The we go to the moveLink state. Timeout 30 seconds to go back to RUN.
You can say 
/1001 reset to reset everything and rereading the notecard
/1001 design to go to design state

MOVELINK:
User clicks on the map and if they clicked on a hotspot area matching the name of 
the red (currently clicked label) then the label will move with a CORRECT answer on chat.
otherwise it will not move and says WRONG.
In either case we go to the RUN state to click again on the same or other labels.

DESIGN:
Usually owner click on where they want to define a new area (topleft point of this area)
at this point the board records the point and asks for the name of the area,
input a "." to end design phase. 

DESIGN_BOTTOM_RIGHT:
User must specify the bottom right corner of the area and at this point the program will answer
with the following:
<name>|<tlx,tly,brx,bry>
that can be copy and pasted to the notecard for the script to identify all the spot areas.



**/

// Salahzar Stenvaag February 2017
// Note that when in design mode the board must have rotation 0
// and should be used on the right side

integer BOARD_CHANNEL = 1001;
string UI_RESET = "RESET";
string UI_DESIGN = "DESIGN";
string UI_HELP = "HELP";

integer LISTENER;

integer DEBUG = 0;


list NAMES;
list VALUES;


// notecard state
string NCNAME;
integer NCLINE;

// 
string SPOTNAME;
vector TOPLEFT;
vector BOTTOMRIGHT;

integer LINKNUMBER;
string LINKNAME;
vector RED = <1,0,0>;
vector WHITE = <1,1,1>;
integer TIMEOUT = 10;

vector ST_COORD;
vector OFFSET;

unlisten(){
    if (LISTENER != -1) llListenRemove(LISTENER);
}
info(string s){
    llSay(0,s);
}
debug(string s){
    if (DEBUG == 1) llOwnerSay("DEBUG: " + s);
}

// giving a ST vector findout which area holds it
string find_hot_spot(vector st){
    integer i = 0;
    integer numElements = llGetListLength(NAMES);
    debug("checking st: " + (string)st + " list size: " + (string)numElements);
    for (i = 0; i < numElements; i++) {
        string name = llList2String(NAMES,i);
        rotation r = (rotation)llList2String(VALUES,i);
        debug("checking st: " + (string)st + " against " + name + " " + (string)r);
        if (st.x >= r.x && st.x <= r.z && st.y >= r.s && st.y <= r.y) {
            debug("found " + name);
            return name;
        }
    }
    debug("not found");
    return "";
}

help(){
    info("channel: " + (string)BOARD_CHANNEL + " commands: design, reset, help");
}

process_line_notecard(string str){
    debug("Processing " + str);
    list pieces = llParseStringKeepNulls(str,["|"],[]);
    integer p = 0;
    string name = llList2String(pieces,0);
    NAMES += llStringTrim(name,STRING_TRIM);
    string rot = llList2String(pieces,1);
    VALUES += [(rotation)rot];
    info("added " + name + " data: " + rot);
}
random(){
    debug("performing random positining of cards");
    integer i = 0;
    vector scale = llGetScale();
    for (i = 2; i < llGetNumberOfPrims() + 1; i++) {
        debug("moving card #" + (string)i);
        LINKNUMBER = i;
        setOff();
        vector randompoint = <0,-0.5 * scale.y,(llFrand(1.0) - 0.5) * scale.z>;
        debug("going to random point " + (string)randompoint);
        move(randompoint);
    }
}
hilightPrim(){
    llSetLinkPrimitiveParamsFast(LINKNUMBER,[PRIM_COLOR,ALL_SIDES,RED,1]);
}
unHilightPrim(){
    llSetLinkPrimitiveParamsFast(LINKNUMBER,[PRIM_COLOR,ALL_SIDES,WHITE,1]);
}
setOn(){
    hilightPrim();
    setTimer();
}

setTimer(){
    llSetTimerEvent(0);
    llSetTimerEvent(TIMEOUT);
}
offTimer(){
    llSetTimerEvent(0);
}
setOff(){
    unHilightPrim();
    offTimer();
}
string fixed(float input){
    integer precision = 3;
    if ((precision = (precision - 7) - (precision < 1)) & -2147483648) return llGetSubString((string)input,0,precision);
    return (string)input;
}
string fixedvector(vector v){
    return fixed(v.x) + "," + fixed(v.y);
}



move(vector to){
    llSetLinkPrimitiveParamsFast(LINKNUMBER,[PRIM_POS_LOCAL,to,PRIM_POS_LOCAL,to,PRIM_POS_LOCAL,to]);
}

// default state will read configuration and go to
// run state
default {

    state_entry() {
        random();
        NCNAME = "CONFIG";
        debug("reading notecard " + NCNAME);
        NCLINE = 0;
        llGetNotecardLine(NCNAME,NCLINE);
    }

    dataserver(key id,string str) {
        if (str == EOF) {
            info("Finished notecard read " + (string)NCLINE + " lines");
            state run;
            return;
        }
        process_line_notecard(str);
        debug("reading line " + (string)NCLINE);
        NCLINE++;
        llGetNotecardLine(NCNAME,NCLINE);
    }
}

state run {

    state_entry() {
        info("click a label to move it");
        llListen(1001,"",NULL_KEY,"");
    }

    touch_start(integer count) {
        LINKNUMBER = llDetectedLinkNumber(0);
        debug("You touched link#" + (string)LINKNUMBER);
        if (LINKNUMBER >= 2) {
            LINKNAME = llGetLinkName(LINKNUMBER);
            state moveLink;
            return;
        }
        info("You must touch a card to be moved");
    }

    listen(integer channel,string name,key id,string message) {
        debug("received command " + message);
        message = llToUpper(message);
        if (message == UI_HELP) help();
        if (message == UI_DESIGN) state design;
        if (message == UI_RESET) {
            random();
            llResetScript();
        }
    }

    changed(integer change) {
        llResetScript();
    }
}
state moveLink {

    state_entry() {
        info("click where you think " + LINKNAME + " should be moved");
        setOn();
    }

    touch_start(integer count) {
        integer link = llDetectedLinkNumber(0);
        if (link < 2) {
            vector v = llDetectedTouchST(0);
            vector scale = llGetScale();
            float x = (v.x - 0.5) * scale.y;
            float y = (v.y - 0.5) * scale.z;
            OFFSET = <0,x,y>;
            ST_COORD = v;
            string spot = find_hot_spot(v);
            if (spot == LINKNAME) {
                info("CORRECT!!!!!");
                move(OFFSET);
            }
            else  {
                info("mmmm... " + LINKNAME + " is actually in another place");
            }
            setOff();
            state run;
        }
        else  {
            info("You must touch where you think " + LINKNAME + " is ");
        }
    }

    timer() {
        setOff();
        state run;
    }
}
state design {

    state_entry() {
        LISTENER = -1;
        info("Click on the top left of spot area you want to define \nto name a hotspot");
        setTimer();
    }

    timer() {
        unlisten();
        state run;
    }

    listen(integer channel,string name,key id,string str) {
        debug("received " + str);
        SPOTNAME = str;
        if (llStringTrim(SPOTNAME,STRING_TRIM) == ".") {
            info("finishing editing");
            unlisten();
            state run;
        }
        unlisten();
        state design_bottom_right;
    }


    touch_start(integer total_number) {
        setTimer();
        info("input name of the spot, or . to finish design");
        LISTENER = llListen(0,"",llDetectedKey(0),"");
        TOPLEFT = llDetectedTouchST(0);
        debug("TOPLEFT: " + (string)TOPLEFT);
    }
}
state design_bottom_right {

    state_entry() {
        info("Click on area bottom right to define '" + SPOTNAME + "' hotspot");
        llListen(-1,"",NULL_KEY,"");
        setTimer();
    }

    touch_start(integer total_number) {
        BOTTOMRIGHT = llDetectedTouchST(0);
        debug("BOTTOMRIGHT: " + (string)BOTTOMRIGHT);
        rotation rot = (rotation)("<" + fixedvector(TOPLEFT) + "," + fixedvector(BOTTOMRIGHT) + ">");
        debug("rot: " + (string)rot);
        info("Add this to the CONFIG notecard\n" + SPOTNAME + "|" + (string)rot);
        state design;
    }
}
