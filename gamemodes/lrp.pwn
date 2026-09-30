//============================================================================
// SA-MP 0.3.7 LRP Gamemode dengan TextDraw HUD
// Base: lexjusto Simple Gamemode | Enhanced: LRP Features
// Credits: pBlueG (MySQL), Incognito (Streamer), Zeex (ZCMD)
//============================================================================

#include <a_samp>
#include <streamer>
#include <a_mysql>
#include <zcmd>
#include <sscanf2>
#include <colors>

//============================================================================
// DEFINES
//============================================================================
#define MYSQL_HOST     			"127.0.0.1"
#define MYSQL_USER     			"root"
#define MYSQL_DB 				"samp_lrp"
#define MYSQL_PASS 				"root"
#define MYSQL_LOG_TYPE          LOG_ALL

#define TABLE_ACCOUNTS          "accounts"
#define GAMEMODE_HOSTNAME       "SA-MP LRP Gamemode v1.0"
#define GAMEMODE_NAME          	"LRP-GM"
#define SUPPORT_EMAIL           "admin@samp-lrp.com"

#undef MAX_PLAYERS
#define MAX_PLAYERS 50

#define INVALID_PLAYER_DATA 	-1
#define MAX_EMAIL_LEN    		64
#define MAX_PASSWORD_LEN     	36
#define MAX_IPADRESS_LEN      	40
#define MAX_CHATMESS_LEN        144
#define MAX_JOB_LEN             32

#define PlayerName(%1) 			PlayerInfo[%1][pName]
#define BYTES_PER_CELL 			(cellbits / 8)

#define COLOR_FADE1 			0xE6E6E6E6
#define COLOR_FADE2 			0xC8C8C8C8
#define COLOR_FADE3 			0xAAAAAAAA
#define COLOR_FADE4 			0x8C8C8C8C
#define COLOR_FADE5 			0x6E6E6E6E

//============================================================================
// FORWARD DECLARATIONS
//============================================================================
forward MySQLConnect();
forward OnPlayerJoin(playerid);
forward PlayerCheckRegister(playerid);
forward PlayerCreateAccount(playerid, regemail[], regpassword[], reginvited[], reggender, regskin);
forward PlayerLogin(playerid);
forward PlayerLoadData(playerid);
forward PlayerSaveData(playerid);
forward PlayerUpdateHUD(playerid);
forward KickFix(playerid);
forward ClearAnim(playerid);
forward MysqlErrorMessage(playerid);

//============================================================================
// VARIABLES
//============================================================================
new MySQL_C1;
new query[2048];
new RolePlayChat = 1;

//============================================================================
// ENUMS
//============================================================================
enum pInfo
{
	pID,
    pName[MAX_PLAYER_NAME],
    pEmail[MAX_EMAIL_LEN],
    pRegDate,
    pRegIP[MAX_IPADRESS_LEN],
	pLastDate,
    pLastIP[MAX_IPADRESS_LEN],
    pRegistered,
    pInvited[MAX_PLAYER_NAME],
    pGender,
    bool:pLogged,
	pLevel,
	pMoney,
	pSkin,
	pJob,
	pAdmin,
	pHealth
};

enum tInfo
{
    pRegPassword[MAX_PASSWORD_LEN],
    pRegEmail[MAX_EMAIL_LEN],
    pRegInvited[MAX_PLAYER_NAME],
    pRegGender,
    pRegSkin
};

enum dDialog
{
	dNull = 0,
	dRegister,
	dRegisterEmail,
	dRegisterGender,
	dRegisterSkin,
	dRegisterInvited,
	dRegisterEnd,
	dLogin
};

new PlayerInfo[MAX_PLAYERS][pInfo];
new TempInfo[MAX_PLAYERS][tInfo];

// TextDraw Variables
new Text:tdPlayerName[MAX_PLAYERS];
new Text:tdPlayerMoney[MAX_PLAYERS];
new Text:tdPlayerHealth[MAX_PLAYERS];
new Text:tdPlayerLevel[MAX_PLAYERS];
new Text:tdPlayerJob[MAX_PLAYERS];

