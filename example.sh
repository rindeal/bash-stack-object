#!/bin/bash

source ./stack.sh || { echo "stack.sh not found"; exit 1; }

echo "Let's create some stack, shall we?"
stack::new s
echo "Size of the new stack is $(${s}.size)"

echo "Now push some values onto it"
${s}.push {1..20}

echo "Size of the filled stack is $(${s}.size)"

echo "Top value is '$(${s}.top)'"

echo "Now pop out some values out of it"
while (( $(${s}.size) > 10 )) ; do
    ${s}.pop
done

echo "Now pop out the rest using some pretty printing"
val=''
while (( $(${s}.size) )) ; do
    ${s}.pop val
    printf ">> %02d <<\n" "${val}"
done
unset val

echo "Size of the emptied stack = $(${s}.size)"

echo "Now destroy the stack"
${s}.destroy

echo "And try to push some value again"
${s}.push "Ouch" 2>/dev/null
(( $? == 127 )) && echo "Error: Command was not found" || echo "This stack implementation is a broken crap, you knew it"
