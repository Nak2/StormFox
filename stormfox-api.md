# StormFox API

[![N|Solid](https://i.imgur.com/HMHQEmA.png)](https://steamcommunity.com/sharedfiles/filedetails/?id=1132466603)

Definitions:
  - time-varable is a number between 0 and 1440 that indicates the time. 
    - 1440 and 0 is midnight
    - 360 is sunrise
    - 720 is midday
    - 1080 is sunset
- Brackets
    - "[]" around an argument or result, means its optional. It can be left/return as a nil.

# List of commen and useful functions:
#### Time Functions
| Functions        | Description| Eample of input  |
| -------------------- |:-------------|:------|
| StormFox.StringToTime([String](http://wiki.garrysmod.com/page/Category:string): time-string)  | returns time-value from a string. Incl AM/PM support. | "11:00 PM" or "23:00" |
| StormFox.GetTimeSpeed()                                                                       | returns the ingame-minutes-pr-second, set by; sf_timespeed x. | |
| StormFox.GetTime([boolean](http://wiki.garrysmod.com/page/Category:boolean): return wholenumbers) | returns the current time-varable. |
| StormFox.GetRealTime([[number](http://wiki.garrysmod.com/page/Category:number): time-value],[[boolean](http://wiki.garrysmod.com/page/Category:boolean) Use AM and OM]) | returns the current time as a string.| |
| StormFox.GetDate()                                                                                        | returns day, month as a number. | |
| StormFox.GetRealDate([[boolean](http://wiki.garrysmod.com/page/Category:boolean): return only 3 letters]) | returns day and month acording to StormFox, as a string. |
| StormFox.SpecialDay([[number](http://wiki.garrysmod.com/page/Category:number): day],[[number](http://wiki.garrysmod.com/page/Category:number): month]) | returns a table of some special events, for the given or current day. |
| StormFox.IsNight() | returns true if its night |
| StormFox.IsDay() | returns true if its day |
|**Server Side**|
|StormFox.SetTime([number](http://wiki.garrysmod.com/page/Category:number): time-value) | Sets the current time (Don't call this often)| [number](http://wiki.garrysmod.com/page/Category:number) time-value or [String](http://wiki.garrysmod.com/page/Category:string) time-string|  

#### Weather Functions
| Functions        | Description           |
| ------------- |:-------------|
| StormFox.IsRaining() | returns true if its raining |
| StormFox.IsThunder() | return true if there is thunder. |
| StormFox.CelsiusToFahrenheit([number](http://wiki.garrysmod.com/page/Category:number): celsius) | returns Freedom units.|
| StormFox.GetBeaufort([number](http://wiki.garrysmod.com/page/Category:number): meters-pr-second) | returns Beaufort-unit and description. |
| StormFox.GetWeather() | returns the current weather. |
| StormFox.GetWeatherID() | returns the ID of the current weather.|
| StormFox.GetTemperature([boolean](http://wiki.garrysmod.com/page/Category:boolean): use farenheight)| returns the current temperature.|
|**SERVER**|
|StormFox.SetWeather([String](http://wiki.garrysmod.com/page/Category:string): Weather ID, [number](http://wiki.garrysmod.com/page/Category:number): magnitude, [[number](http://wiki.garrysmod.com/page/Category:number): transition time in seconds)]| Sets the weather |
| StormFox.SetTemperature([number](http://wiki.garrysmod.com/page/Category:number): temperature, [boolean](http://wiki.garrysmod.com/page/Category:boolean): use_fahrenheit) | Sets the temperature |
| StormFox.SetThunder( [boolean](http://wiki.garrysmod.com/page/Category:boolean) ) | Sets thunder |

#### Sun/Moon Functions
| Functions        | Description           |
| ------------- |:-------------|
| StormFox.GetSunAngle([[number](http://wiki.garrysmod.com/page/Category:number): time-value]) | returns the angle of the sun. |
| StormFox.GetMoonAngle([[number](http://wiki.garrysmod.com/page/Category:number): time-value]) |  returns the angle of the moon. |
| StormFox.GetMoonPhase() | returns the moon-phase and light-procent of the moon. |
| **CLIENT** |
| StormFox.GetMoonMaterial() | returns [IMaterial](http://wiki.garrysmod.com/page/Category:IMaterial): generated moonlight-material, [IMaterial](http://wiki.garrysmod.com/page/Category:IMaterial): the moondark-material, [number](http://wiki.garrysmod.com/page/Category:number): current moon-rotation.|
| StormFox.GetMoonVisibility() | returns moon visibility between 0-1 as a [number](http://wiki.garrysmod.com/page/Category:number) |
| StormFox.GetSunVisibility() | returns sun visibility between 0-1 as a [number](http://wiki.garrysmod.com/page/Category:number) |
| StormFox.GetSunRayVisibility() | returns sun-ray visibility between 0-1 as a [number](http://wiki.garrysmod.com/page/Category:number) |

#### StormFox hooks
| Hooks                 | Description                                               | Arguments |
| -------------         |:-----------------------------------                       |:--------------|
| StormFox - PostInit   | Called when StormFox has launched.                        |
| StormFox - PostEntity | Called when StormFox is loading and entites are valid.    |
| StormFox - PostEntityScan | Called when StormFox has scanned for map-entites.     |
| StormFox - NewWeather | Called when StormFox changes weather.                     | [String](http://wiki.garrysmod.com/page/Category:string): WeatherID, [String](http://wiki.garrysmod.com/page/Category:string): OldWeatherID |
| StormFox - DataChange | Called when data changes.                                 | [String](http://wiki.garrysmod.com/page/Category:string):DATA, Any Value, [[number](http://wiki.garrysmod.com/page/Category:number): lerp-time] |
| StormFox - NetDataChange | Called when network-data changes.                      | [String](http://wiki.garrysmod.com/page/Category:string):DATA, Any Value, [[number](http://wiki.garrysmod.com/page/Category:number): lerp-time]               |
| StormFox - Timechange | Called when timespeed changes. (sf_timespeed)             | [number](http://wiki.garrysmod.com/page/Category:number) |
| StormFox - Timeset| Called when time have been set.                               |
| StormFox-Sunrise                                                                  | Called on sunrise |
| StormFox-Sunset                                                                   | Callen on sunset |
| StormFox-NewDay												                    | Called on new days |
