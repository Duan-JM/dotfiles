## Most used command

```bash
# basic
tmux a -t <session-name> # reattach
tmux kill-server # kill server
tmux new -s <session-name>

# windows / session
<prefix> - c     # new windows
<prefix> - ,     # rename windows
<prefix> - [ / ] # pre or next window
<prefix> - w     # change windows
<prefix> - s     # change sessions

# panel
<prefix> - = / - # split or vertical split panel
<prefix> - <c-h> # hjkl resize panel

# config or plugin
<prefix> - r     # reload tmux.conf
<prefix> - I     # install plugin with tpm
<prefix> - U     # update plugin
<prefix> - <c-s> # save layout
<prefix> - <c-r> # reload layout

# visual mode
<prefix> - v   # copy mode
# press space to start copy then enter to end
# use <prefix> - p to paste
```

## Notes

Special Thanks to ms-jpq, my tmux conf is basically built upon her settings
[here](https://github.com/cyproterone/tmux). Please also checkout her awesome
cli-tools [sad](https://github.com/ms-jpq/sad).


## References
- ms-jpq's settings [here](https://github.com/cyproterone/tmux)

