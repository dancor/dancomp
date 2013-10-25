import Control.Applicative
import Control.Arrow
import Control.Concurrent
import Control.Monad
import Data.List
import Data.Maybe
import FUtil
import HSH
import System.Console.GetOpt
import System.Directory
import System.Environment
import System.FilePath
import qualified Data.Map as M
import System.Posix.Process.Internals
import System.Process
import System.IO

data Options = Options {
  optEmail :: Bool}

defaultOptions :: Options
defaultOptions = Options {
  optEmail = False}

options :: [OptDescr (Options -> Options)]
options = [
  Option "e" ["email"]
    (NoArg (\ opts -> opts {optEmail = True}))
    "Process an email."]

breakAfter :: (a -> Bool) -> [a] -> ([a], [a])
breakAfter f = first (uncurry (++)) . rePairLeft . second (break f) . splitAt 1

breakAfters f [] = []
breakAfters f l = uncurry (:) . second (breakAfters f) $ breakAfter f l

grabStr :: String -> String
grabStr = takeWhile (/= '"') . drop 1 . dropWhile (/= '"')

extractDate :: [String] -> (String, [String])
extractDate l = (map (\ c -> if c == '.' then '-' else c) . grabStr . head $
  filter ("[Date " `isPrefixOf`) l, l)

newSlot :: String -> M.Map String Int -> (String, M.Map String Int)
newSlot day m = (day ++ "." ++ show i, M.insert day i m) where
  i = fromMaybe 0 (M.lookup day m) + 1

dealWithNew dir l = do
  mOrig <- (M.map maximum . M.fromListWith (++) . map (second (:[])) .
    map (second (read . takeWhile (/= '.') . drop 1) . break (== '.')) .
    filter (\ x -> ".pgn" `isSuffixOf` x || ".pgn.can" `isSuffixOf` x)) <$>
    getDirectoryContents dir
  let
    rs = filter (("dancor" `isInfixOf`) . snd) .
      map (second unlines . extractDate) $
      breakAfters ("[Event " `isPrefixOf`) l
    pgnsAndFs = fst $
      foldl'
        (\ (a, m) (day, pgn) ->
          first ((:a) . (,) pgn . (++ ".pgn")) $ newSlot day m)
        ([], mOrig)
        rs
    filenames = sort $ map snd pgnsAndFs
  mapM_ (\ (pgn, f) -> writeFile (dir </> f) pgn) pgnsAndFs
  return filenames

emailDropHeaders = drop 1 . dropWhile (not . null)

waitForCrafty = do
  (pIn, pOut, pErr, pId) <- runInteractiveProcess "/usr/bin/pgrep"
    ["crafty.bin"] Nothing Nothing
  hClose pIn
  waitForProcess pId
  ls <- lines <$> hGetContents pOut
  unless (null ls) $ threadDelay 1000000 >> waitForCrafty

main = do
  args <- getArgs
  let
    (opts, []) = case getOpt Permute options args of
      (o, n, []) -> (foldl (flip id) defaultOptions o, n)
      (_, _, e) -> error $ concat e
    dir = "/home/danl/g/ch/fics"
    newFN = dir </> "new"
  waitForCrafty
  l <- if optEmail opts
    then dropWhile null . emailDropHeaders . lines <$> getContents
    else
      ifM (doesFileExist newFN)
        (dropWhile null . lines <$> readFile newFN)
        (return [])
  fsDone <- if null l
    then return []
    else dealWithNew dir l <* whenM (doesFileExist newFN) (removeFile newFN)
  appendFile "/home/danl/log/chanal" $ "[" ++ show l ++ "]\n"
  fs <- if optEmail opts
    then return fsDone
    else sort . filter (".pgn" `isSuffixOf`) <$> getDirectoryContents dir
  appendFile "/home/danl/log/chanal" $ "[" ++ show fs ++ "]\n"
  print fs
  inCd "/home/danl/g/ch" $ forM_ fs
    --(\ f -> runIO ("./anal", ["fics" </> f]) >> removeFile (dir </> f))
    (\ f -> system ("./anal fics" </> f) >> removeFile (dir </> f))
