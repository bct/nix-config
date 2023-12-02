module ExtraWorkspaces where

import XMonad

type ExtraWorkspace = (String, String, Maybe String, Maybe (X ()))

extraWorkspaces :: [ExtraWorkspace]
extraWorkspaces = [
  -- icon, name, dir, action
  -- https://www.nerdfonts.com/cheat-sheet

    -- nf-md-brain
    ("\xf09d1", "aa", Just "aa/src", Nothing)

    -- nf-md-nix
  , ("\xf313", "nix", Just "personal/nix-config", Nothing)
  ]
