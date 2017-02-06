#!/bin/bash
# Copyright 2016-2017 Jan Chren (rindeal)
# Distributed under the terms of the BSD 3-Clause licence

# NOTE: this function must not contain any variables to prevent shadowing
@type() {
    if ! [[ "$(declare -p "${1}" 2>/dev/null)" =~ declare[[:space:]]-(.).* ]] ; then
        echo "${FUNCNAME}: Error: unknown type" &>2
        return 1
    fi

    case "${BASH_REMATCH[1]}" in
    '-'|'r')    echo - ;;
    'i')  echo i ;;
    'a')  echo a ;;
    'A')  echo A ;;
    *)
        echo "${FUNCNAME}: Error: unknown type '${BASH_REMATCH[1]}'" &>2
        return 1
        ;;
    esac
}

# NOTE: __out_v is the only shadowable variable
@out() {
    (($# != 3)) && { echo "${FUNCNAME}: error"; return 1; }

    # set case
    if [[ "${1}" =~ ^[1-9]$ ]] ; then
        unset __out_${1}
        local __out_v="$(declare -p "${3}")"
        eval declare -g -$(@type "${3}") __out_${1}="${__out_v#*=}" || return 1

    # get case
    elif [[ "${3}" =~ ^[1-9]$ ]] ; then
        if [[ "${1}" == '-' ]] ; then
            eval "printf '%s\n' \"\${__out_${3}}\""
        else
            local __out_v="$(declare -p "__out_${3}")"
            eval eval ${1}="${__out_v#*=}" || return 1
        fi
        unset __out_${3}

    # error case
    else
        echo "${FUNCNAME}: error"
        return 1
    fi

    return 0
}

_stack:size() {
    local sid="${1?"${FUNCNAME}: error"}"

    eval "declare -i size=\${#${sid}[@]}"
    (($?)) && { echo "${FUNCNAME}: Error: assign returned an error" >&2; return 1; }

    [[ "${!#}" == '-' ]] && echo "${size}"
    @out 1 = size
}

_stack:push() {
    local sid="${1?"${FUNCNAME}: error"}"
    shift
    eval "${sid}+=( \"\${@}\" )"
    (($?)) && { echo "${FUNCNAME}: Error: assign returned an error" >&2; return 1; }
}

_stack:top() {
    local sid="${1?"${FUNCNAME}: error"}"
    local val

    declare -i i=
    _stack:size "${sid}"
    @out i = 1

    # --i = bash arrays are indexed from zero
    ((--i < 0)) && \
        { echo "${FUNCNAME}: Error: stack is empty" >&2; return 1; }

    eval "val=\"\${${sid}[${i}]}\""
    (($?)) && { echo "${FUNCNAME}: Error: assign returned an error" >&2; return 1; }

    [[ "${!#}" == '-' ]] && printf '%s\n' "${val}"
    @out 1 = val
}

_stack:pop() {
    local sid="${1?"${FUNCNAME}: error"}"
    declare -i i=
    _stack:size "${sid}"
    @out i = 1

    # bash arrays are indexed from zero
    ((--i < 0)) && \
        { echo "${FUNCNAME}: Error: stack is empty" >&2; return 1; }

    local val
    _stack:top "${sid}"
    (($?)) && { echo "${FUNCNAME}: Error: :top returned an error" >&2; return 1; }
    @out val = 1

    unset ${sid}[${i}]
    (($?)) && { echo "${FUNCNAME}: Error: unset returned an error" >&2; return 1; }

    [[ "${!#}" == '-' ]] && printf '%s\n' "${val}"
    @out 1 = val
}

__stack:methods() {
    local line methods=() regex="declare -f (.*)"

    while read -r line ; do
        methods+=( "${line#*:}" )
    done < <( compgen -A function -X '!_stack:*' )

    [[ "${!#}" == '-' ]] && echo "${methods[@]}"
    @out 1 = methods
}

_stack:destroy() {
    local sid="${1?"${FUNCNAME}: error"}"

    ## destroy wrapper funcs
    declare -a methods=()
    __stack:methods
    @out methods = 1
    unset -f "${methods[@]/#/"${sid}."}"
    (($?)) && { echo "${FUNCNAME}: Error: unsetting functions returned an error" >&2; return 1; }

    ## destroy the variable holding our stack
    unset "${sid}"
    (($?)) && { echo "${FUNCNAME}: Error: unsetting sid returned an error" >&2; return 1; }
}

stack:new() {
    local ret_var="${1?"${FUNCNAME}: error"}"
    declare -- sid

    ## generate stack id
    while (( 1 )) ; do
        sid="__stack_oop_${FUNCNAME[1]}_$((RANDOM*RANDOM))"
        if ! declare -p "${sid}" &>/dev/null ; then
            break
        fi
    done

    # create array holding our stack
    eval "declare -g -a ${sid}=()"

    ## generate wrappers
    __stack:methods
    local m _methods
    @out _methods = 1
    for m in "${_methods[@]}" ; do
        eval "
            ${sid}.${m}() {
                _stack:${m} '${sid}' \"\${@}\"
            }
        "
    done

    ## And finally assign the id to the variable.
    ## This will allow calling functions like `${ret_var}.method`
    eval "${ret_var}='${sid}'"
}
