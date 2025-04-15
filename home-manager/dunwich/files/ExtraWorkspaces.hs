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

    -- nf-md-email
  , ("\xf01ee", "mail", Nothing, Just $ spawn "chromium --new-window mail.google.com")

    -- nf-md-slack
  , ("\xf04b1", "slack", Nothing, Just $ spawn "slack")

    -- film
  , ("\xf008", "kino", Nothing, Nothing)
  ]
