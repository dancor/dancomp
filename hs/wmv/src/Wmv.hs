{-# LANGUAGE PatternGuards #-}

import Control.Applicative
import Control.Arrow
import Control.Concurrent
import Control.Monad
import Data.List
import Data.List.Utils
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
    , wVerbose :: !Bool
    }
    deriving Show

charWAndH :: P2 Rational
--charWAndH = P2 8 13
charWAndH = P2 10 16
-- For 2160p:
--charWAndH = P2 16 28

scrsUnitChWAndH :: [P2 Rational]
scrsUnitChWAndH = [P2 80 40, P2 80 40]

pInit :: P2 Rational
pInit = P2 0 1

wInit :: Wmv
wInit = Wmv 1 pInit pInit "" False

readCoord :: Rational -> ReadS (P2 Rational)
readCoord _ arg@('+':y)
  | [(rat2, rest)] <- readRat y = [(P2 0 rat2, rest)]
  | otherwise = []
readCoord maxVal arg
  | [(rat1, rest)] <- readRat arg =
    case rest of
      '+':y -> case readRat y of
        (rat2, rest2):_ -> [(P2 rat1 rat2, rest2)]
        _ -> [(P2 rat1 (maxVal - rat1), y)]
      _ -> [(P2 rat1 $ min 1 (maxVal - rat1), rest)]
  | otherwise = []

-- | Numeric's readFloat almost works, but we also want to allow
-- numbers starting directly with "." instead of "0.".
readRat :: ReadS Rational
readRat ('.':y)
  | [(dec, rest)] <- readDec y = [(dec % 10 ^ length (show dec), rest)]
  | otherwise = []
readRat x = readFloat x

procArgs :: [P2 Rational] -> [String] -> Wmv
procArgs scrsWAndHUnits = procVerbose wInit
  where
    procVerbose w ("-v":rest) = procScr (w {wVerbose = True}) rest
    procVerbose w rest = procScr w rest

    procScr w (('s':nStr):rest) = procX (w {wScr = read nStr}) rest
    procScr w rest = procX w rest

    procX w (arg:rest) =
        procY (w {wX = coord1}) rest
      where
        coord1 = case readCoord (p1 $ scrsWAndHUnits !! (wScr w - 1)) arg of
          [(c, "")] -> c
          hm -> error $
            "arg: " ++ show arg ++ "; readCoord s1WUnits arg: " ++ show hm

    procY w args
      | arg:restArgs <- args,
        [(coord2, "")] <- readCoord (p2 $ scrsWAndHUnits !! (wScr w - 1)) arg =
        procTitle (w {wY = coord2}) restArgs
      | otherwise = procTitle w args

    procTitle w [] = procTitle w [":ACTIVE:"]
    procTitle w [arg] = w {wTitle = arg}
    procTitle _ args = error $ "Multiple arguments for title: " ++ show args

doWmv :: [P2 Rational] -> [P2 Rational] -> Wmv -> IO ()
doWmv scrsPixelWAndH scrsUnitWAndH w = do
    let scrUnitWAndH = scrsUnitWAndH !! (wScr w - 1)
        gX = show . floor $ sum (map p1 $ take (wScr w - 1) scrsPixelWAndH) +
            p1 scrUnitWAndH * p1 (wX w)
        gY = show . floor $ p2 scrUnitWAndH * p1 (wY w)
        [gW, gH] = map (show . floor)
            [p1 scrUnitWAndH * p2 (wX w), p2 scrUnitWAndH * p2 (wY w)]
        [tW, tH] = map (show . floor)
            [ p1 scrUnitWAndH * p2 (wX w) / p1 charWAndH
            , p2 scrUnitWAndH * p2 (wY w) / p2 charWAndH
            ]
        cmd = "wmctrl"
        args = ["-r", wTitle w, "-e", intercalate "," ["0", gX, gY, gW, gH]]
        doMv = rawSystem "wmctrl" args
    when (wVerbose w) . putStrLn $ intercalate " " (cmd:args)
    case wTitle w of
      "--xywh" -> putStrLn $ intercalate " " [gX, gY, gW, gH]
      "--terminal-xywh" -> putStrLn $ intercalate " " [gX, gY, tW, tH]
      "--geometry" -> putStrLn $ concat [gW, "x", gH, "+", gX, "+", gY]
      "--terminal-geometry" ->
        putStrLn $ concat [tW, "x", tH, "+", gX, "+", gY]
      _ -> do
        rawSystem "wmctrl"
            ["-r", wTitle w, "-b", "remove,maximized_vert,maximized_horz"]
        doMv
        -- gnome-terminal needs a second move, so again after 0.2 s:
        threadDelay 200000
        doMv
        return ()

twoWords :: String -> (String, String)
twoWords = (\(x:y:_) -> (x, y)) . words

readI :: String -> Int
readI = read

main :: IO ()
main = do
    scrsPixelWAndH <- map (
        (\(x, y) -> P2 (fromIntegral $ readI x) (fromIntegral $ readI y)) .
        twoWords . replace "x" " " . head . words) .
        filter ("*" `isInfixOf`) . lines <$> readProcess "xrandr" [] ""
    -- A unit is a place on the screen for a normal size text terminal.
    let scrsUnitWAndH = zipWith
            (\(P2 _scrPixelW scrPixelH) (P2 scrUnitChW _scrUnitChH) ->
                P2 (p1 charWAndH * scrUnitChW) scrPixelH
                )
            scrsPixelWAndH
            scrsUnitChWAndH
        scrsWAndHUnits = zipWith
            (\(P2 scrPixelW scrPixelH) (P2 scrUnitW scrUnitH) ->
                P2 (scrPixelW / scrUnitW) (scrPixelH / scrUnitH)
                )
            scrsPixelWAndH
            scrsUnitWAndH
    args <- getArgs
    doWmv scrsPixelWAndH scrsUnitWAndH $ procArgs scrsWAndHUnits args
