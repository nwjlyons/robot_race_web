/**
 * Cycles through the given array, infinitely.
 *
 * Example:
 *
 *  > cycle(["cyan", "magenta", "yellow"], 5)
 *  > "yellow"
 */
export function cycle<T>(array: T[], index: number): T {
    return array[index % array.length]
}