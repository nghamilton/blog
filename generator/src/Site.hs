{-# LANGUAGE OverloadedStrings #-}

import qualified GHC.IO.Encoding as E

import           Data.Monoid (mappend)
import           Data.Time   (getCurrentTime)

import           Hakyll

import           Links
import           People
import           Posts
import           Projects
import           Talks
import           Util.Index
import           Util.Pandoc

main :: IO ()
main = do
  E.setLocaleEncoding E.utf8
  -- TODO possibly load config from a file?
  pandocMathCompilerFns <- setupPandocMathCompiler $ PandocMathCompilerConfig 1000 ["prftree"]
  let
    pandocMathCompiler = pmcfCompiler pandocMathCompilerFns
    renderPandocMath = pmcfRenderPandoc pandocMathCompilerFns

  nowish <- getCurrentTime

  hakyll $ do
    match "images/**" $ do
        route   idRoute
        compile copyFileCompiler

    match "fonts/**" $ do
        route   idRoute
        compile copyFileCompiler

    match "js/**" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/**" $ do
        route   idRoute
        compile compressCssCompiler

    match "share/**" $ do
        route   idRoute
        compile copyFileCompiler

    match "location.html" $ do
        route niceRoute
        compile $ do
          let locationCtx =
                constField "location-active" "" `mappend` defaultContext

          getResourceBody
            >>= loadAndApplyTemplate "templates/default.html" locationCtx
            >>= relativizeUrls
            >>= removeIndexHtml

    match "contact.html" $ do
        route niceRoute
        compile $ do
          let contactCtx =
                constField "contact-active" "true" `mappend` defaultContext
          getResourceBody
            >>= loadAndApplyTemplate "templates/default.html" contactCtx
            >>= relativizeUrls
            >>= removeIndexHtml

    talkRules pandocMathCompilerFns

    projectRules pandocMathCompilerFns

    peopleRules pandocMathCompilerFns

    postRules pandocMathCompilerFns

    match "index.html" $ do
        route $ setExtension "html"
        compile $ do
            posts <- fmap (take 5) . recentFirst =<< loadAll "posts/**"
            courseCtx <- getCourseLinksCtx nowish defaultContext

            let indexCtx =
                    courseCtx                                `mappend`
                    constField "home-active" ""              `mappend`
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                -- >>= renderPandocMath
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls
                >>= removeIndexHtml

    match "templates/*" $ compile templateBodyCompiler

    -- http://jaspervdj.be/hakyll/tutorials/05-snapshots-feeds.html
    let
      rss name render' =
        create [name] $ do
          route idRoute
          compile $ do
            let feedCtx = postCtx `mappend` bodyField "description"
            posts <- fmap (take 10) . recentFirst =<< loadAllSnapshots "posts/**" "post-content"
            render' feedConfiguration feedCtx posts

    rss "rss.xml" renderRss
    rss "atom.xml" renderAtom

feedConfiguration :: FeedConfiguration
feedConfiguration =
  FeedConfiguration {
      feedTitle       = "Queensland Functional Programming Lab"
    , feedDescription = ""
    , feedAuthorName  = "QFPL"
    , feedAuthorEmail = "contact@qfpl.io"
    , feedRoot        = "https://blog.qfpl.io"
    }
