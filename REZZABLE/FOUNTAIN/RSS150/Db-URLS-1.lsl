// use an object as a memory store
//
// due to problems in LSL handling of lists we have kind of leaks so if huge elements needed
// need to reset it often


list values=[];

integer DEBUG=0;

integer BANK=1; // which bank we are (it will taken from the name of the script xxxx-###)

integer ADD = 1; // store a value
integer LOADI  = 2; // load a value
integer NUM = 3; // load by index
integer DELETE= 4; // delete a value
integer DELALL= 5; // delete all values (reset)
integer FREE = 6;  // ask how much free memory

debug(string str)
{
    if(DEBUG==1) llOwnerSay("DEBUG("+(string)BANK+"): "+str);
}

default {

    state_entry()
    {
        string scriptname=llGetScriptName();
        list pieces=llParseString2List(scriptname,[" ","-","."],[]);
        string lastpiece=llList2String(pieces,-1);
        if(llSubStringIndex(llToUpper(scriptname),"DEBUG")>=0) DEBUG=1;
        BANK=(integer)lastpiece;
        if(BANK==0) BANK=1;
        debug("My name is: "+scriptname+" BANK is "+(string)BANK+ " freeMemory: "+(string)llGetFreeMemory());

    }

    // Requests received on std channels
    // id holds the key, str the value
    link_message(integer sender_num, integer bnk, string str, key id){
        if(bnk!=BANK) return;
        string ret="OK";
        string strid=(string)id;
        integer num=(integer)llGetSubString(strid,0,0);
        string akey=llGetSubString(strid,1,-1); integer ikey=(integer)akey;
        debug("received action: "+(string)num+" key: "+akey+" value: "+str);
        if(num==ADD) values+=str;
        if(num==LOADI) ret=llList2String(values,(integer)akey); // ***
        if(num==NUM) ret=(string) llGetListLength(values);      // ***
        if(num==DELETE) values=(values=[])+llDeleteSubList(values,ikey,ikey);
        if(num==DELALL)
        {
            llSetObjectDesc(ret);
            llResetScript();
        }
        else if(num==FREE) ret=(string)llGetFreeMemory();       // ***
        llSetObjectDesc(ret);
    }

}