//
// INFOBOOK 001
// Xyzzy Implementation using board 40x10,
// use index to have a quick look on a notecard

// using states:
// default for setting up
// index
// content



// to debug important things for developing
integer DEBUG=1;
integer TIMERINTERVAL=600;

// internal things
list notecards;
integer currentNotecard;
integer notecardLine;

key notecardKey;

// options related
integer options_timeron=1;
integer privacy=2; // 0 public, 1=group, 2=owner, default owner


string feed;
integer start; // start offset in RSS
integer begin; // start offset in title array
list titles; // where all the titles go
list links;
string title;

/////////////// CONSTANTS ///////////////////
// XyText Message Map.
integer DISPLAY_STRING      = 204000;
integer DISPLAY_EXTENDED    = 204001;
integer REMAP_INDICES       = 204002;
integer RESET_INDICES       = 204003;
integer SET_FADE_OPTIONS    = 204004;
integer SET_FONT_TEXTURE    = 204005;
integer SET_COLOR           = 204007;
integer RESCAN_LINKSET      = 204008;



// privacy option
integer privacy=2; 
// items in MENU
string RESET="reset";
string PRIVACY="privacy";
string TIMER="timer";
string HELP="help";
string REFRESH="refresh";

integer MENUCHANNEL; // listening here for menu

// DEBUG
// Use this whenever you want to say something to developer
// ===========================================================
debug(string x)
{
	if(DEBUG==1) llOwnerSay("DEBUG: "+x);
}
info(string x)
{
	
	llSay(0,x);
	
}
error(string x)
{
	info("ERROR: "+x);
}



help(){
	info("INFOBOOK V1.0 Read Books");
	info("touch the caption for menu. Touch each line for opening up a browser on that news");
	info(" do slideshows ");
}

// XYshow
// show a message on a specific row (0-9)
// use an optional offset
// ==============================================
XYshow(integer row, string x)
{
	
	string lastchar=llGetSubString(x,-1,-1);
	llMessageLinked(LINK_THIS,DISPLAY_STRING,x,(string)row);
	
}


// CLEAN
// be sure the whiteboard is clean now
// ============================================
clean(){
	integer i;
	for(i=0;i<10;i++){
		XYshow(i," ");
	}
	
}

// get a true random channel number
integer randomchannel(){
	integer get_time = llGetUnixTime()/2;
	float time = llFrand((float)get_time);
	return llFloor(time) + 100000000;
	
}
// STATE: INDEX
// load current notecard in memory
// currentNotecard 		set to which notecard to read
// content[] will have the complete content of the notecard
// ====================================================================
loadNote(){
	// clean up memory
	start=0; line=0; content=[];
	// show the title
	XYshow(10,currentNotecard);
	// set up the notereading
	llGetNotecardLine(currentNotecard, line);
	
}

// REFRESH
// refresh content
// using begin for starting index
// =========================================
refresh(){
	// loop over all first titles
	integer i;
	integer j;
	
	for(i=0;i<llGetListLength(content);i++){
		if(i<10){
			XYshow(i,">"+llList2String(titles,i+begin));
			
		}
	}
	
	for(j=i;j<10;j++) XYshow(j," ");
	
}

// DODIALOG
// Just display the actions you want
// ==============================================================================
doDialog()
{
	list actions=[ HELP, RESET, PRIVACY, TIMER, REFRESH ];
	debug("dialog on "+(string)MENUCHANNEL);
	llDialog(llDetectedKey(0), "Choose an action", actions, MENUCHANNEL); // present dialog on click
}

// PROCESSTOUCHED
// understand from the object name which is the correct action
// to do.
integer process_touched(string objname){
	debug("clicked object : "+objname);
	// if cliecked onw of the component lines
	// detect the line no and launch the proper external
	// http viewer
	
	if(llGetSubString(objname,0,8)=="xyzzytext"){
		
		// find the real row
		integer x=(integer)llGetSubString(objname,10,-1);
		if(x<10){
			debug("Should open notecard: "+llList2String(links,x));
			return 1;
		}
		
	}
	
	
	if(objname=="UP") {
		begin-=10;
		if(begin<0)begin=0;
		
		refresh();
		return 1;
	}
	if(objname=="DOWN") {
		begin+=10;
		if((begin+1)>llGetListLength(titles))begin=0;
		
		refresh();
		return 1;
	}
	if(objname=="LEFT") {
		if(currentFeed==0) return;
		currentFeed--;
		changeFeed(llList2String(feeds,currentFeed));
		return 1;
	}
	
	if(objname=="RIGHT") {
		currentFeed++;
		if(currentFeed>=notecardLine) currentFeed=0;
		changeFeed(llList2String(feeds,currentFeed));
		return 1;
	}
	
	
	
	
	return 0;
}

