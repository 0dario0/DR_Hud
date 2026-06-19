fx_version "adamant"

game "gta5"

name 'DR_hud'
author 'DR_Studio'
description 'Modern Hud'

client_script { 
"main/client.lua"
}

server_script {
"main/server.lua",
} 

shared_script "main/shared.lua"


ui_page "index.html"

files {
    'index.html',
    'vue.js',
    'assets/**/*.*',
    'assets/font/*.otf',  
}

escrow_ignore { 'main/shared.lua' }

lua54 'yes'
-- dependency '/assetpacks'