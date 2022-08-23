" Insert or delete brackets, parens, quotes in pairs.
" Maintainer:	JiangMiao <jiangfriend@gmail.com>
" Contributor: camthompson
" Last Change:  2019-02-02
" Version: 2.0.0
" Homepage: http://www.vim.org/scripts/script.php?script_id=3599
" Repository: https://github.com/jiangmiao/auto-pairs
" License: MIT

import autoload 'pairs/utils.vim'

if exists('g:AutoPairsLoaded') || &cp
  finish
end
let g:AutoPairsLoaded = 1

if !exists('g:AutoPairs')
  let g:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"', '```':'```', '"""':'"""', "'''":"'''", "`":"`"}
end

" default pairs base on filetype
func! AutoPairsDefaultPairs()
  if exists('b:autopairs_defaultpairs')
    return b:autopairs_defaultpairs
  end
  let r = copy(g:AutoPairs)
  let allPairs = {
        \ 'vim': {'\v^\s*\zs"': ''},
        \ 'rust': {'\w\zs<': '>', '&\zs''': ''},
        \ 'php': {'<?': '?>//k]', '<?php': '?>//k]'}
        \ }
  for [filetype, pairs] in items(allPairs)
    if &filetype == filetype
      for [open, close] in items(pairs)
        let r[open] = close
      endfor
    end
  endfor
  let b:autopairs_defaultpairs = r
  return r
endf

if !exists('g:AutoPairsMapBS')
  let g:AutoPairsMapBS = 1
end

" Map <C-h> as the same BS
if !exists('g:AutoPairsMapCh')
  let g:AutoPairsMapCh = 1
end

if !exists('g:AutoPairsMapCR')
  let g:AutoPairsMapCR = 1
end

if !exists('g:AutoPairsWildClosedPair')
  let g:AutoPairsWildClosedPair = ''
end

if !exists('g:AutoPairsMapSpace')
  let g:AutoPairsMapSpace = 1
end

if !exists('g:AutoPairsCenterLine')
  let g:AutoPairsCenterLine = 1
end

if !exists('g:AutoPairsShortcutToggle')
  let g:AutoPairsShortcutToggle = '<M-p>'
end

if !exists('g:AutoPairsShortcutFastWrap')
  let g:AutoPairsShortcutFastWrap = '<M-e>'
end

if !exists('g:AutoPairsMoveCharacter')
  let g:AutoPairsMoveCharacter = "()[]{}\"'"
end

if !exists('g:AutoPairsShortcutJump')
  let g:AutoPairsShortcutJump = '<M-n>'
endif

" Fly mode will for closed pair to jump to closed pair instead of insert.
" also support AutoPairsBackInsert to insert pairs where jumped.
if !exists('g:AutoPairsFlyMode')
  let g:AutoPairsFlyMode = 0
endif

" When skipping the closed pair, look at the current and
" next line as well.
if !exists('g:AutoPairsMultilineClose')
  let g:AutoPairsMultilineClose = 1
endif

" Work with Fly Mode, insert pair where jumped
if !exists('g:AutoPairsShortcutBackInsert')
  let g:AutoPairsShortcutBackInsert = '<M-b>'
endif

if !exists('g:AutoPairsSmartQuotes')
  let g:AutoPairsSmartQuotes = 1
endif

" split text to two part
" returns [orig, text_before_open, open]
func! s:matchend(text, open)
    let m = matchstr(a:text, '\V'.a:open.'\v$')
    if m == ""
      return []
    end
    return [a:text, strpart(a:text, 0, len(a:text)-len(m)), m]
endf

" add or delete pairs base on g:AutoPairs
" AutoPairsDefine(addPairs:dict[, removeOpenPairList:list])
"
" eg:
"   au FileType html let b:AutoPairs = AutoPairsDefine({'<!--' : '-->'}, ['{'])
"   add <!-- --> pair and remove '{' for html file
func! AutoPairsDefine(pairs, ...)
  let r = AutoPairsDefaultPairs()
  if a:0 > 0
    for open in a:1
      unlet r[open]
    endfor
  end
  for [open, close] in items(a:pairs)
    let r[open] = close
  endfor
  return r
endf

func! AutoPairsInsert(key)
  if !b:autopairs_enabled
    return a:key
  end

  let b:autopairs_saved_pair = [a:key, getpos('.')]

  let [before, after, afterline] = pairs#utils#GetLineContext()

  " Ignore auto close if prev character is \
  if before[-1:-1] == '\'
    return a:key
  end

  " check open pairs
  for [open, close, opt] in b:AutoPairsList
    let ms = s:matchend(before.a:key, open)
    let m = matchstr(afterline, '^\v\s*\zs\V'.close)
    if len(ms) > 0
      " process the open pair
      
      " remove inserted pair
      " eg: if the pairs include < > and  <!-- --> 
      " when <!-- is detected the inserted pair < > should be clean up 
      let target = ms[1]
      let openPair = ms[2]
      if len(openPair) == 1 && m == openPair
        break
      end
      let bs = ''
      let del = ''
      while len(before) > len(target)
        let found = 0
        " delete pair
        for [o, c, opt] in b:AutoPairsList
          let os = s:matchend(before, o)
          if len(os) && len(os[1]) < len(target)
            " any text before openPair should not be deleted
            continue
          end
          let cs = pairs#utils#MatchBegin(afterline, c)
          if len(os) && len(cs)
            let found = 1
            let before = os[1]
            let afterline = cs[2]
            let bs = bs.pairs#utils#Backspace(os[2])
            let del = del.pairs#utils#Delete(cs[1])
            break
          end
        endfor
        if !found
          " delete charactor
          let ms = s:matchend(before, '\v.')
          if len(ms)
            let before = ms[1]
            let bs = bs.pairs#utils#Backspace(ms[2])
          end
        end
      endwhile
      return bs.del.openPair.close.pairs#utils#Left(close)
    end
  endfor

  " check close pairs
  for [open, close, opt] in b:AutoPairsList
    if close == ''
      continue
    end
    if a:key == g:AutoPairsWildClosedPair || opt['mapclose'] && opt['key'] == a:key
      " the close pair is in the same line
      let m = matchstr(afterline, '^\v\s*\V'.close)
      if m != ''
        if before =~ '\V'.open.'\v\s*$' && m[0] =~ '\v\s'
          " remove the space we inserted if the text in pairs is blank
          return "\<DEL>".pairs#utils#Right(m[1:])
        else
          return pairs#utils#Right(m)
        end
      end
      let m = matchstr(after, '^\v\s*\zs\V'.close)
      if m != ''
        if a:key == g:AutoPairsWildClosedPair || opt['multiline']
          if b:autopairs_return_pos == line('.') && getline('.') =~ '\v^\s*$'
            normal! ddk$
          end
          call search(m, 'We')
          return "\<Right>"
        else
          break
        end
      end
    end
  endfor


  " Fly Mode, and the key is closed-pairs, search closed-pair and jump
  if g:AutoPairsFlyMode &&  a:key =~ '\v[\}\]\)]'
    if search(a:key, 'We')
      return "\<Right>"
    endif
  endif

  return a:key
endf

func! AutoPairsDelete()
  if !b:autopairs_enabled
    return "\<BS>"
  end

  let [before, after, ig] = pairs#utils#GetLineContext()
  for [open, close, opt] in b:AutoPairsList
    let b = matchstr(before, '\V'.open.'\v\s?$')
    let a = matchstr(after, '^\v\s*\V'.close)
    if b != '' && a != ''
      if b[-1:-1] == ' '
        if a[0] == ' '
          return "\<BS>\<DELETE>"
        else
          return "\<BS>"
        end
      end
      return pairs#utils#Backspace(b).pairs#utils#Delete(a)
    end
  endfor

  return "\<BS>"
  " delete the pair foo[]| <BS> to foo
  for [open, close, opt] in b:AutoPairsList
    let m = s:matchend(before, '\V'.open.'\v\s*'.'\V'.close.'\v$')
    if len(m) > 0
      return pairs#utils#Backspace(m[2])
    end
  endfor
  return "\<BS>"
endf


" Fast wrap the word in brackets
func! AutoPairsFastWrap()
  let c = @"
  normal! x
  let [before, after, ig] = pairs#utils#GetLineContext()
  if after[0] =~ '\v[\{\[\(\<]'
    normal! %
    normal! p
  else
    for [open, close, opt] in b:AutoPairsList
      if close == ''
        continue
      end
      if after =~ '^\s*\V'.open
        call search(close, 'We')
        normal! p
        let @" = c
        return ""
      end
    endfor
    if after[1:1] =~ '\v\w'
      normal! e
      normal! p
    else
      normal! p
    end
  end
  let @" = c
  return ""
endf

func! AutoPairsJump()
  call search('["\]'')}]','W')
endf

func! AutoPairsMoveCharacter(key)
  let c = getline(".")[col(".")-1]
  let escaped_key = substitute(a:key, "'", "''", 'g')
  return "\<DEL>\<ESC>:call search("."'".escaped_key."'".")\<CR>a".c."\<LEFT>"
endf

func! AutoPairsBackInsert()
  let pair = b:autopairs_saved_pair[0]
  let pos  = b:autopairs_saved_pair[1]
  call setpos('.', pos)
  return pair
endf

func! AutoPairsSpace()
  if !b:autopairs_enabled
    return "\<SPACE>"
  end

  let [before, after, ig] = pairs#utils#GetLineContext()

  for [open, close, opt] in b:AutoPairsList
    if close == ''
      continue
    end
    if before =~ '\V'.open.'\v$' && after =~ '^\V'.close
      if close =~ '\v^[''"`]$'
        return "\<SPACE>"
      else
        return "\<SPACE>\<SPACE>\<C-G>U\<LEFT>"
      end
    end
  endfor
  return "\<SPACE>"
endf

func! AutoPairsMap(key)
  " | is special key which separate map command from text
  let key = a:key
  if key == '|'
    let key = '<BAR>'
  end
  let escaped_key = substitute(key, "'", "''", 'g')
  " use expr will cause search() doesn't work
  execute 'inoremap <buffer> <silent> '.key." <C-R>=AutoPairsInsert('".escaped_key."')<CR>"
endf

func! AutoPairsToggle()
  if b:autopairs_enabled
    let b:autopairs_enabled = 0
    echo 'AutoPairs Disabled.'
  else
    let b:autopairs_enabled = 1
    echo 'AutoPairs Enabled.'
  end
  return ''
endf

func! s:sortByLength(i1, i2)
  return len(a:i2[0])-len(a:i1[0])
endf

func! AutoPairsInit()
  if exists('b:autopairs_loaded')
    return
  endif
  let b:autopairs_loaded  = 1
  if !exists('b:autopairs_enabled')
    let b:autopairs_enabled = 1
  end

  if !exists('b:AutoPairs')
    let b:AutoPairs = AutoPairsDefaultPairs()
  end

  if !exists('b:AutoPairsMoveCharacter')
    let b:AutoPairsMoveCharacter = g:AutoPairsMoveCharacter
  end

  let b:autopairs_return_pos = 0
  let b:autopairs_saved_pair = [0, 0]
  let b:AutoPairsList = []

  " buffer level map pairs keys
  " n - do not map the first charactor of closed pair to close key
  " m - close key jumps through multi line
  " s - close key jumps only in the same line
  for [open, close] in items(b:AutoPairs)
    let o = open[-1:-1]
    let c = close[0]
    let opt = {'mapclose': 1, 'multiline':1}
    let opt['key'] = c
    if o == c
      let opt['multiline'] = 0
    end
    let m = matchlist(close, '\v(.*)//(.*)$')
    if len(m) > 0 
      if m[2] =~ 'n'
        let opt['mapclose'] = 0
      end
      if m[2] =~ 'm'
        let opt['multiline'] = 1
      end
      if m[2] =~ 's'
        let opt['multiline'] = 0
      end
      let ks = matchlist(m[2], '\vk(.)')
      if len(ks) > 0
        let opt['key'] = ks[1]
        let c = opt['key']
      end
      let close = m[1]
    end
    call AutoPairsMap(o)
    if o != c && c != '' && opt['mapclose']
      call AutoPairsMap(c)
    end
    let b:AutoPairsList += [[open, close, opt]]
  endfor

  " sort pairs by length, longer pair should have higher priority
  let b:AutoPairsList = sort(b:AutoPairsList, "s:sortByLength")

  for item in b:AutoPairsList
    let [open, close, opt] = item
    if open == "'" && open == close
      let item[0] = '\v(^|\W)\zs'''
    end
  endfor


  for key in split(b:AutoPairsMoveCharacter, '\s*')
    let escaped_key = substitute(key, "'", "''", 'g')
    execute 'inoremap <silent> <buffer> <M-'.key."> <C-R>=AutoPairsMoveCharacter('".escaped_key."')<CR>"
  endfor

  " Still use <buffer> level mapping for <BS> <SPACE>
  if g:AutoPairsMapBS
    " Use <C-R> instead of <expr> for issue #14 sometimes press BS output strange words
    execute 'inoremap <buffer> <silent> <BS> <C-R>=AutoPairsDelete()<CR>'
  end

  if g:AutoPairsMapCh
    execute 'inoremap <buffer> <silent> <C-h> <C-R>=AutoPairsDelete()<CR>'
  endif

  if g:AutoPairsMapSpace
    " Try to respect abbreviations on a <SPACE>
    let do_abbrev = "<C-]>"
    execute 'inoremap <buffer> <silent> <SPACE> '.do_abbrev.'<C-R>=AutoPairsSpace()<CR>'
  end

  if g:AutoPairsShortcutFastWrap != ''
    execute 'inoremap <buffer> <silent> '.g:AutoPairsShortcutFastWrap.' <C-R>=AutoPairsFastWrap()<CR>'
  end

  if g:AutoPairsShortcutBackInsert != ''
    execute 'inoremap <buffer> <silent> '.g:AutoPairsShortcutBackInsert.' <C-R>=AutoPairsBackInsert()<CR>'
  end

  if g:AutoPairsShortcutToggle != ''
    " use <expr> to ensure showing the status when toggle
    execute 'inoremap <buffer> <silent> <expr> '.g:AutoPairsShortcutToggle.' AutoPairsToggle()'
    execute 'noremap <buffer> <silent> '.g:AutoPairsShortcutToggle.' :call AutoPairsToggle()<CR>'
  end

  if g:AutoPairsShortcutJump != ''
    execute 'inoremap <buffer> <silent> ' . g:AutoPairsShortcutJump. ' <ESC>:call AutoPairsJump()<CR>a'
    execute 'noremap <buffer> <silent> ' . g:AutoPairsShortcutJump. ' :call AutoPairsJump()<CR>'
  end

  if &keymap != ''
    let l:imsearch = &imsearch
    let l:iminsert = &iminsert
    let l:imdisable = &imdisable
    execute 'setlocal keymap=' . &keymap
    execute 'setlocal imsearch=' . l:imsearch
    execute 'setlocal iminsert=' . l:iminsert
    if l:imdisable
      execute 'setlocal imdisable'
    else
      execute 'setlocal noimdisable'
    endif
  endif

endf

au BufEnter * :call AutoPairsInit()
