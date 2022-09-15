vim9script

export def AutoPairsDefaultPairs(): dict<string>
  if exists('b:auto_pairs_default_pairs')
    return b:auto_pairs_default_pairs
  endif

  final r = copy(g:AutoPairs)
  const all_pairs = {
    'vim': {'\v^\s*\zs"': ''},
    'rust': {'\w\zs<': '>', '&\zs''': ''},
    'php': {'<?': '?>//k]', '<?php': '?>//k]'}
  }

  for [filetype, pairs] in items(all_pairs)
    if &filetype == filetype
      for [open, close] in items(pairs)
        r[open] = close
      endfor
    endif
  endfor
  b:auto_pairs_default_pairs = r
  return r
enddef

export def AutoPairsJump()
  search('["\]'')}]', 'W')
enddef

export def AutoPairsMoveCharacter(key: string): string
  const c = getline(".")[col(".") - 1]
  const escaped_key = substitute(key, "'", "''", 'g')
  return "\<DEL>\<ESC>:call search('"
    .. escaped_key
    .. "')\<CR>a"
    .. c
    .. "\<LEFT>"
enddef
