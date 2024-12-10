{-# LANGUAGE ImportQualifiedPost #-}

module Main where

import Control.Foldl qualified as Fold
import Control.Monad
import Data.Ratio
import Data.Text (pack)
import Options.Applicative
import System.Directory
import System.FilePath
import System.ProgressBar
import Turtle hiding (g, header, input, o, output, splitDirectories, x, (%))

data Params = Params FilePath FilePath
    deriving (Show)

data Dirs = Dirs
    { inputDir :: FilePath
    , outputDir :: FilePath
    , tempDir :: FilePath
    }
    deriving (Show)

main :: IO ()
main = do
    Params i o <- cmdLineParser
    sh $ do
        tmpdir <- mktempdir "/tmp" "topdf"
        dirs <- liftIO $ Dirs <$> makeAbsolute i <*> makeAbsolute o <*> pure tmpdir
        count_ <- fold (find (suffix "jpg") i) Fold.length
        pb <- liftIO $ newProgressBar defStyle 10 $ Progress 0 (count_ + 1) ()
        sh $ pngToJpg dirs pb
        jpgToPdf dirs

magickArgs :: FilePath -> Dirs -> [Text]
magickArgs file (Dirs _ _ tmp) = pack <$> [file, tmp </> newName file]
  where
    newName :: FilePath -> FilePath
    newName z = takeFileName z -<.> "png"

pngToJpg :: Dirs -> ProgressBar () -> Shell ()
pngToJpg dirs@(Dirs input _ _) pb = do
    jpg <- find (suffix "jpg") input
    let z = magickArgs jpg dirs
    sh $ do
        liftIO (incProgress pb 1)
        inproc "magick" z $ pure . unsafeTextToLine . pack $ jpg

jpgToPdf :: Dirs -> Shell ()
jpgToPdf (Dirs input output tmp) = do
    png <- fold (sort (find (suffix "png") tmp)) Fold.list
    let name = takeBaseName input `addExtension` "pdf"
    let inputFiles = pack <$> join png ++ [tmp </> name]
    sh $ inproc "magick" inputFiles empty
    cp (tmp </> name) (output </> name)

cmdLineParser :: IO Params
cmdLineParser =
    execParser $
        info
            (parseParams <**> helper)
            ( fullDesc
                <> progDesc "take a directory of jpgs and create a pdf"
                <> header "take a directory of jpgs and create a pdf"
            )

parseParams :: Parser Params
parseParams =
    Params
        <$> strOption
            ( metavar "<INPUT>"
                <> short 'i'
                <> long "input"
                <> help "directory containing jpgs to collate"
            )
        <*> strOption
            ( metavar "<OUTPUT>"
                <> short 'o'
                <> long "output"
                <> help "destination for pdf"
            )
