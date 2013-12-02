import System.Environment
import System.Process

sys :: String -> [String] -> IO ()
sys cmd args = rawSystem cmd args >> return ()

sudo, ifconfig, eth, wi :: [String] -> IO ()
sudo = sys "sudo"
ifconfig = sudo . ("ifconfig" :)
eth = ifconfig . ("eth0" :)
wi = ifconfig . ("wlan0" :)
sv = sudo . ("sv" :)

main :: IO ()
main = do
    args <- getArgs
    case args of
      ["wi"] -> sv ["force-restart", "wpa-supplicant"] >> sys "dhc" ["wlan0"]
      ["eth"] -> eth ["up"] >> sys "dhc" ["eth0"]
      ["down"] -> wi ["down"] >> eth ["down"]
      ["tun"] -> sudo ["sv", "restart", "sshproxy"]
      _ -> error "usage: nets <down|eth|wi|tun>"
