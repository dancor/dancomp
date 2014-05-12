import Control.Applicative
import Data.Char
import Data.List
import System.Directory
import System.FilePath
import System.Process
import qualified Opt

usage :: String
usage = "usage: adjvol [options]\n" ++ Opt.optInfo

doErrs :: [String] -> a
doErrs errs = error $ concat errs ++ usage

sinkId = "Master"

soundCmd :: [String] -> IO String
soundCmd args = do
    -- verbose:
    print $ "amixer":args

    -- todo: error checking for these?
    (_ec, out, _err) <- readProcessWithExitCode "amixer" args ""
    return out

setVol :: Int -> IO ()
setVol v = do
    _ <- soundCmd ["set", sinkId, show v]
    return ()

getVolLine :: IO String
getVolLine = do
    out <- soundCmd ["get", sinkId]
    let volLine:_ =
          filter ("%" `isInfixOf`) . filter ("dB" `isInfixOf`) $ lines out
    return volLine

getVol :: IO Int
getVol = do
    volLine <- getVolLine
    let volStr:_ = filter (all isDigit) $ words volLine
    return $ read volStr

muteOn :: IO ()
muteOn = do
    _ <- soundCmd ["set", sinkId, "mute"]
    return ()

muteOff :: IO ()
muteOff = do
    _ <- soundCmd ["set", sinkId, "unmute"]
    return ()

getMute :: IO Bool
getMute = do
    volLine <- getVolLine
    return . (== "[off]") . last $ words volLine

delta :: Int
delta = 4

soundMax :: Float
soundMax = 74

lowerVol :: IO ()
lowerVol = setVol =<< (subtract delta) <$> getVol

raiseVol :: IO ()
raiseVol = setVol =<< ((+ delta) <$> getVol)

intToPcnt :: Int -> Float
intToPcnt x = fromIntegral x * 100 / soundMax

pcntToInt :: Float -> Int
pcntToInt x = round $ x * soundMax / 100

main :: IO ()
main = do
    homeDir <- getHomeDirectory
    (opts, tasks) <- Opt.getOpts (homeDir </> ".adjvol" </> "config") usage
    -- way for polyopt to help with exclusive args?  hm
    {-
    when (Opt.lower opts && Opt.raise opts) $
      error "It doesn't make sense to raise and lower the volume.."
    when (Opt.lower opts) $
    -}
    case opts of
      Opt.Opts True False False False Nothing False False ->
        muteOff >> lowerVol
      Opt.Opts False True False False Nothing False False ->
        muteOff >> raiseVol
      Opt.Opts False False True False Nothing False False ->
        --muteOn >> lowerVol  -- so next raise returns to previous
        muteOn
      Opt.Opts False False False True Nothing False False ->
        muteOff
      Opt.Opts False False False False (Just v) False False -> do
        -- WTF?
        --setVol (pcntToInt v) >> muteOff
        muteOff
        setVol (pcntToInt v)
        muteOff
        setVol (pcntToInt v)
        muteOff
        setVol (pcntToInt v)
        muteOff
        setVol (pcntToInt v)
        muteOff
        --setVol (pcntToInt v) >> muteOff >> lowerVol >> raiseVol
      Opt.Opts False False False False Nothing True False ->
        getVol >>= print . intToPcnt
      Opt.Opts False False False False Nothing False True ->
        getMute >>= print
      _ -> error "You must specify exactly one operation."
