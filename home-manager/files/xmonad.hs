import XMonad

import XMonad.Util.EZConfig
import XMonad.Util.Ungrab

import XMonad.Hooks.EwmhDesktops

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.SetWMName

import XMonad.Actions.CycleWS (toggleWS)

import XMonad.Actions.TopicSpace

import XMonad.Actions.SpawnOn (spawnHere, shellPromptHere, spawnOn)
import XMonad.Actions.Volume

import XMonad.Layout.Spacing (smartSpacingWithEdge)
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.Tabbed
import XMonad.Layout.PerWorkspace

import XMonad.Util.Loggers

import Control.Monad ((<=<))
import XMonad.Actions.GridSelect

import Data.Char (ord)

import qualified Data.Map as M
import qualified XMonad.StackSet as SS

topicNameToIcon :: String -> String
topicNameToIcon name = M.findWithDefault name name iconMap
  where
    iconMap = M.fromList [
                 ("?",       " \xf128 ") -- question mark
                ,("web",     "\xfa9e ") -- globe
                ,("project", "\xf499 ") -- beaker
                ,("mi-go",   "\xfd31 ") -- ship wheel
                ,("office",  "\xf6a6 ") -- wireframe cube
              ]

myTopics :: [Topic]
myTopics = ["?", "web", "project", "mi-go", "office"]

myTopicConfig :: TopicConfig
myTopicConfig = TopicConfig
    { topicDirs = M.fromList $
        [ ("project",   "projects")
        ]

    , defaultTopicAction = const spawnShell

    , defaultTopic = "project"

    , topicActions = M.fromList $
        [
          ("?",          spawnShell >>
                         spawn "alacritty -e htop")
        , ("mi-go",      spawn "alacritty -e ssh mi-go.domus.diffeq.com")
        , ("web",        spawn "chromium")
        , ("project",     spawnShell >*> 5)
        ]
    }

myLayout = webWorkspace $ (tiled ||| Mirror tiled ||| Full)
  where
    tiled = Tall nmaster delta ratio
    nmaster = 1     -- Default number of windows in the master pane
    ratio   = 1/2   -- Default proportion of screen occupied by master pane
    delta   = 3/100 -- Percent of screen to increment by when resizing panes

    webWorkspace = onWorkspace "web" tabbed
    tabbed   = tabbedAlways shrinkText tabTheme
    tabTheme = def { fontName = "xft:Ubuntu Mono:pixelsize=18" }

------------------------------------------------------------------------
-- Window rules:

-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
myManageHook = composeAll
    [ className =? "MPlayer"        --> doFloat
    , className =? "mplayer2"       --> doFloat
    , className =? "mpv"            --> doFloat
    , className =? "feh"            --> doFloat
    , title     =? "QEMU"           --> doFloat
    ]

myXmobarPP :: PP
myXmobarPP = def
    { ppSep = ""
    -- workspaces
    , ppCurrent = yellow . wrap " " "" . topicNameToIcon
    , ppHidden = beige . wrap " " "" . topicNameToIcon
    , ppHiddenNoWindows = gray . wrap " " "" . topicNameToIcon
    , ppUrgent = red.wrap (yellow "!") (yellow "!") . topicNameToIcon

    -- layout
    -- the prefix here is weird because i don't know how to add a suffix to the workspaces
    , ppLayout = wrap (" " ++ (darkGreyToBlue "\xe0b0") ++ (beigeOnBlue " ")) ((beigeOnBlue " ") ++ (blueToBeige "\xe0b0")) . beigeOnBlue . renameLayout

    -- window titles
    , ppTitle = darkGreyOnBeige . wrap " " (" " ++ beigeToDarkGrey "\xe0b0") . shorten titleLength
    }
  where
    titleLength = 80

    -- see https://github.com/morhetz/gruvbox for colour list
    beige, yellow, red, gray :: String -> String
    beige = xmobarColor "#ebdbb2" ""
    yellow = xmobarColor "#fabd2f" ""
    red = xmobarColor "#ff5555" ""
    gray = xmobarColor "#928374" ""
    beigeOnBlue = xmobarColor "#ebdbb2" "#458588"
    darkGreyToBlue = xmobarColor "#282828" "#458588"
    blueToBeige = xmobarColor "#458588" "#ebdbb2"
    darkGreyOnBeige = xmobarColor "#282828" "#ebdbb2"
    beigeToDarkGrey = xmobarColor "#ebdbb2" "#282828"

    renameLayout :: String -> String
    renameLayout "Spacing Mirror Tall" = "Mirror Tall"
    renameLayout "Spacing Tall" = "Tall"
    renameLayout "Spacing Tabbed Simplest" = "Tabbed"
    renameLayout x = x

