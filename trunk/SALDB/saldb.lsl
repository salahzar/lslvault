string SALDB = "http://www.salahzar.info/lsl/ls.php?"; // my remote db base link

integer STORE = 100;
integer LOAD  = 200;
integer DELETE= 300;
integer DELOWNER = 400; // delete all of the owner (reset)
integer LIST = 500;

integer MAXSTORE=10;
// Channel used to
integer RECVSTORE = 999;




key    reqid_load;                          // request id
string thekey;
string group;
string ret;
string NONE="==NONE==";


key agent;
integer callernum;



// standard call to httpd to perform various commands
// use POST and form url encoded to guarantee at least 2048 chars
http(string cmd){
	ret=NONE;
	
	string url = SALDB;
	string str = cmd +"&group="+group+"&max="+(string)MAXSTORE+"&owner_key="+(string)agent;
	
	//llSay(0,url + " " + str);
	reqid_load=llHTTPRequest( url, [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"],str);
	
	
	
	
	
}
// Save a value to httpdb with the specified name.
remote_save( string name, string value) {
	thekey=name;
	http("command=store&key="+name+"&value="+(value));
}

remote_delete( string name) {
	thekey=name;
	http("command=delete&key="+name);
}

remote_delete_group( string group){
	http("command=deletegroup&group="+group);
}

// Load named data from httpdb.
remote_load( string name) {
	thekey=name;
	http("command=get&key="+name);
}

remote_list(){
	thekey=group;
	http("command=getgroup");
}

default {
	
	state_entry(){
		agent=llGetOwner(); // this object is uniquely determined by its key
		group=llGetOwner(); // group is set to owner
		// remote_save("REZZED",llGetObjectName());
	}
	
	
	// Requests received on std channels
	// id holds the key, str the value
	link_message(integer sender_num, integer num, string str, key id){
		callernum=sender_num;
		if(num==STORE){
			remote_save( (string)id, str);
			return;
		}
		if(num==LOAD){
			remote_load( (string)id);
			return;
		}
		if(num==DELETE){
			remote_delete( (string)id);
			return;
		}
		if(num==DELOWNER){
			remote_delete_group(group);
			return;
		}
		if(num==LIST){
			remote_list();
			return;
		}
	}
	
	
	// returns ret
	http_response( key reqid, integer status, list meta, string body ) {
		//body=llUnescapeURL(body);
		//llOwnerSay("Agent: "+(string)agent+" Key: "+thekey+" recvd: ["+(string)llStringLength(body)+"]"+body);
		//llOwnerSay("Status: "+(string)status+" Metadata: "+llList2String(meta,0)+ "- "+llList2String(meta,1));
		
		if ( reqid == reqid_load ) {
			ret=body;
			llMessageLinked(callernum,RECVSTORE,body,NULL_KEY);
			
		}
	}
}