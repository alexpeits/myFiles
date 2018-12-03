import System.IO
import System.Exit

import Data.Maybe (isJust)

import Control.Monad.IO.Class

import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.InsertPosition
import XMonad.Layout.NoBorders
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.Fullscreen
import XMonad.Layout.Named
import XMonad.Util.Run (spawnPipe, safeSpawn, runProcessWithInput)
import XMonad.Util.NamedWindows
import XMonad.Util.Ungrab
import XMonad.Util.NamedScratchpad
import XMonad.Actions.CycleWS
import XMonad.Actions.WindowBringer

import qualified XMonad.StackSet as W

import qualified Data.Map        as M
import Graphics.X11.ExtraTypes.XF86

------------------------------------------------------------------------
-- Terminal
myTerminal = "/usr/bin/gnome-terminal"

-- Screensaver
-- myScreensaver = "slock"
myScreensaver = "xscreensaver-command -lock"

-- Region screenshot
mySelectScreenshot = "gnome-screenshot -a"

-- Window screenshot
myWindowScreenshot = "scrot ~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png -s"

-- Fullscreen screenshot
myScreenshot = "gnome-screenshot"

-- Launcher
-- myLauncher = "dmenu_run"
myLauncher = unwords
  [ "rofi -modi drun,run -show drun"
  , "-matching fuzzy -no-levenshtein-sort -sort"
  , "-theme lb -show-icons -kb-mode-next Alt+m"
  ]

rofiGoToWinArgs =
  [ "-dmenu"
  , "-i", "-p", "Go to window"
  , "-matching", "fuzzy", "-no-levenshtein-sort", "-sort"
  , "-theme", "lb"
  ]

-- Scratchpads
myScratchpads =
  [ NS "scratch" "gedit --class=Scratch ~/.scratch.txt" (className =? "Scratch") smallRectBR
  -- , NS "scratch" "gnome-terminal --role=scratch -- em ~/.scratch.org" (role =? "scratch") smallRectBR
  -- , NS "zeal" "zeal" (className =? "Zeal") largeRectM
  , NS "docs" "firefox --new-instance --class Docs -P Simple https://hoogle.haskell.org https://www.haskell.org/hoogle/" (className =? "Docs") medRectBR
  , NS "dropTerm" "gnome-terminal --role=dropTerm" (role =? "dropTerm") dropDown
  ]
  where role = stringProperty "WM_WINDOW_ROLE"
        title = stringProperty "WM_NAME"

myScratchAction = namedScratchpadAction myScratchpads  -- helper

-- Various geometries
--
-- helpers for RationalRect
myTopMargin = 20 / 1080  -- depends on xmobar height
middleRR w h = W.RationalRect ((1 - w) / 2) ((1 - h) / 2) w h
topRightRR w h = W.RationalRect (1 - w) myTopMargin w h
topLeftRR w h = W.RationalRect 0 myTopMargin w h
botRightRR w h = W.RationalRect (1 - w) (1 - h) w h
botLeftRR w h = W.RationalRect 0 (1 - h) w h
dropDownRR w h = W.RationalRect 0 myTopMargin w h

largeRectM = customFloating $ middleRR 0.8 0.8
medRectM = customFloating $ middleRR 0.65 0.75
medRectBR = customFloating $ botRightRR 0.4 0.45
smallRectTR = customFloating $ topRightRR 0.25 0.3
smallRectBR = customFloating $ botRightRR 0.3 0.4
dropDown = customFloating $ dropDownRR 1 0.4

------------------------------------------------------------------------
-- Workspaces
--
{-myWorkspaces = ["1:term","2:web","3:code","4:vm","5:media"] ++ map show [6..9]-}
{- myWorkspaces = map show [1..9] -}
myWorkspaces =
    [ "1:main"
    , "2:term"
    , "3:emacs"
    , "4:chat"
    , "5:music"
    , "6:vm"
    ] ++ map show [7..9]
nWorkspace = (myWorkspaces !!) . pred  -- helper

------------------------------------------------------------------------
-- Window rules
-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
myManageHook = composeAll
    [
      className =? "Emacs" --> doShift (nWorkspace 3)
    , className =? "Slack" --> doShift (nWorkspace 4)
    , className =? "Skype" --> doShift (nWorkspace 4)
    , className =? "Pidgin" --> doShift (nWorkspace 4)
    , className =? "vlc" --> doShift (nWorkspace 5)
    , className =? "Spotify" --> doShift (nWorkspace 5)
    , className =? "spotify" --> doShift (nWorkspace 5)
    , className =? "VirtualBox" --> doShift (nWorkspace 6)
    , className =? "VirtualBox Manager" --> doShift (nWorkspace 6)

    -- , className =? "Nautilus" --> medRectM
    , className =? "Gnome-calculator" --> smallRectTR

    , className =? "Indicator.py" --> doFloatAt 0.43 0.43
    , className =? "Zenity" --> doFloatAt 0.43 0.43
    , className =? "Gsimplecal" --> doFloatAt 0.815 0.022

    , className =? "stalonetray" --> doIgnore
    , isFullscreen --> doFullFloat
    ]

