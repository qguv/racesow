/**
 * Racesow_Player
 *
 * @package Racesow
 * @subpackage Player
 * @version 1.0.3
 */
class Racesow_Player_Implemented
{
	/**
	 * The player himself
	 */
	Racesow_Player @player;
	
	/**
	 * Set the player
	 * @param Racesow_Player @player
	 * @return void
	 */
	void setPlayer( Racesow_Player @player )
	{
		@this.player = @player;
	}

	/**
	 * Get the race delta
	 * @return void
	 */
	Racesow_Player @getPlayer()
	{
		return @this.player;
	}
}
