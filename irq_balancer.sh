#!/bin/bash

ncpus=$(nproc)

n=0
for irq in `grep eth /proc/interrupts | awk '{print $1}' | sed s/\://g`
do
  f="/proc/irq/$irq/smp_affinity"
  test -r "$f" || continue
  cpu=$[$ncpus - ($n % $ncpus) - 1]
  if [ $cpu -ge 0 ]
  then
    mask=`printf %x $[2 ** $cpu]`
    echo "Assign SMP affinity: eth queue $n, irq $irq, cpu $cpu, mask 0x$mask"
    echo "$mask" > "$f"
    let n+=1
  fi
done
