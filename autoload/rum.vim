let s:rumList = []

function! rum#add(num, name)
  let num = a:num
  let name = a:name

  if g:rum.disabled
    return
  endif

  if type(num) == 1
    let num = str2nr(num)
  endif

  if !rum#isIgnored(name)
    let i = index(s:rumList, { 'name': name, 'num': num })
    if i > -1
      let item = remove(s:rumList, i)
      call insert(s:rumList, item, 0)
    else
      call insert(s:rumList, { 'name': name, 'num': num }, 0)
    endif
  endif
endfunction

function! rum#remove(num, name)
  let num = a:num
  let name = a:name

  if type(num) == 1
    let num = str2nr(num)
  endif

  let i = index(s:rumList, { 'name': name, 'num': num })
  if i > -1
    call remove(s:rumList, i)
  endif
endfunction

function! rum#suspend()
  let g:rum.disabled = 1
endfunction

function! rum#resume(...)
  let g:rum.disabled = 0
  if s:rumList[0].num != bufnr('%')
    call rum#add(bufnr('%'), fnamemodify(bufname('%'), ':.'))
  endif
endfunction

function! rum#get()
  return s:rumList
endfunction

function! rum#ignore(pattern)
  call add(g:rum.blacklist, a:pattern)
endfunction

function! rum#isIgnored(file)
  for Pattern in g:rum.blacklist
    if type(Pattern) == 1 && match(a:file, Pattern) > -1
      return 1
    elseif type(Pattern) == 2 && Pattern(a:file)
      return 1
    endif
  endfor

  return 0
endfunction

function! rum#prev(count)
  call rum#move(a:count)
endfunction

function! rum#next(count)
  call rum#move(a:count * -1)
endfunction

function! rum#move(count)
  call rum#suspend()
  let current = index(s:rumList, { 'num': bufnr('%'), 'name': fnamemodify(bufname('%'), ":.") })
  let index = current + a:count
  if index < 0
    let index = 0
  endif

  let buf = s:rumList[ current + a:count ]
  exec 'b' buf.num

  if exists('s:resume_timeout')
    call timer_stop(s:resume_timeout)
  endif

  let s:resume_timeout = timer_start(g:rum.resume_timeout, function('rum#resume'))
endfunction
