/* See LICENSE file for copyright and license details. */

#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const unsigned int gappih    = 0;        /* horiz inner gap between windows */
static const unsigned int gappiv    = 0;        /* vert inner gap between windows */
static const unsigned int gappoh    = 0;        /* horiz outer gap between windows and screen edge */
static const unsigned int gappov    = 0;        /* vert outer gap between windows and screen edge */
static       int smartgaps          = 0;        /* 1 means no outer gap when there is only one window */
static const int showbar            = 1;        /* 0 means no bar (toggle with MOD+b) */
static const int topbar             = 1;        /* 0 means bottom bar */
static const int vertpad            = 10;       /* vertical padding of bar */
static const int sidepad            = 10;       /* horizontal padding of bar */
static const char *fonts[]          = { "Jetbrains Mono NerdFont:size=12:style=Bold", "monospace:size=12" };
static const char dmenufont[]       = "Jetbrains Mono NerdFont:size=12:style=Bold";
#include "themes/theme.h"
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_accnt, col_accnt },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   isfullscreen   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           0,             -1 },
	{ "Firefox",  NULL,       NULL,       1 << 8,       0,           0,             -1 },
};

/* layout(s) */
static const float mfact     = 0.5;  /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */
static const int refreshrate = 120;  /* refresh rate (per second) for client move/resize */

