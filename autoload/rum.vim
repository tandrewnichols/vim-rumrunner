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

function! rum#resume()
  let g:rum.disabled = 0
  if s:rumList[0].num != bufnr('%')
    call rum#add(bufnr('%'), bufname('%'))
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
