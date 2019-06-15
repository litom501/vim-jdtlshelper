" Assist in the use of Java language server in Vim
" Version: 0.1.0
" Auther : litom <litom501+vim@gmail.com>
" License: MIT License

" Java Launguage Server
" https://github.com/eclipse/eclipse.jdt.ls

let s:save_cpo = &cpo
set cpo&vim

" install base directory
let s:cache_home = empty($XDG_CACHE_HOME) ? '~/.cache' : $XDG_CACHE_HOME
let s:default_install_dir_name = 'tools'
let s:default_install_dir = s:cache_home . '/' . s:default_install_dir_name
let s:install_path = expand(get(g:, 'jdtlshelper#install_dir', s:default_install_dir))

" server directory
let s:jdt_ls_dir_name = 'eclipse.jdt.ls'

" server data directory
let s:default_data_dir_name = 'eclipse.jdt.ls-data'
let s:jdt_ls_data_dir = expand(get(g:, 'jdtlshelper#data_dir', s:install_path . '/' . s:default_data_dir_name . '/'))
let s:clean_data_dir = get(g:, 'jdtlshelper#clean_data_dir', v:false)
let s:custom_properties = get(g:, 'jdtlshelper#custom_properties', [])

" support Java 10 after 0.23
" latest
" http://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz
let s:jdt_ls_download_url = get(g:,'jdtlshelper#download_url', 'http://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz')

let s:jdt_ls_download_file = 'jdt-language-server.tar.gz'

function! s:get_download_filepath() abort
  return s:install_path . '/' . s:jdt_ls_download_file
endfunction

function! s:get_plugins_filepath() abort
  return s:install_path . '/' . s:jdt_ls_dir_name . '/plugins'
endfunction

"e.g. org.eclipse.equinox.launcher_1.5.100.v20180611-1436.jar
function! s:get_launcher_jar_filename() abort
  return fnamemodify(globpath(s:get_plugins_filepath(), 'org.eclipse.equinox.launcher_*.jar'), ':t')
endfunction

