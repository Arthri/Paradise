/**
 * Creates an array of grouped elements, the first of which contains
 * the first elements of the given arrays, the second of which contains
 * the second elements of the given arrays, and so on.
 *
 * @returns {any[]}
 */
export const zip = (...arrays) => {
  if (arrays.length === 0) {
    return;
  }
  const otherArrays = arrays.slice(1);
  return arrays[0].map((v, i) => [v, ...otherArrays.map((array) => array[i])]);
};
