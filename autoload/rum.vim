let g:rum.list = []

function! rum#add(num, name)
  let num = a:num
  let name = a:name

  if g:rum.disabled
    return
  endif

  let entry = rum#normalize(num, name)

  if !rum#isIgnored(name)
    let i = index(g:rum.list, entry)
    if i == -1
      call insert(g:rum.list, entry, 0)
    elseif i > 0
      let item = remove(g:rum.list, i)
      call insert(g:rum.list, item, 0)
    endif
  endif
endfunction

function! rum#normalize(num, name)
  return {
    \  'name': fnamemodify(a:name, ':p'),
    \  'num': type(a:num) == 0 ? a:num : str2nr(a:num)
    \}
endfunction

function! rum#remove(num, name)
  let num = a:num
  let name = a:name

  let i = index(g:rum.list, rum#normalize(num, name))
  if i > -1
    call remove(g:rum.list, i)
  endif
endfunction

function! rum#suspend()
  let g:rum.disabled = 1
endfunction

function! rum#resume(...)
  let g:rum.disabled = 0
  if g:rum.list[0].num != bufnr('%')
    call rum#add(bufnr('%'), fnamemodify(bufname('%'), ':.'))
  endif
endfunction

function! rum#get()
  return g:rum.list
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
  if len(g:rum.list) == 1
    return
  endif

  call rum#suspend()
  let current = index(g:rum.list, rum#normalize(bufnr('%'), bufname('%')))
  let index = current + a:count

  if index < 0 || index > len(g:rum.list) - 1
    return
  endif

  let buf = g:rum.list[ index ]
  exec 'b' buf.num

  if exists('s:resume_timeout')
    call timer_stop(s:resume_timeout)
  endif

  let s:resume_timeout = timer_start(g:rum.resume_timeout, function('rum#resume'))
endfunction
