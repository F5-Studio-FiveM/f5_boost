fx_version 'cerulean'
game 'gta5'

author 'F5 Studio - https://f5stud.io'
description 'Advanced FPS Optimization Tool'
version '1.0.0'

lua54 'yes'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'locales/*.lua',
    'shared/locale.lua',
}

server_scripts {
    'server/version_check.lua',
    'server/db.lua',
    'server/profiles.lua',
}

client_scripts {
    'client/main.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/logo.png',
}
