#define INF_TABLE_SIMPLERANKS           "inf_simpleranks"

ConVar g_hPrestigePoints = null;

PointCheck_OnPluginStart() {
		g_hPrestigePoints = CreateConVar("ig_pointcheck_min", "0", "Point requirement to join the server, 0 to disable");
}


stock void PointCheck_InitClient( int client )
{
		int min = g_hPrestigePoints.IntValue;
		
		if ( min == 0 )
		{
			return;
		}

		Handle db = Influx_GetDB();
		
		
		int userid = GetClientUserId( client );
		
		int uid = Influx_GetClientId( client );
		
		static char szQuery[256];
		
		
		FormatEx( szQuery, sizeof( szQuery ),
				"SELECT * FROM "...INF_TABLE_SIMPLERANKS..." WHERE uid=%i AND cachedpoints >= %i", uid, min );
		
		
		SQL_TQuery( db, Thrd_InitClient, szQuery, userid, DBPrio_Normal );
}

public void Thrd_InitClient( Handle db, Handle res, const char[] szError, int client )
{
	if ( res == null )
	{
			LogError( db, "checking client points" );
			return;
	}
	
	if ( (client = GetClientOfUserId( client )) < 1 || !IsClientInGame( client ) ) return;
	
	if ( !SQL_FetchRow( res ) )
	{
		KickClient(client, "You must have at least %i point(s) to join this server", g_hPrestigePoints.IntValue);
        RedirectClient(client
	}
}