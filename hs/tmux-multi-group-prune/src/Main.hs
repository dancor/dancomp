module Main where

import Control.Arrow
import Data.Function
import Data.List
import System.Process

main :: IO ()
main = do
  o <- readProcess "tmux" ["list-sessions"] ""
  let
    procLine l = (takeWhile (/= ')') . drop 2 $ dropWhile (/= 'p') l,
      (takeWhile (/= ':') l, "(attached)" `isSuffixOf` l))
  mapM_ (\ n -> readProcess "tmux" ["kill-session", "-t", n] "") .
    filter (/= "lalala") . map fst .
    filter (not . snd) . concat . filter (any snd) . map (map snd) .
    groupBy ((==) `on` fst) . sort . filter (not . null . fst) .
    map procLine $ lines o
