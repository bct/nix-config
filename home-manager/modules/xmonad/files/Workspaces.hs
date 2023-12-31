module Workspaces where

import XMonad

import XMonad.Actions.SpawnOn (spawnHere)
import XMonad.Actions.TopicSpace

import qualified Data.Map as M
import Data.Maybe (mapMaybe)

import ExtraWorkspaces (ExtraWorkspace, extraWorkspaces)

web :: String
web = "web"

topicNameToIcon :: String -> String
topicNameToIcon name = M.findWithDefault name name iconMap ++ " "
  where
    iconMap :: M.Map String String
    iconMap = M.fromList $ [
                 ("?",     " \xf128") -- question mark
                ,(web,     "\xeb01")  -- globe
              ] ++ map (\(icon, name, _, _) -> (name, icon)) extraWorkspaces

topicNameWithIconPrefix :: String -> String
topicNameWithIconPrefix name = (topicNameToIcon name) ++ " " ++ name

topics :: [Topic]
topics = ["?", web] ++ map (\(icon, name, _, _) -> name) extraWorkspaces

extraTopicDirs :: [(String, String)]
extraTopicDirs = mapMaybe doMap extraWorkspaces
  where
    doMap :: ExtraWorkspace -> Maybe (String, String)
    doMap = (\(_, name, maybeDir, _) -> fmap (\dir -> (name, dir)) maybeDir)

extraTopicActions :: [(String, X ())]
extraTopicActions = mapMaybe doMap extraWorkspaces
  where
    doMap :: ExtraWorkspace -> Maybe (String, X())
    doMap = (\(_, name, _, maybeAct) -> fmap (\act -> (name, act)) maybeAct)

topicConfig :: TopicConfig
topicConfig = TopicConfig
    { topicDirs = M.fromList extraTopicDirs
    , defaultTopicAction = const spawnShell
    , defaultTopic = "project"
    , topicActions = M.fromList $
        [
          ("?",            spawnShell >>
                           spawn "alacritty -e htop")
        , (web,            spawn "chromium")
        ] ++ extraTopicActions
    }

spawnShell :: X ()
spawnShell = currentTopicDir topicConfig >>= spawnShellIn

spawnShellIn :: Dir -> X ()
spawnShellIn dir = do
  t <- asks (terminal . config)
  spawnHere $ "cd " ++ dir ++ " && " ++ t
