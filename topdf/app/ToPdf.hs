{-# LANGUAGE ImportQualifiedPost #-}

module Main where

import Control.Foldl qualified as Fold
import Control.Monad
import Data.Text (pack)
import Data.Text.Lazy qualified as TL
import System.FilePath
import System.ProgressBar
import Turtle hiding (splitDirectories)

main :: IO ()
main = sh $ do
    tmpdir <- mktempdir "/tmp" "topdf"
    cwd <- pwd
    count_ <- fold (find (suffix "jpg") cwd) Fold.length
    pb <- liftIO $ newProgressBar myStyle 10 $ Progress 0 count_ ()
    sh $ convert pb tmpdir
    topdf tmpdir

newName :: FilePath -> FilePath
newName z = takeFileName z -<.> "png"

command :: FilePath -> FilePath -> [Text]
command dest file = pack <$> [file, dest </> newName file]

convert :: ProgressBar () -> FilePath -> Shell ()
convert pb dest = do
    src <- pwd
    jpg <- find (suffix "jpg") src
    let z = command dest jpg
    sh $ do
        liftIO (incProgress pb 1)
        inproc "magick" z $ pure . unsafeTextToLine . pack $ jpg

topdf :: FilePath -> Shell Line
topdf src = do
    dest <- pwd
    jpgt <- fold (sort (find (suffix "png") src)) Fold.list
    let name = takeBaseName dest `addExtension` "pdf"
    let inputFiles = pack <$> join jpgt ++ [dest </> name]
    inproc "magick" inputFiles empty

myStyle :: Style s
myStyle =
    Style
        { styleOpen = "["
        , styleClose = "]"
        , styleDone = '='
        , styleCurrent = '>'
        , styleTodo = '.'
        , stylePrefix = percentage
        , stylePostfix = exact
        , styleWidth = ConstantWidth 60
        , styleEscapeOpen = const TL.empty
        , styleEscapeClose = const TL.empty
        , styleEscapeDone = const TL.empty
        , styleEscapeCurrent = const TL.empty
        , styleEscapeTodo = const TL.empty
        , styleEscapePrefix = const TL.empty
        , styleEscapePostfix = const TL.empty
        , styleOnComplete = WriteNewline
        }