function! jdtlshelper#install() abort
  let download_filepath = s:get_download_filepath()
  let l:deploy_path = s:install_path . '/' . s:jdt_ls_dir_name

  " check old downloading file
  let downloading_filepath = l:download_filepath . '_tmp'
  if filereadable(l:downloading_filepath)
    call delete(l:downloading_filepath)
  endif

  " try to download update
  if filereadable(l:download_filepath)
    echo '[jdtlshelper] Checking for updates of eclipse.jdt.ls'
    execute 'silent! !echo [jdtlshelper] Checking for updates of eclipse.jdt.ls'
    execute 'silent! !curl -f -L -z ' . l:download_filepath . ' -o ' . l:downloading_filepath . ' ' . s:jdt_ls_download_url
    if v:shell_error
      echoerr '[jdtlshelper] error occurred during check new jdt language server.'
      return v:false
    endif

    if !filereadable(l:downloading_filepath)
      redraw!
      echomsg '[jdtlshelper]  no update'
      if !isdirectory(l:deploy_path)
        echo '[jdtlshelper] reinstalling...'
        return s:install_module(download_filepath, l:deploy_path)
      endif
      return v:true
    endif

  " new download
  else
    echo '[jdtlshelper] Downloading jdt language server'
    if !isdirectory(s:install_path)
      call mkdir(s:install_path, 'p')
      redraw!
      echomsg '[jdtlshelper] Create directory ''' . s:install_path . ''''
    endif
    execute 'silent! !echo [jdtlshelper] Downloading jdt language server'
    execute 'silent! !curl -f -L -o ' . l:downloading_filepath . ' ' . s:jdt_ls_download_url
    if v:shell_error
      echoerr '[jdtlshelper] error occurred during download jdt langage server.'
      return 0
    endif
  endif

  " delete old download
  let old_filepath = l:download_filepath . '_old'
  if filereadable(l:old_filepath)
    call delete(l:old_filepath)
  endif

  " backup current download
  if filereadable(l:download_filepath)
    call rename(l:download_filepath, l:old_filepath)
  endif

  " rename new download
  if filereadable(l:downloading_filepath)
    call rename(l:downloading_filepath, l:download_filepath)
  endif

  " deploy
  return s:install_module(download_filepath, l:deploy_path)
endfunction

function! s:install_module(module_filepath, deploy_path) abort
  " backup current deployment
  if isdirectory(a:deploy_path)
    call rename(a:deploy_path, a:deploy_path . '_old')
  endif

  " create deploy directory
  call mkdir(a:deploy_path, 'p')

  echo '[jdtlshelper] Extracting jdt language server.'
  execute 'silent! !echo [jdtlshelper] Extracting jdt language server.'
  execute 'silent! !tar xf ' . a:module_filepath . ' -C ' . a:deploy_path
  if v:shell_error
    echoerr '[jdtlshelper] error occurred during extract a install file.'
    return v:false
  endif
  echo '[jdtlshelper] extracted jdt language server.'

  if isdirectory(a:deploy_path . '_old')
    call delete(a:deploy_path . '_old', 'rf')
  endif

  redraw!
  echomsg '[jdtlshelper] Installed jdt language server.'
  return v:true
endfunction

function! jdtlshelper#get_server_command() abort
  echo 'jdtlshelper : ' . expand('%:p')
  echo 'jdtlshelper : ' . &fileformat
  echo 'jdtlshelper : ' . &fileencoding

  if has('win64')
    let l:jdt_ls_config_dir_name = 'config_win'
  elseif has('unix')
    let l:jdt_ls_config_dir_name = 'config_linux'
  elseif has('mac')
    let l:jdt_ls_config_dir_name = 'config_mac'
  endif

  if s:clean_data_dir && isdirectory(s:jdt_ls_data_dir)
    let l:result=delete(s:jdt_ls_data_dir, 'rf')
    if l:result == -1
      echo '[jdtlshelper] couldn''t delete the data directory ''' . s:jdt_ls_data_dir . ''''
    endif
  endif

  " data directory of jdt language server
  if !isdirectory(s:jdt_ls_data_dir)
    call mkdir(s:jdt_ls_data_dir, 'p')
    echo '[jdtlshelper] Create a data directory ''' . s:jdt_ls_data_dir . ''''
  endif

" Before JDK9
"java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044
"-Declipse.application=org.eclipse.jdt.ls.core.id1
"-Dosgi.bundles.defaultStartLevel=4
"-Declipse.product=org.eclipse.jdt.ls.core.product -Dlog.level=ALL -noverify
"-Xmx1G -jar ./plugins/org.eclipse.equinox.launcher_1.5.200.v20180922-1751.jar
"-configuration ./config_linux -data /path/to/data
"
" JDK 9
"java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044
"-Declipse.application=org.eclipse.jdt.ls.core.id1
"-Dosgi.bundles.defaultStartLevel=4
"-Declipse.product=org.eclipse.jdt.ls.core.product -Dlog.level=ALL -noverify
"-Xmx1G -jar ./plugins/org.eclipse.equinox.launcher_1.5.200.v20180922-1751.jar
"-configuration ./config_linux -data /path/to/data 
"--add-modules=ALL-SYSTEM
"--add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED

  " \ '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044',
  let commands = [
        \ 'java',
        \ '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        \ '-Dosgi.bundles.defaultStartLevel=4',
        \ '-Declipse.product=org.eclipse.jdt.ls.core.product',
        \ '-Dlog.level=ALL',
        \ '-noverify',
        \ '-Xmx1G']
  let options_module_system = [
        \ '--add-modules',
        \ 'ALL-SYSTEM',
        \ '--add-opens',
        \ 'java.base/java.util=ALL-UNNAMED',
        \ '--add-opens',
        \ 'java.base/java.lang=ALL-UNNAMED']
  let options_environment = [
        \ '-jar',
        \ expand(s:install_path) . '/' . s:jdt_ls_dir_name . '/plugins/' . s:get_launcher_jar_filename(),
        \ '-configuration',
        \ expand(s:install_path) . '/' . s:jdt_ls_dir_name . '/' . l:jdt_ls_config_dir_name,
        \ '-data',
        \ s:jdt_ls_data_dir]

  let commands = extend(commands, s:custom_properties)
  if s:is_module_system_used()
    let commands = extend(commands, options_module_system)
  endif
  let commands = extend(commands, options_environment)
  return commands
endfunction

function! s:is_module_system_used() abort
  let version_str = systemlist('java -version')
  if v:shell_error
    echoerr '[jdtlshelper] Couldn't get java version'
  endif

  if s:is_java_version('1.8', l:version_str[0])
    return v:false
  elseif s:is_java_version('1.7', l:version_str[0])
    return v:false
  elseif s:is_java_version('1.6', l:version_str[0])
    return v:false
  else
    return v:true
  end
endfunction

function! s:is_java_version(target, version_str)
  return matchstrpos(a:version_str, 'version "'. a:target)[1] != -1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