//============================================================================
// SPAWN POINTS
//============================================================================
new Float:NewPlayerSpawns[][] =
{
    {2804.1511, -2437.3279, 13.6297, 89.2193},
    {2759.0200, -2561.1782, 13.6383, 1.1954}
};

//============================================================================
// MAIN
//============================================================================
main(){}

//============================================================================
// STOCKS - UTILITY
//============================================================================
stock MySQLConnect()
{
    new connecttime = GetTickCount();
    MySQL_C1 = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS);
    if(mysql_errno()) 
	{
		print("-> ERROR: Tidak bisa connect ke database!");
		return false;
	}
    else 
	{
		printf("-> MySQL Connected (%d ms)", GetTickCount() - connecttime);
		return true;
	}
}

stock SendClientFormattedMessage(playerid, color, fstring[], {Float, _}:...)
{
    static const STATIC_ARGS = 3;
    new n = (numargs() - STATIC_ARGS) * BYTES_PER_CELL;
    
	if (n)
    {
        new message[144];
        #emit CONST.alt fstring
        #emit LCTRL 5
        #emit ADD
        #emit STOR.S.pri 0@n
        
        #emit LOAD.S.alt n
        #emit ADD
        #emit STOR.S.pri 4@n
        
        do
        {
            #emit LOAD.I
            #emit PUSH.pri
            n -= BYTES_PER_CELL;
            #emit LOAD.S.pri 4@n
        }
        while (n > 0);
        
        #emit PUSH.S fstring
        #emit PUSH.C 128
        #emit PUSH.ADR message
        #emit PUSH.C 128
        #emit SYSREQ.C format
        
        return SendClientMessage(playerid, color, message);
    }
    else
    {
        return SendClientMessage(playerid, color, fstring);
    }
}

stock PlayerClearChat(playerid, size) 
{
	for(new s; s < size; s++) 
		SendClientMessage(playerid, -1, " ");
}

stock ResetPlayerInfo(playerid)
{
	PlayerInfo[playerid][pLogged] = false;
	PlayerInfo[playerid][pID] = INVALID_PLAYER_DATA;
	PlayerInfo[playerid][pName] = "\0";
	PlayerInfo[playerid][pEmail] = "\0";
	PlayerInfo[playerid][pRegDate] = 0;
	PlayerInfo[playerid][pRegIP] = "\0";
	PlayerInfo[playerid][pLastDate] = 0;
	PlayerInfo[playerid][pLastIP] = "\0";
	PlayerInfo[playerid][pRegistered] = 0;
	PlayerInfo[playerid][pInvited] = "\0";
	PlayerInfo[playerid][pGender] = 0;
	PlayerInfo[playerid][pLevel] = 1;
	PlayerInfo[playerid][pMoney] = 0;
	PlayerInfo[playerid][pSkin] = 0;
	PlayerInfo[playerid][pJob] = 0;
	PlayerInfo[playerid][pAdmin] = 0;
	PlayerInfo[playerid][pHealth] = 100;
	
	TempInfo[playerid][pRegPassword] = "\0";
	TempInfo[playerid][pRegEmail] = "\0";
	TempInfo[playerid][pRegGender] = 0;
	TempInfo[playerid][pRegSkin] = 0;
	TempInfo[playerid][pRegInvited] = "\0";
}

stock PlayerKick(playerid)
{
	SetTimerEx("KickFix", 250, false, "d", playerid);
	return 1;
}

