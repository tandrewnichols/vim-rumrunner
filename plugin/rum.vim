if exists('g:loaded_rum') || &cp | finish | endif

let g:loaded_rum = 1

function! s:Set(option, default) abort
  exec "let g:rumrunner_" . a:option "= get(g:, 'rebuff_" . a:option . "', a:default)"
endfunction

" Set some defaults
for [option, default] in items({
  \  'resume_timeout': 2000,
  \  'disabled': 0,
  \  'ignore_dirs': 1,
  \  'ignore_help': 1,
  \  'ignore_unlisted': 1,
  \  'ignore_diffs': 1,
  \  'log': 1,
  \  'blacklist': [],
  \  'list': []
  \})
  call s:Set(option, default)
endfor

let g:rumrunner_VERSION = '1.0.1'

function! s:Init()
  for item in argv()
    let entry = bufnr(item)
    if index(g:rumrunner_list, entry) == -1
      call add(g:rumrunner_list, entry)
    endif
  endfor
endfunction

augroup RumRunner
  au!
  au VimEnter * call s:Init()
  au BufEnter,BufNew * call rum#add(expand('<abuf>'))
  au BufWipeout,BufDelete * call rum#remove(expand('<abuf>'))
augroup END

" Ignore some things
if g:rumrunner_ignore_diffs
  call add(g:rumrunner_blacklist, {name -> &ft == 'diff'})
  call add(g:rumrunner_blacklist, '\(\.diff\|\.patch\)$')
  call add(g:rumrunner_blacklist, '^fugitive')
endif

if g:rumrunner_ignore_dirs
  call add(g:rumrunner_blacklist, function('isdirectory'))
endif

if g:rumrunner_ignore_help
  call add(g:rumrunner_blacklist, {name -> &ft == 'help'})
endif

if g:rumrunner_ignore_unlisted
  call add(g:rumrunner_blacklist, {name -> !buflisted(name)})
endif

command! -nargs=0 -count=1 RumPrev :call rum#prev(<count>)
command! -nargs=0 -count=1 RumNext :call rum#next(<count>)
command! -nargs=0 RumSuspend :call rum#suspend()
command! -nargs=0 RumResume :call rum#resume()

nnoremap <Plug>RumPrev :call rum#prev(v:count ? v:count : 1)<CR>
nnoremap <Plug>RumNext :call rum#next(v:count ? v:count : 1)<CR>
nnoremap <Plug>RumSuspend :call rum#suspend()<CR>
nnoremap <Plug>RumResume :call rum#resume()<CR>

if !hasmapto('<Plug>RumPrev')
  nmap [r <Plug>RumPrev
endif

if !hasmapto('<Plug>RumNext')
  nmap ]r <Plug>RumNext
endif

if !hasmapto('<Plug>RumSuspend')
  nmap [R <Plug>RumSuspend
endif

if !hasmapto('<Plug>RumResume')
  nmap ]R <Plug>RumResume
endif
