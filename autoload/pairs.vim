vim9script

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