#define FORCE_VSPLIT 1  /* nrowgrid layout: force two clients to always split vertically */
#include "vanitygaps.c"
#include "unfloat.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },                   /* first entry is default - MOD+ALT+1, layouts[0] */
	{ "[M]",      monocle },                /* MOD+ALT+3, layouts[1] */
	{ "[@]",      spiral },                 /* MOD+ALT+7, layouts[2] */
	{ "[\\]",     dwindle },
	{ "H[]",      deck },
	{ "TTT",      bstack },                 /* MOD+ALT+5, layouts[5] */
	{ "===",      bstackhoriz },
	{ "HHH",      grid },                   /* MOD+ALT+6, layouts[7] */
	{ "###",      nrowgrid },
	{ "---",      horizgrid },
	{ ":::",      gaplessgrid },
	{ "|M|",      centeredmaster },         /* MOD+ALT+4, layouts[11] */
	{ ">M>",      centeredfloatingmaster },
	{ "><>",      NULL },                   /* no layout function means floating - MOD+ALT+2, layouts[13] */
	{ NULL,       NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define ALTKEY Mod1Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-c", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_accnt, "-sf", col_gray4, NULL };
static const char *termcmd[]  = { "kitty", NULL };

#include "movestack.c"
static const Key keys[] = {
	/* modifier                     key                    function        argument */
	{ MODKEY,                       XK_d,                  spawn,          {.v = dmenucmd } },                            // open app launcher MOD+d
	{ MODKEY,                       XK_Return,             spawn,          {.v = termcmd } },                             // spawn terminal MOD+Return
	{ MODKEY|ShiftMask,             XK_Return,             spawn,          SHCMD("thunar") },                             // open file manager MOD+Shift+Return
	{ MODKEY,                       XK_w,                  spawn,          SHCMD("$HOME/.local/bin/wallpaper.sh next") }, // next wallpaper MOD+w
	{ MODKEY|ShiftMask,             XK_w,                  spawn,          SHCMD("$HOME/.local/bin/wallpaper.sh prev") }, // prev wallpaper MOD+Shift+w
	{ MODKEY,                       XK_s,                  spawn,          SHCMD("flameshot gui") },                      // screenshot MOD+s
	{ MODKEY,                       XK_b,                  spawn,          SHCMD("brave") },                              // launch brave browser MOD+b
	{ MODKEY,                       XK_m,                  spawn,          SHCMD("mullvad-browser") },                    // launch mullvad browser MOD+m
	{ MODKEY,                       XK_t,                  spawn,          SHCMD("lxappearance") },                       // launch lxappearance MOD+t
	{ MODKEY,                       XK_space,              spawn,          SHCMD("kitty --hold cat ~/.config/dwm/keybinds.txt") }, // show keybinds MOD+space
	{ MODKEY|ALTKEY|ShiftMask,      XK_l,                  spawn,          SHCMD("exec slock") },                         // lockscreen MOD+ALT+Shift+l
	{ MODKEY,                       XK_x,                  spawn,          SHCMD("archlinux-logout") },                   // logout menu MOD+x
	{ MODKEY,                       XK_j,                  focusstack,     {.i = +1 } },                                  // focus window down stack MOD+j
	{ MODKEY,                       XK_k,                  focusstack,     {.i = -1 } },                                  // focus window up stack MOD+k
	{ MODKEY|ShiftMask,             XK_j,                  movestack,      {.i = +1 } },                                  // move window down stack MOD+Shift+j
	{ MODKEY|ShiftMask,             XK_k,                  movestack,      {.i = -1 } },                                  // move window up stack MOD+Shift+k
	{ MODKEY,                       XK_i,                  incnmaster,     {.i = +1 } },                                  // increase windows in master area MOD+i
	{ MODKEY|ShiftMask,             XK_d,                  incnmaster,     {.i = -1 } },                                  // decrease windows in master area MOD+Shift+d
	{ MODKEY,                       XK_h,                  setmfact,       {.f = -0.05} },                                // adjust mfact MOD+h
	{ MODKEY,                       XK_l,                  setmfact,       {.f = +0.05} },                                // adjust mfact MOD+l
	{ MODKEY|ShiftMask,             XK_h,                  setcfact,       {.f = +0.25} },                                // adjust cfact MOD+Shift+h
	{ MODKEY|ShiftMask,             XK_l,                  setcfact,       {.f = -0.25} },                                // adjust cfact MOD+Shift+l
	{ MODKEY|ShiftMask,             XK_o,                  setcfact,       {.f =  0.00} },                                // reset cfact MOD+Shift+o
	{ MODKEY|ALTKEY,                XK_u,                  incrgaps,       {.i = +10 } },                                 // adjust gaps MOD+ALT+u
	{ MODKEY|ALTKEY|ShiftMask,      XK_u,                  incrgaps,       {.i = -10 } },                                 // adjust gaps MOD+ALT+Shift+u
	{ MODKEY|ALTKEY,                XK_g,                  togglegaps,     {0} },                                         // toggle gaps MOD+ALT+g
	{ MODKEY|ALTKEY|ShiftMask,      XK_g,                  defaultgaps,    {0} },                                         // reset gaps MOD+ALT+Shift+g
	{ MODKEY|ShiftMask,             XK_bracketleft,        setborderpx,    {.i = -2 } },                                  // decrease border width MOD+Shift+[
	{ MODKEY|ShiftMask,             XK_bracketright,       setborderpx,    {.i = +2 } },                                  // increase border width MOD+Shift+]
	{ MODKEY|ShiftMask,             XK_BackSpace,          setborderpx,    {.i = 0 } },                                   // reset border width MOD+Shift+BackSpace
	{ MODKEY,                       XK_Tab,                view,           {0} },                                         // previous tag MOD+Tab
	{ MODKEY,                       XK_Left,               shiftview,      {.i = -1 } },                                  // cycle tag left MOD+Left
	{ MODKEY,                       XK_Right,              shiftview,      {.i = +1 } },                                  // cycle tag right MOD+Right
	{ MODKEY,                       XK_q,                  killclient,     {0} },                                         // close window MOD+q
	{ MODKEY|ShiftMask,             XK_f,                  togglefullscr,  {0} },                                         // toggle actualfullscreen MOD+Shift+f
	{ MODKEY|ShiftMask,             XK_z,                  unfloatvisible, {.v = &layouts[0]} },                          // make floating windows tiled MOD+Shift+z
	{ MODKEY|ALTKEY,                XK_1,                  setlayout,      {.v = &layouts[0]} },                          // layout: tile MOD+ALT+1
	{ MODKEY|ALTKEY,                XK_2,                  setlayout,      {.v = &layouts[13]} },                         // layout: float MOD+ALT+2
	{ MODKEY|ALTKEY,                XK_3,                  setlayout,      {.v = &layouts[1]} },                          // layout: monocle MOD+ALT+3
	{ MODKEY|ALTKEY,                XK_4,                  setlayout,      {.v = &layouts[11]} },                         // layout: centeredmaster MOD+ALT+4
	{ MODKEY|ALTKEY,                XK_5,                  setlayout,      {.v = &layouts[5]} },                          // layout: bstack MOD+ALT+5
	{ MODKEY|ALTKEY,                XK_6,                  setlayout,      {.v = &layouts[7]} },                          // layout: grid MOD+ALT+6
	{ MODKEY|ALTKEY,                XK_7,                  setlayout,      {.v = &layouts[2]} },                          // layout: spiral MOD+ALT+7
	// { MODKEY,                    XK_0,                  view,           {.ui = ~0 } },                                 // view all windows MOD+0
	// { MODKEY|ShiftMask,          XK_0,                  tag,            {.ui = ~0 } },                                 // move window to all tags MOD+Shift+0
	{ MODKEY,                       XK_comma,              focusmon,       {.i = -1 } },                                  // focus prev monitor MOD+,
	{ MODKEY,                       XK_period,             focusmon,       {.i = +1 } },                                  // focus next monitor MOD+.
	{ MODKEY|ShiftMask,             XK_comma,              tagmon,         {.i = -1 } },                                  // move window to prev monitor MOD+Shift+,
	{ MODKEY|ShiftMask,             XK_period,             tagmon,         {.i = +1 } },                                  // move window to next monitor MOD+Shift+.
	TAGKEYS(                        XK_1,                                    0)                                           // switch tag MOD+[1-9]
	TAGKEYS(                        XK_2,                                    1)
	TAGKEYS(                        XK_3,                                    2)
	TAGKEYS(                        XK_4,                                    3)
	TAGKEYS(                        XK_5,                                    4)
	TAGKEYS(                        XK_6,                                    5)
	TAGKEYS(                        XK_7,                                    6)
	TAGKEYS(                        XK_8,                                    7)
	TAGKEYS(                        XK_9,                                    8)
	{ MODKEY|ShiftMask,             XK_q,                  quit,           {0} },                                         // quit dwm MOD+Shift+q
	{ 0,                            XF86XK_AudioRaiseVolume, spawn,        SHCMD("pamixer -i 5") },                       // volume up
	{ 0,                            XF86XK_AudioLowerVolume, spawn,        SHCMD("pamixer -d 5") },                       // volume down
	{ 0,                            XF86XK_AudioMute,        spawn,        SHCMD("pamixer -t") },                         // toggle mute
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
