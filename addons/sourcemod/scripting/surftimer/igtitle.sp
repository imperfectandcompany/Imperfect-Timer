#define MAX_TITLE_LENGTH 128
#define MAX_TITLES 32
#define MAX_RAWTITLE_LENGTH 1024

char g_szCustomTitleRaw[MAXPLAYERS + 1][MAX_RAWTITLE_LENGTH];

/* for future reference with multiple titles
void FormatTitle(int client, char[] raw, char[] out, int size) {
		char parts[32][32];
		char colored[32] = "";
		int numParts = ExplodeString(raw, "`", parts, sizeof(parts), sizeof(parts[]));
		if (numParts >= 1) {
				int num = StringToInt(parts[0]);
				if (num == 0) {
						if (StrEqual(parts[0], "vip")) {
								if (IsPlayerVip(client, true, false)) {
										colored = "{green}VIP";
								}
						} else if (StrEqual(parts[0], "admin")) {
								if (CheckCommandAccess(client, "", ADMFLAG_ROOT)) {
										colored = "{red}ADMIN";
								}
						} else if (StrEqual(parts[0], "mod")) {
								if (CheckCommandAccess(client, "", ADMFLAG_KICK)) {
										colored = "{yellow}MOD";
								}
						}
				} else if (num > 0 && num < numParts) {
						strcopy(colored, sizeof(colored), parts[num]);
				}
		}
		FormatTitleSlug(colored, out, size);
}
*/

void FormatTitleSlug(const char[] raw, char[] out, int size) {
    strcopy(out, size, raw);
    char rawNoColor[32];
    strcopy(rawNoColor, sizeof(rawNoColor), raw);
    String_ToLower(rawNoColor, rawNoColor, sizeof(rawNoColor));

    if (StrEqual(rawNoColor, "rapper")) strcopy(out, size, "{yellow}RAPPER");
    if (StrEqual(rawNoColor, "beat")) strcopy(out, size, "{yellow}BEATBOXER");
    if (StrEqual(rawNoColor, "dj")) strcopy(out, size, "{yellow}DJ");
    if (StrEqual(rawNoColor, "staff")) strcopy(out, size, "{yellow}STAFF");
    if (StrEqual(rawNoColor, "surfer")) strcopy(out, size, "{pink}SURFER");
    ReplaceString(out, size, "{red}", "{lightred}", false);
    ReplaceString(out, size, "{limegreen}", "{lime}", false);
    ReplaceString(out, size, "{white}", "{default}", false);
}

public Action Command_GiveTitle(int client, int args) {
    if (!IsValidClient(client)) {
        PrintToServer("Error Give Title");
        return Plugin_Handled; 
    }
    if (args < 2) {
        CReplyToCommand(client, "Usage: <name> <title> - title can be rapper, dj, beat, or something custom (if paid)");
        return Plugin_Handled;
    }
    char targetStr[MAX_NAME_LENGTH], szBuffer[MAX_TITLE_LENGTH];
    GetCmdArg(1, targetStr, sizeof(targetStr));
    GetCmdArg(2, szBuffer, sizeof(szBuffer));
    int target = FindTarget(client, targetStr, true, false);
    GiveTitle(client, target, szBuffer);
    return Plugin_Handled;
}

public void GiveTitle(int client, int target, const char[] title) {
    if (target < 0) {
            CReplyToCommand(client, "Target player not found");
            return;
    }
    if (!IsClientInGame(target)) {
            CReplyToCommand(client, "Player not yet loaded");
            return;
    }
    char newTitle[MAX_RAWTITLE_LENGTH];
    Format(newTitle, sizeof(newTitle), "%s", title);

    /*  for future reference; multiple titles with delimiter
    if (StrEqual(g_szCustomTitleRaw[target], "")) {
            Format(newTitle, sizeof(newTitle), "0`%s", title);
    } else {
            Format(newTitle, sizeof(newTitle), "%s`%s", g_szCustomTitleRaw[target], title);
    } */

    char targetNamed[MAX_NAME_LENGTH];
    GetClientName(target, targetNamed, sizeof(targetNamed));
    char pretty[MAX_TITLE_LENGTH];
    FormatTitleSlug(title, pretty, sizeof(pretty));
    SaveRawTitle(target, pretty);
    CPrintToChatAll("%s was granted the title: %s", targetNamed, pretty);
}

public Action Command_RemoveTitle(int client, int args) {
    if (!IsValidClient(client))
        return Plugin_Handled;
    if (args < 2) {
        CReplyToCommand(client, "Usage: <name> <title>");
        return Plugin_Handled;
    }
    char targetStr[MAX_NAME_LENGTH], szBuffer[MAX_TITLE_LENGTH];
    GetCmdArg(1, targetStr, sizeof(targetStr));
    GetCmdArg(2, szBuffer, sizeof(szBuffer));
    int target = FindTarget(client, targetStr, true, false);
    RemoveTitle(client, target, szBuffer);
    return Plugin_Handled;
}

public void RemoveTitle(int client, int target, const char[] title) {
    if (!IsClientInGame(target)) {
            CReplyToCommand(client, "Player not yet loaded");
            return;
    }
    char newTitle[MAX_RAWTITLE_LENGTH] = "";
    if (!StrEqual(title, "all")) {
            char parts[MAX_TITLES][MAX_TITLE_LENGTH];
            int numParts = ExplodeString(g_szCustomTitleRaw[target], "`", parts, sizeof(parts), sizeof(parts[]));
            for (int i = 0; i < numParts; i++) {
                    if (i == 0 || !StrEqual(parts[i], title, false)) {
                            if (i != 0) {
                                    StrCat(newTitle, sizeof(newTitle), "`");
                            }
                            StrCat(newTitle, sizeof(newTitle), parts[i]);
                    }
            }
    }
    SaveRawTitle(target, newTitle);

    char targetNamed[MAX_NAME_LENGTH];
    GetClientName(target, targetNamed, sizeof(targetNamed));
    char pretty[MAX_TITLE_LENGTH];
    FormatTitleSlug(title, pretty, sizeof(pretty));
    CPrintToChatAll("%s was stripped of title: %s", targetNamed, pretty);
}

public void SaveRawTitle(int client, char[] raw) {
    char rawEx[MAX_RAWTITLE_LENGTH*2+1];
    SQL_EscapeString(g_hDb, raw, rawEx, sizeof(rawEx));

    char sSteamID[32];
    if (!GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID), true)) {
            return;
    }

    char szQuery[MAX_RAWTITLE_LENGTH*4+100];
    Format(szQuery, sizeof(szQuery), " \
            INSERT INTO ck_vipadmins \
            SET steamid='%s', title='%s' \
            ON DUPLICATE KEY UPDATE title='%s' \
        ", sSteamID, rawEx, rawEx);
    SQL_TQuery(g_hDb, SaveRawTitle2, szQuery, client);
}

public void SaveRawTitle2(Handle hDriver, Handle hResult, const char[] error, any client) {
    PrintToServer("Successfully updated custom title.");
    g_bdbHasCustomTitle[client] = true;
    g_bDbCustomTitleInUse[client] = false;
}