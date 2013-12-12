{-# LANGUAGE PatternGuards #-}

import Control.Arrow
import Control.Concurrent
import Data.List
import Data.Ratio
import Numeric
import System.Environment
import System.Process

data P2 a = P2
    { p1 :: !a
    , p2 :: !a
    }
    deriving Show

data Wmv = Wmv
    { wScr :: !Int
    , wX :: !(P2 Rational)
    , wY :: !(P2 Rational)
    , wTitle :: !String
    }
    deriving Show

charW, charH :: Rational
charW = 8
charH = 13

s1UnitChW, s1UnitChH :: Rational
s1UnitChW = 80
s1UnitChH = 40

s1UnitW, s1UnitH :: Rational
s1UnitW = charW * s1UnitChW
-- s1UnitH = charH * s1UnitChH
s1UnitH = s1H

s1W, s1H :: Rational
s1W = 1366
s1H = 768

s1WUnits, s1HUnits :: Rational
s1WUnits = s1W / s1UnitW
s1HUnits = s1H / s1UnitH

pInit :: P2 Rational
pInit = P2 0 1

wInit :: Wmv
wInit = Wmv 1 pInit pInit ""

readCoord :: Rational -> ReadS (P2 Rational)
readCoord _ arg@('+':y)
  | [(rat2, rest)] <- readRat y = [(P2 0 rat2, rest)]
  | otherwise = []
readCoord maxVal arg
  | [(rat1, rest)] <- readRat arg =
    case rest of
      '+':y -> case readRat y of
        (rat2, rest2):_ -> [(P2 rat1 rat2, rest2)]
        _ -> [(P2 rat1 (maxVal - rat1), rest)]
      _ -> [(P2 rat1 $ min 1 (maxVal - rat1), rest)]
  | otherwise = []

-- | Numeric's readFloat almost works, but we also want to allow
-- numbers starting directly with "." instead of "0.".
readRat :: ReadS Rational
readRat x@('.':y)
  | [(dec, rest)] <- readDec y = [(dec % 10 ^ length (show dec), rest)]
  | otherwise = []
readRat x = readFloat x

procArgs :: [String] -> Wmv
procArgs = procScr wInit
  where
    procScr w (('s':nStr):rest) = procX (w {wScr = read nStr}) rest
    procScr w rest = procX w rest

    procX w (arg:rest) =
        procY (w {wX = coord1}) rest
      where
        [(coord1, "")] = readCoord s1WUnits arg

    procY w args
      | arg:restArgs <- args,
        [(coord2, "")] <- readCoord s1HUnits arg =
        procTitle (w {wY = coord2}) restArgs
      | otherwise = procTitle w args

    procTitle w [] = procTitle w [":ACTIVE:"]
    procTitle w [arg] = w {wTitle = arg}
    procTitle _ args = error $ "Multiple arguments for title: " ++ show args

doWmv :: Wmv -> IO ()
doWmv w = do
    rawSystem "wmctrl"
        ["-r", wTitle w, "-b", "remove,maximized_vert,maximized_horz"]
    {-
    print
        [ "-r", wTitle w, "-e"
        , intercalate "," . map show $ map floor
          [ s1UnitW * p1 (wX w)
          , s1UnitH * p1 (wY w)
          , s1UnitW * p2 (wX w)
          , s1UnitH * p2 (wY w)
          ]
        ]
    -}
    let doMv = rawSystem "wmctrl"
            [ "-r", wTitle w, "-e"
            , intercalate "," . ("0":) . map show $ map floor
              [ s1UnitW * p1 (wX w)
              , s1UnitH * p1 (wY w)
              , s1UnitW * p2 (wX w)
              , s1UnitH * p2 (wY w)
              ]
            ]
    doMv
    -- gnome-terminal needs a second move, so again after 0.2 s:
    threadDelay 200000
    doMv
    return ()

main :: IO ()
main = do
    args <- getArgs
    --print $ procArgs args
    doWmv $ procArgs args
