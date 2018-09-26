hi RumSuspended cterm=bold ctermfg=red
hi RumRunning cterm=bold ctermfg=green

function! rum#add(num) abort
  let num = a:num

  if g:rumrunner_disabled
    return
  endif

  let entry = rum#normalize(num)

  if !rum#isIgnored(entry)
    let i = index(g:rumrunner_list, entry)
    if i == -1
      call insert(g:rumrunner_list, entry, 0)
    elseif i > 0
      let item = remove(g:rumrunner_list, i)
      call insert(g:rumrunner_list, item, 0)
    endif
  endif
endfunction

function! rum#remove(num) abort
  let num = a:num

  let i = index(g:rumrunner_list, rum#normalize(num))
  if i > -1
    call remove(g:rumrunner_list, i)
  endif
endfunction

function! rum#normalize(num) abort
  return type(a:num) == 0 ? a:num : str2nr(a:num)
endfunction

function! rum#suspend() abort
  " If suspend is explicitly called while the
  " suspension timer is running, cancel the timer
  " and switch to manual resume.
  call rum#checkTimer()

  if !g:rumrunner_disabled
    let g:rumrunner_disabled = 1
    call rum#startTimer()
  endif
endfunction

function! rum#resume(...) abort
  " If resume is explicitly called while the
  " suspension timer is running, cancel the timer.
  call rum#checkTimer()

  let g:rumrunner_disabled = 0
  if !len(g:rumrunner_list) || g:rumrunner_list[0] != bufnr('%')
    call rum#add(bufnr('%'))
  endif

  call rum#startTimer()
endfunction

function! rum#startTimer() abort
  if g:rumrunner_log
    let s:log_timeout = timer_start(100, 'rum#log')
  endif
endfunction

function! rum#log(...) abort
  let type = g:rumrunner_disabled ? 'RumSuspended' : 'RumRunning'
  let msg = g:rumrunner_disabled ? 'Rumrunner suspended' : 'Rumrunner active'
  exec 'echohl' type
  echo msg
  echohl None
endfunction

function! rum#get() abort
  return g:rumrunner_list
endfunction

function! rum#ignore(pattern) abort
  call add(g:rumrunner_ignorelist, a:pattern)
endfunction

function! rum#isIgnored(num) abort
  let file = bufname(a:num)
  for Pattern in g:rumrunner_ignorelist
    if type(Pattern) == 1 && match(file, Pattern) > -1
      return 1
    elseif type(Pattern) == 2 && Pattern(file)
      return 1
    endif
  endfor

  return 0
endfunction

function! rum#prev(count) abort
  call rum#move(a:count)
endfunction

function! rum#next(count) abort
  call rum#move(a:count * -1)
endfunction

function! rum#move(count) abort
  if len(g:rumrunner_list) == 1
    if bufnr('%') != g:rumrunner_list[0]
      exec 'b' g:rumrunner_list[0]
    endif
    return
  endif

  if !g:rumrunner_disabled
    call rum#suspend()
  endif

  let current = index(g:rumrunner_list, rum#normalize(bufnr('%')))
  let index = current + a:count

  if index < 0 || index > len(g:rumrunner_list) - 1
    return
  endif

  let buf = g:rumrunner_list[ index ]
  exec 'b' buf

  call rum#checkTimer()

  let s:resume_timeout = timer_start(g:rumrunner_resume_timeout, function('rum#resume'))
endfunction

function! rum#checkTimer() abort
  if exists('s:resume_timeout')
    call timer_stop(s:resume_timeout)
    unlet s:resume_timeout
  endif

  if exists('s:log_timeout')
    call timer_stop(s:log_timeout)
    unlet s:log_timeout
  endif
endfunction

function! rum#list(bang) abort
  let cmd = a:bang ? 'sp' : 'vsp'
  
  let entries = []

  for bufnum in rum#get()
    if len(bufnum) < 6
      let num = bufnum . repeat(' ', 6 - len(bufnum))
    else
      let num = bufnum
    endif
    call add(entries, num . bufname(bufnum))
  endfor

  exec "keepjumps hide" cmd "[Rumrunner]"
  setlocal modifiable
  normal! gg"_dG
  call setline(1, entries)
  call rum#configure()
endfunction

function! rum#configure() abort
  setlocal nonumber
  setlocal foldcolumn=0
  setlocal nofoldenable
  setlocal nospell
  setlocal nobuflisted
  setlocal filetype=rum
  setlocal buftype=nofile
  setlocal nomodifiable
  setlocal noswapfile
  setlocal nowrap

  augroup RumList
    au!
    au BufLeave \[Rumrunner\] bw | call rum#resume()
  augroup END

  call rum#map(g:rumrunner_close_mapping, ":q")
  call rum#map(g:rumrunner_select_mapping, ":call rum#activate()")
  call rum#map(g:rumrunner_move_down_mapping, ":call rum#reorder(1)")
  call rum#map(g:rumrunner_move_up_mapping, ":call rum#reorder(-1)")
  call rum#map(g:rumrunner_remove_mapping, ":call rum#reorder(0)")
  
  call rum#suspend()
endfunction

function! rum#map(lhs, rhs) abort
  exec "nnoremap <buffer> <nowait> <silent>" lhs rhs . "\<CR>"
endfunction

function! rum#activate() abort
  let num = rum#getNumFromLine()
  q
  exec "b" num
endfunction

function! rum#getNumFromLine() abort
  let line = getline('.')
  return matchstr(line, '^\d\+')
endfunction

function! rum#reorder(dir) abort
  if a:dir < 0
    " If we're already on the frist line, we can't move it up.
    " Just return early.
    if line('.') == 1
      return
    endif

    " If we're on the last line, the behavior is slightly different.
    if line('.') == line('$')
      let cmd = '"rddP'
    else
      let cmd = '"rddkP'
    endif
  elseif a:dir > 0
    if line('.') == line('$')
      return
    else
      let cmd = '"rddp'
    endif
  else
    let cmd = '"_dd'
  endif

  let num = rum#getNumFromLine()
  let index = index(g:rumrunner_list, str2nr(num))
  let item = remove(g:rumrunner_list, index)

  if a:dir != 0
    let newIndex = a:dir < 0 ? index - 1 : index + 1
    call insert(g:rumrunner_list, item, newIndex)
  endif

  setlocal modifiable
  exec "normal!" cmd
  setlocal nomodifiable
endfunction
