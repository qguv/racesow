/*
Copyright (C) 1997-2001 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#define	UI_API_VERSION	    28

#include "../cgame/ref.h"

//
// these are the functions exported by the refresh module
//
typedef struct
{
	// halts the application
	void ( *Error )( const char *str );

	// console messages
	void ( *Print )( const char *str );

	// dynvars
	dynvar_t *( *Dynvar_Create )( const char *name, qboolean console, dynvar_getter_f getter, dynvar_setter_f setter );
	void ( *Dynvar_Destroy )( dynvar_t *dynvar );
	dynvar_t *( *Dynvar_Lookup )( const char *name );
	const char *( *Dynvar_GetName )( dynvar_t *dynvar );
	dynvar_get_status_t ( *Dynvar_GetValue )( dynvar_t *dynvar, void **value );
	dynvar_set_status_t ( *Dynvar_SetValue )( dynvar_t *dynvar, void *value );
	void ( *Dynvar_AddListener )( dynvar_t *dynvar, dynvar_listener_f listener );
	void ( *Dynvar_RemoveListener )( dynvar_t *dynvar, dynvar_listener_f listener );

	// console variable interaction
	cvar_t *( *Cvar_Get )( const char *name, const char *value, int flags );
	cvar_t *( *Cvar_Set )( const char *name, const char *value );
	cvar_t *( *Cvar_ForceSet )( const char *name, const char *value );      // will return 0 0 if not found
	void ( *Cvar_SetValue )( const char *name, float value );
	float ( *Cvar_Value )( const char *name );
	const char *( *Cvar_String )( const char *name );

	int ( *Cmd_Argc )( void );
	char *( *Cmd_Argv )( int arg );
	char *( *Cmd_Args )( void );        // concatenation of all argv >= 1

	void ( *Cmd_AddCommand )( const char *name, void ( *cmd )( void ) );
	void ( *Cmd_RemoveCommand )( const char *cmd_name );
	void ( *Cmd_ExecuteText )( int exec_when, const char *text );
	void ( *Cmd_Execute )( void );

	void ( *R_ClearScene )( void );
	void ( *R_AddEntityToScene )( const entity_t *ent );
	void ( *R_AddLightToScene )( const vec3_t org, float intensity, float r, float g, float b, const struct shader_s *shader );
	void ( *R_AddPolyToScene )( const poly_t *poly );
	void ( *R_RenderScene )( const refdef_t *fd );
	void ( *R_EndFrame )( void );
	void ( *R_ModelBounds )( const struct model_s *mod, vec3_t mins, vec3_t maxs );
	struct model_s *( *R_RegisterModel )( const char *name );
	struct shader_s *( *R_RegisterSkin )( const char *name );
	struct shader_s *( *R_RegisterPic )( const char *name );
	struct shader_s *( *R_RegisterLevelshot )( const char *name, struct shader_s *defaultPic, qboolean *matchesDefault );
	struct skinfile_s *( *R_RegisterSkinFile )( const char *name );
	qboolean ( *R_LerpTag )( orientation_t *orient, const struct model_s *mod, int oldframe, int frame, float lerpfrac, const char *name );
	void ( *R_DrawStretchPic )( int x, int y, int w, int h, float s1, float t1, float s2, float t2, const vec4_t color, const struct shader_s *shader );
	void ( *R_TransformVectorToScreen )( const refdef_t *rd, vec3_t const in, vec2_t out );
	int ( *R_SkeletalGetNumBones )( const struct model_s *mod, int *numFrames );
	int ( *R_SkeletalGetBoneInfo )( const struct model_s *mod, int bone, char *name, size_t name_size, int *flags );
	void ( *R_SkeletalGetBonePose )( const struct model_s *mod, int bone, int frame, bonepose_t *bonepose );

	struct sfx_s *( *S_RegisterSound )( const char *name );
	void ( *S_StartLocalSound )( const char *s );
	void ( *S_StartBackgroundTrack )( const char *intro, const char *loop );
	void ( *S_StopBackgroundTrack )( void );

	// fonts
	struct mufont_s *( *SCR_RegisterFont )( const char *name );
	void ( *SCR_DrawString )( int x, int y, int align, const char *str, struct mufont_s *font, vec4_t color );
	int ( *SCR_DrawStringWidth )( int x, int y, int align, const char *str, int maxwidth, struct mufont_s *font, vec4_t color );
	void ( *SCR_DrawClampString )( int x, int y, const char *str, int xmin, int ymin, int xmax, int ymax, struct mufont_s *font, vec4_t color );
	size_t ( *SCR_strHeight )( struct mufont_s *font );
	size_t ( *SCR_strWidth )( const char *str, struct mufont_s *font, int maxlen );
	size_t ( *SCR_StrlenForWidth )( const char *str, struct mufont_s *font, size_t maxwidth );

	void ( *CL_Quit )( void );
	void ( *CL_SetKeyDest )( int key_dest );
	void ( *CL_ResetServerCount )( void );
	char *( *CL_GetClipboardData )( qboolean primary );
	void ( *CL_FreeClipboardData )( char *data );

	const char *( *Key_GetBindingBuf )( int binding );
	void ( *Key_ClearStates )( void );
	const char *( *Key_KeynumToString )( int keynum );
	void ( *Key_SetBinding )( int keynum, char *binding );
	qboolean ( *Key_IsDown )( int keynum );

	qboolean ( *VID_GetModeInfo )( int *width, int *height, qboolean *wideScreen, int mode );

	void ( *GetConfigString )( int i, char *str, int size );
	unsigned int ( *Milliseconds )( void );

	// files will be memory mapped read only
	// the returned buffer may be part of a larger pak file,
	// or a discrete file from anywhere in the quake search path
	// a -1 return means the file does not exist
	// NULL can be passed for buf to just determine existance
	int ( *FS_FOpenFile )( const char *filename, int *filenum, int mode );
	int ( *FS_Read )( void *buffer, size_t len, int file );
	int ( *FS_Write )( const void *buffer, size_t len, int file );
	int ( *FS_Print )( int file, const char *msg );
	int ( *FS_Tell )( int file );
	int ( *FS_Seek )( int file, int offset, int whence );
	int ( *FS_Eof )( int file );
	int ( *FS_Flush )( int file );
	void ( *FS_FCloseFile )( int file );
	qboolean ( *FS_RemoveFile )( const char *filename );
	int ( *FS_GetFileList )( const char *dir, const char *extension, char *buf, size_t bufsize, int start, int end );
	int ( *FS_GetGameDirectoryList )( char *buf, size_t bufsize );
	const char *( *FS_FirstExtension )( const char *filename, const char *extensions[], int num_extensions );

	// maplist
	const char *( *ML_GetFilename )( const char *fullname );
	const char *( *ML_GetFullname )( const char *filename );
	size_t ( *ML_GetMapByNum )( int num, char *out, size_t size );

	void *( *Mem_Alloc )( size_t size, const char *filename, int fileline );
	void ( *Mem_Free )( void *data, const char *filename, int fileline );

	void ( *MM_UIRequest )( int action, const char *data );
	int ( *MM_GetStatus )( void );
} ui_import_t;

typedef struct
{
	// if API is different, the dll cannot be used
	int ( *API )( void );
	void ( *Init )( int vidWidth, int vidHeight, int protocol, int sharedSeed );
	void ( *Shutdown )( void );

	void ( *Refresh )( unsigned int time, int clientState, int serverState, qboolean demoplaying, qboolean backGround );
	void ( *DrawConnectScreen )( const char *serverName, const char *rejectmessage, int downloadType, const char *downloadfilename, 
		float downloadPercent, int downloadSpeed, int connectCount, qboolean demoplaying, qboolean backGround );

	void ( *Keydown )( int key );
	void ( *Keyup )( int key );
	void ( *CharEvent )( qwchar key );

	void ( *MouseMove )( int dx, int dy );

	void ( *ForceMenuOff )( void );
	void ( *AddToServerList )( char *adr, char *info );

	void ( *MM_UIReply )( int action, const char *data );
} ui_export_t;
