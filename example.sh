#!/bin/bash

source ./stack.sh || { echo "./stack.sh not found"; exit 1; }

echo "First, create a snapshot of the current environment to detect"
echo "possible memory leaks after we end up working with our stack."
env="$(set | grep -v '^_=')"
echo
echo "Ok, let's create some stack, shall we?"

stack:new s

${s}.size
@out size = 1

echo "Size of the new stack is '${size}', but also '$(${s}.size -)'."
unset size

echo "Now push some values onto it."

${s}.push value{1..20}

echo "Size of the filled stack is '$(${s}.size -)'."

${s}.top
@out top = 1

echo "Top value is '${top}', but also '$(${s}.top -)."
unset top

echo "Now pop out the values."
echo
while (( $(${s}.size -) )) ; do

    ${s}.pop -

    ${s}.pop
    @out val = 1
    echo "${val}"

done
unset val
echo
echo "Size of the emptied stack is $(${s}.size -)."
echo "Now destroy the stack."

${s}.destroy

echo
echo "And try to push some value again."

${s}.push "Ouch" 2>/dev/null

(( $? == 127 )) && echo "  > Error: Command was not found. <" || echo "This stack implementation is a broken crap, you knew it."
echo 'Delete the variable holding the stack "object".'
unset s
echo
echo "Now compare the snapshot of the environment before we used the stack with the current state:"
echo
echo -n '  >>> '
diff -s <( printf "%s\n" "${env}" ) <( unset env RANDOM; set  | grep -v '^_=' | egrep -v '(BASH_REMATCH=)')