stock CreatePlayerHUD(playerid)
{
	tdPlayerName[playerid] = TextDrawCreate(15.0, 20.0, " ");
	TextDrawLetterSize(tdPlayerName[playerid], 0.25, 1.0);
	TextDrawUseBox(tdPlayerName[playerid], 0);
	TextDrawColor(tdPlayerName[playerid], 0xFFFFFFFF);
	TextDrawShowForPlayer(playerid, tdPlayerName[playerid]);

	tdPlayerMoney[playerid] = TextDrawCreate(15.0, 35.0, " ");
	TextDrawLetterSize(tdPlayerMoney[playerid], 0.25, 1.0);
	TextDrawColor(tdPlayerMoney[playerid], 0x00FF00FF);
	TextDrawShowForPlayer(playerid, tdPlayerMoney[playerid]);

	tdPlayerHealth[playerid] = TextDrawCreate(15.0, 50.0, " ");
	TextDrawLetterSize(tdPlayerHealth[playerid], 0.25, 1.0);
	TextDrawColor(tdPlayerHealth[playerid], 0xFF0000FF);
	TextDrawShowForPlayer(playerid, tdPlayerHealth[playerid]);

	tdPlayerLevel[playerid] = TextDrawCreate(15.0, 65.0, " ");
	TextDrawLetterSize(tdPlayerLevel[playerid], 0.25, 1.0);
	TextDrawColor(tdPlayerLevel[playerid], 0xFFFF00FF);
	TextDrawShowForPlayer(playerid, tdPlayerLevel[playerid]);

	tdPlayerJob[playerid] = TextDrawCreate(15.0, 80.0, " ");
	TextDrawLetterSize(tdPlayerJob[playerid], 0.25, 1.0);
	TextDrawColor(tdPlayerJob[playerid], 0x00FFFFFF);
	TextDrawShowForPlayer(playerid, tdPlayerJob[playerid]);
}

stock UpdatePlayerHUD(playerid)
{
	new string[128];
	
	format(string, sizeof(string), "Nama: %s", PlayerInfo[playerid][pName]);
	TextDrawSetString(tdPlayerName[playerid], string);

	format(string, sizeof(string), "Uang: $%d", PlayerInfo[playerid][pMoney]);
	TextDrawSetString(tdPlayerMoney[playerid], string);

	new Float:health;
	GetPlayerHealth(playerid, health);
	format(string, sizeof(string), "HP: %.0f", health);
	TextDrawSetString(tdPlayerHealth[playerid], string);

	format(string, sizeof(string), "Level: %d", PlayerInfo[playerid][pLevel]);
	TextDrawSetString(tdPlayerLevel[playerid], string);

	new job[MAX_JOB_LEN] = "Belum Ada";
	if(PlayerInfo[playerid][pJob] == 1) job = "Polisi";
	else if(PlayerInfo[playerid][pJob] == 2) job = "Taxi Driver";
	else if(PlayerInfo[playerid][pJob] == 3) job = "Petani";
	
	format(string, sizeof(string), "Job: %s", job);
	TextDrawSetString(tdPlayerJob[playerid], string);
}

stock MysqlErrorMessage(playerid)
{
    if(playerid == INVALID_PLAYER_ID) 
	{
		printf("-> MySQL Error Code: #%d", mysql_errno());
		return 0;
	}
	else
	{
 		PlayerClearChat(playerid, 50);
		new mysqlerror[MAX_CHATMESS_LEN];
		format(mysqlerror, sizeof(mysqlerror), "Server error connecting to database. (Error Code: #%d)", mysql_errno());
	    SendClientMessage(playerid, -1, mysqlerror);
	    PlayerKick(playerid);
		printf("-> MySQL Error Code: #%d | Player: %s[%d]", mysql_errno(), PlayerName(playerid), playerid);
	}
	return 1;
}

stock PlayerSpawn(playerid)
{
    if(!PlayerInfo[playerid][pLogged]) 
		return SendClientMessage(playerid, -1, "Anda harus login!"), PlayerKick(playerid);

   	new randomspawn = random(sizeof(NewPlayerSpawns));
	SetPlayerPos(playerid, NewPlayerSpawns[randomspawn][0], NewPlayerSpawns[randomspawn][1], NewPlayerSpawns[randomspawn][2]);
    SetPlayerFacingAngle(playerid, NewPlayerSpawns[randomspawn][3]);

	SetCameraBehindPlayer(playerid);
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);
	SetPlayerHealth(playerid, 100);
	return 1;
}

