//
// INFOBOOK 001
// Xyzzy Implementation using board 10rowX40cols,

// Features:
// 1\ use index to have a quick look on a notecard
// 2\ privacy settings
// 3\ wordwrapping setting (but without scrolling left/right)
// 4\ Possibility of automated slideshow with configurable time=0=off,5,10,15sec

// using states:
// default for setting up
// index for dealing with notecard choosing
// content for dealing with actual content



// to debug important things for developing
integer DEBUG=0;
string MYNAME="INFOBOOK V1.0";
integer ROWS=10;
integer COLS=40;



// options related
float optionsTimer=10; // can be 10 or 60 (10 sec or 60 sec before switching)
integer optionsPrivacy=2; // 0 public, 1=group, 2=owner, default owner
integer optionsWRAP=1; // 0 don't wrap 1 wrap lines
integer play=0; // if automatic slideshow on


// items in MENU
string RESET="reset";
string PRIVACY="privacy";
string TIMER="timer(10/60s)";
string WRAP="wrap";
string HELP="help";
string MENU="menu";


// DEBUG/COMMUNICATION FUNCTIONS FUNCTIONS
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

// Handle privacy

integer privacy(key id){
	// allow public only clicking on a news or up/down
	if( id != llGetOwner() )
	{
		
		// group only if key is from same group
		if(optionsPrivacy==1 && !llSameGroup(id) ) {
			error("Not same group");
			return 0;
		}
		// only owner can do
		if(optionsPrivacy==2 ) {
			error("Not owner");
			return 0;
		}
		
	}
	// ok we have the right of doing this
	return 1;
}

// Help will display README??
help(){
	info(MYNAME);
	info("touch the caption for menu.");
	info(" do slideshows ");
}

// XYshow
// show a message on a specific row (0-9)
// use an optional offset
// ==============================================
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


XYshow(integer row, string x)
{
	llMessageLinked(LINK_THIS,DISPLAY_STRING,x,(string)row);
	
}
// CLEAN
// be sure the whiteboard is clean now
// ============================================
XYclean(){
	integer i;
	for(i=0;i<ROWS;i++){
		XYshow(i," ");
	}
	
}
XYtitle(string title)
{
	integer padding=(20-llStringLength(title))/2;
	while(padding>0) {
		title=" "+title;
		padding--;
	}
	XYshow(ROWS,title);
}

////////////////////////////////////////////////////////////////////////////////////////
// DIALOG/MENU  SECTION
integer MENUCHANNEL; // listening here for menu using random functions
// selects a true random channel number
randomchannel(){
	integer get_time = llGetUnixTime()/2;
	float time = llFrand((float)get_time);
	MENUCHANNEL = llFloor(time) + 100000000;
	
}

// do effective listening
doListen()
{
	llListen(MENUCHANNEL,"",NULL_KEY,"");
}

// DODIALOG
// Just display the actions you want
// ==============================================================================
doDialog()
{
	list actions=[ HELP, RESET, PRIVACY, TIMER, WRAP, MENU ];
	debug("dialog on "+(string)MENUCHANNEL);
	llDialog(llDetectedKey(0), "Choose an action", actions, MENUCHANNEL); // present dialog on click
}

// interpretMenu. If anything correctly done returns 1 otherwise 0
integer interpretMenu(key id,string message)
{
	if(message == MENU){
		state index;
	}
	// handle menu
	if(message == PRIVACY){
		if( (id==llGetOwner()) ||
			llSameGroup(id) ){
			++optionsPrivacy;
			if(optionsPrivacy>2)optionsPrivacy=0;
			if(optionsPrivacy==0)info("changing privacy to PUBLIC");
			if(optionsPrivacy==1)info("changing privacy to GROUP");
			if(optionsPrivacy==2)info("changing privacy to OWNER");
		}
		return 1;
	}
	if(message == RESET ){
		info("resetting script");
		llResetScript();
		return 1;
	}
	
	if(message == HELP) {
		help();
		return 1;
	}
	
	if(message == TIMER){
		if(optionsTimer==10.0)
		{
			
			optionsTimer=60.0;
			info("Timer time 60sec");
		}
		else
		{
			
			optionsTimer=10.0;
			info("Timer time 10sec");
			
		}
		return 1;
		
	}
	if(message == WRAP ){
		if(optionsWRAP==0)
		{
			optionsWRAP=1;
			info("Wrap ON");
		}
		else
		{
			optionsWRAP=0;
			info("Wrap OFF");
		}
	}
	return 0;
}

