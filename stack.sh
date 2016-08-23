#!/bin/bash
# Copyright 2016 Jan Chren (rindeal)
# Distributed under the terms of the BSD 3-Clause licence

__stack::size() {
    local __size_sid="${1?"${FUNCNAME}: error"}" __size_res_var="${2}"
    local __size_sz

    eval "${__size_res_var:-"__size_sz"}=\"\${#${__size_sid}[@]}\""
    (($?)) && { echo "${FUNCNAME}: Error: assign returned an error" >&2; return 1; }

    [[ -n "${__size_res_var}" ]] || printf '%s\n' "${__size_sz}"
}

__stack::push() {
    local __push_sid="${1?"${FUNCNAME}: error"}"
    shift
    eval "${__push_sid}+=( \"\${@}\" )"
    (($?)) && { echo "${FUNCNAME}: Error: assign returned an error" >&2; return 1; }
}

__stack::top() {
    local __top_sid="${1?"${FUNCNAME}: error"}" __top_res_var="${2}"
    local __top_i=-1 __top_val

    __stack::size "${__top_sid}" __top_i
    # bash arrays are indexed from zero
    ((--__top_i < 0)) && \
        { echo "${FUNCNAME}: Error: stack is empty" >&2; return 1; }

    eval "${__top_res_var:-"__top_val"}=\"\${${__top_sid}[${__top_i}]}\""
    (($?)) && { echo "${FUNCNAME}: Error: assign returned an error" >&2; return 1; }

    [[ -n "${__top_res_var}" ]] || printf '%s\n' "${__top_val}"
}

__stack::pop() {
    local __pop_sid="${1?"${FUNCNAME}: error"}" __pop_res_var="${2}"
    local __pop_i=-1
    __stack::size "${__pop_sid}" __pop_i
    # bash arrays are indexed from zero
    ((--__pop_i < 0)) && \
        { echo "${FUNCNAME}: Error: stack is empty" >&2; return 1; }

    local __pop_val
    __stack::top "${__pop_sid}" "${__pop_res_var:-"__pop_val"}"
    (($?)) && { echo "${FUNCNAME}: Error: ::top returned an error" >&2; return 1; }

    unset ${__pop_sid}[${__pop_i}]
    (($?)) && { echo "${FUNCNAME}: Error: unset returned an error" >&2; return 1; }

    [[ -n "${__pop_res_var}" ]] || printf '%s\n' "${__pop_val}"
}

__stack::get_methods() {
    echo destroy pop push size top
}

__stack::destroy() {
    local __destroy_sid="${1?"${FUNCNAME}: error"}"

    ## destroy wrapper funcs
    local __destroy_methods=( $(__stack::get_methods) )
    unset -f "${__destroy_methods[@]/#/"${__destroy_sid}."}"
    (($?)) && { echo "${FUNCNAME}: Error: unsetting functions returned an error" >&2; return 1; }

    ## destroy the variable holding our stack
    unset "${__destroy_sid}"
    (($?)) && { echo "${FUNCNAME}: Error: unsetting __destroy_sid returned an error" >&2; return 1; }
}

stack::new() {
    local __new_ret_var="${1?"${FUNCNAME}: error"}"
    local __new_sid

    ## generate stack id
    while (( 1 )) ; do
        __new_sid="__stack_oop_${FUNCNAME[1]}_$((RANDOM*RANDOM))"
        if ! declare -p "${__new_sid}" &>/dev/null ; then
            break
        fi
    done

    # create array holding our stack
    eval "declare -g -a ${__new_sid}=()"

    ## generate wrappers
    local __new_m
    for __new_m in $(__stack::get_methods) ; do
        eval "
            ${__new_sid}.${__new_m}(){
                __stack::${__new_m} '${__new_sid}' \"\${@}\"
            }
        "
    done

    ## And finally assign the id to the variable.
    ## This will allow calling functions like `${__new_ret_var}.method`
    eval "${__new_ret_var}='${__new_sid}'"
}
