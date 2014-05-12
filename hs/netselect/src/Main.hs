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
      ["dhcp-debug"] -> sys "dhc" ["-v", "wlan0"]
      ["down"] -> wi ["down"] >> eth ["down"]
      ["eth"] -> eth ["up"] >> sys "dhc" ["eth0"]
      ["tun"] -> sudo ["sv", "restart", "sshproxy"]
      ["wi"] -> sv ["force-restart", "wpa-supplicant"] >> sys "dhc" ["wlan0"]
      ["wi-debug"] -> do
        sv ["force-stop", "wpa-supplicant"]
        sudo ["wpa_supplicant", "-d", "-Dwext", "-iwlan0", 
            "-c/etc/wpa_supplicant.conf"]
      _ -> error "usage: nets <dhcp-debug | down | eth | tun | wi | wi-debug>"
