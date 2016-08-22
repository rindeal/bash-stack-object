#!/bin/bash
# Copyright 2016 Jan Chren (rindeal)
# Distributed under the terms of the BSD 3-Clause licence

__stack::get_id() {
    eval "${2:-"_sid"}=\"${FUNCNAME[${1}]%.*}\""
}

__stack::size() {
    local _stack_id="${1?"${FUNCNAME}: error"}"
    local _size
    eval "${2:-"_size"}=\"\${#${_stack_id}[@]}\""
    [[ -n "${2}" ]] || printf '%d\n' "${_size}"
}

__stack::push() {
    local _stack_id="${1?"${FUNCNAME}: error"}"
    shift

    local _i='' _item
    __stack::size "${_stack_id}" _i

    for _item in "${@}" ; do
        eval "${_stack_id}[${_i}]='${_item}'"
        ((_i++))
    done

    return 0
}

__stack::top() {
    local __sid="${1?"${FUNCNAME}: error"}" __rv="${2}"
    local __i=-1
    __stack::size "${__sid}" __i
    # bash arrays are indexed from zero
    ((--__i))

    local __vl
    eval "__vl=\"\${${__sid}[${__i}]}\""

    if [[ -n "${__rv}" ]] ; then
        eval "${__rv}=\"\${__vl}\""
    else
        printf '%s\n' "${__vl}"
    fi

    return 0
}

__stack::pop() {
    local __sid="${1?"${FUNCNAME}: error"}" _res_var="${2}"
    local __i=-1
    __stack::size "${__sid}" __i
    # bash arrays are indexed from zero
    ((--__i))

    local item
    __stack::top "${__sid}" "${_res_var:-"item"}"

    unset ${__sid}[${__i}]

    [[ -n "${_res_var}" ]] || printf '%s\n' "${item}"
}

__stack::get_methods() {
    echo destroy pop push size top
}

__stack::destroy() {
    local __sid="${1?"${FUNCNAME}: error"}"

    ##destroy wrapper funcs
    local methods=( $(__stack::get_methods) )
    unset -f "${methods[@]/#/"${__sid}."}"

    ## destroy the variable holding our stack
    unset "${__sid}"
}

stack::new() {
    local _rvar="${1?"${FUNCNAME}: error"}"
    local __stack_id

    ## generate stack id
    while (( 1 )) ; do
        __stack_id="__stack_oop_${FUNCNAME[1]}_$((RANDOM*RANDOM))"
        if ! declare -p "${__stack_id}" &>/dev/null ; then
            break
        fi
    done

    # create array holding our stack
    eval "declare -g -a ${__stack_id}=()"

    ## generate wrappers
    local m
    for m in $(__stack::get_methods) ; do
        eval "
            ${__stack_id}.${m}(){
                __stack::${m} '${__stack_id}' \"\${@}\"
            }
        "
    done

    ## And finally assign the id to the variable.
    ## This will allow calling functions like `${_rvar}.method`
    eval "${_rvar}='${__stack_id}'"
}