------------------------------------------------------------------------
-- Layouts
-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--
-- on hold: Accordion, Full
myLayout = avoidStruts $
  Tall nmaster delta halfRatio
  ||| named "Focus" (Mirror (Tall nmaster delta bigMasterRatio))
  ||| ThreeColMid nmaster delta halfRatio
  ||| named "Tabs" simpleTabbed
  where
     -- The default number of windows in the master pane
     nmaster = 1
     -- Percent of screen to increment by when resizing panes
     delta = 3/100
     -- Ratios
     halfRatio = 1/2
     bigMasterRatio = 75/100

------------------------------------------------------------------------
-- Notifications

data LibNotifyUrgencyHook = LibNotifyUrgencyHook deriving (Read, Show)

instance UrgencyHook LibNotifyUrgencyHook where
    urgencyHook LibNotifyUrgencyHook w = do
        name     <- getName w
        Just idx <- W.findTag w <$> gets windowset
        safeSpawn "notify-send" [show name, "workspace " ++ idx]

------------------------------------------------------------------------
-- Colors and borders
-- Currently based on the ir_black theme.
--
myNormalBorderColor  = "#626262"
myFocusedBorderColor = "#ffbab5"

-- Color of current window title in xmobar.
-- xmobarTitleColor = "#FFB6B0"
xmobarTitleColor = "#d58966"

-- Color of current workspace in xmobar.
-- xmobarCurrentWorkspaceColor = "#B7FF85"
xmobarCurrentWorkspaceColor = "#2ec8a2"

xmobarLayoutColor = "#676767"
xmobarSepColor = xmobarLayoutColor

-- Width of the window border in pixels.
myBorderWidth = 1

------------------------------------------------------------------------
-- Key bindings

-- helpers
isActiveWS :: WindowSpace -> Bool
isActiveWS ws@(W.Workspace tag _ _) = isActive && isNotScratch
  where isActive = isJust $ W.stack ws
        isNotScratch = tag /= "NSP"

getScreenshot :: X ()
getScreenshot = do
  scrStr <-
    runProcessWithInput "rofi-dmenu-args.sh"
    ["Screenshot type", "Area", "Window", "Full"] ""
  case filter (/= '\n') scrStr of
    "Area"   -> spawn mySelectScreenshot
    "Window" -> unGrab >> spawn myWindowScreenshot
    "Full"   -> spawn myScreenshot
    _        -> return ()

--
-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
myModMask = mod4Mask

myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
  ----------------------------------------------------------------------
  -- Custom key bindings
  --

  -- Start a terminal.  Terminal to start is specified by myTerminal variable.
  [ ((modMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)

  -- Lock the screen using command specified by myScreensaver.
  , ((modMask .|. controlMask, xK_l), spawn myScreensaver)

  -- Spawn the launcher using command specified by myLauncher.
  -- Use this to launch programs without a key binding.
  , ((modMask, xK_p), spawn myLauncher)

  -- Move to workspace of selected window
  , ((modMask .|. shiftMask, xK_p) , gotoMenuArgs' "rofi" rofiGoToWinArgs)

  -- scratchpads
  , ((mod4Mask, xK_z), myScratchAction "dropTerm")
  , ((mod4Mask .|. shiftMask, xK_n), myScratchAction "scratch")
  , ((mod4Mask .|. shiftMask, xK_d), myScratchAction "docs")

  -- Ask for screenshot type and take screenshot
  , ((modMask .|. controlMask .|. shiftMask, xK_p), getScreenshot)

  -- Basically toggles xmobar (useful for fullscreen), requires lowerOnStart=True
  , ((mod4Mask .|. shiftMask, xK_f), sendMessage ToggleStruts)

  -- Mute/unmute volume.
  -- There is a bug with this one:
  -- , ((0, xF86XK_AudioMute), spawn "amixer -q set Master toggle")
  -- Workaround
  , ((0, xF86XK_AudioMute), spawn "amixer -D pulse set Master 1+ toggle")

  -- Decrease volume.
  , ((0, xF86XK_AudioLowerVolume), spawn "amixer -q set Master 5%-")

  -- Increase volume.
  , ((0, xF86XK_AudioRaiseVolume), spawn "amixer -q set Master 5%+")

  -- Toggle mic
  , ((0, xF86XK_AudioMicMute), spawn "amixer -q set Capture toggle")

  -- Next track
  , ((mod4Mask, xK_F2), spawn "playerctl previous")

  -- Previous track
  , ((mod4Mask, xK_F3), spawn "playerctl play-pause")

  -- Play/pause
  , ((mod4Mask, xK_F4), spawn "playerctl next")

  -- Increase brightness.
  , ((0, xF86XK_MonBrightnessUp),
     spawn "xbacklight -inc 5%")
     -- spawn "sudo /home/alex/bin/brightness.sh up")

  -- Decrease brightness.
  , ((0, xF86XK_MonBrightnessDown),
     spawn "xbacklight -dec 5%")
     -- spawn "sudo /home/alex/bin/brightness.sh down")

  --------------------------------------------------------------------
  -- "Standard" xmonad key bindings
  --

  -- Close focused window.
  , ((modMask .|. shiftMask, xK_c), kill)

  -- Cycle through the available layout algorithms.
  , ((modMask, xK_space), sendMessage NextLayout)

  --  Reset the layouts on the current workspace to default.
  , ((modMask .|. shiftMask, xK_space), setLayout $ XMonad.layoutHook conf)

  -- Move focus to the next window.
  , ((modMask, xK_Tab), windows W.focusDown)

  -- Move focus to the next window.
  , ((modMask, xK_j), windows W.focusDown)

  -- Move focus to the previous window.
  , ((modMask, xK_k), windows W.focusUp)

  -- Move focus to the master window.
  , ((modMask, xK_m), windows W.focusMaster)

  -- Swap the focused window and the master window.
  , ((modMask, xK_Return), windows W.swapMaster)

  -- Swap the focused window with the next window.
  , ((modMask .|. shiftMask, xK_j), windows W.swapDown)

  -- Swap the focused window with the previous window.
  , ((modMask .|. shiftMask, xK_k), windows W.swapUp)

  -- Shrink the master area.
  , ((modMask, xK_h), sendMessage Shrink)

  -- Expand the master area.
  , ((modMask, xK_l), sendMessage Expand)

  -- Push window back into tiling.
  , ((modMask, xK_t), withFocused $ windows . W.sink)

  -- Increment the number of windows in the master area.
  , ((modMask, xK_comma), sendMessage (IncMasterN 1))

  -- Decrement the number of windows in the master area.
  , ((modMask, xK_period), sendMessage (IncMasterN (-1)))

  -- Quit xmonad.
  , ((modMask .|. shiftMask, xK_q), io exitSuccess)

  -- Restart xmonad.
  , ((modMask, xK_q), restart "xmonad" True)

  -- Cycle active workspaces
  -- , ((modMask, xK_o), moveTo Next (WSIs (return isActiveWS)))
  -- , ((modMask .|. shiftMask, xK_o), moveTo Prev (WSIs (return isActiveWS)))
  ]
  ++

  -- mod-[1..9], Switch to workspace N
  -- mod-shift-[1..9], Move client to workspace N
  [((m .|. modMask, k), windows $ f i)
      | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
      , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
  ++

  -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
  -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
  [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
      | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
      , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]


------------------------------------------------------------------------
-- Mouse bindings
--

myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList
  [
    -- mod-button1, Set the window to floating mode and move by dragging
    ((modMask, button1),
     (\w -> focus w >> mouseMoveWindow w))

    -- mod-button2, Raise the window to the top of the stack
    , ((modMask, button2),
       (\w -> focus w >> windows W.swapMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modMask, button3),
       (\w -> focus w >> mouseResizeWindow w))

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
  ]

------------------------------------------------------------------------
-- Startup hook
-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
myStartupHook = return ()

------------------------------------------------------------------------
-- Run xmonad with all the defaults we set up.
--
main = do
  xmproc <- spawnPipe "xmobar ~/.xmonad/xmobar.hs"
  xmonad $ fullscreenSupport $ defaults {
      logHook = dynamicLogWithPP $ xmobarPP {
            ppOutput = hPutStrLn xmproc
          , ppTitle = xmobarColor xmobarTitleColor "" . shorten 80
          , ppCurrent = xmobarColor xmobarCurrentWorkspaceColor "" . wrap "[" "]"
          , ppSep = xmobarColor xmobarSepColor "" " | "
          , ppLayout = xmobarColor xmobarLayoutColor ""
          , ppHidden = (\ws -> if ws == "NSP" then "" else ws)
      }
      , manageHook = manageDocks <+> insertPosition Below Newer <+> myManageHook <+> namedScratchpadManageHook myScratchpads
      , startupHook = setWMName "LG3D"
  }


------------------------------------------------------------------------
-- Combine it all together
-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs
--
-- No need to modify this.
--
defaults = defaultConfig {
    -- simple stuff
    terminal           = myTerminal,
    focusFollowsMouse  = False,
    clickJustFocuses   = False,
    borderWidth        = myBorderWidth,
    modMask            = myModMask,
    workspaces         = myWorkspaces,
    normalBorderColor  = myNormalBorderColor,
    focusedBorderColor = myFocusedBorderColor,

    -- key bindings
    keys               = myKeys,
    mouseBindings      = myMouseBindings,

    -- hooks, layouts
    layoutHook         = smartBorders myLayout,
    manageHook         = myManageHook,
    startupHook        = myStartupHook,
    handleEventHook    = handleEventHook defaultConfig <+> docksEventHook
}
