import System.Console.GetOpt (ArgDescr(NoArg, ReqArg), ArgOrder(RequireOrder),
  OptDescr(Option), getOpt, usageInfo)
import System.Directory (getHomeDirectory)
import System.Environment (getArgs)
import System.Process (callProcess, readProcess)
setVol = (\v -> callProcess "pamixer" ["--set-volume", show v])
  :: Int -> IO ()
getVol = read <$> readProcess "pamixer" ["--get-volume"] ""
  :: IO Int
muteOn, muteOff, raiseVol, lowerVol :: IO ()
muteOn = callProcess "pamixer" ["-m"]
muteOff = callProcess "pamixer" ["-u"]
getMute = (== "true\n") <$> readProcess "pamixer" ["--get-mute"] ""
raiseVol = callProcess "pamixer" ["-i", "5"]
lowerVol = callProcess "pamixer" ["-d", "5"]
optDescs = [
  Option "l" ["lower"] (NoArg lowerVol) "Lower the volume",
  Option "r" ["raise"] (NoArg $ muteOff >> raiseVol) "Raise the volume",
  Option "m" ["mute"] (NoArg muteOn) "Mute the volume",
  Option "u" ["unmute"] (NoArg muteOff) "Unmute the volume",
  Option "s" ["set"] (ReqArg (\s -> muteOff >> setVol (read s)) "PERCENT")
    "Set the volume",
  Option "g" ["get"] (NoArg $ getVol >>= print) "Get the volume",
  Option "M" ["get-mute"] (NoArg $ getMute >>= print) "Get the mute state"] 
  :: [OptDescr (IO ())]
main = do
  homeDir <- getHomeDirectory
  args <- getArgs
  let usageStr = usageInfo "usage: adjvol [OPTIONS]" optDescs
  case getOpt RequireOrder optDescs args of
    ([],_,_) -> error usageStr
    (opts,[],[]) -> sequence_ opts
    (_,nonOpts,errs) -> error $ concat errs ++ concatMap
      (\n -> "Unrecognized argument: " ++ show n ++ "\n") nonOpts ++ usageStr
  :: IO ()
