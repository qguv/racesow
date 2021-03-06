class Racesow_Gametype_CoopRace : Racesow_Gametype
{
    
    Racesow_Gametype_CoopRace()
    {
        
    }
    
    ~Racesow_Gametype_CoopRace()
    {
        
    }
    
    void InitGametype()
    {
      gametype.title = "Coop Race";
      
      // if the gametype doesn't have a config file, create it
      if ( !G_FileExists( "configs/server/gametypes/race.cfg" ) )
      {
          String config;
    
          // the config file doesn't exist or it's empty, create it
          config = "//*\n"
                   + "//* Coop Race settings\n"
                   + "//*\n"
                   + "set g_scorelimit \"0\" // a new feature..?\n"
                   + "set g_warmup_timelimit \"0\" // ... \n"
                   + "set g_maxtimeouts \"0\" \n"
                   + "set g_disable_vote_timeout \"1\" \n"
                   + "set g_disable_vote_timein \"1\" \n"
                   + "set g_disable_vote_scorelimit \"1\" \n"
                   + "\n"
    			 + "echo race.cfg executed\n";
    
          G_WriteFile( "configs/server/gametypes/race.cfg", config );
          G_Print( "Created default base config file for race\n" );
          G_CmdExecute( "exec configs/server/gametypes/race.cfg silent" );
      }
   
      gametype.isTeamBased = false;
      gametype.hasChallengersQueue = false;
      gametype.maxPlayersPerTeam = 0;
      gametype.spawnpointRadius = 0;
      gametype.autoInactivityRemove = true;
      gametype.playerInteraction = true;
      gametype.freestyleMapFix = false;
      gametype.enableDrowning = true;
    
    	// disallow warmup, no matter what config files say, because it's bad for racesow timelimit.
      g_warmup_timelimit.set("0"); //g_warmup_enabled was removed in warsow 0.6
	
      G_ConfigString( CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %t 96 %i 48 %l 48 %s 85" );
	    G_ConfigString( CS_SCB_PLAYERTAB_TITLES, "Name Clan Time Speed Ping State" );
    }
    
    void SpawnGametype()
    {
        
    }
    
    void Shutdown()
    {
        
    }
    
    bool MatchStateFinished( int incomingMatchState )
    {
        if (incomingMatchState == MATCH_STATE_POSTMATCH)
        {
            map.startOvertime();
            return map.allowEndGame();
        }
        return true;
    }
    
    void MatchStateStarted()
    {
        switch ( match.getState() )
        {
        case MATCH_STATE_WARMUP:
            match.launchState( MATCH_STATE_PLAYTIME );
            break;
    
        case MATCH_STATE_COUNTDOWN:
            break;
    
        case MATCH_STATE_PLAYTIME:
            map.setUpMatch();
            break;
    
        case MATCH_STATE_POSTMATCH:
            gametype.pickableItemsMask = 0;
            gametype.dropableItemsMask = 0;
            GENERIC_SetUpEndMatch();
            break;
    
        default:
            break;
        }
    }
    
    void ThinkRules()
    {
        // set all clients race stats
        cClient @client;

        for ( int i = 0; i < maxClients; i++ )
        {
            @client = @G_GetClient( i );

            if ( client.state() < CS_SPAWNED )
                continue;

            Racesow_Player @player = Racesow_GetPlayerByClient( client );

            if( ( player.client.team == TEAM_SPECTATOR ) && !( player.client.chaseActive ) )
                @player.race = null;

            if ( player.isRacing() )
            {
                client.setHUDStat( STAT_TIME_SELF, player.race.getCurrentTime() / 100 );
                if ( player.highestSpeed < player.getSpeed() )
                    player.highestSpeed = player.getSpeed(); // updating the heighestSpeed attribute.
            }

            client.setHUDStat( STAT_TIME_BEST, player.getBestTime() / 100 );
            client.setHUDStat( STAT_TIME_RECORD, map.getHighScore().getTime() / 100 );
            if ( isUsingRacesowClient(client) )
            {
                client.setHUDStat( STAT_TIME_ALPHA, map.getWorldHighScore().getTime() / 100 );
            }
            addFastcapHUDStats( @client );
            if ( client.getEnt().health > client.getEnt().maxHealth )
                client.getEnt().health -= ( frameTime * 0.001f );
        }
    }
    
    void playerRespawn( cEntity @ent, int old_team, int new_team )
    {
        if ( ent.isGhosting() )
	        return;
	        
        Racesow_Player @player = Racesow_GetPlayerByClient( ent.client );
        // remove gunblade auto attacking
        ent.client.setPMoveFeatures( ent.client.pmoveFeatures & ~PMFEAT_GUNBLADEAUTOATTACK );

        // disable autojump
        if ( rs_allowAutoHop.boolean == false )
        {
            ent.client.setPMoveFeatures( ent.client.pmoveFeatures & ~PMFEAT_CONTINOUSJUMP );
        }
        
        ent.client.inventorySetCount( WEAP_GUNBLADE, 1 );
        player.getClient().stats.setScore(player.bestRaceTime);
        player.restartingRace();
    }
    
    void scoreEvent( cClient @client, String &score_event, String &args )
    {
        
    }
    
    String @ScoreboardMessage( uint maxlen )
    {
        String scoreboardMessage, entry;
        cTeam @team;
        cEntity @ent;
        int i, playerID;
        int racing;
        //int readyIcon;

        @team = @G_GetTeam( TEAM_PLAYERS );

        // &t = team tab, team tag, team score (doesn't apply), team ping (doesn't apply)
        entry = "&t " + int( TEAM_PLAYERS ) + " 0 " + team.ping + " ";
        if ( scoreboardMessage.len() + entry.len() < maxlen )
            scoreboardMessage += entry;

        // "Name Time Ping State"
        for ( i = 0; @team.ent( i ) != null; i++ )
        {
            @ent = @team.ent( i );
            Racesow_Player @player = Racesow_GetPlayerByClient( ent.client );

            int playerID = ( ent.isGhosting() && ( match.getState() == MATCH_STATE_PLAYTIME ) ) ? -( ent.playerNum + 1 ) : ent.playerNum;
			
            entry = "&p " + playerID + " " + ent.client.clanName + " "
                + player.getBestTime() + " "
                + player.highestSpeed + " "
                + ent.client.ping + " " + player.getState() + " ";
            if ( scoreboardMessage.len() + entry.len() < maxlen )
                scoreboardMessage += entry;
        }
        return @scoreboardMessage;
    }
    
    cEntity @SelectSpawnPoint( cEntity @self )
    {
        if( @alphaFlagBase != null )
        {
            return @bestFastcapSpawnpoint();
        }
        else
        {
            return null; // select random
        }
    }
    
    bool UpdateBotStatus( cEntity @self )
    {
        return false;// let the default code handle it itself
    }
    
    bool Command( cClient @client, String @cmdString, String @argsString, int argc )
    {
        return false;
    }
}
