{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators     #-}

module Example (startApp) where

import           Network.HTTP.Types.Status      (status404)
import           Network.Wai                    (responseFile)
import           Network.Wai.Application.Static (defaultWebAppSettings)
import           Network.Wai.Handler.Warp       (defaultSettings, setPort,
                                                 setTimeout)
import           Network.Wai.Handler.WarpTLS    (runTLS, tlsSettings)
import           Servant                        (Application, Proxy (..), Raw,
                                                 Server, serve,
                                                 serveDirectoryWith)
import           WaiAppStatic.Types             (StaticSettings (..),
                                                 unsafeToPiece)

type API = Raw

certLoc :: FilePath
certLoc = "certificate.pem"

keyLoc :: FilePath
keyLoc = "key.pem"

-- When running in production set the port explicitly to 443
startApp :: IO ()
startApp = runTLS tlsConf serverConf app
  where
    tlsConf    = tlsSettings certLoc keyLoc
    serverConf = setTimeout 15 . setPort 3000 $ defaultSettings

app :: Application
app = serve api server

api :: Proxy API
api = Proxy

server :: Server API
server = serveDirectoryWith settings
  where
    dfs = defaultWebAppSettings rootPath
    ixs  = map unsafeToPiece ["index.html", "index.htm"]
    settings = dfs{ ssIndices    = ixs
                  , ss404Handler = Just custom404
                  , ssUseHash    = False
                  }

rootPath :: FilePath
rootPath = "/var/www"

html404 :: FilePath
html404 = "404.html"

custom404 :: Application
custom404 _ sendResponse = sendResponse response
  where
    headers = [("Content-Type", "text/html; charset=UTF-8")]
    response = responseFile status404 headers html404 Nothing
