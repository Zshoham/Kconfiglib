/* SPDX-License-Identifier: ISC */
/*
 * Helpers for using Kconfig Boolean and tristate symbols in C and
 * preprocessor expressions. Include the generated configuration header first.
 *
 * The KCONFIG_IS_*() and KCONFIG_TRISTATE() macros are C expressions: code in
 * ordinary C branches remains parsed and type-checked in every configuration.
 * KCONFIG_SELECT_TRISTATE() and KCONFIG_IF_*() select token sequences before
 * C parsing. Use them only for declarations or APIs that do not exist in all
 * configurations, and enclose every selected token sequence in parentheses.
 */
#ifndef KCONFIGLIB_H
#define KCONFIGLIB_H

#define KCONFIGLIB_ARG_PLACEHOLDER_1 0,
#define KCONFIGLIB_TAKE_SECOND_ARG(_ignored, value, ...) value

#define KCONFIGLIB_IS_DEFINED(value) KCONFIGLIB__IS_DEFINED(value)
#define KCONFIGLIB__IS_DEFINED(value) \
    KCONFIGLIB___IS_DEFINED(KCONFIGLIB_ARG_PLACEHOLDER_##value)
#define KCONFIGLIB___IS_DEFINED(arg1_or_junk) \
    KCONFIGLIB_TAKE_SECOND_ARG(arg1_or_junk 1, 0)

#define KCONFIGLIB_DEBRACKET(...) __VA_ARGS__
#define KCONFIGLIB_COND_CODE_1(flag, if_code, else_code) \
    KCONFIGLIB__COND_CODE_1(flag, if_code, else_code)
#define KCONFIGLIB__COND_CODE_1(flag, if_code, else_code) \
    KCONFIGLIB___COND_CODE_1(KCONFIGLIB_ARG_PLACEHOLDER_##flag, \
                             if_code, else_code)
#define KCONFIGLIB___COND_CODE_1(one_or_two_args, if_code, else_code) \
    KCONFIGLIB____COND_CODE_1(one_or_two_args if_code, else_code)
#define KCONFIGLIB____COND_CODE_1(_ignored, value, ...) \
    KCONFIGLIB_DEBRACKET value

#define KCONFIG_TRISTATE_DISABLED 0
#define KCONFIG_TRISTATE_MODULE   1
#define KCONFIG_TRISTATE_BUILTIN  2

/*
 * Values returned by KCONFIG_TRISTATE(). They match the Kconfig ordering
 * disabled < module < built in.
 */

/*
 * KCONFIG_IS_BUILTIN(CONFIG_FOO) evaluates to 1 when CONFIG_FOO is 'y', and
 * to 0 otherwise.
 */
#define KCONFIG_IS_BUILTIN(option) KCONFIGLIB_IS_DEFINED(option)

/*
 * KCONFIG_IS_MODULE(CONFIG_FOO) evaluates to 1 when CONFIG_FOO is 'm', and
 * to 0 otherwise.
 */
#define KCONFIG_IS_MODULE(option) KCONFIGLIB_IS_DEFINED(option##_MODULE)

/*
 * KCONFIG_IS_ENABLED(CONFIG_FOO) evaluates to 1 when CONFIG_FOO is 'y' or
 * 'm', and to 0 otherwise.
 */
#define KCONFIG_IS_ENABLED(option) \
    (KCONFIG_IS_BUILTIN(option) || KCONFIG_IS_MODULE(option))

/*
 * KCONFIG_TRISTATE(CONFIG_FOO) evaluates to KCONFIG_TRISTATE_BUILTIN for
 * 'y', KCONFIG_TRISTATE_MODULE for 'm', and KCONFIG_TRISTATE_DISABLED for
 * 'n' or an undefined symbol.
 */
#define KCONFIG_TRISTATE(option) \
    (KCONFIG_IS_BUILTIN(option) ? KCONFIG_TRISTATE_BUILTIN : \
     KCONFIG_IS_MODULE(option) ? KCONFIG_TRISTATE_MODULE : \
                                 KCONFIG_TRISTATE_DISABLED)

/*
 * KCONFIG_IS_REACHABLE(CONFIG_FOO, CURRENT_MODULE) evaluates to 1 when
 * CONFIG_FOO is built in, or when it is a module and CURRENT_MODULE expands
 * to 1. CURRENT_MODULE may be undefined for built-in compilation.
 */
#define KCONFIG_IS_REACHABLE(option, current_module) \
    (KCONFIG_IS_BUILTIN(option) || \
     (KCONFIG_IS_MODULE(option) && KCONFIGLIB_IS_DEFINED(current_module)))

/*
 * KCONFIG_SELECT_TRISTATE(CONFIG_FOO, (builtin_tokens), (module_tokens),
 *                         (disabled_tokens)) emits exactly one parenthesized
 * token sequence: the one matching the tristate value of CONFIG_FOO.
 *
 * The outer parentheses around each branch are removed. This permits commas
 * inside a branch, for example an initializer entry written as ``(value,)``.
 * Macro arguments are expanded before selection.
 *
 * Use KCONFIG_IS_ENABLED() for ordinary conditional execution instead, so
 * both C branches remain type-checked.
 */
#define KCONFIG_SELECT_TRISTATE(option, builtin_code, module_code, \
                                 disabled_code) \
    KCONFIGLIB_COND_CODE_1(option, builtin_code, \
        (KCONFIGLIB_COND_CODE_1(option##_MODULE, module_code, disabled_code)))

/*
 * KCONFIG_IF_BUILTIN(CONFIG_FOO, (tokens)) emits tokens only for a built-in
 * ('y') symbol.
 */
#define KCONFIG_IF_BUILTIN(option, code) \
    KCONFIG_SELECT_TRISTATE(option, code, (), ())
/*
 * KCONFIG_IF_MODULE(CONFIG_FOO, (tokens)) emits tokens only for a module
 * ('m') symbol.
 */
#define KCONFIG_IF_MODULE(option, code) \
    KCONFIG_SELECT_TRISTATE(option, (), code, ())
/*
 * KCONFIG_IF_ENABLED(CONFIG_FOO, (tokens)) emits tokens for either a built-in
 * ('y') or module ('m') symbol. All KCONFIG_IF_*() macros emit nothing for
 * undefined or disabled symbols. Put statement semicolons inside the
 * parenthesized token argument.
 */
#define KCONFIG_IF_ENABLED(option, code) \
    KCONFIG_SELECT_TRISTATE(option, code, code, ())

#endif /* KCONFIGLIB_H */
