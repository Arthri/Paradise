import { reduce, zip } from './collections';

/**
 * Creates a vector, with as many dimensions are there are arguments.
 */
export const vecCreate = (...components) => {
  if (Array.isArray(components[0])) {
    return [...components[0]];
  }
  return components;
};

const ADD = (a, b) => a + b;
const SUB = (a, b) => a - b;
const MUL = (a, b) => a * b;
const DIV = (a, b) => a / b;

export const vecAdd = (...vecs) => {
  return reduce((a, b) => zip(a, b).map((v) => ADD(...v)))(vecs);
};

export const vecSubtract = (...vecs) => {
  return reduce((a, b) => zip(a, b).map((v) => SUB(...v)))(vecs);
};

export const vecMultiply = (...vecs) => {
  return reduce((a, b) => zip(a, b).map((v) => MUL(...v)))(vecs);
};

export const vecDivide = (...vecs) => {
  return reduce((a, b) => zip(a, b).map((v) => DIV(...v)))(vecs);
};

export const vecScale = (vec, n) => {
  return vec.map((x) => x * n);
};

export const vecInverse = (vec) => {
  return vec.map((x) => -x);
};

export const vecLength = (vec) => {
  return Math.sqrt(reduce(ADD)(vecMultiply(vec, vec)));
};

export const vecNormalize = (vec) => {
  return vecDivide(vec, vecLength(vec));
};
