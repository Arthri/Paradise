/**
 * A fast implementation of reduce.
 */
export const reduce = (reducerFn, initialValue) => (array) => {
  const length = array.length;
  let i;
  let result;
  if (initialValue === undefined) {
    i = 1;
    result = array[0];
  } else {
    i = 0;
    result = initialValue;
  }
  for (; i < length; i++) {
    result = reducerFn(result, array[i], i, array);
  }
  return result;
};

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
