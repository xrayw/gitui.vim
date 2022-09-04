
let s:prev_win = -1
let s:nvim = has('nvim')

command! -bang Gitui call s:open_gitui()

function s:open_gitui()
  let dir = s:git_root_dir()
  if !s:is_git_dir(dir)
    echo "Not a git repository"
    return
  endif

  if s:nvim
    let s:prev_win = nvim_get_current_win()
    call s:open_gitui_floatwin(dir)
  else
    let s:prew_win_view = winsaveview()
    call s:open_gitui_popupwin(dir)
  endif

endfunction

" ============== vim
function s:open_gitui_popupwin(dir)
  let [l,c] = [&lines, &columns]
  let [height, width] = [ceil(l*0.8)+1, ceil(c*0.8)+1]
  let [row, coll] = [ceil(l-height)/2, ceil(c-width)/2]

  let gitui_buf = bufadd('')
  call bufload(gitui_buf)
  setlocal filetype=gitui
  setlocal nocursorcolumn
  " call setbufvar(gitui_buf, '&buflisted', 0)

  let win = popup_create(gitui_buf, {
      \ 'border': [],
      \ 'pos': 'center',
      \ 'close': 'button',
      \ 'drag': 1,
      \ 'resize': 1,
      \ 'minheight': float2nr(height),
      \ 'minwidth': float2nr(width)
      \ })
  " autocmd WinLeave <buffer> silent! call popup_close(win)
  nnoremap <buffer> x :call popup_close(win)<cr>

  let cmd='gitui -d ' . a:dir
  call term_start(cmd, {
      \ 'term_name': 'gitui'
      \ })
   startinsert
endfunction

" =============== neovim
function s:open_gitui_floatwin(dir)
  let [l,c] = [&lines, &columns]
  let [height, width] = [ceil(l*0.8)+1, ceil(c*0.8)+1]
  let [row, coll] = [ceil(l-height)/2, ceil(c-width)/2]

  let config = {
      \ 'style': 'minimal',
      \ 'relative': 'editor',
      \ 'border': 'single',
      \ 'row': row,
      \ 'col': coll,
      \ 'width': float2nr(width),
      \ 'height': float2nr(height),
      \ }

  let gitui_buf = nvim_create_buf(0, 1)
  let window = nvim_open_win(gitui_buf, 1, config)
  setlocal filetype=gitui
  setlocal nocursorcolumn
  autocmd WinLeave <buffer> silent! execute 'hide'
  
  let cmd = 'gitui -d ' . a:dir
  call termopen(cmd, {'on_exit': function('s:on_exit')})
  startinsert
endfunction

function s:on_exit(job_id, code, event)
  if a:code != 0
    return
  endif

  if nvim_win_is_valid(s:prev_win)
    call nvim_set_current_win(s:prev_win)
    s:prev_win=-1
  endif
endfunction


function s:exist_gitui()
  return executable('gitui')
endfunction

function s:git_root_dir() abort
  return system('git rev-parse --show-toplevel')
endfunction

function s:is_git_dir(dir)
  return matchstr(a:dir, '^fatal:.*') == ''
endfunction

call s:open_gitui()
