# ***************************************************
# This tests display expressions.
# ***************************************************
set debuggertesting on
b 6
c
display a
display b 
disable display b
disable display 1
c
enable display b
enable display 1
undisplay a
undisplay 2
c
q

