module Dancomp where

import System.IO
import System.Posix

askKill :: [ProcessID] -> IO ()
askKill pids = do
  putStr "Send SIGTERM to these processes (y/n)? "
  hFlush stdout
  l <- getLine
  case l of
    'y':_ -> do
      mapM_ (signalProcess sigTERM) pids
      -- todo: check to see if they are still running?
      putStr "Sent.  Send SIGKILL to these processes (y/n)? "
      hFlush stdout
      l2 <- getLine
      case l2 of
        'y':_ -> do
          mapM_ (signalProcess sigKILL) pids
          putStrLn "Sent."
        _ -> putStrLn "Not sent."
    _ -> putStrLn "Nothing sent."