// default will just set up everything and then pass to proper states:
// index and content
default
{
	on_rez(integer parm)
	{
		llResetScript();
	}
	state_entry()
	{
		// random channel to be choosen
		MENUCHANNEL=randomchannel();
		debug("Listening on menu channel "+(string)MENUCHANNEL);
		llListen(MENUCHANNEL,"",NULL_KEY,"");
		
		integer i;
		notecards=[];
		for(i=0;i<llGetInventoryNumber(INVENTORY_NOTECARD);i++)
			notecards+=llGetInventoryName(INVENTORY_NOTECARD,i);
		
		currentNotecard=0;
		// go doing indexing
		state index;
		llSetText(MYNAME,<0,0,0>,0);
		help();
		state index;
	}
}
state index
{
	// on entering in this state must display the listing of notecards available
	state_entry(){
		notecardIndex=0;
		refreshIndex();
	}
	
	
	touch_start(integer total_number)
	{
		// PRIVACY CHECK
		string touched=llGetLinkName (llDetectedLinkNumber(0));
		integer n=(integer)touched;
		
		
		
		if(process_touched(touched)==1) return;
		
		
		// access to menu is blocked
		key id=llDetectedKey(0);
		// allow public only clicking on a news or up/down
		if( id != llGetOwner() )
		{
			
			// group only if key is from same group
			if(privacy==1 && !llSameGroup(id) ) {
				error("Not same group");
				return;
			}
			// only owner can do
			if(privacy==2 ) {
				error("Not owner");
				return;
			}
		}
		
		
		// display menu
		doDialog();
	}
	// instructions must be something like
	// 0:pippo meaning write pippo on row 0
	listen(integer channel, string name, key id, string message)
	{
		// PRIVACY CHECK
		//key id=llDetectedKey(0);
		if( id != llGetOwner() ){
			debug("Not owner");
			// group only if key is from same group
			if(privacy==1 && !llSameGroup(id) ) {
				debug("group privacy violated");
				return;
			}
			// only owner can do
			if(privacy==2 ) {
				debug("Owner privacy violated");
				return;
			}
		}
		debug("received on channel "+(string)channel+" msg "+message);
		// setting new name feed (first the name then a space and the http feed)
		if(channel==FEEDCHANGECHANNEL){
			changeFeed(message);
			
			return;
		}
		// handle menu
		if(message == PRIVACY){
			if( (id==llGetOwner()) ||
				llSameGroup(id) ){
				++privacy;
				if(privacy>2)privacy=0;
				if(privacy==0)llSay(0,"changing privacy to PUBLIC");
				if(privacy==1)llSay(0,"changing privacy to GROUP");
				if(privacy==2)llSay(0,"changing privacy to OWNER");
			}
			return;
		}
		if(message == RESET ){
			debug("resetting script");
			llResetScript();
			return;
		}
		
		if(message == HELP) {
			help();
			return;
		}
		
		if(message == TIMER){
			if(timeron==1)
			{
				llSetTimerEvent(0.0);
				timeron=0;
				info("Timer switched off");
			}
			else
			{
				llSetTimerEvent(TIMERINTERVAL);
				timeron=1;
				info("Timer switched on");
				
			}
			
		}
		if(message == REFRESH )
		{
			info("Refreshing feed...");
			changeFeed(llList2String(feeds,currentFeed));
			info("Feed refreshed");
		}
		
		
	}
	
	// will fully read the notecard and position properly into content
	// uses 
	dataserver(key id, string data)
	{
		debug("dataserver received data: "+data);
		
		if (data != EOF)
		{
			
			// data in: we must display it fully
			
			debug("displaying data on line "+(string)wbline);
			integer i;
			// how many real rows to display, wrap lines longer than if
			// wrap option had been selected
			if(optionsWRAP==1){
				integer numrows=llStringLength(data)/NUMCHARSXROW;
				integer offset=0;
				for(i=0;i<=numrows;i++){
					string msg=llGetSubString(data,offset,offset+NUMCHARSXROW);
					content+=msg;
				}
			}
			else
				content+=
			
			
			// now go fetching next dont do if line > 9
			line = line + 1;
			query = llGetNotecardLine(notecard, line);
			
		} else {
			// last line of text
			// clear overflow flag if set
			// clear lines at bottom
			while(wbline<14){
				wbline++;
				show("",wbline);
			}
			debug("setting overflow to false");
			llSetText("Notecard complete",<1,1,1>,1);
			overflow=0;
			wbline=0;
		}
		
	}
	
}