// REFRESH INDEX
// refresh content
// using indexNotecard for starting index
// =========================================
refreshIndex(){
	// loop over all first titles
	integer i;
	integer j;
	
	for(i=0;i<10;i++){
		j=i+indexNotecard;
		if(j<numNotecards){
			XYshow(i,">"+llList2String(notecards,j));
		} else XYshow(i," ");
	}
	
}

// REFRESH CONTENT
// refresh content
// using indexNotecard for starting index
// =========================================
refreshContent(){
	// loop over all first titles
	integer i;
	integer j;
	
	for(i=0;i<10;i++){
		j=i+indexContent;
		if(j<numContent){
			XYshow(i,llList2String(contents,j));
		} else XYshow(i," ");
	}
}
doPlay()
{
	
	indexContent+=ROWS;
	if((indexContent+1)>numContent)
	{
		llSetTimerEvent(0.0); // stop timer for now waiting completion of reading
		indexNotecard+=1;
		if((indexNotecard+1)>numNotecards) indexNotecard=0;
		currentNotecard=llList2String(notecards,indexNotecard);
		indexContent=0; numContent=0; notecardLine=0; contents=[];
		llGetNotecardLine(currentNotecard, numContent);
		XYtitle(currentNotecard);
	}
	else
	{
		refreshContent();
	}
	
}
// internal things for index status
list notecards;
string currentNotecard;
integer notecardLine; // dataserver temporary
integer numNotecards=0;
integer indexNotecard=0;

key notecardKey;


// internal things for content status
list contents=[];
integer indexContent=0;
integer numContent=0;



// default will just set up everything and then pass to proper states:
// index and content
default
{
	on_rez(integer parm)
	{
		llResetScript();
	}
	touch_start(integer num){
	}
	state_entry()
	{
		// random channel to be choosen for substates
		randomchannel();
		debug("Listening on menu channel "+(string)MENUCHANNEL);
		
		integer i;
		notecards=[];
		for(i=0;i<llGetInventoryNumber(INVENTORY_NOTECARD);i++){
			notecards+=llGetInventoryName(INVENTORY_NOTECARD,i);
			numNotecards++;
		}
		
		
		llSetText(MYNAME,<0,0,0>,0);
		help();
		state index;
	}
}





