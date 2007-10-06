string mystate="reset";
string akey="";
integer olf;

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
default {
	
	state_entry()
	{
		// enable listening on 1000 channel
		llListen(1000,"",NULL_KEY,"");
		debug("client started");
	}
	touch_start(integer total_number)
	{
		llDialog(llDetectedKey(0),"Choose operation",["load","store","list","free","del","delall","reset" ],1000);
	}
	listen(integer channel, string name, key id, string message)
	{
		if(message=="reset")
		{
			llListenRemove(olf);
			llSay(0,"reset object");
			mystate="reset";
			return;
		}
		
		if(channel==1000)
		{
			// this is the menu
			if(message=="load")
			{
				mystate="load";
				olf=llListen(0,"",id,"");
				
				llSay(0,"digit the key you want to load");
				return;
			}
			if(message=="store")
			{
				mystate="store";
				olf=llListen(0,"",id,"");
				
				
				llSay(0,"digit the key you want to store");
				return;
			}
			if(message=="list")
			{
				mystate="result";
				llMessageLinked(LINK_THIS,LIST,"",NULL_KEY);
				return;
			}
			if(message=="free")
			{
				mystate="result";
				llMessageLinked(LINK_THIS,FREE,"",NULL_KEY);
				return;
			}
			if(message=="del")
			{
				mystate="del";
				olf=llListen(0,"",id,"");
				
				
				llSay(0,"digit the key you want to delete");
				return;
			}
			if(message=="delall")
			{
				mystate="result";
				llMessageLinked(LINK_THIS,DELALL,"",NULL_KEY);
				return;
			}
		}
		if(channel==0)
		{
			if(mystate=="load")
			{
				llSay(0,"Sent load request for key "+message);
				llMessageLinked(LINK_THIS,LOAD,"",(key)message);
				mystate="result";
				return;
			}
			if(mystate=="store")
			{
				akey=message;
				mystate="store1";
				llSay(0,"key is "+akey+". Input the value you want to store");
				return;
			}
			if(mystate=="store1")
			{
				llSay(0,"Sent store request for key "+akey+" value "+message);
				llMessageLinked(LINK_THIS,STORE,message,(key)akey);
				mystate="result";
				return;
			}
			if(mystate=="del")
			{
				llSay(0,"Sent del request for key "+akey);
				llMessageLinked(LINK_THIS,DELETE,"",(key)message);
				mystate="result";
				return;
			}
			
		}
		
	}
	
	// Requests received on std channels
	// id holds the key, str the value
	link_message(integer sender_num, integer num, string str, key id){
		llSay(0,"received from db: "+str);
	}
	
}