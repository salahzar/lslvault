//
// RSS121
// developed for rezzable.com
// Oct 2007
// Salahzar Stenvaag


// remote RSS php returning link1<br>title1<br> simple feeds
//string SALRSS = "http://www.differenceengineers.com/rssrezz/rss_reader.php?";
string SALRSS = "http://www.salahzar.info/lsl/rezzable.php?";

integer WHISPERCHANNEL=31415; // if <>0 will use this channel and whispering instead of linked set channel
key avatar=NULL_KEY;

integer RSSROWS=5; // number of news which are viewed at one TIME
integer RSSTITLE=0; //
integer CHANNEL=-1;
integer MAXTITLES=10;

// for reading SETUP
string NOTECARD="SETUP";
integer notecardline=0;

integer ENABLELEASE=1;
integer KILLBUBBLES=0;
string OBJNAME="Bubble";
integer LISTENINGCHANNEL=1;
float BUOYANCY=1.001;


vector OFFSETBUBBLE=<0,0,1>;
vector MAXPUSH=<0.01,0.01,0.01>;
integer WRAPCOLUMN=40;
string MOREVERB="MORE";
string PREVVERB="PREV";
string NEXTVERB="NEXT";
vector OMEGAAXIS=<0,0,5>;
float OMEGASPINRATE=1;
float OMEGAGAIN=1;
integer REVERSED=1;
integer ptr_news=0;

integer listenerLeasing;
integer listenerMenu;
// TIMER stuff
integer TIMER_IDLE=60; // every minute just do something
integer TIMER_REFRESH=3600; // every hour just refresh
integer TIMER_LEASE=20; // 20 sec for leasing

integer timer_state; // current timer state (one of the timer_idle or timer_lease values

integer timer_idle=0; // timer idle
integer total_idle=0; // accumulator to understand when IDLE becomes refresh
integer timer_lease=2; // timer if somebody leased the object

integer DEBUG=0;    // debug, coming from object name

// when clicked copy description and url here
string description;
string link;
string title;

integer start; // start offset in RSS
integer begin; // start offset in title array

// title stuff
string label;
string locked;
//==================================================================
// UTILITY FUNCTIONS
// DEBUG
// Use this whenever you want to say something to developer
// ===========================================================
debug(string x)
{
    if(DEBUG==1) llOwnerSay("DEBUG(main): "+x);
}
info(string x)
{
    llSetText(x,CLINE,1);
    debug(x);
}
setTitle(string x)
{
    llSetText(x,CTITLE,1);
}
error(string x)
{
    info("ERROR: "+x);
}
// utility function
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
        + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

//====================================================================
// DB handling interface. Each object handles around 8K of information
// PARSER is special, used to parse rss feed
// PROTOCOL OF COMMUNICATION:
// UDP: JUST ONESHOT COMMAND
// TCP: WAIT FOR AN ANSWER IN OBJECT DESCRIPTION
//
// cmd: an integer number specifying which command
// bank: which bank object to send the message
// name: first parameter (usually the name of the key)
// value: 2nd parameter usually the description of the key
//====================================================================
// indexes of database objects keeping the values
integer DB_URLS=1;
integer DB_TITLES=2;
integer DB_DESC=3;
integer PARSER=4;
integer MAXTIMEOUT=10; // 10 secs timeout

// commands to be sent to DB object
integer ADD=1;
integer LOAD=2;
integer NUM=3; integer PARSE=3;
integer DEL=4;
integer RST=5;
integer FREE=6;

string WAIT="==WAIT==";

// UDP: ONE SHOT COMMAND DON'T EXPECT AN ANSWER (very fast, don't wait for answer
fireCmd(integer cmd, integer bank, string name, string value)
{
    llMessageLinked(LINK_THIS,bank,value,(key)((string)cmd+name));
}

// TCP: wait for an answer and return it back from Object Description
string waitCmd(integer cmd,integer bank,string name,string value)
{
    // put WAIT descriptor there
    llSetObjectDesc(WAIT);

    // send the command
    llMessageLinked(LINK_THIS,bank,value,(key)((string)cmd+name));

    // wait for object description being changed. If slave object is very fast
    // we might even not wait at all
    string ret=llGetObjectDesc();
    float time=0;
    while(ret==WAIT)
    {
        time+=0.05;

        // if more than 10 secs something is going bad return an error
        if(time>MAXTIMEOUT) return "TIMEOUT";
        llSleep(0.05);
        ret=llGetObjectDesc();
    }
    return ret;
}
// DB HANDLING INTERFACE END
//============================================================================