//////////////////////////////////////////////////////////////////
// SHOWING NOTECARD CONTENT ALLOWING CLICKING ON EACH LINE
//////////////////////////////////////////////////////////////////
state index
{
	// on entering in this state must display the listing of notecards available
	state_entry(){
		debug("Entering index state");
		indexNotecard=0;
		refreshIndex();
		contents=[];
		XYtitle("INDEX");
		// allow menu actions
		doListen();
		play=0;
	}
	
	
	touch_start(integer total_number)
	{
		// check we can do it
		if(privacy(llDetectedKey(0))==0) return;
		
		// do whatever needed
		string objname=llGetLinkName (llDetectedLinkNumber(0));
		debug("clicked object : "+objname);
		
		// if clicked one of the component lines
		// detect the line no and launch the proper external
		// http viewer
		
		if(llGetSubString(objname,0,8)=="xyzzytext"){
			
			// find the real row
			integer x=(integer)llGetSubString(objname,10,-1);
			if(x<10){
				currentNotecard=llList2String(notecards,x);
				debug("Should open notecard: "+llList2String(notecards,x));
				
				// change state to render actual notecard
				state content;
			}
			
		}
		
		
		if(objname=="UP") {
			indexNotecard-=ROWS;
			if(indexNotecard<0)indexNotecard=0;
			
			refreshIndex();
			return;
		}
		if(objname=="DOWN") {
			indexNotecard+=ROWS;
			if((indexNotecard+1)>numNotecards) indexNotecard=0;
			
			refreshIndex();
			return;
		}
		if(objname=="PLAY"){
			play=1;
			currentNotecard=llList2String(notecards,indexNotecard);
			info("slideshow starting");
			state content;
			
		}
		
		
		
		// display menu if not clicked on a cell or up/down
		doDialog();
	}
	// instructions must be something like
	// 0:pippo meaning write pippo on row 0
	listen(integer channel, string name, key id, string message)
	{
		debug("received on channel "+(string)channel+" msg "+message);
		
		
		// privacy checking
		if(privacy(id)==0) return;
		
		if(interpretMenu(id,message)==1) return;
		
		
		
	}
}



// must openup the currentNotecard and show its content
state content
{
	// notecard
	state_entry(){
		
		indexContent=0; numContent=0; notecardLine=0;
		llGetNotecardLine(currentNotecard, numContent);
		XYtitle(currentNotecard);
		if(play==1) llSetTimerEvent(optionsTimer);
		
	}
	
	touch_start(integer total_number)
	{
		// check we can do it
		if(privacy(llDetectedKey(0))==0) return;
		
		// do whatever needed
		string objname=llGetLinkName (llDetectedLinkNumber(0));
		debug("clicked object : "+objname);
		
		
		
		if(objname=="UP")
		{
			indexContent-=ROWS;
			if(indexContent<0)indexContent=0;
			
			refreshContent();
			return;
		}
		if(objname=="DOWN")
		{
			indexContent+=ROWS;
			if((indexContent+1)>numContent)indexContent=0;
			
			refreshContent();
			return;
		}
		if(objname=="PLAY") {
			if(play==0)
			{
				llSetTimerEvent(optionsTimer);
				play=1;
				doPlay();
				info("Slideshow started");
			}
			return;
		}
		if(objname=="STOP") {
			if(play==1)
			{
				play=0;
				llSetTimerEvent(0.0);
				info("Slideshow stopped");
			}
			return;
		}
		
		// display menu if not clicked on a cell or up/down
		doDialog();
	}
	timer()
	{
		debug("timer started");
		doPlay();
	}
	// instructions must be something like
	listen(integer channel, string name, key id, string message)
	{
		debug("received on channel "+(string)channel+" msg "+message);
		
		
		// privacy checking
		if(privacy(id)==0) return;
		
		if(interpretMenu(id,message)==1) return;
		
		
		
	}
	
	// will fully read the notecard and position properly into content
	// uses
	dataserver(key id, string data)
	{
		debug("dataserver received data: "+data);
		
		if (data != EOF)
		{
			
			// data in: we must display it fully
			
			
			integer i;
			// how many real rows to display, wrap lines longer than if
			// wrap option had been selected
			if(optionsWRAP==1){
				integer numrows=llStringLength(data)/COLS+1;
				integer offset=0;
				for(i=0;i<numrows;i++){
					string msg=llGetSubString(data,offset,offset+COLS);
					contents+=msg;
					offset+=COLS;
					numContent++;
				}
			}
			else {
				contents+=data;
				numContent++;
			}
			notecardLine++;
			
			
			// now go fetching next dont do if line > 9
			llGetNotecardLine(currentNotecard, notecardLine);
			
		} else {
			debug("Finishing Read notecard.");
			// display it
			doListen();
			refreshContent();
			if(play==1) llSetTimerEvent(optionsTimer);
		}
		
	}
	
}
