function! ember_tools#inject#Run(...)
  let saved_view = winsaveview()

  try
    if a:0 > 0
      " The service name has been provided as an argument
      let service_name = a:1
    else
      let saved_iskeyword = &iskeyword
      set iskeyword+=.,-,/
      " The service name is under the cursor
      if !ember_tools#search#UnderCursor('\%(this\.\|@\)get[( ][''"]\zs\k\+[''"]')
        echoerr
              \ "Can't find any service used under the cursor, " .
              \ "consider using :Inject <service-name>"
        let &iskeyword = saved_iskeyword
        return
      endif
      let service_name = expand('<cword>')
      let &iskeyword = saved_iskeyword
    endif

    let service_path = ember_tools#ExistingLogicFile(b:ember_root.'/app/services/'.service_name)
    if service_path == ''
      echoerr "Can't find service: '".service_name."'"
      return
    endif

    if s:FindExtendLine() <= 0
      echoerr
            \ "Couldn't find where to place the injection. ".
            \ "The structure doesn't seem like an Ember class"
      return ''
    endif

    let end_line = s:FindClosingBracket()
    let property_name = ember_tools#util#CamelCase(substitute(service_name, '-', '_', 'g'))

    if s:FindExistingInjection(property_name, end_line)
      echomsg "Ember Tools: Service is already injected: '".property_name."'"
      return
    endif

    " May fail, doesn't matter much
    call s:FindOtherInjections(end_line)

    call append(line('.'), property_name.': Ember.inject.service(),')
    let saved_view.lnum += 1
    let service_line = line('.') + 1
    let end_line += 1

    exe service_line.'normal! =='

    if service_line + 1 < end_line && getline(service_line + 1) =~ '\S'
      call append(service_line, '')
      let saved_view.lnum += 1
    endif

    echomsg "Ember Tools: Injected service: '".property_name."'"
  finally
    call winrestview(saved_view)
  endtry
endfunction

function! s:FindExtendLine()
  let extend_pattern = '\%(\k\|\.\)\+\.extend(\_[^){]*{'

  let short_export_line = search('^export default '.extend_pattern.'\s*}\ze)\s*;\=\s*$', 'ce')
  if short_export_line > 0
    " special case, let's add some space
    exe "normal! i\<cr>\<cr>\<esc>kk$"
    return short_export_line
  endif

  let export_line = search('^export default '.extend_pattern.'$', 'ce')
  if export_line > 0
    return export_line
  endif

  let extend_line_above = search(extend_pattern.'$', 'cWbe')
  if extend_line_above > 0
    return extend_line_above
  endif

  let extend_line_below = search(extend_pattern.'$', 'cWe')
  if extend_line_below > 0
    return extend_line_below
  endif
endfunction

function! s:FindClosingBracket()
  let saved_position = getpos('.')
  normal! %
  let closing_bracket_line = line('.')
  call setpos('.', saved_position)

  return closing_bracket_line
endfunction

function! s:FindOtherInjections(stopline)
  let injection_pattern = '^\s*\k\+:\s*\%(Ember\.\)\=\%(inject\.\)\=\(service\|controller\)('

  call search(injection_pattern, 'cW', a:stopline)
  while search(injection_pattern, 'W', a:stopline) > 0
    " just search(), the cursor will be moved there
  endwhile
endfunction

function! s:FindExistingInjection(property_name, stopline)
  let injection_pattern = '^\s*'.
        \ a:property_name.
        \ ':\s*\%(Ember\.\)\=\%(inject\.\)\=\(service\|controller\)('

  return search(injection_pattern, 'cW', a:stopline)
endfunction
