return [[Stormfox 中文版 BY Niko

#StormFox
	sf_description.newversion = 您正在运行SF的Beta版
	sf_description.oldversion = 您正在运行SF的旧版本

#Tool
	sf_tool.menu 		= 菜单
	sf_tool.maptexture 	= 地图纹理
	sf_tool.maptexture.helpm1 = 按鼠标1添加材料
	sf_tool.maptexture.helpm2 = 按鼠标2删除材料
	sf_tool.permaentity = 永久实体
	sf_tool.addmaterial = 添加
	sf_tool.cancel 		= 取消
	sf_tool.menu_reload = 按R进入菜单

#Variables
	sf_type.roof 		= 屋顶
	sf_type.dirtgrass 	= 土/草
	sf_type.road 		= 路
	sf_type.pavement 	= 路面

	# - Weather
		sf_weather.clear 		= 清楚
		sf_weather.rain 		= 雨
		sf_weather.raining 		= 下雨
		sf_weather.sleet 		= 雨雪
		sf_weather.snowing 		= 下雪
		sf_weather.fog 			= 多雾路段
		sf_weather.light_fog 	= 轻雾
		sf_weather.heavy_fog 	= 浓雾
		sf_weather.storm 		= 风暴
		sf_weather.thunder 		= 雷
		sf_weather.cloudy 		= 多云
		sf_weather.lava 		= 岩浆
		sf_weather.lava_eruption= 熔岩喷发
		sf_weather.sandstorm 	= 沙暴
		sf_weather.radioactive 	= 放射
		sf_weather.radioactive_rain= 放射性雨

	# - Wind
		sf_winddescription.calm 			= 安静
		sf_winddescription.light_air		= 软风
		sf_winddescription.light_breeze		= 微风
		sf_winddescription.gentle_breeze	= 微风
		sf_winddescription.moderate_breeze	= 和风
		sf_winddescription.fresh_breeze		= 清劲凤
		sf_winddescription.strong_breeze	= 强风
		sf_winddescription.near_gale		= 大风附近
		sf_winddescription.gale				= 大风
		sf_winddescription.strong_gale		= 烈风
		sf_winddescription.storm			= 风暴
		sf_winddescription.violent_storm	= 急风暴雨
		sf_winddescription.hurricane		= 飓风
		sf_winddescription.cat2				= 类别 2
		sf_winddescription.cat3				= 类别 3
		sf_winddescription.cat4				= 类别 4
		sf_winddescription.cat5				= 类别 5

#Weather
	sf_current_weather = 当前天气

#Server Settings
	sf_description.autopilot		 = 尝试修复启动时的所有问题
	sf_description.timespeed		 = 秒的游戏时间pr实际秒
	sf_description.moonscale		 = 月球秤
	sf_description.moonphase 		 = 启用月相.
	sf_description.enablefog 		 = 允许SF编辑雾
	sf_description.weatherdebuffs 	 = 启用天气减益/损坏/影响
	sf_description.windpush 		 = 在道具上启用风推
	sf_description.lightningbolts 	 = 启用雷击
	sf_description.enable_mapsupport = 为地图启用实体支持
	sf_description.sunmoon_yaw 	 	 = 太阳/月亮偏航
	sf_description.debugcompatibility = 启用SF兼容性调试器
	sf_description.skybox 			 = 启用 SF-skybox
	sf_description.enable_ekstra_lightsupport = 启用额外的灯光支持（大地图上的滞后）
	sf_description.start_time 		 = 在特定时间启动服务器
	sf_description.mapbloom 		 = 允许SF编辑光晕花
	sf_description.enable_mapbrowser = 允许管理员使用SF浏览器更改地图
	sf_description.allowcl_disableeffects = 允许客户端禁用SF效果
	sf_description.autoweather 		 = 启用天气生成
	sf_description.realtime 		 = 按照当地时间。
	sf_description.foliagesway 		 = 启用树叶摇摆
	sf_description.override_soundscape = 覆盖地图声景
	sf_description.sf_enable_ekstra_entsupport = 根据灯光变化更新所有实体 （为服务器计价）

#Client Settings
	sf_description.disableeffects 		= 禁用所有效果
	sf_description.exspensive 			= [0-7+] 启用大量天气计算
	sf_description.exspensive_fps 		= 使用FPS缩放质量设置
	sf_description.exspensive_manually 	= 手动设置质量设置
	sf_description.material_replacment 	= 为天气影响启用材料替换
	sf_description.allow_rainsound 		= 启用雨声
	sf_description.allow_windsound 		= 启用声音
	sf_description.allow_dynamiclights 	= 启用来自 SF
	sf_description.allow_sunbeams 		= 启用阳光
	sf_description.allow_dynamicshadow 	= 启用动态灯光/阴影
	sf_description.dynamiclightamount 	= 控制动态光量
	sf_description.redownloadlightmaps 	= 更新光照贴图（可能滞后于大图）
	sf_description.allow_raindrops 		= 在屏幕上启用雨滴
	sf_description.renderscreenspace_effects = 启用2D渲染
	sf_description.useAInode 			= 使用AI节点可获得更可靠的声音和效果
	sf_description.enable_breath 		= 启用冷呼吸效果
	sf_description.enable_windoweffect 	= 在易碎的窗户上启用雨滴
	sf_description.enable_windoweffect_enable_tr = 检查雨水是否落在易碎的窗户上
	sf_description.rainpuddle_enable 	= 产生雨的水生雨水坑 （需要AI节点）
	sf_description.footsteps_enable 	= 在雪中渲染脚步声
	sf_description.footsteps_max 		= 最大脚步声
	sf_description.footsteps_distance 	= 在雪中足迹的渲染距离
	sf_description.hq_shadowmaterial 	= 设置HQ阴影convars

#Map Settings
	sf_description.map_entities			 = 地图实体
	sf_description.dynamiclight 		 = 为所有客户提供动态照明
	sf_description.replace_dirtgrassonly = 仅更换草/污垢
	sf_description.wind_breakconstraints = 打破约束并在强风中解冻道具

#StormFox msg
	sf_added_content 			= 添加 %i 内容文件
	sf_permisson.deny 			= 您无权访问天气设置
	sf_permisson.denysettings 	= 您无权访问SF设置
	sf_permisson.denymap 		= 您无权更改地图
	sf_permisson.denymapsetting = 该服务器已禁用地图浏览器
	sf_permisson.denymapmissing = 服务器缺少地图
	sf_generating.puddles 		= 生成的水坑位置
	sf_missinglanguage 			= 缺少语言文件：

#MapData
	sf_mapdata_load 	 = 加载的地图数据
	sf_mapdata_invalid 	 = 来自服务器的无效地图数据!
	sf_mapdata_cleanup 	 = 清洁地图更改 ...
	sf_ain_load 		 = 加载的.ain文件

#Interface basics
	Settings 		 = 设定
	Server Settings  = 服务器设定
	Client Settings  = 客户端设置
	Controller 		 = 控制者
	Troubleshooter 	 = 疑难解答
	Reset 			 = 重启
	Weather Controller = 天气控制器
	Effects 		 = 特效
	Map Browser 	 = 地图浏览器
	Map 			 = 地图
	Clients 		 = 客户群
	Other 			 = 其他
	Time 			 = 时间
	Misc 			 = 杂项
	Weather 		 = 天气
	Auto Weather 	 = 汽车天气
	Adv Light 		 = Adv 光
	Sun / Moon 		 = 日/月
	Changelog 		 = 变更日志
	Temperature 	 = 温度
	Wind 			 = 风
	Quality 		 = 质量
	Materials 		 = 用料
	Rain/Snow Effects= 雨/雪影响

#Interface adv	
	sf_troubleshooter.description 	= 这将显示设置的常见问题
	sf_temperature_range 		 	= 温度范围
	sf_setwindangle 			 	= 设置风角
	sf_setweather 					= 设定天气
	sf_settime 						= 设置时间
	sf_holdc 						= 按住C
	sf_interface_lighttheme 		= 轻主题
	sf_interface_darktheme 			= 黑暗主题
	sf_interface_light 				= 光
	sf_interface_light_range 		= 光线范围: 
	sf_interface_save_on_exit 		= 退出时保存
	sf_interface_adv_light 			= Adv 光
	sf_interface_closechat 			= 关闭聊天进行互动
	sf_interface_closeconsole 		= 关闭控制台
	sf_interface_material_replacment= 材料更换
	sf_interface_max_wind 			= 最大风
	sf_interface_max_footprints 	= 最大足迹
	sf_interface_footprint_render 	= 足迹渲染距离
	sf_interface_language 			= 语言覆盖 

#Errors and warning
	sf_missing_convar 				= 缺少Convar
	sf_warning_clientlag 			= 可以落后于一些客户！
	sf_warning_serverlag 			= 会造成严重的服务器延迟！
	sf_warning_reqmapchange 		= 需要mapchange
	sf_description.disabled_on_server = 在此服务器上已禁用
	sf_warning_unsupportmap 		= 在不受支持的地图上必填
	sf_warning_missingmaterial.title = 您缺少材料。
	sf_warning_missingmaterial.nevershow = 不要再显示这个
	sf_warning_missingmaterial 		= 您缺少 %i 材料(s).
	sf_warning_unfinished_a 		= 尚未完成。 请在服务器设置中使用疑难解答
	sf_warning_unfinished_b 		= 打开服务器端疑难解答（需要权限）
]]
