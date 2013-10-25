import Control.Concurrent
import Control.Monad
import FUtil
import HSH
import System.Console.GetOpt
import System.Environment
import qualified Data.Map as M

data Options = Options {
  optConn :: Bool,
  optKeep :: Bool,
  optDrop :: Bool
  }

defOpts :: Options
defOpts = Options {
  optConn = False,
  optKeep = False,
  optDrop = False
  }

options :: [OptDescr (Options -> Options)]
options = [
  Option "c" ["conn"] (NoArg (\ o -> o {optConn = True}))
    "connect to home server etc after connecting",
  Option "k" ["keep-existing"] (NoArg (\ o -> o {optKeep = True}))
    "keep existing connections up",
  Option "d" ["drop"] (NoArg (\ o -> o {optDrop = True}))
    "drop single specified connection"
  ]

mill :: Int
mill = 1000 ^ 2

-- note: down functions should not be capable of failing
ifaces :: String -> [(String, (String, (IO (), IO ())))]
ifaces host = [
  ("l", ("lan (default)", (lanUp, lanDown))),
  ("w", ("wifi", (wifiUp True host, wifiDown))),
  ("s", ("sprint-evdo", (sprintUp, sprintDown))),
  ("c", ("new-sprint-evdo", (newSprintUp, newSprintDown))),
  ("a", ("att-gsm", (attUp, attDown))),
  ("h", ("homelan", (homeUp host, homeDown))),
  ("W", ("homewifi", (wifiUp False host, wifiDown))),
  --("t", ("tether", (tetherUp, tetherDown)))
  ("x", ("all-down", (return (), return ())))
  ]

lanUp :: IO ()
lanUp = do
  runIO "dh eth0"
  putStrLn ">>> lan up"

lanDown :: IO ()
lanDown = do
  runIO "sudo /sbin/ifconfig eth0 down || true"
  putStrLn ">>> lan down"

hostPreferredIP2Dig :: String -> Int
hostPreferredIP2Dig host = case host of
  "duro" -> 70
  "kiva" -> 71
  "hank" -> 72
  "anoa" -> 73
  "doty" -> 74
  "lunk" -> 76
  "sika" -> 77
  _      -> 69

homeUp :: String -> IO ()
homeUp host = do
  let
    ip = show (hostPreferredIP2Dig host + 100)
  runIO $ "sudo /sbin/ifconfig eth0 192.168.0." ++ ip ++
    " netmask 255.255.255.0 up"
  runIO "sudo route add default gw 192.168.0.1"
  runIO "sudo cp /etc/resolv.conf.orig /etc/resolv.conf"
  putStrLn ">>> home up"
  threadDelay $ 1 * 1000^2
  runIO "sudo cp /etc/resolv.conf.orig /etc/resolv.conf"

homeDown :: IO ()
homeDown = do
  runIO "sudo /sbin/ifconfig eth0 down || true"
  putStrLn ">>> home down"

wifiUp :: Bool -> [Char] -> IO ()
wifiUp doDhcp host = do
  runIO ("sudo", ["sv", "up", "wpa_supplicant"])
  if doDhcp
    then do
      threadDelay $ 1 * 1000^2
      runIO "dh wlan0"
    else do
      let
        ip = show (hostPreferredIP2Dig host)
      runIO $ "sudo /sbin/ifconfig wlan0 192.168.0." ++ ip ++
        " netmask 255.255.255.0 up"
      runIO "sudo route add default gw 192.168.0.1"
  putStrLn ">>> wifi up"

wifiDown :: IO ()
wifiDown = do
  runIO "sudo sv down wpa_supplicant || true"
  -- fixme: need to also manually take down wlan0/ra0?
  putStrLn ">>> wifi down"

sprintUp :: IO ()
sprintUp = do
  runIO ("sudo", ["pon", "sprint"])
  threadDelay $ 5 * 1000^2
  putStrLn ">>> sprint up"

sprintDown :: IO ()
sprintDown = do
  runIO "sudo poff sprint || true"
  putStrLn ">>> sprint down"

newSprintUp :: IO ()
newSprintUp = do
  runIO ("sudo", ["pon", "cdma"])
  threadDelay $ 5 * 1000^2
  putStrLn ">>> cdma up"

newSprintDown :: IO ()
newSprintDown = do
  runIO "sudo poff cdma || true"
  putStrLn ">>> cdma down"

attUp :: IO ()
attUp = do
  runIO ("sudo", ["pon", "att"])
  threadDelay $ 5 * 1000^2
  putStrLn ">>> att up"

attDown :: IO ()
attDown = do
  runIO "sudo poff att || true"
  putStrLn ">>> att down"

doIface :: Options -> [Char] -> IO ()
doIface opts iface = do
  -- not sure why this is ever up.. but it makes things wack
  -- todo figure that out
  runIO "sudo /sbin/ifconfig tap0 down || true"
  host <- runSL "hostname"
  let ifaces' = ifaces host
  case lookup iface ifaces' of
    Just (_desc, (fUp, fDown)) ->
      sequence fs
      where
      fs =
        if optDrop opts
          then [fDown]
          else
            if optKeep opts
              then [fUp]
              else (map (snd . snd . snd) ifaces') ++ [fUp]
    _ -> error $ "unknown interface abbr " ++ show iface ++ " from " ++
      show (map fst ifaces')
  --runIO "sudo sh -c 'echo nameserver 4.2.2.2 > /etc/resolv.conf'"
  -- wrong place for this..:
  --when (iface `notElem` ["h", "x"]) $ runIO "dh"
  -- seem to need this again sometimes wtf?
  threadDelay $ 1 * mill
  runIO "sudo /sbin/ifconfig tap0 down || true"
  when (optConn opts) $ do
    --runIO "fbre"
    threadDelay $ 2 * mill
    runIO "redan -cs"
    runIO "/home/danl/fixes/notif"

main :: IO ()
main = do
  host <- runSL "hostname"
  let
    usage = unlines $ [
      "usage: net <options> <interface-abbr>",
      "interface-abbrs are:"] ++ map (\ (a, (s, _)) -> a ++ " -> " ++ s)
      (ifaces host)
  (opts, args) <- doArgs usage defOpts options
  case args of
    [] -> doIface opts "l"
    [iface] -> doIface opts iface
    _ -> error "usage"
