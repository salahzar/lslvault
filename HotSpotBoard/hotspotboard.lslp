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

string UI_ADDED_DATA = "added {0} data: {1}";
string UI_FINISHED_NOTECARD = "Finished notecard read {0} lines";
string UI_CLICK_A_LABEL = "click a label to move it";
string UI_ADD_TO_NOTECARD = "Add this to the CONFIG notecard\n{0}|{1}";
string UI_MUST_CLICK_A_LABEL = "You must touch a card to be moved";
string UI_CLICK_WHERE_TO_MOVE = "click where you think {0} should be moved";
string UI_CORRECT = "CORRECT!!!!!";
string UI_WRONG = "mmmm... {0} is actually in another place";
string UI_CLICK_WHERE_YOU_THINK = "You must touch where you think {0} is";
string UI_CLICK_ON_TOPLEFT = "Click on the top left of spot area you want to define \nto name a hotspot";
string UI_FINISH_EDITING = "finishing editing";
string UI_NAME_SPOT = "input name of the spot, or . to finish design";
string UI_CLICK_BOTTOMRIGHT = "Click on area bottom right to define '{0}' hotspot";

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
info(string s) { infos(s,[]); }
infos(string s, list args){
	llSay(0,format(s,args));
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
string format(string text, list args)
{
	integer len=llGetListLength(args);
	if(len==0) {
		return text;
	} else {
		string ret=text;
		integer i;
		for(i=0;i<len;i++) {
			integer pos=llSubStringIndex(ret,"{"+(string)i+"}");
			if(pos!=-1) {
				ret=llDeleteSubString(ret,pos,pos+llStringLength("{"+(string)i+"}")-1);
				ret=llInsertString(ret,pos,llList2String(args,i));
			} else {
				return "error";
			}
		}
		return ret;
	}
}

process_line_notecard(string str){
    debug("Processing " + str);
    list pieces = llParseStringKeepNulls(str,["|"],[]);
    integer p = 0;
    string name = llList2String(pieces,0);
    NAMES += llStringTrim(name,STRING_TRIM);
    string rot = llList2String(pieces,1);
    VALUES += [(rotation)rot];
    infos(UI_ADDED_DATA, [name, rot]);
}
// return list of positions for unit testing
list starting_order(integer n) {
	list pos = [];
    integer i;
    for(i=0; i < n; i++) pos+=i;
    return pos;
}
list shuffle(list input) {
	return llListRandomize(input,1);
}

list random_helper(integer n, vector scale, integer random){
	if(n<1) return [];
    debug("performing initial positioning of labels");
    list ret = []; 
    list x = starting_order(n);
    if(random) x = shuffle(x);
    integer i; float delta = scale.z / n;
    for (i = 0; i < n; i++) {
    	 float height = delta * i + delta / 2 - scale.z / 2;
    	vector point = <0, -0.5 * scale.y, height>;
        integer j = llList2Integer(x,i);
        debug("moving label #" + (string)j + " to " +(string)point);
        
        move(j + 2,point);
        ret += point;
    }
    return ret;
}

random() {
	random_helper(llGetNumberOfPrims()-1,llGetScale(), TRUE);
}

setTimer(){
    llSetTimerEvent(0);
    llSetTimerEvent(TIMEOUT);
}
offTimer(){
    llSetTimerEvent(0);
}

string fixed(float input, integer precision){
    if ((precision = (precision - 7) - (precision < 1)) & 0xFFFFFFFF80000000) 
    	return llGetSubString((string)input,0,precision);
    return (string)input;
}
string fixedvector(vector v, integer precision){
    return fixed(v.x,precision) + "," + fixed(v.y,precision);
}



move(integer link, vector to){
    llSetLinkPrimitiveParamsFast(link,[PRIM_POS_LOCAL,to,PRIM_POS_LOCAL,to,PRIM_POS_LOCAL,to]);
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
            infos(UI_FINISHED_NOTECARD,[(string)NCLINE]);
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
        info(UI_CLICK_A_LABEL);
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
        key avatar = llDetectedKey(0); 
        if(avatar==llGetOwner()){
        	llDialog(avatar," ",[ UI_DESIGN, UI_RESET ], 1001);
        } else {
        	info(UI_MUST_CLICK_A_LABEL);
        }
    }

    listen(integer channel,string name,key id,string message) {
        debug("received command " + message);
        message = llToUpper(message);
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
        infos(UI_CLICK_WHERE_TO_MOVE, [LINKNAME]);
        setTimer();
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
                info(UI_CORRECT);
                move(LINKNUMBER,OFFSET);
            }
            else  {
                infos(UI_WRONG, [LINKNAME]);
            }
            offTimer();
            state run;
        }
        else  {
            infos(UI_CLICK_WHERE_YOU_THINK, [LINKNAME]);
        }
    }

    timer() {
        offTimer();
        state run;
    }
}
state design {

    state_entry() {
        LISTENER = -1;
        info(UI_CLICK_ON_TOPLEFT);
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
            info(UI_FINISH_EDITING);
            unlisten();
            state run;
        }
        unlisten();
        state design_bottom_right;
    }


    touch_start(integer total_number) {
        setTimer();
        info(UI_NAME_SPOT);
        LISTENER = llListen(0,"",llDetectedKey(0),"");
        TOPLEFT = llDetectedTouchST(0);
        debug("TOPLEFT: " + (string)TOPLEFT);
    }
}
state design_bottom_right {

    state_entry() {
        infos(UI_CLICK_BOTTOMRIGHT,[SPOTNAME]);
        llListen(-1,"",NULL_KEY,"");
        setTimer();
    }

    touch_start(integer total_number) {
        BOTTOMRIGHT = llDetectedTouchST(0);
        debug("BOTTOMRIGHT: " + (string)BOTTOMRIGHT);
        string rots = "<" + fixedvector(TOPLEFT,3) + "," + fixedvector(BOTTOMRIGHT,3) + ">";
        rotation rot = (rotation)(rots);
        debug("rot: " + rots);
        infos(UI_ADD_TO_NOTECARD,[SPOTNAME,rots]);
        state design;
    }
}
