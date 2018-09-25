if has('syntax')
  syn match rumNumber     "^[0-9]\+"
  syn match rumFileName   "\f\+$"

  hi def link rumNumber   Number
  hi def link rumFileName String
endif
