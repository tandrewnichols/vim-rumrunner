if exists('g:rum_loaded') || &cp | finish | endif

let g:rum_loaded = 1

if !exists('g:rum')
  let g:rum = {}
endif

" Set some defaults
let g:rum = extend(g:rum, {
  \  'resume_timeout': 2000,
  \  'disabled': 0,
  \  'ignore_dirs': 1,
  \  'ignore_help': 1,
  \  'ignore_unlisted': 1,
  \  'ignore_diffs': 1,
  \  'blacklist': [],
  \  'list': []
  \}, 'keep')

function! s:Init()
  let initial = argv()
  for item in initial
    let entry = { 'name': fnamemodify(item, ':p'), 'num': bufnr(item) }
    if index(g:rum.list, entry) == -1
      call add(g:rum.list, entry)
    endif
  endfor
  echo g:rum.list
endfunction

augroup RumRunner
  au!
  au VimEnter * call s:Init()
  au BufEnter,BufNew * call rum#add(expand('<abuf>'), expand('<afile>'))
  au BufWipeout,BufDelete * call rum#remove(expand('<abuf>'), expand('<afile>'))
augroup END

if g:rum.ignore_diffs
  call add(g:rum.blacklist, {name -> &ft == 'diff'})
  call add(g:rum.blacklist, '\(\.diff\|\.patch\)$')
  call add(g:rum.blacklist, '^fugitive')
endif

" Ignore some things
if g:rum.ignore_dirs
  call add(g:rum.blacklist, function('isdirectory'))
endif

if g:rum.ignore_help
  call add(g:rum.blacklist, {name -> &ft == 'help'})
endif

if g:rum.ignore_unlisted
  call add(g:rum.blacklist, {name -> !buflisted(name)})
endif

command! -nargs=0 -count=1 RumPrev :call rum#prev(<count>)
command! -nargs=0 -count=1 RumNext :call rum#next(<count>)

nnoremap <Plug>RumPrev :call rum#prev(v:count ? v:count : 1)<CR>
nnoremap <Plug>RumNext :call rum#next(v:count ? v:count : 1)<CR>

if !hasmapto('<Plug>RumPrev')
  nmap [r <Plug>RumPrev
endif

if !hasmapto('<Plug>RumNext')
  nmap ]r <Plug>RumNext
endif
