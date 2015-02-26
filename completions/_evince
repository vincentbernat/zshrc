#compdef evince

local arguments
arguments=(
  '(-p --page-label)'{-p,--page-label=}'[the page label of the document to display]'
  '(-i --page-index)'{-i,--page-index=}'[the page number of the document to display]'
  '(-f --fullscreen)'{-f,--fullscreen}'[run evince in fullscreen mode]'
  '(-s --presentation)'{-s,--presentation}'[run evince in presentation mode]'
  '(-w --preview)'{-w,--preview}'[run evince as a previewer]'
  '(-l --find)'{-l,--find=}'[the word or phrase to find in the document]'
  '--display=[X display to use]'
  '*:PostScript, Djvu or PDF file:_files -g "*.(#i)(pdf|ps|eps|djvu)(-.)"'
)
_arguments -s $arguments
