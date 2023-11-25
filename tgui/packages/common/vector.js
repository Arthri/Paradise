import { zip } from './collections';

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
  return zip(...vecs).map((v) => v.reduce(ADD, 0));
};

export const vecSubtract = (...vecs) => {
  return zip(...vecs).map((v) => v.reduce(SUB, 0));
};

export const vecMultiply = (...vecs) => {
  return zip(...vecs).map((v) => v.reduce(MUL, 0));
};

export const vecDivide = (...vecs) => {
  return zip(...vecs).map((v) => v.reduce(DIV, 0));
};

export const vecScale = (vec, n) => {
  return vec.map((x) => x * n);
};

export const vecInverse = (vec) => {
  return vec.map((x) => -x);
};

export const vecLength = (vec) => {
  return Math.sqrt(vecMultiply(vec, vec).reduce(ADD, 0));
};

export const vecNormalize = (vec) => {
  return vecDivide(vec, vecLength(vec));
};