stock ProxDetector(Float:radi, playerid, string[], col1, col2, col3, col4, col5)
{
    new Float:posx, Float:posy, Float:posz;
    new Float:oldposx, Float:oldposy, Float:oldposz;
    new Float:tempposx, Float:tempposy, Float:tempposz;
    
	GetPlayerPos(playerid, oldposx, oldposy, oldposz);
    
	for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            GetPlayerPos(i, posx, posy, posz);
            tempposx = (oldposx - posx);
            tempposy = (oldposy - posy);
            tempposz = (oldposz - posz);
            
			if(GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(i))
            {
                if (((tempposx < radi/16) && (tempposx > -radi/16)) && ((tempposy < radi/16) && (tempposy > -radi/16)) && ((tempposz < radi/16) && (tempposz > -radi/16))) 
					SendClientMessage(i, col1, string);
                else if (((tempposx < radi/8) && (tempposx > -radi/8)) && ((tempposy < radi/8) && (tempposy > -radi/8)) && ((tempposz < radi/8) && (tempposz > -radi/8))) 
					SendClientMessage(i, col2, string);
                else if (((tempposx < radi/4) && (tempposx > -radi/4)) && ((tempposy < radi/4) && (tempposy > -radi/4)) && ((tempposz < radi/4) && (tempposz > -radi/4))) 
					SendClientMessage(i, col3, string);
                else if (((tempposx < radi/2) && (tempposx > -radi/2)) && ((tempposy < radi/2) && (tempposy > -radi/2)) && ((tempposz < radi/2) && (tempposz > -radi/2))) 
					SendClientMessage(i, col4, string);
                else if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi))) 
					SendClientMessage(i, col5, string);
            }
        }
    }
    return 1;
}

//============================================================================
// MYSQL CALLBACKS
//============================================================================
public OnPlayerJoin(playerid)
{
	PlayerClearChat(playerid, 50);
	SendClientMessage(playerid, -1, "Selamat datang di SA-MP LRP Gamemode!");

    mysql_format(MySQL_C1, query, sizeof(query), "SELECT `name` FROM `"TABLE_ACCOUNTS"` WHERE `name` = '%e'", PlayerName(playerid));
	mysql_function_query(MySQL_C1, query, true, "PlayerCheckRegister", "d", playerid);

	if(mysql_errno()) return MysqlErrorMessage(playerid);
	return 1;
}

public PlayerCheckRegister(playerid)
{
	new rows, fields;
	cache_get_data(rows, fields);

	if(rows) 
		ShowPlayerDialog(playerid, dLogin, DIALOG_STYLE_PASSWORD, "{FFFFFF}Login", "{FFFFFF}Akun Anda terdaftar. Masukkan password:", "Login", "Keluar");
	else 
		ShowPlayerDialog(playerid, dRegister, DIALOG_STYLE_INPUT, "{FFFFFF}Register", "{FFFFFF}Akun belum terdaftar. Buat password baru:", "Register", "Keluar");
 	return 1;
}

public PlayerCreateAccount(playerid, regemail[], regpassword[], reginvited[], reggender, regskin)
{
	new regip[MAX_IPADRESS_LEN];
	GetPlayerIp(playerid, regip, sizeof(regip));
	
	mysql_format(MySQL_C1, query, sizeof(query), "INSERT INTO `"TABLE_ACCOUNTS"` (`name`, `email`, `password`, `regdate`, `regip`, `registered`, `invited`, `gender`, `skin`, `level`, `money`) VALUES ('%e', '%e', MD5('%e'), '%d', '%e', '0', '%e', '%d', '%d', '1', '500')",
   	PlayerName(playerid), regemail, regpassword, gettime(), regip, reginvited, reggender, regskin);
	
	mysql_function_query(MySQL_C1, query, false, "", "");

	if(mysql_errno()) return MysqlErrorMessage(playerid);

	mysql_format(MySQL_C1, query, sizeof(query), "SELECT * FROM `"TABLE_ACCOUNTS"` WHERE `name` = '%e' LIMIT 0,1", PlayerName(playerid));
	mysql_function_query(MySQL_C1, query, true, "PlayerLogin", "d", playerid);

	if(mysql_errno()) return MysqlErrorMessage(playerid);
    return 1;
}

