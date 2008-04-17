# ***************************************************
# This tests step, next, finish and continue
# ***************************************************
set debuggertesting on
set callstyle last
next
where
step a
step 2
where
n 2
step
where
step 3
where
# finish
quit
