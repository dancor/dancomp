{-# LANGUAGE TemplateHaskell #-}

module Opt where

import Data.PolyOpt

$(polyOpt [
  noArg ["lower"] "l"
    "lower the volume",
  noArg ["raise"] "r"
    "raise the volume",
  noArg ["mute"] "m"
    "mute the volume",
  noArg ["unmute"] "u"
    "unmute the volume",
  reqArgGen ["set"] "s"
    "PERCENT" [t|Maybe Float|] [|Nothing|] [|Just . read|]
    "set volume to given PERCENT (0..100)",
  noArg ["get"] "g"
    "get the volume percent",
  noArg ["get-mute"] "M"
    "get the mute state"
  ])

