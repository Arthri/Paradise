const COMPARATOR = (objA, objB) => {
  const criteriaA = objA.criteria;
  const criteriaB = objB.criteria;
  const length = criteriaA.length;
  for (let i = 0; i < length; i++) {
    const a = criteriaA[i];
    const b = criteriaB[i];
    if (a < b) {
      return -1;
    }
    if (a > b) {
      return 1;
    }
  }
  return 0;
};

/**
 * Creates an array of elements, sorted in ascending order by the results
 * of running each element in a collection thru each iteratee.
 *
 * Iteratees are called with one argument (value).
 *
 * @returns {any[]}
 */
export const sortBy =
  (...iterateeFns) =>
  (array) => {
    if (!Array.isArray(array)) {
      return array;
    }
    let length = array.length;
    // Iterate over the array to collect criteria to sort it by
    let mappedArray = [];
    for (let i = 0; i < length; i++) {
      const value = array[i];
      mappedArray.push({
        criteria: iterateeFns.map((fn) => fn(value)),
        value,
      });
    }
    // Sort criteria using the base comparator
    mappedArray.sort(COMPARATOR);
    // Unwrap values
    while (length--) {
      mappedArray[length] = mappedArray[length].value;
    }
    return mappedArray;
  };

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
