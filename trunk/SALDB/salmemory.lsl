// use an object as a memory store
list keys=[];
list values=[];

integer STORE = 100; // store a value
integer LOAD  = 200; // load a value
integer DELETE= 300; // delete a value
integer DELALL= 350; // delete all values (reset)
integer FREE = 400;  // ask how much free memory
integer LIST = 500;  // list current values


debug(string str)
{
	llOwnerSay("DEBUG: "+str);
}


string
	mem_free()
{
	return (string)llGetFreeMemory();
}

// Save or update a value to httpdb with the specified name.
integer mem_save( string name, string value)
{
	integer prev=llListFindList(keys,[ name ]);
	if(prev>=0)
		values=(values=[])+llListReplaceList(values,[ value ], prev, prev);
	else
	{
		keys+=[name];
		values+=[value];
	}
	return 0;
}
string
	mem_get( string name)
{
	integer prev=llListFindList(keys,[ name ]);
	if(prev>=0) return llList2String(values,prev);
	// not found
	return "";
}

integer mem_delete( string name)
{
	integer prev=llListFindList(keys,[ name ]);
	if(prev>=0)
	{
		keys=(keys=[])+llDeleteSubList(keys,prev,prev);
		values=(values=[])+llDeleteSubList(values,prev,prev);
	}
	return 0;
}
integer mem_delall()
{
	keys=[];
	values=[];
	return 0;
}


string mem_list(){
	return llList2CSV(keys);
}

action( integer sender_num, string ret)
{
	debug("action returned: "+ret);
	llMessageLinked(sender_num, 0, ret, NULL_KEY);
}

default {
	
		// Requests received on std channels
	// id holds the key, str the value
	link_message(integer sender_num, integer num, string str, key id){
		if(num==0) return;
		debug("received num: "+(string)num+" key: "+(string)id+" value: "+str);
		if(num==STORE) action( sender_num, (string) mem_save( (string)id, str ));
		else if(num==LOAD) action( sender_num, (string) mem_get( (string)id) );
		else if(num==DELETE) action( sender_num, (string) mem_delete( (string) id));
		else if(num==DELALL) action( sender_num, (string) mem_delall());
		else if(num==LIST) action( sender_num, (string) mem_list());
		else if(num==FREE) action( sender_num, (string) mem_free());
		else
			llSay(0,str+" unrecognized");
	}
	
}