--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Main where

--------------------------------------------------------------------------------
import           Control.Applicative        ((<$>), (<*>))
import           Data.Text                  (Text)
import qualified Data.Text                  as T
--  import qualified Snap.Blaze                 as Snap
import qualified Snap.Core                  as Snap
import qualified Snap.Http.Server           as Snap
import qualified Text.Blaze.Html5           as H
import           Text.Digestive
import           Text.Digestive.Blaze.Html5
import           Text.Digestive.Snap

------------------------------------------------------------------------

import Text.Blaze.Html (Html)
import Snap.Core (MonadSnap (..), addHeader, modifyResponse, writeLBS, writeText)
-- import Text.Blaze.Html.Renderer.Utf8 (renderHtml)
import Text.Blaze.Html.Renderer.Pretty (renderHtml)


blaze :: Snap.MonadSnap m => Html -> m ()
blaze response = do
    modifyResponse $ addHeader "Content-Type" "text/html; charset=UTF-8"
    writeText $ T.pack $ renderHtml response



--------------------------------------------------------------------------------
type Product = Text


--------------------------------------------------------------------------------
type Quantity = Int


--------------------------------------------------------------------------------
data Order = Order
    { orderProduct  :: Product
    , orderQuantity :: Quantity
    } deriving (Show)


--------------------------------------------------------------------------------
orderForm :: Monad m => Formlet Text m Order
orderForm def = Order
    <$> "product"  .: text                              (orderProduct  <$> def)
    <*> "quantity" .: stringRead "Can't parse quantity" (orderQuantity <$> def)


--------------------------------------------------------------------------------
orderView :: View H.Html -> H.Html
orderView view = do
    childErrorList "" view

    label     "product" view "Product: "
    inputText "product" view
    H.br

    label     "quantity" view "Quantity: "
    inputText "quantity" view
    H.br


--------------------------------------------------------------------------------
ordersForm :: Monad m => Form Text m [Order]
ordersForm = "orders" .: listOf orderForm (Just def)
  where
    def =
        [ Order "Milk"  2
        , Order "Bread" 3
        ]


--------------------------------------------------------------------------------
ordersView :: View H.Html -> H.Html
ordersView view = do
    label     "orders.indices" view "(Usually hidden) Indices: "
    inputText "orders.indices" view
    H.br

    mapM_ orderView $ listSubViews "orders" view


--------------------------------------------------------------------------------
site :: Snap.Snap ()
site = do
    r <- runForm "test" ordersForm
    case r of
        (view, Nothing) -> do
            let view' = fmap H.toHtml view
            blaze $ form view' "/" $ do
                ordersView view'
                H.br
                inputSubmit "Submit"
        (_, Just order) ->
            blaze $ do
                H.h1 "OK"
                H.toHtml $ show order


--------------------------------------------------------------------------------
main :: IO ()
main = Snap.httpServe Snap.defaultConfig site
