#!/bin/bash

SESSION=LocalLab

tmux -2 new-session -d -s $SESSION

# main window for installation
tmux new-window -t $SESSION:1 
# Setup a window per lab machine
tmux new-window -t $SESSION:2 'ssh root@master.cluster1'
tmux new-window -t $SESSION:3 'ssh root@node1.cluster1'
tmux new-window -t $SESSION:4 'ssh root@node2.cluster1'

# Set default window
tmux select-window -t $SESSION:1

# Attach to session
tmux -2 attach-session -t $SESSION

