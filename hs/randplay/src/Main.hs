import Data.Random
import System.Environment
import System.Posix.Process
import System.Process

main = do
    args <- getArgs
    out <- readProcess "find" (args ++
        words "-iname *.mp3 -o -iname *.ogg -o -iname *.flac -o -iname *.aac")
        ""
    randList <- runRVar (shuffle $ lines out) StdRandom
    executeFile "mp" True randList Nothing
