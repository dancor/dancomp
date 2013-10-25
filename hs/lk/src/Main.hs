-- lookup scrabble words

import Control.Monad
import Data.Char
import System.Console.GetOpt
import System.Environment
import System.IO
import System.Process
import qualified Data.Set as S

--data OptFlag = Defn | DefnR | Sowpods deriving Eq
data OptFlag = WdsOnly | Twl deriving Eq

progOpts :: [OptDescr OptFlag]
progOpts = [
  Option "o" ["words-only"] (NoArg WdsOnly) "do not give definitions",
  --Option "r" ["def-recurse"] (NoArg DefnR) "give defns for defn references",
  --Option "s" ["sowpods"] (NoArg Sowpods) "use sowpods scrabble dictionary"
  Option "t" ["twl"] (NoArg Twl) "use the smaller twl scrabble dictionary"
  ]

doReplacements :: (Eq a) => [(a, [a])] -> [a] -> [a]
doReplacements reps = concatMap (\ x -> case lookup x reps of
  Just y -> y
  Nothing -> [x])

wordRefs :: [Char] -> [[Char]]
wordRefs line = let line' = drop 1 $ dropWhile (`notElem` "{<") line in
  if null line'
    then []
    else let (word, line'') = span (/= '=') line' in
      word:wordRefs line''

lkR :: Int -> [OptFlag] -> [String] -> String -> IO (S.Set String)
lkR depth opts grepArgs line = do
  putStrLn $ replicate (3 * (depth - 1)) ' ' ++
    (if depth > 0 then "=> " else "") ++ line
  {-
  if DefnR `elem` opts
    then do
      wdLists <- mapM (lk (depth + 1) opts grepArgs) $ wordRefs line
      return (S.unions wdLists)
    else return $ S.singleton $ head $ words line
  -}
  return . S.singleton . head $ words line

dictGrep :: Int -> [OptFlag] -> String -> String -> [String] ->
  IO (S.Set String)
dictGrep depth opts ptn dictF grepArgs = do
  (pIn, pOut, pErr, pId) <- runInteractiveProcess "grep" (ptn:dictF:grepArgs)
    Nothing Nothing
  cOut <- hGetContents pOut
  wdLists <- mapM (lkR depth opts grepArgs) $ lines cOut
  cErr <- hGetContents pErr
  hPutStr stderr cErr
  waitForProcess pId
  return $ S.unions wdLists

lk :: Int -> [OptFlag] -> [String] -> [Char] -> IO (S.Set String)
lk depth opts grepArgs word = do
  let
    dictF = "/usr/share/dict/CSW12TWL06.txt"
    ptn = "^" ++
      (if Twl `elem` opts then " " else ".") ++
      doReplacements [('.', "[^ ]")] (map toUpper word) ++ "\\b"
  dictGrep depth opts ptn dictF $
    if WdsOnly `elem` opts then "-o":grepArgs else grepArgs

main :: IO ()
main = do
  args <- getArgs
  let
    usage = "usage: ./lk.hs [options] word-pattern"
    doErrs errs = error $ concat errs ++ usageInfo usage progOpts
  (opts, wordL) <- case getOpt Permute progOpts args of
    (o, n, []) -> return (o, n)
    (_, _, errs) -> doErrs errs
  case wordL of
    word:grepArgs -> lk 0 opts grepArgs word >> return ()
    _ -> doErrs []
