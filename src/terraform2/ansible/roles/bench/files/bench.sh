#!/bin/bash

dir=(/mnt/ebs/1)

for item in ${dir[@]};do
  cd $item
  echo ${item} ===================
  echo r
  fio -name=r -direct=1 -rw=read -bs=4k -size=1G -numjobs=16 -runtime=16 -group_reporting
  echo w
  fio -name=w -direct=1 -rw=write -bs=4k -size=1G -numjobs=16 -runtime=16 -group_reporting
  echo rr
  fio -name=rr -direct=1 -rw=randread -bs=4k -size=1G -numjobs=16 -runtime=16 -group_reporting
  echo rw
  fio -name=rw -direct=1 -rw=randwrite -bs=4k -size=1G -numjobs=16 -runtime=16 -group_reporting
done