Config { overrideRedirect = False
       , font = "UbuntuMono Nerd Font 18"
       , bgColor = "#282828"
       , fgColor = "#ebdbb2"
       , position = TopH 25
       , commands = [ Run Weather "CYEG"
                      [ "--template", "<weather> <tempC>°C"
                      ] 36000
	                  , Run Load
                      [ "--template", "󰇅 <load1> <load5> <load15>"
                      , "--ddigits", "2" -- 2 decimal places
                      , "-L", "2"
                      , "-H", "8"
                      , "--high", "#9d0006,#ebdbb2"
                      , "--normal", "#076678,#ebdbb2"
                      ] 10
                    , Run Alsa "default" "Master"
                      [ "--template", "<status> <volume>%"
                      , "--" -- volume specific options
                        , "--on",   "󰖀"
                        , "--off",  "󰖁"
                        , "--onc",  "#282828,#ebdbb2" -- On colour
                        , "--offc", "#282828,#ebdbb2" -- Off colour
                      ]
                    , Run Network "wlp0s20f3"
                      [
                      ] 50
                    , Run Network "wg0"
                      [ "--nastring", "󰿇"
                      ] 50
                    , Run Battery
                      [ "--template" , "<acstatus>"
                      , "--Low"      , "10"        -- units: %
                      , "--High"     , "80"        -- units: %
                      , "--low"      , "#fabd2f,#cc241d"
                      , "--normal"   , "#b57614,#ebdbb2"
                      , "--high"     , "#79740e,#ebdbb2"

                      , "--" -- battery specific options
                        -- discharging status
                        , "-o"	, "󰁿 <left>% (<timeleft>)"
                        -- AC "on" status
                        , "-O"	, "<fc=#d65d0e,#ebdbb2>󰢝 (<timeleft>)</fc>"
                        -- charged status
                        , "-i"	, "<fc=#427b58,#ebdbb2>󰂅 Charged</fc>"
                      ] 50
                    , Run Date "<fc=#8be9fd>%H:%M</fc> %a %m-%d" "date" 600
                    , Run XMonadLog
                    ]
       , sepChar = "%"
       , alignSep = "}{"
       , template = "%XMonadLog% }{ <fc=#282828,#ebdbb2> %CYEG% | %load% | %battery% | %alsa:sofhdadsp:Master% | %wlp0s20f3% %wg0% </fc> %date% "
       , verbose = True
     }
