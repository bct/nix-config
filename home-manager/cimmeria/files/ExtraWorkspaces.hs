module ExtraWorkspaces where

import XMonad

type ExtraWorkspace = (String, String, Maybe String, Maybe (X ()))

extraWorkspaces :: [ExtraWorkspace]
extraWorkspaces = [
  -- icon, name, dir, action
  -- https://www.nerdfonts.com/cheat-sheet

    -- beaker
    ("\xf499", "project", Just "projects", Nothing)

   -- ship wheel
  , ("\xf0833", "mi-go", Nothing, Just $ spawn "alacritty -e ssh bct@mi-go.domus.diffeq.com")

    -- nf-md-email
  , ("\xf01ee", "mail", Nothing, Just $ spawn "alacritty -e ssh bct@mail.domus.diffeq.com")

    -- wireframe cube
  , ("\xf01a7", "slicer", Nothing, Just $ spawn "cura")

    -- film
  , ("\xf008", "kino", Nothing, Nothing)
  ]
