vim9script

export def AutoPairsJump()
  search('["\]'')}]', 'W')
enddef
