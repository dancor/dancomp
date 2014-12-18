import Control.Applicative
import Data.List
import GHC.IO.Exception
import System.Directory
import System.Posix.Env
import System.FilePath
import System.Process
import qualified Opt

usage :: String
usage = "usage: adjvol [options]\n" ++ Opt.optInfo

doErrs :: [String] -> a
doErrs errs = error $ concat errs ++ usage

sinkId :: String
--sinkId = "0"
--sinkId = "1"
sinkId = "alsa_output.pci-0000_00_1b.0.analog-stereo"

pacmd :: [String] -> IO String
pacmd args = do
    {-
    setEnv "DISPLAY" ":0" False
    setEnv "PULSE_RUNTIME_PATH" "/home/danl/.config/pulse/" False
    readProcessWithExitCode "pacmd" args ""
    -}
    (ec, out, err) <- readProcessWithExitCode "sudo" (["-u", "pulse",
        "PULSE_RUNTIME_PATH=/var/run/pulse", "--", "pacmd"] ++ args) ""
    case (ec, err) of
      (ExitSuccess, "") -> return out
      _ -> error $ show ec ++ "\nstdout:\n" ++ out ++ "\nstderr:\n" ++ err

setVol :: Int -> IO ()
setVol v = do
    -- todo: error checking?
    _out <- pacmd ["set-sink-volume", sinkId, show v]
    return ()

getVol :: IO Int
getVol = do
    -- todo: handle error if missing in out
    out <- pacmd ["dump"]
    return . read . (!! 2) . words . head .
        filter ("set-sink-volume" `isPrefixOf`) $ lines out

muteOn :: IO ()
muteOn = do
    -- todo: error checking?
    _out <- pacmd ["set-sink-mute", sinkId, "yes"]
    return ()

muteOff :: IO ()
muteOff = do
    -- todo: error checking?
    _out <- pacmd ["set-sink-mute", sinkId, "no"]
    return ()

getMute :: IO Bool
getMute = do
    -- todo: handle error if missing in out
    out <- pacmd ["dump"]
    return . (== "yes") . (!! 2) . words . head .
        filter ("set-sink-mute" `isPrefixOf`) $ lines out

delta :: Int
delta = 0xf00

lowerVol :: IO ()
lowerVol = do
    curVol <- getVol
    setVol (curVol - delta)

raiseVol :: IO ()
raiseVol = setVol =<< ((+ delta) <$> getVol)

intToPcnt :: Int -> Float
intToPcnt x = fromIntegral x * 100 / 65536

pcntToInt :: Float -> Int
pcntToInt x = round $ x * 65536 / 100

main :: IO ()
main = do
    putStrLn "hi"
    homeDir <- getHomeDirectory
    putStrLn homeDir
    (opts, tasks) <- Opt.getOpts (homeDir </> ".adjvol" </> "config") usage
    -- way for polyopt to help with exclusive args?  hm
    {-
    when (Opt.lower opts && Opt.raise opts) $
      error "It doesn't make sense to raise and lower the volume.."
    when (Opt.lower opts) $
    -}
    case opts of
      Opt.Opts True False False False Nothing False False -> do
        putStrLn "lower"
        -- muteOff
        lowerVol
      Opt.Opts False True False False Nothing False False ->
        muteOff >> raiseVol
      Opt.Opts False False True False Nothing False False ->
        --muteOn >> lowerVol  -- so next raise returns to previous
        muteOn
      Opt.Opts False False False True Nothing False False ->
        muteOff
      Opt.Opts False False False False (Just v) False False ->
        -- WTF?
        --setVol (pcntToInt v) >> muteOff
        muteOff >> setVol (pcntToInt v)
        --setVol (pcntToInt v) >> muteOff >> lowerVol >> raiseVol
      Opt.Opts False False False False Nothing True False ->
        getVol >>= print . intToPcnt
      Opt.Opts False False False False Nothing False True ->
        getMute >>= print
      _ -> error "You must specify exactly one operation."