gsconfig2 colorizer = (buildDefaultGSConfig colorizer) { gs_cellheight = 30, gs_cellwidth = 100 }

gsConfig = (buildDefaultGSConfig colorizer) { gs_navigate = myNavigator }
  where
    myNavigator :: TwoD a (Maybe a)
    myNavigator = makeXEventhandler $ shadowWithKeymap navKeyMap navDefaultHandler
    navKeyMap   = M.fromList [
          ((0,xK_Escape), cancel)
         ,((0,xK_Return), select)
         ,((0,xK_slash) , substringSearch myNavigator)
         ,((0,xK_h)     , move (-1,0)  >> myNavigator)
         ,((0,xK_t)     , move (0,1)   >> myNavigator)
         ,((0,xK_n)     , move (0,-1)   >> myNavigator)
         ,((0,xK_s)     , move (1,0)  >> myNavigator)
         ,((0,xK_space) , setPos (0,0) >> myNavigator)
         ]
    -- The navigation handler ignores unknown key symbols
    navDefaultHandler = const myNavigator

    -- based on the default stringColorizer
    colorizer :: String -> Bool -> X (String, String)
    colorizer s active =
      if active
        then return ("#fabd2f", "black")
        else return ("#" ++ backgrounds !! (stringSumMod s $ length backgrounds), "#ebdbb2")

    stringSumMod :: String -> Int -> Int
    stringSumMod s m = mod (sum $ map ord s) m

    backgrounds :: [String]
    backgrounds = ["282828", "cc241d", "98971a", "d79921", "458588", "b16286", "689d6a", "a89984"]

wsgrid = gridselect gsConfig <=< asks $ map (\x -> (x,x)) . workspaces . config

-- gridSelectWorkspace reorders the workspaces which is incredibly annoying
promptedGoto  = wsgrid >>= flip whenJust (switchTopic myTopicConfig)
promptedShift = wsgrid >>= \x -> whenJust x $ \y -> windows (SS.greedyView y . SS.shift y)

spawnShell :: X ()
spawnShell = currentTopicDir myTopicConfig >>= spawnShellIn

spawnShellIn :: Dir -> X ()
spawnShellIn dir = do
  t <- asks (terminal . config)
  spawnHere $ "cd " ++ dir ++ " && " ++ t

main :: IO ()
main = xmonad
     . ewmh
     . withEasySB (statusBarProp "xmobar" (pure myXmobarPP)) defToggleStrutsKey
     $ myConfig

myConfig = def
    { terminal = "alacritty"
    , workspaces = myTopics
    , layoutHook = smartSpacingWithEdge 10 $ smartBorders $ myLayout
    , manageHook = myManageHook
    -- fix Java apps, e.g. the Arduino IDE
    -- https://hackage.haskell.org/package/xmonad-contrib-0.16/docs/XMonad-Hooks-SetWMName.html
    , startupHook = setWMName "LG3D"
    }
  `additionalKeysP`
    [
      -- Switch to the previously active workspace
      ("M-r", toggleWS)

      -- Launch dmenu with a custom font
    , ("M-p", spawn "dmenu_run -fn 'Ubuntu Mono-16'")

      -- Switch workspaces (GridSelect)
    , ("M-t",   promptedGoto)

      -- Move a window to a workspace (GridSelect)
    , ("M-S-t", promptedShift)

      -- Launch the action for the current topic
    , ("M-a", currentTopicAction myTopicConfig)

    -- Push window back into tiling
    , ("M-g", withFocused $ windows . SS.sink)

    , ("<XF86MonBrightnessUp>", spawn "light -T 3")
    , ("<XF86MonBrightnessDown>", spawn "light -T 0.33")

    , ("<XF86AudioLowerVolume>", lowerVolume 3 >> return ())
    , ("<XF86AudioRaiseVolume>", raiseVolume 3 >> return ())
    , ("<XF86AudioMute>", toggleMute    >> return ())
    ]