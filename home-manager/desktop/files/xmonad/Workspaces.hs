module Workspaces where

import XMonad

import XMonad.Actions.SpawnOn (spawnHere)
import XMonad.Actions.TopicSpace

import qualified Data.Map as M

-- icons
-- https://www.nerdfonts.com/cheat-sheet
iconQuestionMark :: String
iconQuestionMark = "\xf128"

iconGlobe :: String
iconGlobe = "\xeb01"

iconBeaker :: String
iconBeaker = "\xf499"

iconShipWheel :: String
iconShipWheel = "\xf0833"

iconWireframeCube :: String
iconWireframeCube = "\xf01a7"

iconFilm :: String
iconFilm = "\xf008"

iconMail :: String
iconMail = "\xf01ee"

-- topic names
--
-- this is a hack, would really prefer not to include the icon in the topic
-- name, but it's the easiest way to get icons in the gridselect.
project :: String
project = iconBeaker ++ "  project"

miGo :: String
miGo = iconShipWheel ++ "  mi-go"

slicer :: String
slicer = iconWireframeCube ++ "  slicer"

web :: String
web = iconGlobe ++ "  web"

kino ::String
kino = iconFilm ++ "  kino"

mail :: String
mail = iconMail ++ "  mail"

topicNameToIcon :: String -> String
topicNameToIcon name = M.findWithDefault name name iconMap ++ " "
  where
    iconMap :: M.Map String String
    iconMap = M.fromList [
                 ("?",     " " ++ iconQuestionMark)
                ,(web,     iconGlobe)
                ,(project, iconBeaker)  -- beaker
                ,(miGo,    iconShipWheel) -- ship wheel
                ,(slicer,  iconWireframeCube) -- wireframe cube
                ,(kino,    iconFilm)  -- film
                ,(mail,    iconMail)  -- nf-md-email
              ]

topics :: [Topic]
topics = ["?", web, project, miGo, slicer, mail, kino]

topicConfig :: TopicConfig
topicConfig = TopicConfig
    { topicDirs = M.fromList $
        [ (project,   "projects")
        ]

    , defaultTopicAction = const spawnShell

    , defaultTopic = project

    , topicActions = M.fromList $
        [
          ("?",            spawnShell >>
                           spawn "alacritty -e htop")
        , (miGo,           spawn "alacritty -e ssh bct@mi-go.domus.diffeq.com")
        , (web,            spawn "chromium")
        , (project,        spawnShell >*> 5)
        , (mail,           spawn "alacritty -e ssh bct@mail.domus.diffeq.com")
        ]
    }

spawnShell :: X ()
spawnShell = currentTopicDir topicConfig >>= spawnShellIn

spawnShellIn :: Dir -> X ()
spawnShellIn dir = do
  t <- asks (terminal . config)
  spawnHere $ "cd " ++ dir ++ " && " ++ t
