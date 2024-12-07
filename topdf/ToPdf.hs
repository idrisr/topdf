{-# LANGUAGE ImportQualifiedPost #-}

module Main where

import Control.Foldl qualified as Fold
import Control.Monad
import Data.Text (pack)
import System.FilePath
import System.ProgressBar
import Turtle hiding (splitDirectories)

main :: IO ()
main = sh $ do
    tmpdir <- mktempdir "/tmp" "topdf"
    cwd <- pwd
    count_ <- fold (find (suffix "jpg") cwd) Fold.length
    pb <- liftIO $ newProgressBar defStyle 10 $ Progress 0 count_ ()
    sh $ pngToJpg pb tmpdir
    jpgToPdf tmpdir

magickArgs :: FilePath -> FilePath -> [Text]
magickArgs dest file = pack <$> [file, dest </> newName file]
  where
    newName :: FilePath -> FilePath
    newName z = takeFileName z -<.> "png"

pngToJpg :: ProgressBar () -> FilePath -> Shell ()
pngToJpg pb dest = do
    src <- pwd
    jpg <- find (suffix "jpg") src
    let z = magickArgs dest jpg
    sh $ do
        liftIO (incProgress pb 1)
        inproc "magick" z $ pure . unsafeTextToLine . pack $ jpg

jpgToPdf :: FilePath -> Shell Line
jpgToPdf src = do
    dest <- pwd
    jpg <- fold (sort (find (suffix "png") src)) Fold.list
    let name = takeBaseName dest `addExtension` "pdf"
    let inputFiles = pack <$> join jpg ++ [dest </> name]
    inproc "magick" inputFiles empty
