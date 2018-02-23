if exists('g:rum_loaded') || &cp | finish | endif

let g:rum_loaded = 1

if !exists('g:rum')
  let g:rum = {}
endif

let g:rum = extend(g:rum, {
      \  'timeout': 1000,
      \  'disabled': 0,
      \  'ignore_dirs': 1,
      \  'blacklist': []
      \}
      \, 'keep')

augroup RumRunner
  au!
  au BufEnter,BufNew * call rum#add(expand('<abuf>'), expand('<afile>'))
  au BufWipeout,BufDelete * call rum#remove(expand('<abuf>'), expand('<afile>'))
augroup END

if g:rum.ignore_dirs
  call add(g:rum.blacklist, function('isdirectory'))
endif
