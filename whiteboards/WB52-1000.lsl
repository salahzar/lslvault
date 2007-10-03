//
// V0.52 Whiteboard able to show notecard
// enahncements:
// 1\ will use object name as start for channel: ex WB51-1000 will accept /1001 for first line etc
// 2\ menu channel now is randomly choosed
// 3\ if line begins with /1001 @text will use
// 4\ PRIVACY option, possibility of letting it be touched and modified by GROUP, OWNER, or public.

//
integer DEBUG=0;
integer TITLE      = 204000;

list notelist=[];
integer startchannel=0;
integer privacy=0; // 0 public, 1=group, 2=owner

string CLEAN="+clean";
string RESET="+reset";
string PURGENOTES="+purgenotes";
string PRIVACY="+privacy";
string HELP="+help";

// important to draw on the 3 objects composing each line
string str0; // first 10 chrs  parsed
string str1; // second set of 10 chrs parsed
string str2; // third set of 10 chrs parsed

// Used to read the notecard
key query;
integer line;
integer wbline; // line currently displayed on the whiteboard
string notecard;
integer overflow=0; // in case notecard more than 10 lines touching it will scroll

integer CHANNEL=100000; // listening here for menu
integer LINK_PIECES=1000; // initial identity of 30 pieces (until 1029)
debug(string x)
{
	if(DEBUG==1) llOwnerSay(x);
}

help(){
	llSay(0,"V0.52 Whiteboard by Salahzar Stenvaag");
	llSay(0,"help - this help");
	llSay(0,"clean - clean the whiteboard");
	llSay(0,"/x text as in /1 line will display line of first line");
	llSay(0,"              /10 line will display line on the last line");
}

// show a message on a specific row (0-9)
show(integer row)
{
	integer ch=LINK_PIECES + (row * 3);
	
	llMessageLinked(LINK_SET,ch,str0,NULL_KEY);
	llMessageLinked(LINK_SET,ch+1,str1,NULL_KEY);
	llMessageLinked(LINK_SET,ch+2,str2,NULL_KEY);
	
}
showChannel(integer row, integer cmdoffset, string str)
{
	debug("on line "+(string)row+ "cmdoffset: "+(string)cmdoffset+" "+str);
	integer ch=LINK_PIECES + (row * 3);
	
	llMessageLinked(LINK_SET,cmdoffset+ch,str,NULL_KEY);
	llMessageLinked(LINK_SET,cmdoffset+ch+1,str,NULL_KEY);
	llMessageLinked(LINK_SET,cmdoffset+ch+2,str,NULL_KEY);
}

// split 30 character line in 3 pieces to be suitable to be sent to individual elements
split(string x, integer init){
	str0=llGetSubString(x,init+0,init+9);
	str1=llGetSubString(x,init+10,init+19);
	str2=llGetSubString(x,init+20,init+29);
	debug(str0+"/"+str1+"/"+str2);
}

