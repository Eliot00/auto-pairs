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

def UnicodeLen(pair: string): number
  return len(split(pair, '\zs'))
enddef

