import Control.Concurrent
import Control.Monad
import Data.List
import System.Environment
import System.IO
import System.Process
import Text.Regex.Posix

-- Run a command and manipulate its output and error streams
-- in deciding what to report to stderr.
-- Also wait for the process to finish.
filterCommand :: (String -> String) -> (String -> String) -> String -> IO ()
filterCommand outF errF cmd = do
    (_pIn, pOut, pErr, pId) <- runInteractiveCommand cmd
    forkIO $ hGetContents pErr >>= (hPutStr stderr . errF)
    hGetContents pOut >>= (hPutStr stderr . outF)
    waitForProcess pId
    return ()

--ssName = "xscreensaver"
ssName = "gnome-screensaver"

ignAlrRun :: String -> String
ignAlrRun = id
{-
ignAlrRun = unlines . ignL . lines
  where
    ignL all@(a:b:x) =
        if a =~ ("^" ++ ssName ++ ": [0-9][0-9]:[0-9][0-9]:[0-9][0-9]: " ++
                 "already running on display ") &&
           b =~ "^ from process "
        then x else all
    ignL x = x
-}


ignActLock :: String -> String
ignActLock = id
{-
ignActLock = unlines . ignL . lines
  where
    ignL (ssName ++ "-command: activating and locking.":"":x) = x
    ignL x = x
-}

main :: IO ()
main = do
    args <- getArgs
    case args of
      [] -> do
        runCommand "xset dpms 10"
        runCommand "xset dpms force off"
      ["-k"] -> runCommand "xset dpms 0"
      _ -> error "usage: ./blankscr (-k)"
    return ()
    -- forkIO . forever $
    -- filterCommand id ignAlrRun ssName
    -- filterCommand ignActLock id $ ssName ++ "-command --lock"
    {-
    let waitForUnblank = do
            (_pIn, pOut, pErr, pId) <-
                runInteractiveCommand $ ssName ++ "-command"
            forkIO $ hGetContents pErr >>= hPutStr stderr
            l <- hGetLine pOut
            let ws = words l
            unless (null ws) $
                case head ws of
                "UNBLANK" -> terminateProcess pId
                "LOCK" -> waitForUnblank
                _ -> hPutStrLn stderr l >> waitForUnblank
    waitForUnblank
    -}
