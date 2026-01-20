/*
 * Test file for no-comments-please.nvim
 * This file contains various C comment patterns to test folding behavior
 * MISRA-C compliant comment styles
 */

#include <stdio.h>
#include <stdint.h>

// Single-line comment using C99 style (should NOT fold)

int32_t example1(void)
{
    return 42;
}

/*
 * Multi-line block comment that spans
 * multiple lines. This should be folded
 * when the plugin is active.
 */

int32_t example2(void)
{
    int32_t x = 10; /* inline comment (should NOT fold) */
    return x * 2;
}

// Another single-line comment (should NOT fold)
// Check this

/*
 * This is another multi-line comment block.
 * It contains several lines of text.
 * This should also be folded.
 */

/**
 * @brief Doxygen-style documentation comment.
 *
 * This is a typical function documentation block
 * used in many C projects. Should be foldable.
 *
 * @param value Input value to process
 * @return Processed result
 */
int32_t documented_function(int32_t value)
{
    return value * 2;
}

// Single comment between functions

int32_t simple_function(void)
{
    return 0;
}

/*
 * First consecutive block comment.
 * This is part of a series of comment blocks.
 */

/*
 * Second consecutive block comment.
 * When merge_consecutive is enabled,
 * this should be merged with the previous one.
 */

struct Config {
    int32_t width;   /* inline comment for width */
    int32_t height;  /* inline comment for height */
};

/*
 * Function with nested structure.
 * Contains various code patterns.
 */
int32_t with_nested_structure(void)
{
    if (1) {
        /*
         * Nested multi-line comment inside a function.
         * Should be foldable independently.
         */
        struct Config cfg = {
            .width = 100,   /* inline width */
            .height = 200   /* inline height */
        };
        return cfg.width;
    }
    return 0;
}

/**
 * @brief Another Doxygen comment block.
 *
 * Testing multiple documentation blocks
 * with different formatting styles.
 *
 * @note This is a note section
 * @warning This is a warning section
 */
void documented_function2(void)
{
    // Single line comment in function body
    int32_t result = 42;
    printf("Result: %d\n", result);
}

/*
 * MISRA-C Rule Documentation Block
 *
 * Rule 1: All variables must be initialized
 * Rule 2: No implicit type conversions
 * Rule 3: All functions must have prototypes
 */

static inline int32_t inline_function(void)
{
    return 1;
}

/*
 * Final multi-line comment block.
 * Testing if comment folding works at the end of file.
 */
