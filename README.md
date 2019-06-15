# vim-jdtlshelper
Assist in the use of Java language server in Vim
## USAGE
### install/update
Download latest module from https://github.com/eclipse/eclipse.jdt.ls . And install the module.

    call jdtlshelper#install()

### start server
e.g. vim-lsp

```
  if executable('java')
    augroup LspJava
      autocmd!
      autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'eclipse.jdt.ls',
        \ 'cmd': {server_info -> jdtlshelper#get_server_command()},
        \ 'root_uri':{server_info->lsp#utils#path_to_uri(
        \               lsp#utils#find_nearest_parent_file_directory(
        \                 lsp#utils#get_buffer_path(), 'pom.xml'))},
        \ 'whitelist': ['java'],
        \ })
    augroup end
  endif
```