// be sure the whiteboard is clean now
clean(){
	integer i;
	for(i=0;i<30;i++){
		llMessageLinked(LINK_SET,LINK_PIECES+i," ",NULL_KEY);
		// set standard black color
		llMessageLinked(LINK_SET,LINK_PIECES+i+700,"<0,0,0>",NULL_KEY);
		// set standard size
		llMessageLinked(LINK_SET,LINK_PIECES+i+600,".366",NULL_KEY);
	}
	// set standard black color
	
}
// Used to read all the notecard on this object
readtitles(){
	string text="List of current notes\n";
	integer i;
	notelist=[];
	for(i=0;i<llGetInventoryNumber(INVENTORY_NOTECARD);i++){
		string notecard=llGetInventoryName(INVENTORY_NOTECARD,i);
		text+=(string)i+"\ "+notecard+"\n";
		notelist+=notecard;
	}
	
	// show owner what we discovered
	debug(text);
	
}
doDialog()
{
	list actions=notelist + [ CLEAN, RESET, PURGENOTES, PRIVACY ];
	llDialog(llDetectedKey(0), "Choose an action", actions, CHANNEL); // present dialog on click
}
readnotecard(){
	line = 0;
	debug("Reading notecard "+notecard+"...");
	query = llGetNotecardLine(notecard, line);
	
}
default
{
	state_entry()
	{
		// random channel to be choosen
		integer get_time = llGetUnixTime()/2;
		float time = llFrand((float)get_time);
		CHANNEL = llFloor(time) + 100000000;
		debug("Listening on channel "+(string)CHANNEL);
		//llSay(0, "Say /100 row: message!");
		llAllowInventoryDrop(TRUE);
		list l= llParseString2List(llGetObjectName(),["-"],[]);
		if(llGetListLength(l)>1){
			startchannel=llList2Integer(l,1);
			debug("Listening to channel starting from "+(string)startchannel);
		}
		
		// listen to channels from 1 to 10 for direct
		integer i;
		llListen(startchannel,"",NULL_KEY,"");
		for(i=startchannel+1;i<startchannel+11;i++){
			llListen(i,"",NULL_KEY,"");
			llListen(i+700,"",NULL_KEY,"");
			llListen(i+600,"",NULL_KEY,"");
		}
		// listen for menu command
		llListen(CHANNEL,"",NULL_KEY,"");
		
		
		
	}
	changed(integer c)
	{
		
		if (c & CHANGED_INVENTORY) {
			readtitles();
			doDialog();
		}
	}
	
	touch_start(integer total_number)
	{
		key id=llDetectedKey(0);
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
		string touched=llGetLinkName (llDetectedLinkNumber(0));
		debug("touched object: "+touched);
		if(touched == "NEXT")
		{
			
			if(overflow==1){
				debug("overflow so clean previous page");
				clean();
				// go on reading lines from notecard
				wbline=-1;
				query = llGetNotecardLine(notecard, line);
				
			}
			return;
			
		}
		
		
		else if(touched == "PREV")
		{
			if(overflow==1){
				debug("overflow so clean previous page");
				clean();
				// go on reading lines from notecard
				wbline=-1; line-=10;
				if(line<0) line=0;
				query = llGetNotecardLine(notecard, line);
				
			}
			return;
			
		}
		debug("standard touch");
		readtitles();
		doDialog();
		
	}
	// instructions must be something like
	// 0:pippo meaning write pippo on row 0
	listen(integer channel, string name, key id, string message)
	{
		if(id != llGetOwner() ){
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
		if(channel==startchannel){
			// set title
			llMessageLinked(LINK_SET,TITLE,message,NULL_KEY);
			return;
		}
		if(channel>startchannel && channel<(startchannel+11)){
			channel-=startchannel;
			split(message,0);
			show(channel-1);
			return;
		}
		if(channel > (startchannel+700) &&              channel<(startchannel+711) )
		{
			// change color get it and send in turn to
			showChannel(channel-700-startchannel-1,700,message);
		}
		if(channel > (startchannel+600) &&              channel<(startchannel+611) )
		{
			// change thickness get it and send in turn to
			showChannel(channel-600-startchannel-1,600,message);
		}
		if(channel==CHANNEL){
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
				clean();
				return;
			}
			if(message==CLEAN) {
				debug("cleaning script");
				clean();
				return;
			}
			if(message==PURGENOTES){
				integer i;
				for(i=0;i<llGetListLength(notelist);i++){
					string note=llList2String(notelist,i);
					llRemoveInventory(note);
				}
				llResetScript();
				clean();
				return;
			}
			
			if(message==HELP){
				help();
				return;
			}
			debug("You have chosen to show on the whiteboard the notecard named "+message);
			notecard=message;
			// be sure whiteboard is clean
			clean();
			
			// activate dataserver
			wbline=-1;
			readnotecard();
			return;
			
		}  // end menu part
		
	}
	// this is where the fun is: get each line and showing it on the whiteboard (max 10 lines)
	dataserver(key id, string data)
	{
		debug("dataserver received data: "+data);
		
		if (data != EOF)
		{
			
			if(llGetSubString(data,0,0)=="/"){
				debug("a comment line, skipping it");
				line++;
				query = llGetNotecardLine(notecard, line);
				return;
			}
			// data in: we must display it fully
			
			debug("displayng data on line "+(string)wbline);
			integer i;
			integer numrows=llStringLength(data)/10;
			integer offset=0;
			for(i=0;i<=numrows;i++){
				split(data,offset);
				if(str0!="" || str1!="" || str2!=""){
					wbline++;
					if(wbline<10) {
						show(wbline);
						offset+=30;
					} else {
						// must reread the previous line
						//line--;
						jump over;
					}
				}
			}
			@over;
			if(wbline>=10) {
				debug("stopping reading since more than 10 lines");
				// now go fetching next but check if more than lines to be written
				
				// no more room for this line so we set overflow true
				overflow=1; // when in overflow, touch will display next page
				debug("Will overflow");
				llSetText("There are other pages, touch for them...",<1,0,0>,1);
				wbline=-1;
				return;
			}
			
			
			// now go fetching next dont do if line > 9
			line = line + 1;
			query = llGetNotecardLine(notecard, line);
			
		} else {
			// last line of text
			// clear overflow flag if set
			debug("setting overflow to false");
			llSetText("Notecard complete",<1,1,1>,1);
			overflow=0;
			wbline=0;
		}
		
	}
	
	
}
