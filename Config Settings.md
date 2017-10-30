# StormFox Commands
*Command*                    | *Description*              
:----------------------------| ------------
sf_menu                      | Opens the SF weather-menu
sf_open_mapbrowser           | Opens the map-browser
sf_setweather                | Sets the current weather to the given value

# StormFox Settings
## Server ConVars
*ConVar*                     | *Value*       | *Description*              
:----------------------------| ------------- |  ------------
**Time**                     |               |
sf_timespeed                 | [0-66]        | The minutes of gametime pr second.
sf_start_time                | [12- or 24-clock string]|Start the server at a specific time.
**Weather**                  |               |              
sf_disableweatherdebuffs     | [0/1]         | Disable weather debuffs/damage/impact. (Off by default on servers) 
sf_disable_windpush          | [0/1]         | Disable wind-push on props (Off by default on servers and can cause lag). 
sf_disablelightningbolts     | [0/1]         | Disable lightning strikes.
**Weather Generator**        |               |              
sf_disable_autoweather       | [0/1]         |  Disable the automatic weather-generator.
sf_disable_autoweather_cold  | [0/1]         | Disable the autoweather creating cold temperatures and snow.
**Map effects**              |               |              
sf_moonscale                 | [number]      | Set the moonscale.
sf_sv_material_replacment    | [0/1]         | Enables material-replacment for weather effects.
sf_replacment_dirtgrassonly  | [0/1]         | Only replace dirt and grass. (Useful on crazy maps)
sf_disablefog                | [0/1]         | Disables SF editing the fog.
sf_disableskybox             | [0/1]         | Disables SF editing the skybox's varables.
sf_disable_mapsupport        | [0/1]         | Disables SF creating missing entities.
sf_enable_ekstra_lightsupport| [0/1]         | Enables ekstra lightsupport (engine.LightStyle).
sf_disable_mapbloom          | [0/1]         | Disables the light-bloom.
**Other**|                   |               |
sf_disblemapbrowser          | [0/1]         | Disable mapchange with the mapbrowser (On by default for servers)
sf_debugcompatibility        | [0/1]         | This will make SF scan for addons and scripts breaking hooks. (Overrides hook.Call)

## Client Convars
*ConVar*                     | *Value*       | *Description*              
:----------------------------| ------------- |  ------------
**Time**                     |               |
sf_exspensive                | [0-20]        | Ther weather quality-level. 0 will make it automatic measure for the best setting.
sf_material_replacment       | [0/1]         | Enable material replacment for weather effects. (clientside)
sf_allow_rainsound           | [0/1]         | Enable rain-sounds
sf_allow_windsound           | [0/1]         | Enable wind-sounds
sf_allow_dynamiclights       | [0/1]         | Enable lamp-lights from sf.
sf_allow_sunbeams            | [0/1]         | Enable sunbeams.
sf_allow_dynamicshadow       | [0/1]         | Enable dynamic light/shadows.
sf_redownloadlightmaps       | [0/1]         | Lighterrors fix and required with sf_enable_ekstra_lightsupport (Can lags).
sf_allow_raindrops           | [0/1]         | Enables raindrops on the screen.

