#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DEBUG false

ConVar g_cvarRounds;

float g_lastMsgTime[MAXPLAYERS + 1];

bool g_seenMessage[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "Dys Round Info",
	description = "Command to show round number info in a game message",
	author = "bauxite, credits to Atomy and Snoopkirby",
	version = "0.2.0",
	url = "",
};

public void OnPluginStart()
{
	g_cvarRounds = FindConVar("mp_rounds");
	RegConsoleCmd("sm_rounds", Cmd_ShowRounds, "Show the round info");
	HookEvent("player_spawn", OnPlayerSpawnPost, EventHookMode_Post);
	HookEvent("round_restart", OnRoundStartPost, EventHookMode_PostNoCopy);
}

public void OnRoundStartPost(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			RequestFrame(ShowRounds, i);
		}
	}
}

public void OnPlayerSpawnPost(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	
	if(g_seenMessage[client])
	{
		return;
	}
	
	g_seenMessage[client] = true;
	
	ShowRounds(client);
}

public Action Cmd_ShowRounds(int client, int args)
{
	if(client <= 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	float curTime = GetGameTime();
	
	if(g_lastMsgTime[client] == 0.0 || curTime > g_lastMsgTime[client] + 10.0)
	{
		g_lastMsgTime[client] = curTime;
		ShowRounds(client);
	}
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	for(int i = 1; i < MaxClients; i++)
	{
		g_lastMsgTime[i] = 0.0;
		g_seenMessage[i] = false;
	}
}

public void OnClientDisconnect_Post(int client)
{
	g_seenMessage[client] = false;
}

void ShowRounds(int client)
{
	char msg[32];
	int curRound = GameRules_GetProp("m_iRound");
	int maxRound = g_cvarRounds.IntValue;
	
	Format(msg, sizeof(msg), "Round %d of %d", curRound, maxRound);
	
	KeyValues kv = new KeyValues("Message", "title", msg);
	kv.SetColor("color", 0, 235, 0, 255);
	kv.SetNum("level", 3);
	kv.SetNum("time", 10);
	
	CreateDialog(client, kv, DialogType_Msg);

	delete kv;
}