public PlayerLogin(playerid)
{
    new rows, fields;
	cache_get_data(rows, fields);
	
	if(!rows)
	{
	    SendClientMessage(playerid, -1, "Password salah! Coba lagi.");
		return ShowPlayerDialog(playerid, dLogin, DIALOG_STYLE_PASSWORD, "{FFFFFF}Login", "{FFFFFF}Akun Anda terdaftar. Masukkan password:", "Login", "Keluar");
	}
	else 
		PlayerLoadData(playerid);
		
    return 1;
}

public PlayerLoadData(playerid)
{
	new rowid = 0;

    PlayerInfo[playerid][pID] = cache_get_field_content_int(rowid, "id", MySQL_C1);
    cache_get_field_content(rowid, "email", PlayerInfo[playerid][pEmail], MySQL_C1, MAX_EMAIL_LEN);
    PlayerInfo[playerid][pRegDate] = cache_get_field_content_int(rowid, "regdate", MySQL_C1);
    cache_get_field_content(rowid, "regip", PlayerInfo[playerid][pRegIP], MySQL_C1, MAX_IPADRESS_LEN);
    PlayerInfo[playerid][pLastDate] = cache_get_field_content_int(rowid, "lastdate", MySQL_C1);
    cache_get_field_content(rowid, "lastip", PlayerInfo[playerid][pLastIP], MySQL_C1, MAX_IPADRESS_LEN);
    PlayerInfo[playerid][pRegistered] = cache_get_field_content_int(rowid, "registered", MySQL_C1);
    cache_get_field_content(rowid, "invited", PlayerInfo[playerid][pInvited], MySQL_C1, MAX_PLAYER_NAME);
    PlayerInfo[playerid][pGender] = cache_get_field_content_int(rowid, "gender", MySQL_C1);
    PlayerInfo[playerid][pLevel] = cache_get_field_content_int(rowid, "level", MySQL_C1);
    PlayerInfo[playerid][pMoney] = cache_get_field_content_int(rowid, "money", MySQL_C1);
    PlayerInfo[playerid][pSkin] = cache_get_field_content_int(rowid, "skin", MySQL_C1);
    PlayerInfo[playerid][pJob] = cache_get_field_content_int(rowid, "job", MySQL_C1);
    PlayerInfo[playerid][pAdmin] = cache_get_field_content_int(rowid, "admin", MySQL_C1);
	
    if(PlayerInfo[playerid][pRegistered] == 0)
    {
        PlayerInfo[playerid][pLevel] = 1;
        PlayerInfo[playerid][pMoney] = 500;
        PlayerInfo[playerid][pRegistered] = 1;

    	mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `registered` = '1', `level` = '1', `money` = '500' WHERE `name` = '%e'", PlayerName(playerid));
		mysql_function_query(MySQL_C1, query, false, "", "");

		if(mysql_errno()) return MysqlErrorMessage(playerid);
		SetPlayerHealth(playerid, 100);
    	SendClientMessage(playerid, -1, "Akun berhasil dibuat!");
    }
    else
    {
        SetPlayerHealth(playerid, 100);
        SendClientMessage(playerid, -1, "Selamat datang kembali!");
    }

    PlayerInfo[playerid][pLogged] = true;
    SpawnPlayer(playerid);

    new lastip[MAX_IPADRESS_LEN];
    GetPlayerIp(playerid, lastip, sizeof(lastip));
	mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `lastdate` = '%d', `lastip` = '%e', `logged` = '1' WHERE `name` = '%e'", gettime(), lastip, PlayerName(playerid));
	mysql_function_query(MySQL_C1, query, false, "", "");

	if(mysql_errno()) return MysqlErrorMessage(playerid);
    return 1;
}

