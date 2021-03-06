-- vanilla
local helpers = require 'vanilla.v.libs.utils'

-- perf
local pairs = pairs
local ogetenv = os.getenv
local app_run_evn = ogetenv("VA_ENV") or 'development'

local va_ngx_conf = {}
va_ngx_conf.common = {
	VA_ENV = app_run_evn,
	INIT_BY_LUA = 'nginx.init',
	LUA_PACKAGE_PATH = '',
	LUA_PACKAGE_CPATH = '',
	VANILLA_WAF = 'vanilla.sys.waf.acc'
}

va_ngx_conf.env = {}
va_ngx_conf.env.development = {
    LUA_CODE_CACHE = false,
    PORT = 7200
}

va_ngx_conf.env.test = {
    LUA_CODE_CACHE = true,
    PORT = 7201
}

va_ngx_conf.env.production = {
    LUA_CODE_CACHE = true,
    PORT = 80
}

local function getNgxConf(conf_arr)
	if conf_arr['common'] ~= nil then
		local common_conf = conf_arr['common']
		local env_conf = conf_arr['env'][app_run_evn]
		for directive, info in pairs(common_conf) do
			env_conf[directive] = info
		end
		return env_conf
	elseif conf_arr['env'] ~= nil then
		return conf_arr['env'][app_run_evn]
	end
	return {}
end

local function buildConf()
	local get_app_va_ngx_conf = helpers.try_require('config.nginx', {})
	local app_ngx_conf = getNgxConf(get_app_va_ngx_conf)
	local sys_ngx_conf = getNgxConf(va_ngx_conf)
	if app_ngx_conf ~= nil then
		for k,v in pairs(app_ngx_conf) do
			sys_ngx_conf[k] = v
		end
	end
	return sys_ngx_conf
end

local ngx_directive_handle = require('vanilla.sys.nginx.directive'):new(app_run_evn)
local ngx_directives = ngx_directive_handle:directiveSets()

local VaNgxConf = {}

local ngx_run_conf = buildConf()
-- pp(ngx_run_conf)
-- os.exit()
for directive, func in pairs(ngx_directives) do
	if type(func) == 'function' then
		-- if ngx_run_conf[directive] == true then  pp(ngx_run_conf[directive]) pp(directive) end
		VaNgxConf[directive] = func(ngx_directive_handle, ngx_run_conf[directive])
	else
		VaNgxConf[directive] = ngx_run_conf[directive]
	end
end
-- pp(VaNgxConf)
return VaNgxConf