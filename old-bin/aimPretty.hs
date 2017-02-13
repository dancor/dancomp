#!/usr/bin/env runhaskell
import qualified AnsiColor as C
import qualified Data.List as L
import Text.Regex
main = interact $ unlines . map (\x -> subRegex
  (mkRegex $ "^\\((" ++ timeStamp ++ "( [AP]M)?\\)) [^:]+") (
    subRegex (mkRegex $ "^\\(" ++ timeStamp ++ "( [AP]M)?\\) (d(ancor@[^:]+|izanl)|g)") (
      subRegex (mkRegex "^Conversation with .*") x $
        C.yellow ++ "\\0" ++ C.normal
    ) $ C.cyan ++ "\\0" ++ C.normal
  ) $ C.red ++ "\\0" ++ C.normal) . lines where
    sd = "[0-9]"
    timeStamp = L.intercalate ":" $ replicate 3 $ sd ++ sd