public PlayerSaveData(playerid)
{
    PlayerInfo[playerid][pLogged] = false;

  	mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `logged` = '0', `level` = '%d', `money` = '%d', `skin` = '%d', `job` = '%d' WHERE `name` = '%e'",
	PlayerInfo[playerid][pLevel],
	PlayerInfo[playerid][pMoney],
	PlayerInfo[playerid][pSkin],
	PlayerInfo[playerid][pJob],
	PlayerInfo[playerid][pName]);
	
	mysql_function_query(MySQL_C1, query, false, "", "");

	if(mysql_errno()) return MysqlErrorMessage(playerid);
	return 1;
}

public KickFix(playerid)
{
	SendClientMessage(playerid, -1, "Gunakan /quit untuk keluar dari server");
	Kick(playerid);
	return 1;
}

public ClearAnim(playerid) 
{
	return ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.0, 0, 0, 0, 0, 0, 1);
}

//============================================================================
// GAME MODE EVENTS
//============================================================================
public OnGameModeInit()
{
    new launchtime = GetTickCount();

    MySQLConnect();

    if(mysql_errno())
	{
	    SendRconCommand("hostname "GAMEMODE_HOSTNAME" | *ERROR*");
	    SetGameModeText(""GAMEMODE_NAME" | *ERROR*");
		return 0;
	}
    else
    {
	    SendRconCommand("hostname "GAMEMODE_HOSTNAME"");
	    SetGameModeText(""GAMEMODE_NAME"");
	    mysql_log(MYSQL_LOG_TYPE);

	   	EnableStuntBonusForAll(0);
	   	ShowPlayerMarkers(2);
		DisableInteriorEnterExits();

		printf("-> Gamemode ("GAMEMODE_NAME") launched successfully! (%d ms)", GetTickCount() - launchtime);
	}
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	ResetPlayerInfo(playerid);
	GetPlayerName(playerid, PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
	SetTimerEx("OnPlayerJoin", 150, false, "d", playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(PlayerInfo[playerid][pLogged] == true) 
		PlayerSaveData(playerid);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(!PlayerInfo[playerid][pLogged]) 
		return SendClientMessage(playerid, -1, "Anda harus login!"), PlayerKick(playerid);

	PlayerSpawn(playerid);
	SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
    SetPlayerScore(playerid, PlayerInfo[playerid][pLevel]);
	CreatePlayerHUD(playerid);
	UpdatePlayerHUD(playerid);
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(PlayerInfo[playerid][pLogged]) 
		UpdatePlayerHUD(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
    new chattext[MAX_CHATMESS_LEN];
    
	if(PlayerInfo[playerid][pLogged] == false) 
		return SendClientMessage(playerid, -1, "Anda harus login untuk chat!"), 0;

	if(strlen(text) < 1 || strlen(text) > MAX_CHATMESS_LEN) 
		return SendClientMessage(playerid, -1, "Pesan terlalu panjang/pendek!"), 0;

	format(chattext, sizeof(chattext), "[CHAT] %s(%d): %s", PlayerName(playerid), playerid, text);
	ProxDetector(20.0, playerid, chattext, COLOR_FADE1, COLOR_FADE2, COLOR_FADE3, COLOR_FADE4, COLOR_FADE5);
	SetPlayerChatBubble(playerid, text, 0xFFFFFFFF, 20.0, 7000);
	ApplyAnimation(playerid, "PED", "IDLE_CHAT", 4.1, 0, 1, 1, 1, 1, 1);
	SetTimerEx("ClearAnim", 100 * strlen(text), false, "d", playerid);
	return 0;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case dRegister:
		{
		    if(!response) 
				return SendClientMessage(playerid, -1, "Anda membatalkan registrasi."), PlayerKick(playerid);
		    
			if(!strlen(inputtext) || strlen(inputtext) < 3 || strlen(inputtext) > MAX_PASSWORD_LEN)
			{
			    SendClientMessage(playerid, -1, "Password harus 3-36 karakter!");
			    return ShowPlayerDialog(playerid, dRegister, DIALOG_STYLE_INPUT, "{FFFFFF}Register", "{FFFFFF}Password harus 3-36 karakter:\n", "Register", "Keluar");
	        }
	        
			strmid(TempInfo[playerid][pRegPassword], inputtext, 0, strlen(inputtext), MAX_PASSWORD_LEN);
	        ShowPlayerDialog(playerid, dRegisterEmail, DIALOG_STYLE_INPUT, "{FFFFFF}Register", "Masukkan email Anda:", "Lanjut", "Batal");
			return 1;
		}
		
		case dRegisterEmail:
		{
   			if(!response) 
				return SendClientMessage(playerid, -1, "Anda membatalkan registrasi."), PlayerKick(playerid);
   			
		    if(!strlen(inputtext) || strlen(inputtext) > MAX_EMAIL_LEN || strfind(inputtext, "@", true) == -1)
			{
			    SendClientMessage(playerid, -1, "Format email salah! Contoh: user@email.com");
			    return ShowPlayerDialog(playerid, dRegisterEmail, DIALOG_STYLE_INPUT, "{FFFFFF}Register", "Masukkan email Anda:", "Lanjut", "Batal");
	        }
	        
	        strmid(TempInfo[playerid][pRegEmail], inputtext, 0, strlen(inputtext), MAX_EMAIL_LEN);
	        ShowPlayerDialog(playerid, dRegisterGender, DIALOG_STYLE_LIST, "{FFFFFF}Register", "Pilih gender karakter Anda:\nLaki-Laki\nPerempuan", "Pilih", "Batal");
			return 1;
		}
		
		case dRegisterGender:
		{
		    if(!response) 
				return SendClientMessage(playerid, -1, "Anda membatalkan registrasi."), PlayerKick(playerid);
		    
			switch(listitem)
		    {
		        case 0: TempInfo[playerid][pRegGender] = 0;
		        case 1: TempInfo[playerid][pRegGender] = 1;
		        default: TempInfo[playerid][pRegGender] = 0;
		    }
		    
			ShowPlayerDialog(playerid, dRegisterSkin, DIALOG_STYLE_LIST, "{FFFFFF}Register", "Pilih skin karakter:\nSkin 1\nSkin 2\nSkin 3\nSkin 4\nSkin 5", "Pilih", "Batal");
		    return 1;
		}
		
		case dRegisterSkin:
		{
		    if(!response) 
				return SendClientMessage(playerid, -1, "Anda membatalkan registrasi."), PlayerKick(playerid);

		    switch(listitem)
		    {
		        case 0..4: TempInfo[playerid][pRegSkin] = listitem + 1;
		        default: TempInfo[playerid][pRegSkin] = 1;
		    }
		    
			ShowPlayerDialog(playerid, dRegisterEnd, DIALOG_STYLE_MSGBOX, "{FFFFFF}Konfirmasi Registrasi", 
			"Periksa data Anda:\nJika benar, klik OK", "OK", "Batal");

			return 1;
	  	}
		
		case dRegisterEnd:
		{
			if(response) 
			{
				PlayerCreateAccount(playerid, TempInfo[playerid][pRegEmail], TempInfo[playerid][pRegPassword], "", TempInfo[playerid][pRegGender], TempInfo[playerid][pRegSkin]);
			}
			if(!response)
			{
				PlayerClearChat(playerid, 50);
				SendClientMessage(playerid, -1, "Silakan ulangi registrasi dari awal.");
				return ShowPlayerDialog(playerid, dRegister, DIALOG_STYLE_INPUT, "{FFFFFF}Register", "{FFFFFF}Buat password baru:", "Register", "Keluar");
			}
		    return 1;
  		}
		
		case dLogin:
		{
		    if(!response) 
				return SendClientMessage(playerid, -1, "Anda membatalkan login."), PlayerKick(playerid);
		    
			if(!strlen(inputtext) || strlen(inputtext) < 3 || strlen(inputtext) > MAX_PASSWORD_LEN)
			{
			    SendClientMessage(playerid, -1, "Password harus 3-36 karakter!");
			    return ShowPlayerDialog(playerid, dLogin, DIALOG_STYLE_PASSWORD, "{FFFFFF}Login", "{FFFFFF}Masukkan password:", "Login", "Keluar");
		    }
			
			mysql_format(MySQL_C1, query, sizeof(query), "SELECT * FROM `"TABLE_ACCOUNTS"` WHERE `name` = '%e' AND `password` = MD5('%e') LIMIT 0,1", PlayerName(playerid), inputtext);
	  		mysql_function_query(MySQL_C1, query, true, "PlayerLogin", "d", playerid);

	  		if(mysql_errno()) return MysqlErrorMessage(playerid);

	  		return 1;
		}
	}
	return 1;
}

//============================================================================
// COMMANDS
//============================================================================
COMMAND:me(playerid, params[])
{
	if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, -1, "Anda harus login!");
	if(!strlen(params)) return SendClientMessage(playerid, -1, "Gunakan: /me [aksi]");
	
	new message[MAX_CHATMESS_LEN];
	format(message, sizeof(message), "* %s %s", PlayerName(playerid), params);
	ProxDetector(20.0, playerid, message, COLOR_FADE1, COLOR_FADE2, COLOR_FADE3, COLOR_FADE4, COLOR_FADE5);
	return 1;
}

COMMAND:do(playerid, params[])
{
	if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, -1, "Anda harus login!");
	if(!strlen(params)) return SendClientMessage(playerid, -1, "Gunakan: /do [aksi]");
	
	new message[MAX_CHATMESS_LEN];
	format(message, sizeof(message), "(( %s: %s ))", PlayerName(playerid), params);
	ProxDetector(20.0, playerid, message, COLOR_FADE1, COLOR_FADE2, COLOR_FADE3, COLOR_FADE4, COLOR_FADE5);
	return 1;
}

