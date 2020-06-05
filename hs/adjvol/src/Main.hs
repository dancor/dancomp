import Control.Applicative
import Data.List
import GHC.IO.Exception
import System.Console.GetOpt
import System.Directory
import System.Environment
import System.Posix.Env
import System.FilePath
import System.Process
import Text.Read

sinkId :: String
sinkId = "0"

pacmd :: [String] -> IO String
pacmd args = do
    (ec, out, err) <- readProcessWithExitCode "pacmd" args ""
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
    let wds = words . head .
            filter ("set-sink-volume" `isPrefixOf`) $ lines out
    --print wds
    return $ read (wds !! 2)

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

myRead :: String -> Float
myRead s = case readMaybe s of
  Just r -> r
  _ -> error $ "Expected a real number but got " ++ show s

optDescs :: [OptDescr (IO ())]
optDescs = [
    Option "l" ["lower"] (NoArg lowerVol) "Lower the volume",
    Option "r" ["raise"] (NoArg $ muteOff >> raiseVol) "Raise the volume",
    Option "m" ["mute"] (NoArg muteOn) "Mute the volume",
    Option "u" ["unmute"] (NoArg muteOff) "Unmute the volume",
    Option "s" ["set"]
        (ReqArg (\s -> muteOff >> setVol (pcntToInt $ myRead s)) "PERCENT")
        "Set the volume",
    Option "g" ["get"] (NoArg $ getVol >>= print . intToPcnt) "Get the volume",
    Option "M" ["get-mute"] (NoArg $ getMute >>= print) "Get the mute state"] 

main :: IO ()
main = do
    homeDir <- getHomeDirectory
    args <- getArgs
    let usageStr = usageInfo "usage: adjvol [OPTIONS]" optDescs
    case getOpt RequireOrder optDescs args of
      ([],_,_) -> error usageStr
      (opts,[],[]) -> sequence_ opts
      (_,nonOpts,errs) -> error $ concat errs ++ concatMap
        (\n -> "Unrecognized argument: " ++ show n ++ "\n") nonOpts ++ usageStr
