vim9script

const Go = "\<C-G>U"
export const GoLeft = Go .. "\<LEFT>"
export const GoRight = Go .. "\<RIGHT>"

export def Left(pair: string): string
  return repeat(GoLeft, UnicodeLen(pair))
enddef

export def Right(pair: string): string
  return repeat(GoRight, UnicodeLen(pair))
enddef

export def Delete(pair: string): string
  return repeat("\<DEL>", UnicodeLen(pair))
enddef

export def Backspace(pair: string): string
  return repeat("\<BS>", UnicodeLen(pair))
enddef

export def GetLineContext(): list<string>
  const row = getline('.')
  const before_cursor = col('.') - 1
  const before_str = strpart(row, 0, before_cursor)
  var after_str = strpart(row, before_cursor)
  const after_line = after_str
  if g:AutoPairsMultilineClose
    const last_line = line('$')
    var index = line('.') + 1
    while index <= last_line
      const line = getline(index)
      after_str = after_str .. ' ' .. line
      if !(line =~ '\v^\s*$')
        break
      endif
      index = index + 1
    endwhile
  endif

  return [before_str, after_str, after_line]
enddef

def UnicodeLen(pair: string): number
  return len(split(pair, '\zs'))
enddef