COMMAND:help(playerid, params[])
{
	if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, -1, "Anda harus login!");
	
	SendClientMessage(playerid, -1, "===== COMMANDS =====");
	SendClientMessage(playerid, -1, "/me [aksi] - Lakukan aksi");
	SendClientMessage(playerid, -1, "/do [aksi] - OOC action");
	SendClientMessage(playerid, -1, "/stats - Lihat statistik");
	SendClientMessage(playerid, -1, "/job - Lihat job Anda");
	SendClientMessage(playerid, -1, "/quit - Keluar server");
	return 1;
}

COMMAND:stats(playerid, params[])
{
	if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, -1, "Anda harus login!");
	
	new message[256];
	format(message, sizeof(message), "=== Statistik %s ===\nLevel: %d\nUang: $%d\nJob: %d\nHealth: %.0f", 
		PlayerName(playerid), PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pJob], GetPlayerHealth(playerid));
	
	SendClientMessage(playerid, -1, message);
	return 1;
}

COMMAND:job(playerid, params[])
{
	if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, -1, "Anda harus login!");
	
	new job[MAX_JOB_LEN] = "Belum Ada";
	if(PlayerInfo[playerid][pJob] == 1) job = "Polisi";
	else if(PlayerInfo[playerid][pJob] == 2) job = "Taxi Driver";
	else if(PlayerInfo[playerid][pJob] == 3) job = "Petani";
	
	SendClientMessage(playerid, -1, "Pekerjaan Anda: " # job);
	return 1;
}

COMMAND:quit(playerid, params[])
{
	if(PlayerInfo[playerid][pLogged]) 
		PlayerSaveData(playerid);
	Kick(playerid);
	return 1;
}

//============================================================================
// UTILITY FUNCTIONS
//============================================================================
stock ApplyAnimation(playerid, name[], anim[], Float:speed, p, p2, p3, p4, p5, p6 = 0)
{
	if(!IsPlayerInAnyVehicle(playerid)) 
		ApplyAnimation(playerid, name, anim, speed, p, p2, p3, p4, p5, p6);
	return 1;
}

//============================================================================
// END OF SCRIPT
//============================================================================
