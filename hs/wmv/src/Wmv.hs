{-# LANGUAGE PatternGuards #-}

import Data.List
import Numeric
import System.Environment
import System.Process

data P2 a = P2
    { p1 :: !a
    , p2 :: !a
    }

data Wmv = Wmv
    { wScr :: !Int
    , wX :: !(P2 Rational)
    , wY :: !(P2 Rational)
    , wTitle :: !String
    }

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

procArgs :: [String] -> Wmv
procArgs = procScr wInit
  where
    procScr w (('s':nStr):rest) = procX (w {wScr = read nStr}) rest
    procScr w rest = procX w rest

    procX w (arg:rest) = procY (w {wX = readCoord s1WUnits arg}) rest

    procY w [] = procTitle w []
    procY w [title] = procTitle w [title]
    procY w (arg:rest) = procTitle (w {wY = readCoord s1HUnits arg}) rest

    readCoord maxVal arg@('+':rest)
      | (rat2, "") <- readRat rest = P2 0 rat2
      | otherwise = error $ "Could not read coordinates: " ++ arg
    readCoord maxVal arg =
        let (rat1, rest) = readRat arg
        in case rest of
          "" -> P2 rat1 $ min 1 (maxVal - rat1)
          "+" -> P2 rat1 (maxVal - rat1)
          '+':rest2 -> case readRat rest2 of
            (rat2, "") -> P2 rat1 rat2
            _ -> error $ "Could not read coordinates: " ++ arg
          _ -> error $ "Could not read coordinates: " ++ arg

    readRat = head . readFloat

    procTitle w [] = procTitle w [":ACTIVE:"]
    procTitle w [arg] = w {wTitle = arg}
    procTitle _ args = error $ "Multiple arguments for title: " ++ show args

doWmv :: Wmv -> IO ()
doWmv w = do
    rawSystem "wmctrl"
        ["-r", wTitle w, "-b", "remove,maximized_vert,maximized_horz"]
    print
        [ "-r", wTitle w, "-e"
        , intercalate "," . map show $ map floor
          [ s1UnitW * p1 (wX w)
          , s1UnitH * p1 (wY w)
          , s1UnitW * p2 (wX w)
          , s1UnitH * p2 (wY w)
          ]
        ]
    rawSystem "wmctrl"
        [ "-r", wTitle w, "-e"
        , intercalate "," . ("0":) . map show $ map floor
          [ s1UnitW * p1 (wX w)
          , s1UnitH * p1 (wY w)
          , s1UnitW * p2 (wX w)
          , s1UnitH * p2 (wY w)
          ]
        ]
    return ()

main :: IO ()
main = do
    args <- getArgs
    doWmv $ procArgs args
