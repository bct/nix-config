import XMonad

import XMonad.Util.EZConfig
import XMonad.Util.Ungrab

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook

import XMonad.Actions.CycleWS (toggleWS)
import XMonad.Actions.FloatKeys (keysMoveWindowTo)
import XMonad.Actions.TopicSpace

import XMonad.Actions.SpawnOn (spawnHere, shellPromptHere, spawnOn)
import XMonad.Actions.Volume

import XMonad.Actions.PhysicalScreens

import XMonad.Layout.Spacing (smartSpacingWithEdge)
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.Tabbed
import XMonad.Layout.PerWorkspace

import XMonad.Operations (restart)

import XMonad.Util.Loggers
import XMonad.Util.NamedScratchpad
import XMonad.Util.WindowProperties (Property(ClassName), hasProperty)

import Control.Monad ((<=<), when)
import XMonad.Actions.GridSelect

import Data.Char (ord)
import Data.Ratio ((%))

import Text.Printf

import qualified Data.Map as M
import qualified XMonad.StackSet as SS

import qualified Workspaces

scratchpads :: [NamedScratchpad]
scratchpads = [
    NS "music" "supersonic" (className =? "Supersonic")
        (customFloating $ SS.RationalRect (1/4) (1/4) (2/4) (2/4))
  ]

myLayout = webWorkspace $ (tiled ||| Mirror tiled ||| Full)
  where
    tiled = Tall nmaster delta ratio
    nmaster = 1     -- Default number of windows in the master pane
    ratio   = 1/2   -- Default proportion of screen occupied by master pane
    delta   = 3/100 -- Percent of screen to increment by when resizing panes

    webWorkspace = onWorkspace Workspaces.web tabbed
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
    , ppCurrent = yellow . wrap " " "" . Workspaces.topicNameToIcon
    , ppHidden = beige . wrap " " "" . Workspaces.topicNameToIcon
    , ppHiddenNoWindows = gray . wrap " " "" . Workspaces.topicNameToIcon
    , ppVisible = blue . wrap " " "" . Workspaces.topicNameToIcon
    , ppUrgent = red.wrap (yellow "!") "" . Workspaces.topicNameToIcon

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
    blue = xmobarColor "#83a598" ""
    yellow = xmobarColor "#fabd2f" ""
    red = xmobarColor "#cc241d" ""
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

gsConfig = (buildDefaultGSConfig colorizer) { gs_navigate = myNavigator, gs_font = "xft:UbuntuMono Nerd Font:pixelsize=18" }
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

    -- gruvbox
    backgrounds :: [String]
    backgrounds = ["282828", "cc241d", "98971a", "d79921", "458588", "b16286", "689d6a"]

wsgrid = gridselect gsConfig <=< asks $ map (\x -> (Workspaces.topicNameWithIconPrefix(x),x)) . workspaces . config

-- gridSelectWorkspace reorders the workspaces which is incredibly annoying
promptedGoto  = wsgrid >>= flip whenJust (switchTopic Workspaces.topicConfig)
promptedShift = wsgrid >>= \x -> whenJust x $ \y -> windows (SS.greedyView y . SS.shift y)

-- https://github.com/KnairdA/nixos_home/blob/80798e3345bd4f872c8d852e74bc3dc591bcd3b2/gui/conf/xmonad.hs
withCurrentScreen     f = withWindowSet     $ \ws -> f (SS.current ws)
withCurrentScreenRect f = withCurrentScreen $ \s  -> f (screenRect (SS.screenDetail s))

screenResolution = withCurrentScreenRect $ \r -> return (fromIntegral $ rect_width r, fromIntegral $ rect_height r)

centreWindow :: Window -> X()
centreWindow w = do
  -- https://xmonad.haskell.narkive.com/szN8mp3p/get-width-and-height-of-current-screen
  (screenWidth, screenHeight) <- screenResolution
  spawn $ printf "dunstify %d %d" (screenWidth `div` 2) (screenHeight `div` 2)
  keysMoveWindowTo (screenWidth `div` 2, screenHeight `div` 2) (1%2, 1%2) w

fixupFloatingWindowForCurrentDisplay :: X()
fixupFloatingWindowForCurrentDisplay = withFocused fixupWindow
  where
    fixupWindow :: Window -> X()
    fixupWindow w = do shouldResize <- isMyWindow w
                       -- only do the move/resize when the scratchpad got toggled _on_, not off
                       when shouldResize $ centreWindow w

    isMyWindow :: Window -> X Bool
    isMyWindow = hasProperty (ClassName "Supersonic")


myConfig = ewmh $ def
    { terminal = "alacritty"
    , workspaces = Workspaces.topics
    , layoutHook = smartSpacingWithEdge 10 $ smartBorders $ myLayout
    , manageHook = myManageHook <+> (namedScratchpadManageHook scratchpads)

    , normalBorderColor  = "#ebdbb2"
    , focusedBorderColor = "#fe8019"
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
    , ("M-a", currentTopicAction Workspaces.topicConfig)

    -- Push window back into tiling
    , ("M-g", withFocused $ windows . SS.sink)

     -- Move monitor focus left/right
    , ("M-o", onPrevNeighbour def SS.view)
    , ("M-e", onNextNeighbour def SS.view)

    -- Move window to left/right monitor
    , ("M-S-o", onPrevNeighbour def SS.shift)
    , ("M-S-e", onNextNeighbour def SS.shift)

    -- Adjust brightness
    , ("<XF86MonBrightnessUp>", spawn "light -T 3")
    , ("<XF86MonBrightnessDown>", spawn "light -T 0.33")

    -- Adjust volume
    , ("<XF86AudioLowerVolume>", lowerVolume 3 >> return ())
    , ("<XF86AudioRaiseVolume>", raiseVolume 3 >> return ())
    , ("<XF86AudioMute>", toggleMute    >> return ())

    -- Media player controls
    , ("<XF86AudioPlay>", spawn "playerctl play-pause")
    , ("<XF86AudioPrev>", spawn "playerctl previous")
    , ("<XF86AudioNext>", spawn "playerctl next")

    , ("M-m", (namedScratchpadAction scratchpads "music") >> fixupFloatingWindowForCurrentDisplay)
    , ("M-c", withFocused $ centreWindow)

    -- Restart, but do not recompile. Maintain the existing window state.
    , ("M-q", restart "xmonad" True)

    -- Lock the screen
    , ("M-S-l", spawn "sxlock")
    ]

main :: IO ()
main = xmonad
     . withEasySB (statusBarProp "xmobar" (pure myXmobarPP)) defToggleStrutsKey
     $ withUrgencyHook NoUrgencyHook
     $ myConfig
        {
          -- fix Java apps, e.g. the Arduino IDE
          -- https://hackage.haskell.org/package/xmonad-contrib-0.16/docs/XMonad-Hooks-SetWMName.html
          --
          -- this has to happen here so that it overrides the WM name that
          -- "ewmh" sets up
          -- https://wiki.haskell.org/Xmonad/Frequently_asked_questions#Using_SetWMName_with_EwmhDesktops
          startupHook = startupHook myConfig >> setWMName "LG3D"
        }
