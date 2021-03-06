/**
 * Racesow_Player_Auth
 *
 * @package Racesow
 * @subpackage Player
 * @version 1.0.3
 */

const uint RACESOW_AUTH_REGISTERED      = 1;
const uint RACESOW_AUTH_MAP             = 2;
const uint RACESOW_AUTH_MUTE            = 4;
const uint RACESOW_AUTH_KICK            = 8;
const uint RACESOW_AUTH_TIMELIMIT       = 16;
const uint RACESOW_AUTH_RESTART         = 32;
const uint RACESOW_AUTH_SETPERMISSION   = 64;
const uint RACESOW_AUTH_ALL             = 127;

//By default an admin has all permissions except RACESOW_AUTH_SETPERMISSION
const uint RACESOW_AUTH_ADMIN           = (RACESOW_AUTH_REGISTERED | RACESOW_AUTH_MAP | RACESOW_AUTH_MUTE | RACESOW_AUTH_KICK | RACESOW_AUTH_TIMELIMIT | RACESOW_AUTH_RESTART);
 
 class Racesow_Player_Auth : Racesow_Player_Implemented
 {
    /**
	 * Racesow account name
	 * @var String
	 */
	String authenticationName;
    String lastAuthenticationName;
    /**
	 * Racesow account pass
	 * @var String
	 */
	String authenticationPass; 
    String lastAuthenticationPass;
    
    /**
	 * Racesow account token
	 * @var String
	 */
	String authenticationToken;
    String lastAuthenticationToken;

	/**
	 * The Player's unique ID
	 * @var int
	 */
	int playerId;
	
	/**
	 * The Player's nick unique ID
	 * @var int
	 */
	int nickId;
    
    /**
	 * Racesow authorizations bitmask
	 * @var uint
	 */
	uint authorizationsMask;
    uint lastAuthorizationsMask;
	/**
	 * Number of failed auths in a row
	 * @var uint
	 */
	uint failCount;

	/**
	 * The time of the last message
	 * @var int
	 */
	int lastViolateProtectionMessage;

	/**
	 * the time when we started to wait for the player
	 * to authenticate as he uses a protected nickname
	 * @var uint64
	 */
	uint64 violateNickProtectionSince;

    /**
     * Constructor
     */
	Racesow_Player_Auth()
	{
		this.reset();
	}

        
    /**
     * Descructor
     */
	~Racesow_Player_Auth()
	{
	}
    
    /**
     * Reset the whole auth object
     *
     */
	void reset()
	{
        this.resetViolateState();
        this.killAuthentication();
        this.destroyBackup();
	}

    /**
     * Don't blame the player nomore
     *
     * @return void
     */
    void resetViolateState()
    {
        this.violateNickProtectionSince = 0;
        this.lastViolateProtectionMessage = 0;
        this.failCount = 0;
    }
    
    /**
     * Remove all information about the authentication
     * and the authorizations of the player
     *
     * @return void
     */
    void killAuthentication()
    {
        this.nickId = 0;
        this.playerId = 0;
        this.authenticationName = "";
        this.authenticationPass = "";
        this.authenticationToken = "";
        this.authorizationsMask = 0;
    }

    Racesow_Player_Auth @setName(String name)
    {
        this.authenticationName = name;
        return @this;
    }
    
    Racesow_Player_Auth @setPass(String pass)
    {
        this.authenticationPass = pass;
        return @this;
    }
    
    Racesow_Player_Auth @setToken(String token)
    {
        this.authenticationToken = token;
        return @this;
    }
    
    /**
	 * Convert a string to an allowed filename
	 */
	String toFileName(String fileName)
	{
		String outName="";
		uint position = 0;
		for (position = 0; position < fileName.len(); position++)
		{
			String character;
			character=fileName.substr(position,1);
			if (character=='|' || character=='<' || character=='>' || character=='?' ||  character=='!' || character=='\\' || character=='/' || character=='%' || character==':' || character=='*')
				outName+="_";
			else
				outName+=fileName.substr(position,1);
		}
		return outName;
	}
    
	/**
	 * Register a new server account
	 *
	 * @param String &authName
	 * @param String &authEmail
	 * @param String &password
	 * @param String &confirmation
	 * @return bool
	 */
	bool signUp(String &authName, String &authEmail, String &password, String &confirmation)
	{
        if (rs_registrationDisabled.boolean) {
            this.player.sendErrorMessage( rs_registrationInfo.string );
            return false;
        }

        if (this.player.getId() == 0) {
            this.player.sendErrorMessage( "You do not have a player id" );
            return false;
        }

        if (!this.canBeProtected()) {
            this.player.sendErrorMessage( "This nickname can not be used to register" );
            return false;
        }

        if (password != confirmation) {
            this.player.sendErrorMessage( "Passwords do not match" );
            return false;
        }
    
        if (password.len() < 8) {
            this.player.sendErrorMessage( "Password must contain at least 8 characters" );
            return false;
        }
    
        this.player.isWaitingForCommand = true;
        RS_RegisterAccount( authName, authEmail, password, this.player.client.playerNum, this.player.getId() );

        return true;
	}

    /**
	 * Show the login token to the player
     *
	 */
    bool showToken()
    {
        this.player.sendMessage( "The generation of tokens is not yet implemenmted. If you somehow got a working token you can ignore this message.\n" );
        return false;
    }
    
	/**
	 * Authenticate server account
	 * @param String &authName
	 * @param String &password
     * @param bool silent
	 * @return bool
	 */
	bool authenticate( String &authName, String &authPass, bool silent )
	{
		if ( authName == "" || authName == "" && authPass == "" )
		{
			if ( !silent )
			{
				this.player.sendMessage( S_COLOR_RED + "usage: auth <account name> <password> OR auth <token>\n" );
			}

			return false;
		}
        
        if (this.isAuthenticated())
        {
            if (authName == this.authenticationName)
            {
                if ( !silent )
                {
                    this.player.sendMessage( S_COLOR_RED + "You are already authed as " + authName + "\n" );
                }
                return false;
            }
            
            if (authName == this.authenticationToken)
            {
                if ( !silent )
                {
                    this.player.sendMessage( S_COLOR_RED + "You are already authed with that token\n" );
                }
                return false;
            }
        }
        
        this.player.disappear(this.player.getName(), true);
        
        // if only one param was passed, handle it as an authToken
        if (authPass == "")
        {
            this.setToken(authName);
            this.setName("");
            this.setPass("");
        }
        // otherwise it's username/password
        else
        {
            this.setToken("");
            this.setName(authName);
            this.setPass(authPass);
        }
        
        this.player.appear();
        
        return true;
	}
    
    /**
     * SEt the player id and invoke anythink on teh authentication which
     *
     *
     */
    void setPlayerId(int playerId)
    {
        this.playerId = playerId;
        this.player.sendMessage( S_COLOR_BLUE + "Your PlayerID: "+ playerId +"\n" );
    
        if ( playerId != 0)
        {
            if (this.lastViolateProtectionMessage != 0)
            {
                this.player.sendMessage( S_COLOR_GREEN + "Countdown stopped.\n" );
            }
            this.resetViolateState();
        }
    }

	/**
	 * isAuthenticated
	 * @return bool
	 */
	bool isAuthenticated()
	{
		return this.authorizationsMask > 0;
	}

	/**
	 * Check for a nickname change event
	 * @return void
	 */
	void refresh( String &oldNick)
	{
		if ( @this.player == null || @this.player.getClient() == null )
			return;

		if ( oldNick.removeColorTokens() != this.player.getName().removeColorTokens() )
		{
			this.player.disappear(oldNick, true);
            this.player.appear();
        }
	}

    /**
     * Check if the nickname can be protected
     * @return bool
     */
    bool canBeProtected()
    {
        String simplified = this.player.getName().removeColorTokens().tolower();
        int index = simplified.len() - 1;
        if ( simplified[index--] == 41 ) // ')'
        {
            while ( index >= 0 && simplified[index] >= 48 && simplified[index] <= 57 ) // '0' ... '9'
                index--;
            if ( index >= 0 && index != int(simplified.len()) - 2 && simplified[index] == 40 ) // '('
                simplified = simplified.substr( 0, index );
        }
        if ( simplified == "player" )
            return false;
        return true;
    }

	/**
	 * Check if the player is authorized to do something
	 * @param const uint permission
	 * @return bool
	 */
	bool allow( const uint permission )
	{
        //this.player.sendMessage("mask: " + this.authorizationsMask + ", perm: " + permission + " mask & perm:" + ( this.authorizationsMask & permission ) + "\n");
		return ( this.authorizationsMask & permission == permission );
	}

	/**
	 * Get the player's status concerning nickname protection
	 * @return int
	 */
	int wontGiveUpViolatingNickProtection()
	{
		if ( this.violateNickProtectionSince == 0 )
		{
			return 0;
		}

		int seconds = localTime - this.violateNickProtectionSince;
		if ( seconds == this.lastViolateProtectionMessage )
			return -1; // nothing to do

		this.lastViolateProtectionMessage = seconds;

		if ( seconds < 21 )
			return 1;

		return 2;
	}

	String getViolateCountDown()
	{
		String color;
		int seconds = localTime - this.violateNickProtectionSince;
		if ( seconds > 6 )
			color = S_COLOR_RED;
		else if ( seconds > 3 )
			color = S_COLOR_YELLOW;
		else
			color = S_COLOR_GREEN;

		return color + (21 - (localTime - this.violateNickProtectionSince)) + " seconds remaining...";
	}
    
    bool restoreBackup()
    {
        if (this.lastAuthorizationsMask != 0)
        {
            this.authorizationsMask = this.lastAuthorizationsMask;
            this.authenticationName = this.lastAuthenticationName;
            this.authenticationPass = this.lastAuthenticationPass;
            this.authenticationToken = this.lastAuthenticationToken;
            this.destroyBackup();
            return true;
        }
        
        return false;
    }
    
    void destroyBackup()
    {
        this.lastAuthorizationsMask = 0;
        this.lastAuthenticationName = "";
        this.lastAuthenticationPass = "";
        this.lastAuthenticationToken = "";
    }
    
    bool createBackup()
    {
        if (this.authorizationsMask != 0)
        {
            this.lastAuthorizationsMask = this.authorizationsMask;
            this.lastAuthenticationName = this.authenticationName;
            this.lastAuthenticationPass = this.authenticationPass;
            this.lastAuthenticationToken = this.authenticationToken;
            return true;
        }
        
        return false;
    }
    
  /**
     * Callback when a player "appeared"
     *
     * @param int playerId
     * @param int authMask
     * @param int playerIdForNick
     * @param int authMaskForNick
     * @param int personalBest
     * @param int overallTries
     * @return void
     */
    void appearCallback(int playerId, int authMask, int playerIdForNick, int authMaskForNick, int personalBest, int overallTries)
    {
        bool hasToken = this.authenticationToken != "";
        bool hasLogin = this.authenticationName != "" || this.authenticationPass != "";
        String msg;
    
        if ( rs_loadHighscores.boolean )
		{
		    this.player.bestRaceTime = personalBest;
		    if ( gametypeFlag == MODFLAG_RACE || gametypeFlag == MODFLAG_COOPRACE )
		    {
		        this.player.getClient().stats.setScore(personalBest);
		    }
		    this.player.overallTries = overallTries;
		}

        if ( rs_loadPlayerCheckpoints.boolean )
        {
            String checkpoints = RS_PrintQueryCallback(this.player.getClient().playerNum);

            for ( int i = 0; i < numCheckpoints; i++ )
            {
                this.player.bestCheckPoints[i] = checkpoints.getToken(i).toInt();
            }
        }
    
        // if no authentication in the callback
        if (playerId == 0)
        {
            if (hasToken)
            {
                msg = S_COLOR_WHITE + this.player.getName() + S_COLOR_RED + " failed to authenticate via token";
            }
            else if (hasLogin)
            {
                msg = S_COLOR_WHITE + this.player.getName() + S_COLOR_RED + " failed to authenticate as '"+ this.authenticationName + S_COLOR_RED +"'";
            }
                
            if (this.restoreBackup())
            {
                msg += S_COLOR_GREEN + " but is still authenticated as '"+ this.authenticationName +"'";
            }
            else if (authMaskForNick == 0)
            {
                this.setPlayerId(playerIdForNick);
            }
            
            if ( msg != "" )
                G_PrintMsg( null, msg + "\n" );

            this.player.printWelcomeMessage = true;


        }
        else 
        {
            this.destroyBackup();
			
			// print sucess if the player is not already authed or re-authenticating
            if (!this.isAuthenticated() || playerId != this.playerId)
            {
                if (hasToken)
                    G_PrintMsg( null, S_COLOR_WHITE + this.player.getName() + S_COLOR_GREEN + " successfully authenticated via token\n" );
                else if (hasLogin)
                    G_PrintMsg( null, S_COLOR_WHITE + this.player.getName() + S_COLOR_GREEN + " successfully authenticated as "+ this.authenticationName +"\n" );
                else
                    G_PrintMsg( null, S_COLOR_WHITE + this.player.getName() + S_COLOR_GREEN + " successfully authenticated via session\n" );
            }
			
			// now the player is authed!
            this.setPlayerId(playerId);			
			this.authorizationsMask = uint(authMask);
        }
        
        // nick is protected, players is logged in but the nick does not belong to him!
        if ( authMaskForNick != 0 && playerId != playerIdForNick)
        {
            if (this.violateNickProtectionSince == 0) 
            {
                this.violateNickProtectionSince = localTime;
            }
            
			this.player.sendMessage( S_COLOR_RED + "NICKNAME PROTECTION: \n" + S_COLOR_RED + "Please login for the nick '"+ S_COLOR_WHITE + this.player.getName() + S_COLOR_RED + "' or change it. Otherwise you will get gicked.\n" );
			G_PrintMsg(null, this.player.getName() + S_COLOR_RED + " is not authenticated...\n");
            
        }
    }
	
	void nickCallback(int success_state, String &nick)
	{
		if ( success_state == 0 )
		{
			this.player.sendMessage( S_COLOR_RED + "The nick " + nick.getToken(0) + S_COLOR_RED + " is already protected.\n" );
		}
		else if ( success_state == 1 )
		{
			this.player.sendMessage( "Your protected nick is: " + nick.getToken(0) + ".\nType " + S_COLOR_ORANGE + "protectednick update " + S_COLOR_WHITE + "to protect your current nick.\n" );
		}
		else if ( success_state == 2 )
		{
			this.player.sendMessage( "Your protected nick has been updated to: " + nick.getToken(0) + "\n" );
		}
	}
}