// privacy option
integer privacy=2; // 0 public, 1=group, 2=owner, default owner

// items in MENU
string RESET="reset";
string REFRESH="refresh";
string PURGE="remBubbles";
string HELP="help";
integer MENUCHANNEL; // listening here for menu


//=========================================================================
// HANDLING TEXT COMMUNICATION VS LINKED SET OR WHISPERING SET
//=========================================================================

vector BLACK=<0,0,0>;
vector RED=<1,0,0>;
vector GREEN=<0,1,0>;
vector WHITE=<1,1,1>;
vector YELLOW=<1,1,0>;
vector CTITLE=YELLOW;
vector CLINE=WHITE;


//=====================================================================
// RSS parsing part (triggered by rss
// set feed to the name of the feed you want to load
// and just trigger rss()
//
key     reqid_load;                          // http requestid
integer CHUNK_SIZE = 2048;
integer NEEDEDMEMORY=7000;
integer numtitles;
rss(){


    string url = SALRSS;
    //string str = "feed="+feed+"&nodesc=1&start="+(string)start;
    //string str = "feed="+feed+"&start="+(string)start;
    string str="start="+(string)start+"&reverse="+(string)REVERSED;


    debug(url + " " + str);
    reqid_load=llHTTPRequest( url, [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded;charset=utf-8"],str);
    if(reqid_load==NULL_KEY)
        error("Request had been throttled! ... :(");

    // next action done by http_request handler

}
// call this when you are receiving a chunk from HTTP
rss_load(string body)
{
    integer bodylen=llStringLength(body);
    info("received a body, length="+(string)bodylen);
    //debug("Body: "+body);

    // something received
    if(bodylen>1)
    {
        // add this to the parser
        waitCmd(ADD,PARSER,"<br>",body);

        // ask the parser how much free memory
        list  ret=llCSV2List(waitCmd(FREE,PARSER,"",""));
        integer parserfree=(integer)llList2String(ret,0);
        integer curtitles=(integer)llList2String(ret,1);
        info("Received a chunk from rss, parserfree: "+(string)parserfree
            + " # titles: "+(string)curtitles);

        // if enough free memory read again
        if(parserfree>NEEDEDMEMORY && (curtitles/3) < MAXTITLES)
        {
            info("asking next chunk");
            start+=CHUNK_SIZE;
            rss();
            return;
        }
    }

    // PARSE the long string
    debug("parsing the big stuff");
    integer length=(integer)waitCmd(PARSE,PARSER,"<br>","");
    debug("Found "+(string)length+" lines in feed");
    debug((string)llGetFreeMemory());
    integer i;
    // loop over all the strings and store in proper db to be able to find them
    // later
    numtitles=0;
    for(i=0;i<length;)
    {
        info(" Parsing news #"+(string)(numtitles+1)+"/"+(string)(length/3));
        string tmp;
        tmp=waitCmd(LOAD,PARSER,(string)i++,"");
        waitCmd(ADD,DB_URLS,"",tmp);
        debug("load parser");
        tmp=waitCmd(LOAD,PARSER,(string)i++,"");
        //debug("add titles");
        waitCmd(ADD,DB_TITLES,"",tmp);
        //debug("load parser");
        tmp=waitCmd(LOAD,PARSER,(string)i++,"");
        //debug("add descs");
        waitCmd(ADD,DB_DESC,"",tmp);
        //llSleep(0.1);
        numtitles++;
    }
    // limit titles
    if(numtitles>MAXTITLES) numtitles=MAXTITLES;
    //numtitles--;
    info("Found "+(string)numtitles+" news");

    // free memory we don't have anything now in this object
    debug("Free memory in main object: "+(string)llGetFreeMemory());

    begin=0;
    refresh();
    timer_state=timer_idle;
    locked="";
    ptr_news=0;

    llSetTimerEvent(TIMER_IDLE);
    if(ENABLELEASE==0)
    {
        debug("listening to channel: "+(string)LISTENINGCHANNEL);
        llListen(LISTENINGCHANNEL,"",NULL_KEY,"");
    }

}
// end of RSS related thing
//===============================================================================


help(){
    info("RSS V133 RSS Reader by Salahzar Stenvaag");
}
// get a true random channel number for menu dialog
integer randomchannel(){
    integer get_time = llGetUnixTime()/2;
    float time = llFrand((float)get_time);
    return llFloor(time) + 100000000;

}
//
// from a message like BBC http:// do whatever needed to set title and
// show the feed as in currentFeed
// ====================================================================
refreshFeed(){
    debug("refreshing feed");
    // turns off the timer!!!
    llSetTimerEvent(0);
    // clean up memory and database scripts
    start=0;
    fireCmd(RST,DB_URLS,"","");
    fireCmd(RST,DB_TITLES,"","");
    fireCmd(RST,DB_DESC,"","");
    fireCmd(RST,PARSER,"","");



    // HERE IS THE CORE CALL READING THE FEED
    info("Loading FEED...");
    rss();
}

// REFRESH
// refresh content from titles
// using begin for starting index
// offset for viewing left-right
// =========================================
refresh(){
    // loop over all first titles
    // display(RSSTITLE,title,CTITLE);
    integer i;
    debug("Getting titles from db-titles");

    label="";
    for(i=0;i<RSSROWS;i++){
        integer pos=i+begin;
        if(pos<numtitles){
            string row=llToUpper(waitCmd(LOAD,DB_TITLES,(string)pos,""));
            debug("row "+(string)(pos+1)+" display "+row+" "+(string)llGetFreeMemory());
            label=(label="")+label+(string)(pos+1)+". "+row+"\n";
        }
    }
    setTitle(label+locked);


}


// THIS SPLITS A LONG DESCRIPTION IN ROWS WITH \NL TO BE PROPERLY DISPLAYED BY LLSETTEXT
string wrapEntry(integer k, integer maxrow)
{

    //link=waitCmd(LOAD,DB_URLS,(string)(k),"");
    //link=llStringTrim(link,STRING_TRIM);
    description=waitCmd(LOAD,DB_DESC,(string)(k),"");
    debug("should wrap description: "+description);
    list words=llParseString2List(description,[" "],[]);
    string line=llList2String(words,0);

    integer index=1; integer numwords=llGetListLength(words);
    string buffer="";

    while(index<numwords)
    {
        string word=llList2String(words,index);
        if(llStringLength(line+word+" ")<maxrow) line+=" "+word;
        else {
            buffer+=line+"\n";
            line=word;
        }
        index++;
    }
    //debug("returning buffer: "+buffer);
    return buffer+line;
}

purge()
{
    debug("Killing bubbles...");
    llShout(WHISPERCHANNEL,"DIE!!!");
}

//
// MAIN STATE OF THIS OBJECT
//

string help_say()
{
    if(LISTENINGCHANNEL==0)
        return "use "+PREVVERB+" "+NEXTVERB+" "+MOREVERB+" # to get info";
    else
        return "use /"+(string)LISTENINGCHANNEL+" "+MOREVERB+" /"+(string)LISTENINGCHANNEL+" "+NEXTVERB+" /"+(string)LISTENINGCHANNEL+" "+MOREVERB+" # to get info";
}

rez_bubble(integer pos)
{
    debug("Rezzing "+OBJNAME+" for news#"+(string)pos+" and talking at "+(string)WHISPERCHANNEL);
    integer ch=WHISPERCHANNEL;
    // if(DEBUG==1) ch=-ch; // pass debug information to bubble :)
    vector offset=OFFSETBUBBLE+<llFrand(4)-2,llFrand(4)-2,0>;
    llRezObject(OBJNAME,llGetPos()+offset,<llFrand(MAXPUSH.x),llFrand(MAXPUSH.y),llFrand(MAXPUSH.z)>,ZERO_ROTATION,ch); // to inform the bubble to also debug
    vector bubblecolor=<llFrand(1),llFrand(1),llFrand(1)>;
    llWhisper(WHISPERCHANNEL,"B"+(string)BUOYANCY);
    llWhisper(WHISPERCHANNEL,"K"+(string)bubblecolor); // random color for the bubble
    llWhisper(WHISPERCHANNEL,"C"+(string)bubblecolor); // use CLINE as color
    llWhisper(WHISPERCHANNEL,"L"+(string)waitCmd(LOAD,DB_URLS,(string)(pos-1),""));
    llWhisper(WHISPERCHANNEL,"D"+llToUpper(waitCmd(LOAD,DB_TITLES,(string)(pos-1),""))+"\n"+wrapEntry((pos-1),WRAPCOLUMN));
}

default
{
    // whenever taken out from inventory do reset
    on_rez(integer parm)
    {

        llResetScript();

    }

    // set rotation and start reading configuration
    state_entry()
    {
        // clean up memory and database scripts
        start=0;
        fireCmd(RST,DB_URLS,"","");
        fireCmd(RST,DB_TITLES,"","");
        fireCmd(RST,DB_DESC,"","");
        fireCmd(RST,PARSER,"","");
        // no sleep
        // slow rotation
        llTargetOmega(OMEGAAXIS,OMEGASPINRATE,OMEGAGAIN);


        // present ourself
        help();



        // read notecard, at end will read the rss
        notecardline=0;
        llGetNotecardLine(NOTECARD,notecardline);

    }

    // if timer elapsed.
    // timer_lease when object has been leased
    // timer_idle (we must refresh info every 10 minutes)
    timer(){
        debug("timer called");
        if(timer_state==timer_lease)
        {
            debug("expiring lease");
            // LEASE expired
            llDialog(avatar,"Timer expired. Touch again to keep in asking news!",[],-1);

            avatar=NULL_KEY;
            // remove leasing note from title
            locked="";
            setTitle(label);

            // remove listener so that the avatar cannot do again
            llListenRemove(listenerLeasing);

            timer_state=timer_idle;
            llSetTimerEvent(TIMER_IDLE);

            // purge left bubbles
            purge();
            return;
        }
        if(timer_state==timer_idle)
        {
            debug("timer_idle "+(string)ptr_news);
            total_idle+=TIMER_IDLE;
            if(total_idle>=TIMER_REFRESH)
            {
                llResetScript();
                refreshFeed();
                total_idle=0;
            }

            ptr_news++;
            if(ptr_news-begin>RSSROWS || ptr_news > numtitles)
            {

                // loop over all titles when idle
                begin+=RSSROWS;
                if((begin+1)>numtitles)
                {
                    begin=0;
                    ptr_news=1;
                }
                refresh();

            }
            rez_bubble(ptr_news);


            // next iteration
            llSetTimerEvent(TIMER_IDLE);

        }

    }

    // when touched
    touch_start(integer total_number)
    {


        debug("touch_start");
        key id=llDetectedKey(0);
        // check if the booth is currently locked
        if(id==avatar)
        {
            llDialog(id,help_say(),[],-1);
            return;
        }
        if(ENABLELEASE==1)
        {
            if(avatar != NULL_KEY && id!=avatar)
            {
                // tell the avatar he should wait
                llDialog(id,"already locked by "+llKey2Name(avatar)+".. Retry later..",[],-1);
                return;
            }

            debug("locking to avatar "+(string)id);
            avatar=id;
            locked="(locked by "+llKey2Name(avatar)+")";
            llListenRemove(listenerLeasing);
            listenerLeasing =llListen(LISTENINGCHANNEL,"",id,"");
            setTitle(label+locked);
        }

        debug("setting menu");
        // inform the avatar
        list menu=[];
        // allow owner to reset the feed reader
        if(id==llGetOwner()) menu+=["OK", PURGE, RESET, REFRESH ];

        CHANNEL=randomchannel();
        listenerMenu=llListen(CHANNEL,"",id,"");


        llDialog(id,help_say(),menu,CHANNEL);
        // if nothing happens within 20 seconds free the booth
        if(ENABLELEASE==1)
        {
            debug("setting timer for leasing");
            timer_state=timer_lease;
            llSetTimerEvent(TIMER_LEASE);
        }

    }
    // listening to avatar (channel 1 and channel random)
    listen(integer channel, string name, key id, string message)
    {
        debug("received on channel "+(string)channel+" msg "+message+" avatar: "+(string)id);
        llListenRemove(listenerMenu);
        if(ENABLELEASE==1 && id!=avatar && id!=llGetOwner())
        {
            debug("Not allowed listen from avatar "+(string)id);
            return;
        }
        if(id==llGetOwner())
        {

            if(message == RESET )
            {
                debug("resetting script");

                llResetScript();
                state default;
                return;
            }
            if(message == PURGE )
            {
                debug("received purge command");
                purge();
                return;
            }
            if(message == REFRESH)
            {
                debug("received refresh command");
                refreshFeed();
                total_idle=0;
                return;

            }

        }
        // repeat the leasing
        if(ENABLELEASE) llSetTimerEvent(TIMER_LEASE);

        message=llToUpper(message);
        list array=llParseString2List(message,[" "],[]);

        string first=llList2String(array,0);


        // loop over previous set of news
        if(first==PREVVERB)
        {
            begin-=RSSROWS;
            if(begin<0)begin=0;

            refresh();
            return;
        }

        // loop over next set of news
        if(first==NEXTVERB) {
            begin+=RSSROWS;
            if((begin+1)>numtitles)begin=0;

            refresh();
            return;
        }
        // implementing more with a bubble
        if(first==MOREVERB)
        {

            integer pos=(integer)llList2String(array,1);
            if(pos>numtitles) return;

            rez_bubble(pos);

            return;
        }


    }
    // notecard reader
    dataserver(key id, string data)
    {
        //debug("dataserver received data: "+data);

        if (data != EOF)
        {
            info("Reading configuration line #"+(string)notecardline);
            if(llGetSubString(data,0,0)!="#")
            {
                list elements=llParseString2List(data,["=","#"],[]);
                string first=llStringTrim(llToLower(llList2String(elements,0)),STRING_TRIM);
                string rest=llStringTrim(llList2String(elements,1),STRING_TRIM);
                //llOwnerSay("first: "+first+" rest: "+rest);
                // if(first=="title") NC_TITLE=rest;
                if(first=="url") SALRSS=rest;
                if(first=="reversed") REVERSED=(integer)rest;
                if(first=="maxtitles") MAXTITLES=(integer)rest;
                if(first=="titlecolor") CTITLE=(vector)rest;
                if(first=="detailcolor") CLINE=(vector)rest;
                if(first=="idletimer") TIMER_IDLE=(integer)rest;
                if(first=="leasetimer") TIMER_LEASE=(integer)rest;
                if(first=="refreshtimer") TIMER_REFRESH=(integer)rest;
                if(first=="enablelease") ENABLELEASE=(integer)rest;
                if(first=="whisperchannel") WHISPERCHANNEL=(integer)rest;
                if(first=="killbubbles") KILLBUBBLES=(integer)rest;
                if(first=="rssrows") RSSROWS=(integer)rest;
                if(first=="debug") DEBUG=(integer)rest;
                if(first=="neededmemory") NEEDEDMEMORY=(integer)rest;
                if(first=="offsetbubble") OFFSETBUBBLE=(vector)rest;
                if(first=="maxpush") MAXPUSH=(vector)rest;
                if(first=="wrapcolumn") WRAPCOLUMN=(integer)rest;
                if(first=="objname") OBJNAME=rest;
                if(first=="moreverb") MOREVERB=rest;
                if(first=="prevverb") PREVVERB=rest;
                if(first=="nextverb") NEXTVERB=rest;
                if(first=="omegaaxis") OMEGAAXIS=(vector)rest;
                if(first=="omegaspinrate") OMEGASPINRATE=(float)rest;
                if(first=="omegagain") OMEGAGAIN=(float)rest;
                if(first=="listeningchannel") LISTENINGCHANNEL=(integer)rest;
                if(first=="buoyancy") BUOYANCY=(float)rest;

            }


            notecardline++;
            llGetNotecardLine(NOTECARD, notecardline);
        }
        else
        {
            if(DEBUG==1)
            {
                debug("url:"+SALRSS);
                debug("maxtitles:"+(string)MAXTITLES);
                debug("reversed:"+(string)REVERSED);
                debug("titleColor:"+(string)CTITLE);
                debug("detailColor:"+(string)CLINE);
                debug("idleTimer:"+(string)TIMER_IDLE);
                debug("leaseTimer:"+(string)TIMER_LEASE);
                debug("refreshTimer:"+(string)TIMER_REFRESH);
                debug("enableLease:"+(string)ENABLELEASE);
                debug("whisperChannel:"+(string)WHISPERCHANNEL);
                debug("killBubbles:"+(string)KILLBUBBLES);
                debug("rssRows:"+(string)RSSROWS);
                debug("neededMemory:"+(string)NEEDEDMEMORY);
                debug("offsetBubble:"+(string)OFFSETBUBBLE);
                debug("maxPush:"+(string)MAXPUSH);
                debug("wrapColumn:"+(string)WRAPCOLUMN);
                debug("objName:"+(string)OBJNAME);
                debug("moreVerb:"+(string)MOREVERB);
                debug("prevVerb:"+(string)PREVVERB);
                debug("nextVerb:"+(string)NEXTVERB);
                debug("omegaAxis:"+(string)OMEGAAXIS);
                debug("omegaSpinRate:"+(string)OMEGASPINRATE);
                debug("omegaGain:"+(string)OMEGAGAIN);
                debug("listeningChannel:"+(string)LISTENINGCHANNEL);
                debug("buoyancy:"+(string)BUOYANCY);
            }
            info("reading rss");
            rss();

            return;
        }
    }
    // http response
    // handle responses from salrss
    // return a StridedList with LINKS and TITLES
    http_response( key reqid, integer status, list meta, string body ) {
        if ( reqid == reqid_load ) {
            rss_load(body);
        }
    }

}
