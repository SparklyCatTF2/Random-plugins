#include <sourcemod>

public OnPluginStart()
{
	RegConsoleCmd("sm___namecall", Namecall);
}

public Action Namecall(int client, int args)
{
	if(args < 2)
	{
		PrintToChat(client, "__namecall() usage: sm___namecall \"pluginname.smx\" \"functionname\" \"type:Value\" ... ...");
		PrintToChat(client, "__namecall() example: sm___namecall \"TF2Jail.smx\" \"OnPluginStart\" (no values because OnPluginStart doesn't take any)");
		PrintToChat(client, "__namecall() failed, not enough args (2).");
		return Plugin_Handled;
	}
	
	// Creating an array to extract all the arguments
	Handle array = CreateArray(48);
	char arg[48];
	
	for(int i = 1; i <= args; ++i)
	{
		GetCmdArg(i, arg, sizeof(arg));
		PushArrayString(array, arg);
	}
	
	// Now I use arg[48] to store the plugin's name
	
	GetArrayString(array, 0, arg, sizeof(arg));
	
	Handle plugin = FindPluginByFile(arg);
	if(plugin != INVALID_HANDLE)
	{
		if(GetPluginStatus(plugin) == Plugin_Running) // Plugin is running, now let's find the function
		{
			// Now I'm using arg[48] to hold the function name...
			
			GetArrayString(array, 1, arg, sizeof(arg));
			Function plfunc = GetFunctionByName(plugin, arg);
			
			if(plfunc == INVALID_FUNCTION)
			{
				delete array;
				PrintToChat(client, "__namecall() failed, no function such as '%s' was found.", arg);
				return Plugin_Handled;
			}
			else
			{
				if(args == 2)
				{
					Call_StartFunction(plugin, plfunc);
					any retval;
					Call_Finish(retval);
					
					delete array;
					PrintToChat(client, "__namecall() finished, return value: %s", retval);
					return Plugin_Handled;
				}
				else // Welp, this one is harder than without any values
				{
					Call_StartFunction(plugin, plfunc);
					any retval;
					for(int count = 2; count < args; ++count)
					{
						// Aaaand now we use arg[48] for the value, how great
						// At least I'm conserving a few lines of text! :p
						GetArrayString(array, count, arg, sizeof(arg));
						AddValueToFunction(arg, plfunc);
					}
					Call_Finish(retval); // For some reason it doesn't want to show anything as the return value
					
					delete array;
					PrintToChat(client, "__namecall() finished successfully, return value: %s", retval);
					return Plugin_Handled;
				}
			}
		}
		else
		{
			delete array;
			PrintToChat(client, "__namecall() failed, plugin is loaded, but not running.");
			return Plugin_Handled;
		}
	}
	else
	{
		delete array;
		PrintToChat(client, "__namecall() failed, plugin not found.");
		return Plugin_Handled;
	}
	
}

stock void AddValueToFunction(char[] arg, Function func)
{
	char detect[2][48];
	ExplodeString(arg, ":", detect, sizeof(detect), sizeof(detect[]));
	if(StrEqual(detect[0], "i", false))
	{
		int ival = StringToInt(detect[1]);
		Call_PushCell(ival);
	}
	if(StrEqual(detect[0], "f", false))
	{
		float flval = StringToFloat(detect[1]);
		Call_PushFloat(flval);
	}
	if(StrEqual(detect[0], "s", false))
	{
		char sval[48];
		strcopy(sval, 48, detect[1]);
		Call_PushString(sval);
	}
}