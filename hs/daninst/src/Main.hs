import Control.Arrow
import Control.Exception
import Control.Monad
import Data.List
import Data.List.Split
import qualified Data.Map as M
import HSH
import System.Console.GetOpt
import System.Directory
import System.Environment
import System.FilePath
import System.IO.Error

data Options = Options
    { optDoInst   :: Bool
    , optFileList :: Maybe [String]
    , optRemove   :: Bool
    }

dcDefOpts :: Options
dcDefOpts = Options
    { optDoInst   = True
    , optFileList = Nothing
    , optRemove   = False
    }

dcOpts :: [OptDescr (Options -> Options)]
dcOpts =
    [ Option "d" ["diff-only"]
      (NoArg (\ o -> o {optDoInst = False}))
      "just show diffs; do not install"
    , Option "f" ["file-list"]
      (ReqArg (\ a o -> o {optFileList = Just $ splitOn "," a}) "CSV") $
      -- fixme: usability too lol?
      -- also should we error if you specify something that doesn't exist?
      intercalate "\n"
      [ "only intsall these subpaths (don't give host or"
      , "top-level; i.e. hs/ghci.hs for share/gen/hs/ghci.hs)"
      ]
    , Option "r" ["remove"]
      (NoArg (\ o -> o {optRemove = True}))
      "uninstall the target file"
    ]

killDotSlash :: [Char] -> [Char]
killDotSlash ('.':'/':rest) = rest
killDotSlash rest = rest

inCd :: FilePath -> IO b -> IO b
inCd dir f = do
    dirOrig <- HSH.pwd
    HSH.cd dir
    res <- f
    HSH.cd dirOrig
    return res

filesIn :: FilePath -> IO [String]
filesIn dir = inCd dir . fmap (map killDotSlash . lines) $
    run ("find", ["-type", "f", "-or", "-type", "l"])

filesInIfExist :: FilePath -> IO [String]
filesInIfExist dir = do
    hasDir <- doesDirectoryExist dir
    if hasDir then filesIn dir else return []

diff :: Options -> Bool -> [Char] -> ([Char], [Char]) -> IO ()
diff opts instAsRoot destDir (file, dir) = do
    let f1 = destDir </> file
        f2 = dir </> file
        onDiffErr e
            | isUserError e &&
              -- fixme: too lol
              (": exited with code 1" `isSuffixOf` ioeGetErrorString e ||
               ": exited with code 2" `isSuffixOf` ioeGetErrorString e) =
                onFilesDiff
            | otherwise = ioError e
        onFilesDiff = when (optDoInst opts) $ do
            let instCmd c1 cRest =
                    if instAsRoot then ("sudo", c1:cRest) else (c1, cRest)
            inCd dir . runIO $ instCmd "mkdir" ["-p", destDir]
            inCd dir . runIO $ instCmd "cp" ["-d", "--parents", file, destDir]
            putStrLn $ "Installed: " ++ show f2
    if optRemove opts
      then do
        runIO ("sudo", ["rm", f1, f2])
        putStrLn $ "Deleted: " ++ show f1
        putStrLn $ "Deleted: " ++ show f2
      else
        catch (run ("sudo", ["diff", "-du", f1, f2])) onDiffErr

destDirInfos :: [(FilePath, (Bool, FilePath -> FilePath))]
destDirInfos =
    [ ("bin",   (True, const "/usr/local/bin"))
    , ("etc",   (True, const "/etc"))
    , ("home",  (False, id))
    , ("lib",   (True, const "/lib"))
    , ("share", (True, const "/usr/local/share/dancomp"))
    , ("usr",   (True, const "/usr"))
    , ("var",   (True, const "/var"))
    ]

diffDir :: Options -> [Char] -> IO ()
diffDir opts dir = do
    host <- runSL "hostname"
    home <- getEnv "HOME"
    let (instAsRoot, destDir) = case lookup dir destDirInfos of
            Just v -> second ($ home) v
            _ -> error $ "unknown directory: " ++ dir
        cAnoa = "anoa"
        cKiva = "kiva"
        workDirs = ["nonwork"]
        isHomeserver = host `elem` [cKiva, cAnoa]
        dirs = map (\ x -> home </> "p" </> x) .
            concatMap (\ x -> ["dancomp" </> x, "dancomp-secret" </> x]) .
            map (\ x -> "tree" </> x </> dir) $ ["gen"] ++
            workDirs ++
            (if isHomeserver then ["homeserver"] else ["sat"]) ++
            [host]
    dirsFiles <- mapM filesInIfExist dirs
    -- prefer later file listings (host-specific over gen, secret over not)
    let files = M.toList . M.fromList . concat .
            zipWith (map . flip (,)) dirs $
            map (filter (not . isSuffixOf ".swp")) dirsFiles
        files' = case optFileList opts of
            Just fileList -> filter ((`elem` fileList) . fst) files
            Nothing -> files
    mapM_ (diff opts instAsRoot destDir) files'


doArgs :: String -> c -> [OptDescr (c -> c)] -> IO (c, [String])
doArgs header defOpts opts = do
    args <- getArgs
    return $ case getOpt Permute opts args of
        (o, n, []) -> (foldl (flip id) defOpts o, n)
        (_, _, errs) -> error $ concat errs ++ usageInfo header opts

main :: IO ()
main = do
    let usage = "usage: daninst [options] [dirs]"
    (opts, dirs) <- doArgs usage dcDefOpts dcOpts
    mapM_ (diffDir opts) $ case dirs of
        [] -> map fst destDirInfos
        _ -> dirs
