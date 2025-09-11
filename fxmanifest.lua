fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Samuel#0008'
description 'Skills UI for FiveM'
Version '2.0.0'

client_script 'client/*.lua'

server_scripts { '@oxmysql/lib/MySQL.lua', 'bridge/server.lua', 'server/*.lua' }

shared_scripts { 'bridge/init.lua', '@ox_lib/init.lua' }

ui_page 'html/ui.html'

files {
    'levels.lua',
    'html/ui.html',
    'html/style.css',
    'html/app.js',
    'html/bg.png'
}